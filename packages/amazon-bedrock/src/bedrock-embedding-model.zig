const std = @import("std");
const embedding = @import("../../provider/src/embedding-model/v3/index.zig");
const shared = @import("../../provider/src/shared/v3/index.zig");

const config_mod = @import("bedrock-config.zig");
const options_mod = @import("bedrock-options.zig");

/// Amazon Bedrock Embedding Model
pub const BedrockEmbeddingModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    config: config_mod.BedrockConfig,

    /// Maximum embeddings per call
    pub const max_embeddings_per_call: usize = 512;

    /// Supports parallel calls
    pub const supports_parallel_calls: bool = true;

    /// Create a new Bedrock embedding model
    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        config: config_mod.BedrockConfig,
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

        // Determine if model is Titan or Cohere
        const is_titan = std.mem.indexOf(u8, self.model_id, "titan") != null;
        const is_cohere = std.mem.indexOf(u8, self.model_id, "cohere") != null;

        // Build URL
        const url = config_mod.buildInvokeModelUrl(
            request_allocator,
            self.config.base_url,
            self.model_id,
        ) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // For Cohere, we can batch embeddings
        if (is_cohere and values.len > 1) {
            var body = std.json.ObjectMap.init(request_allocator);

            var texts = std.json.Array.init(request_allocator);
            for (values) |value| {
                texts.append(.{ .string = value }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };
            }
            body.put("texts", .{ .array = texts }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
            body.put("input_type", .{ .string = "search_document" }) catch |err| {
                callback(null, err, callback_context);
                return;
            };

            _ = url;
            // Make request and parse response...
        } else if (is_titan) {
            // Titan processes one at a time
            var body = std.json.ObjectMap.init(request_allocator);
            body.put("inputText", .{ .string = values[0] }) catch |err| {
                callback(null, err, callback_context);
                return;
            };

            _ = url;
            // Make request and parse response...
        }

        // For now, return placeholder result
        var embeddings = result_allocator.alloc([]f32, values.len) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        const dimensions: usize = if (is_titan) 1536 else if (is_cohere) 1024 else 768;
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

test "BedrockEmbeddingModel init" {
    const allocator = std.testing.allocator;

    var model = BedrockEmbeddingModel.init(
        allocator,
        "amazon.titan-embed-text-v2:0",
        .{ .base_url = "https://bedrock-runtime.us-east-1.amazonaws.com" },
    );

    try std.testing.expectEqualStrings("amazon.titan-embed-text-v2:0", model.getModelId());
    try std.testing.expectEqual(@as(usize, 512), model.getMaxEmbeddingsPerCall());
}
