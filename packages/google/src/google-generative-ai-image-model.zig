const std = @import("std");
const image = @import("provider").image_model;
const shared = @import("provider").shared;
const provider_utils = @import("provider-utils");

const config_mod = @import("google-config.zig");
const options_mod = @import("google-generative-ai-options.zig");

/// Google Generative AI Image Model
pub const GoogleGenerativeAIImageModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    settings: options_mod.GoogleGenerativeAIImageSettings,
    config: config_mod.GoogleGenerativeAIConfig,

    /// Default maximum images per call
    pub const default_max_images_per_call: u32 = 4;

    /// Create a new Google Generative AI image model
    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        settings: options_mod.GoogleGenerativeAIImageSettings,
        config: config_mod.GoogleGenerativeAIConfig,
    ) Self {
        return .{
            .allocator = allocator,
            .model_id = model_id,
            .settings = settings,
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

    /// Get the maximum images per call
    pub fn getMaxImagesPerCall(self: *const Self) u32 {
        return self.settings.max_images_per_call orelse default_max_images_per_call;
    }

    /// Generate images
    pub fn doGenerate(
        self: *Self,
        call_options: image.ImageModelV3CallOptions,
        provider_options: ?options_mod.GoogleGenerativeAIImageProviderOptions,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?image.ImageModelV3.GenerateResult, ?anyerror, ?*anyopaque) void,
        callback_context: ?*anyopaque,
    ) void {
        // Use arena for request processing
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const request_allocator = arena.allocator();

        var warnings = std.ArrayList(shared.SharedV3Warning).init(request_allocator);

        // Check for unsupported features
        if (call_options.files != null and call_options.files.?.len > 0) {
            callback(null, error.ImageEditingNotSupported, callback_context);
            return;
        }

        if (call_options.mask != null) {
            callback(null, error.ImageEditingNotSupported, callback_context);
            return;
        }

        if (call_options.size != null) {
            warnings.append(.{
                .type = .unsupported,
                .message = "size option not supported, use aspectRatio instead",
            }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
        }

        if (call_options.seed != null) {
            warnings.append(.{
                .type = .unsupported,
                .message = "seed option not supported through this provider",
            }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
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

        // Instances
        var instances = std.json.Array.init(request_allocator);
        var instance = std.json.ObjectMap.init(request_allocator);
        instance.put("prompt", .{ .string = call_options.prompt }) catch |err| {
            callback(null, err, callback_context);
            return;
        };
        instances.append(.{ .object = instance }) catch |err| {
            callback(null, err, callback_context);
            return;
        };
        body.put("instances", .{ .array = instances }) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Parameters
        var parameters = std.json.ObjectMap.init(request_allocator);
        parameters.put("sampleCount", .{ .integer = @intCast(call_options.n orelse 1) }) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        if (call_options.aspect_ratio) |ar| {
            parameters.put("aspectRatio", .{ .string = ar }) catch |err| {
                callback(null, err, callback_context);
                return;
            };
        }

        // Add provider options
        if (provider_options) |opts| {
            if (opts.person_generation) |pg| {
                parameters.put("personGeneration", .{ .string = pg.toString() }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };
            }
            if (opts.aspect_ratio) |ar| {
                parameters.put("aspectRatio", .{ .string = ar.toString() }) catch |err| {
                    callback(null, err, callback_context);
                    return;
                };
            }
        }

        body.put("parameters", .{ .object = parameters }) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Get headers
        var headers = std.StringHashMap([]const u8).init(request_allocator);
        if (self.config.headers_fn) |headers_fn| {
            headers = headers_fn(&self.config);
        }

        _ = url;
        _ = headers;

        // For now, return placeholder result
        // Actual implementation would make HTTP request and parse response
        const n = call_options.n orelse 1;
        const images = result_allocator.alloc([]const u8, n) catch |err| {
            callback(null, err, callback_context);
            return;
        };
        for (images, 0..) |*img, i| {
            _ = i;
            img.* = ""; // Placeholder base64 data
        }

        const result = image.ImageModelV3.GenerateResult{
            .images = images,
            .warnings = warnings.toOwnedSlice() catch &[_]shared.SharedV3Warning{},
            .provider_metadata = null,
        };

        callback(result, null, callback_context);
    }

    /// Convert to ImageModelV3 interface
    pub fn asImageModel(self: *Self) image.ImageModelV3 {
        return .{
            .vtable = &vtable,
            .impl = self,
        };
    }

    const vtable = image.ImageModelV3.VTable{
        .doGenerate = doGenerateVtable,
        .getModelId = getModelIdVtable,
        .getProvider = getProviderVtable,
        .getMaxImagesPerCall = getMaxImagesPerCallVtable,
    };

    fn doGenerateVtable(
        impl: *anyopaque,
        call_options: image.ImageModelV3CallOptions,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?image.ImageModelV3.GenerateResult, ?anyerror, ?*anyopaque) void,
        callback_context: ?*anyopaque,
    ) void {
        const self: *Self = @ptrCast(@alignCast(impl));
        self.doGenerate(call_options, null, result_allocator, callback, callback_context);
    }

    fn getModelIdVtable(impl: *anyopaque) []const u8 {
        const self: *Self = @ptrCast(@alignCast(impl));
        return self.getModelId();
    }

    fn getProviderVtable(impl: *anyopaque) []const u8 {
        const self: *Self = @ptrCast(@alignCast(impl));
        return self.getProvider();
    }

    fn getMaxImagesPerCallVtable(impl: *anyopaque) u32 {
        const self: *Self = @ptrCast(@alignCast(impl));
        return self.getMaxImagesPerCall();
    }
};

test "GoogleGenerativeAIImageModel init" {
    const allocator = std.testing.allocator;

    var model = GoogleGenerativeAIImageModel.init(
        allocator,
        "imagen-4.0-generate-001",
        .{},
        .{},
    );

    try std.testing.expectEqualStrings("imagen-4.0-generate-001", model.getModelId());
    try std.testing.expectEqualStrings("google.generative-ai", model.getProvider());
    try std.testing.expectEqual(@as(u32, 4), model.getMaxImagesPerCall());
}

test "GoogleGenerativeAIImageModel custom max images" {
    const allocator = std.testing.allocator;

    var model = GoogleGenerativeAIImageModel.init(
        allocator,
        "imagen-4.0-generate-001",
        .{ .max_images_per_call = 8 },
        .{},
    );

    try std.testing.expectEqual(@as(u32, 8), model.getMaxImagesPerCall());
}
