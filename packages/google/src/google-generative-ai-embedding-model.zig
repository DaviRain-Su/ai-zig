const std = @import("std");
const embedding = @import("provider").embedding_model;
const shared = @import("provider").shared;
const provider_utils = @import("provider-utils");

const config_mod = @import("google-config.zig");
const options_mod = @import("google-generative-ai-options.zig");

/// Google Generative AI Embedding Model
pub const GoogleGenerativeAIEmbeddingModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    config: config_mod.GoogleGenerativeAIConfig,

    /// Maximum embeddings per API call
    pub const max_embeddings_per_call: usize = 2048;

    /// Supports parallel calls
    pub const supports_parallel_calls: bool = true;

    /// Create a new Google Generative AI embedding model
    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        config: config_mod.GoogleGenerativeAIConfig,
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
        provider_options: ?options_mod.GoogleGenerativeAIEmbeddingProviderOptions,
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

        // Build URL - use single or batch endpoint
        const url = if (values.len == 1)
            std.fmt.allocPrint(
                request_allocator,
                "{s}/models/{s}:embedContent",
                .{ self.config.base_url, self.model_id },
            ) catch |err| {
                callback(null, err, callback_context);
                return;
            }
        else
            std.fmt.allocPrint(
                request_allocator,
                "{s}/models/{s}:batchEmbedContents",
                .{ self.config.base_url, self.model_id },
            ) catch |err| {
                callback(null, err, callback_context);
                return;
            };

        // Build request body
        var body = std.json.ObjectMap.init(request_allocator);

        if (values.len == 1) {
            // Single embedding request
            try body.put("model", .{ .string = std.fmt.allocPrint(
                request_allocator,
                "models/{s}",
                .{self.model_id},
            ) catch |err| {
                callback(null, err, callback_context);
                return;
            } });

            var content = std.json.ObjectMap.init(request_allocator);
            var parts = std.json.Array.init(request_allocator);
            var part = std.json.ObjectMap.init(request_allocator);
            part.put("text", .{ .string = values[0] }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
            parts.append(.{ .object = part }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
            content.put("parts", .{ .array = parts }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
            body.put("content", .{ .object = content }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
        } else {
            // Batch embedding request
            var requests = std.json.Array.init(request_allocator);
            for (values) |value| {
                var req = std.json.ObjectMap.init(request_allocator);
                req.put("model", .{ .string = std.fmt.allocPrint(
                    request_allocator,
                    "models/{s}",
                    .{self.model_id},
                ) catch |err| {
                    callback(null, err, callback_context);
                    return;
                } }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };

                var content = std.json.ObjectMap.init(request_allocator);
                content.put("role", .{ .string = "user" }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };

                var parts = std.json.Array.init(request_allocator);
                var part = std.json.ObjectMap.init(request_allocator);
                part.put("text", .{ .string = value }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };
                parts.append(.{ .object = part }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };
                content.put("parts", .{ .array = parts }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };

                req.put("content", .{ .object = content }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };

                // Add provider options
                if (provider_options) |opts| {
                    if (opts.output_dimensionality) |dim| {
                        req.put("outputDimensionality", .{ .integer = @intCast(dim) }) catch |err| {
                            callback(null, err, callback_context);
                            return;
                        };
                    }
                    if (opts.task_type) |task| {
                        req.put("taskType", .{ .string = task.toString() }) catch |err| {
                            callback(null, err, callback_context);
                            return;
                        };
                    }
                }

                requests.append(.{ .object = req }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };
            }
            body.put("requests", .{ .array = requests }) catch |err| {
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
        const embeddings = result_allocator.alloc([]f32, values.len) catch |err| {
            callback(null, err, callback_context);
            return;
        };
        for (embeddings, 0..) |*emb, i| {
            _ = i;
            emb.* = result_allocator.alloc(f32, 768) catch |err| {
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

test "GoogleGenerativeAIEmbeddingModel init" {
    const allocator = std.testing.allocator;

    var model = GoogleGenerativeAIEmbeddingModel.init(
        allocator,
        "text-embedding-004",
        .{},
    );

    try std.testing.expectEqualStrings("text-embedding-004", model.getModelId());
    try std.testing.expectEqualStrings("google.generative-ai", model.getProvider());
    try std.testing.expectEqual(@as(usize, 2048), model.getMaxEmbeddingsPerCall());
}
