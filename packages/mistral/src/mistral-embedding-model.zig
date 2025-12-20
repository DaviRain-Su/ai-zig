const std = @import("std");
const embedding = @import("provider").embedding_model;
const shared = @import("provider").shared;

const config_mod = @import("mistral-config.zig");

/// Mistral Embedding Model
pub const MistralEmbeddingModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    config: config_mod.MistralConfig,

    /// Maximum embeddings per call
    pub const max_embeddings_per_call: usize = 32;

    /// Supports parallel calls
    pub const supports_parallel_calls: bool = false;

    /// Create a new Mistral embedding model
    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        config: config_mod.MistralConfig,
    ) Self {
        return .{
            .allocator = allocator,
            .model_id = model_id,
            .config = config,
        };
    }

    /// Get the model ID
    pub fn getModelId(self: *const Self) []const u8 {
        return self.model_id;
    }

    /// Get the provider name
    pub fn getProvider(self: *const Self) []const u8 {
        return self.config.provider;
    }

    /// Get the maximum embeddings per call
    pub fn getMaxEmbeddingsPerCall(self: *const Self) usize {
        _ = self;
        return max_embeddings_per_call;
    }

    /// Generate embeddings
    pub fn doEmbed(
        self: *Self,
        values: []const []const u8,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?embedding.EmbeddingModelV3.EmbedResult, ?anyerror, ?*anyopaque) void,
        callback_context: ?*anyopaque,
    ) void {
        // Use arena for request processing
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const request_allocator = arena.allocator();

        // Check max embeddings
        if (values.len > max_embeddings_per_call) {
            callback(null, error.TooManyEmbeddingValues, callback_context);
            return;
        }

        // Build URL
        const url = config_mod.buildEmbeddingsUrl(
            request_allocator,
            self.config.base_url,
        ) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Build request body
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
        body.put("encoding_format", .{ .string = "float" }) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        _ = url;

        // For now, return placeholder result
        const embeddings = result_allocator.alloc([]f32, values.len) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Mistral embeddings are 1024 dimensions
        const dimensions: usize = 1024;
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

    /// Convert to EmbeddingModelV3 interface
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

test "MistralEmbeddingModel init" {
    const allocator = std.testing.allocator;

    var model = MistralEmbeddingModel.init(
        allocator,
        "mistral-embed",
        .{ .base_url = "https://api.mistral.ai/v1" },
    );

    try std.testing.expectEqualStrings("mistral-embed", model.getModelId());
    try std.testing.expectEqual(@as(usize, 32), model.getMaxEmbeddingsPerCall());
}
