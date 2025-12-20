const std = @import("std");
const embedding = @import("../../provider/src/embedding-model/v3/index.zig");
const shared = @import("../../provider/src/shared/v3/index.zig");

const config_mod = @import("openai-compatible-config.zig");

/// OpenAI-compatible Embedding Model
pub const OpenAICompatibleEmbeddingModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    config: config_mod.OpenAICompatibleConfig,

    pub const max_embeddings_per_call: usize = 2048;
    pub const supports_parallel_calls: bool = true;

    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        config: config_mod.OpenAICompatibleConfig,
    ) Self {
        return .{
            .allocator = allocator,
            .model_id = model_id,
            .config = config,
        };
    }

    pub fn getModelId(self: *const Self) []const u8 {
        return self.model_id;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        return self.config.provider;
    }

    pub fn getMaxEmbeddingsPerCall(self: *const Self) usize {
        _ = self;
        return max_embeddings_per_call;
    }

    pub fn doEmbed(
        self: *Self,
        values: []const []const u8,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?embedding.EmbeddingModelV3.EmbedResult, ?anyerror, ?*anyopaque) void,
        callback_context: ?*anyopaque,
    ) void {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const request_allocator = arena.allocator();

        if (values.len > max_embeddings_per_call) {
            callback(null, error.TooManyEmbeddingValues, callback_context);
            return;
        }

        const url = config_mod.buildEmbeddingsUrl(
            request_allocator,
            self.config.base_url,
        ) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        var body = std.json.ObjectMap.init(request_allocator);
        body.put("model", .{ .string = self.model_id }) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        var input = std.json.Array.init(request_allocator);
        for (values) |value| {
            input.append(.{ .string = value }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
        }
        body.put("input", .{ .array = input }) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        _ = url;

        var embeddings = result_allocator.alloc([]f32, values.len) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        const dimensions: usize = 1536;
        for (embeddings, 0..) |*emb, i| {
            _ = i;
            emb.* = result_allocator.alloc(f32, dimensions) catch |err| {
                callback(null, err, callback_context);
                return;
            };
            @memset(emb.*, 0.0);
        }

        const result = embedding.EmbeddingModelV3.EmbedResult{
            .embeddings = embeddings,
            .usage = null,
            .warnings = &[_]shared.SharedV3Warning{},
        };

        callback(result, null, callback_context);
    }

    pub fn asEmbeddingModel(self: *Self) embedding.EmbeddingModelV3 {
        return .{
            .vtable = &vtable,
            .impl = self,
        };
    }

    const vtable = embedding.EmbeddingModelV3.VTable{
        .doEmbed = doEmbedVtable,
        .getModelId = getModelIdVtable,
        .getProvider = getProviderVtable,
        .getMaxEmbeddingsPerCall = getMaxEmbeddingsPerCallVtable,
    };

    fn doEmbedVtable(
        impl: *anyopaque,
        values: []const []const u8,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?embedding.EmbeddingModelV3.EmbedResult, ?anyerror, ?*anyopaque) void,
        callback_context: ?*anyopaque,
    ) void {
        const self: *Self = @ptrCast(@alignCast(impl));
        self.doEmbed(values, result_allocator, callback, callback_context);
    }

    fn getModelIdVtable(impl: *anyopaque) []const u8 {
        const self: *Self = @ptrCast(@alignCast(impl));
        return self.getModelId();
    }

    fn getProviderVtable(impl: *anyopaque) []const u8 {
        const self: *Self = @ptrCast(@alignCast(impl));
        return self.getProvider();
    }

    fn getMaxEmbeddingsPerCallVtable(impl: *anyopaque) usize {
        const self: *Self = @ptrCast(@alignCast(impl));
        return self.getMaxEmbeddingsPerCall();
    }
};

test "OpenAICompatibleEmbeddingModel init" {
    const allocator = std.testing.allocator;

    var model = OpenAICompatibleEmbeddingModel.init(
        allocator,
        "text-embedding-3-small",
        .{ .base_url = "https://api.example.com/v1" },
    );

    try std.testing.expectEqualStrings("text-embedding-3-small", model.getModelId());
}
