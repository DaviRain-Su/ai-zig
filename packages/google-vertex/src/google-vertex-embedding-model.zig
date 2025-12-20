const std = @import("std");
const embedding = @import("../../provider/src/embedding-model/v3/index.zig");
const shared = @import("../../provider/src/shared/v3/index.zig");

const config_mod = @import("google-vertex-config.zig");
const options_mod = @import("google-vertex-options.zig");

/// Google Vertex AI Embedding Model
pub const GoogleVertexEmbeddingModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    config: config_mod.GoogleVertexConfig,

    /// Maximum embeddings per API call
    pub const max_embeddings_per_call: usize = 2048;

    /// Supports parallel calls
    pub const supports_parallel_calls: bool = true;

    /// Create a new Google Vertex AI embedding model
    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        config: config_mod.GoogleVertexConfig,
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
        provider_options: ?options_mod.GoogleVertexEmbeddingProviderOptions,
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
        const url = std.fmt.allocPrint(
            request_allocator,
            "{s}/models/{s}:predict",
            .{ self.config.base_url, self.model_id },
        ) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Build request body
        var body = std.json.ObjectMap.init(request_allocator);

        // Build instances array
        var instances = std.json.Array.init(request_allocator);
        for (values) |value| {
            var instance = std.json.ObjectMap.init(request_allocator);
            instance.put("content", .{ .string = value }) catch |err| {
                callback(null, err, callback_context);
                return;
            };

            if (provider_options) |opts| {
                if (opts.task_type) |task| {
                    instance.put("task_type", .{ .string = task.toString() }) catch |err| {
                        callback(null, err, callback_context);
                        return;
                    };
                }
                if (opts.title) |title| {
                    instance.put("title", .{ .string = title }) catch |err| {
                        callback(null, err, callback_context);
                        return;
                    };
                }
            }

            instances.append(.{ .object = instance }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
        }
        body.put("instances", .{ .array = instances }) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Build parameters
        var parameters = std.json.ObjectMap.init(request_allocator);
        if (provider_options) |opts| {
            if (opts.output_dimensionality) |dim| {
                parameters.put("outputDimensionality", .{ .integer = @intCast(dim) }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };
            }
            if (opts.auto_truncate) |truncate| {
                parameters.put("autoTruncate", .{ .bool = truncate }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };
            }
        }
        if (parameters.count() > 0) {
            body.put("parameters", .{ .object = parameters }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
        }

        // Get headers
        var headers = std.StringHashMap([]const u8).init(request_allocator);
        if (self.config.headers_fn) |headers_fn| {
            headers = headers_fn(&self.config);
        }

        _ = url;
        _ = headers;

        // For now, return placeholder result
        // Actual implementation would make HTTP request and parse response
        var embeddings = result_allocator.alloc([]f32, values.len) catch |err| {
            callback(null, err, callback_context);
            return;
        };
        var total_tokens: u32 = 0;
        for (embeddings, 0..) |*emb, i| {
            _ = i;
            emb.* = result_allocator.alloc(f32, 768) catch |err| {
                callback(null, err, callback_context);
                return;
            };
            @memset(emb.*, 0.0);
            total_tokens += 10; // Placeholder token count
        }

        const result = embedding.EmbeddingModelV3.EmbedResult{
            .embeddings = embeddings,
            .usage = .{
                .tokens = total_tokens,
            },
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
        self.doEmbed(values, null, result_allocator, callback, callback_context);
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

test "GoogleVertexEmbeddingModel init" {
    const allocator = std.testing.allocator;

    var model = GoogleVertexEmbeddingModel.init(
        allocator,
        "text-embedding-004",
        .{ .base_url = "https://us-central1-aiplatform.googleapis.com" },
    );

    try std.testing.expectEqualStrings("text-embedding-004", model.getModelId());
    try std.testing.expectEqual(@as(usize, 2048), model.getMaxEmbeddingsPerCall());
}
