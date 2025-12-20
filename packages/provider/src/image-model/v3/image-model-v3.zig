const std = @import("std");
const shared = @import("../../shared/v3/index.zig");
const json_value = @import("../../json-value/index.zig");
const ImageModelV3CallOptions = @import("image-model-v3-call-options.zig").ImageModelV3CallOptions;
const ImageModelV3Usage = @import("image-model-v3-usage.zig").ImageModelV3Usage;

/// Provider metadata for image models
pub const ImageModelV3ProviderMetadata = std.StringHashMap(ImageProviderData);

pub const ImageProviderData = struct {
    images: json_value.JsonArray,
    extra: ?json_value.JsonValue = null,
};

/// Image generation model specification version 3.
pub const ImageModelV3 = struct {
    /// VTable for dynamic dispatch
    vtable: *const VTable,
    /// Implementation pointer
    impl: *anyopaque,

    pub const specification_version = "v3";

    /// Virtual function table for image model operations
    pub const VTable = struct {
        /// Get the provider name
        getProvider: *const fn (*anyopaque) []const u8,

        /// Get the model ID
        getModelId: *const fn (*anyopaque) []const u8,

        /// Get max images per call
        getMaxImagesPerCall: *const fn (
            *anyopaque,
            *const fn (?*anyopaque, ?u32) void,
            ?*anyopaque,
        ) void,

        /// Generate images
        doGenerate: *const fn (
            *anyopaque,
            ImageModelV3CallOptions,
            std.mem.Allocator,
            *const fn (?*anyopaque, GenerateResult) void,
            ?*anyopaque,
        ) void,
    };

    /// Result of image generation
    pub const GenerateResult = union(enum) {
        success: GenerateSuccess,
        failure: anyerror,
    };

    /// Generated image data
    pub const ImageData = union(enum) {
        /// Base64 encoded images
        base64: []const []const u8,
        /// Binary image data
        binary: []const []const u8,
    };

    /// Successful generation result
    pub const GenerateSuccess = struct {
        /// Generated images as base64 encoded strings or binary data.
        images: ImageData,

        /// Warnings for the call.
        warnings: []const shared.SharedV3Warning = &[_]shared.SharedV3Warning{},

        /// Additional provider-specific metadata.
        provider_metadata: ?ImageModelV3ProviderMetadata = null,

        /// Response information.
        response: ResponseInfo,

        /// Optional token usage.
        usage: ?ImageModelV3Usage = null,
    };

    /// Response information
    pub const ResponseInfo = struct {
        /// Timestamp for the start of the generated response.
        timestamp: i64,

        /// The ID of the response model.
        model_id: []const u8,

        /// Response headers.
        headers: ?std.StringHashMap([]const u8) = null,
    };

    const Self = @This();

    /// Get the provider name
    pub fn getProvider(self: Self) []const u8 {
        return self.vtable.getProvider(self.impl);
    }

    /// Get the model ID
    pub fn getModelId(self: Self) []const u8 {
        return self.vtable.getModelId(self.impl);
    }

    /// Get max images per call (async)
    pub fn getMaxImagesPerCall(
        self: Self,
        callback: *const fn (?*anyopaque, ?u32) void,
        ctx: ?*anyopaque,
    ) void {
        self.vtable.getMaxImagesPerCall(self.impl, callback, ctx);
    }

    /// Generate images
    pub fn doGenerate(
        self: Self,
        options: ImageModelV3CallOptions,
        allocator: std.mem.Allocator,
        callback: *const fn (?*anyopaque, GenerateResult) void,
        ctx: ?*anyopaque,
    ) void {
        self.vtable.doGenerate(self.impl, options, allocator, callback, ctx);
    }

    /// Get a string identifier for this model
    pub fn getId(self: Self, allocator: std.mem.Allocator) ![]u8 {
        const provider = self.getProvider();
        const model_id = self.getModelId();
        return std.fmt.allocPrint(allocator, "{s}:{s}", .{ provider, model_id });
    }
};

/// Helper to implement an image model from a concrete type
pub fn implementImageModel(comptime T: type) ImageModelV3.VTable {
    return .{
        .getProvider = struct {
            fn getProvider(ptr: *anyopaque) []const u8 {
                const self: *T = @ptrCast(@alignCast(ptr));
                return self.getProvider();
            }
        }.getProvider,

        .getModelId = struct {
            fn getModelId(ptr: *anyopaque) []const u8 {
                const self: *T = @ptrCast(@alignCast(ptr));
                return self.getModelId();
            }
        }.getModelId,

        .getMaxImagesPerCall = struct {
            fn getMaxImagesPerCall(
                ptr: *anyopaque,
                callback: *const fn (?*anyopaque, ?u32) void,
                ctx: ?*anyopaque,
            ) void {
                const self: *T = @ptrCast(@alignCast(ptr));
                self.getMaxImagesPerCall(callback, ctx);
            }
        }.getMaxImagesPerCall,

        .doGenerate = struct {
            fn doGenerate(
                ptr: *anyopaque,
                options: ImageModelV3CallOptions,
                allocator: std.mem.Allocator,
                callback: *const fn (?*anyopaque, ImageModelV3.GenerateResult) void,
                ctx: ?*anyopaque,
            ) void {
                const self: *T = @ptrCast(@alignCast(ptr));
                self.doGenerate(options, allocator, callback, ctx);
            }
        }.doGenerate,
    };
}

/// Create an ImageModelV3 from a concrete implementation
pub fn asImageModel(comptime T: type, impl: *T) ImageModelV3 {
    const vtable = comptime implementImageModel(T);
    return .{
        .vtable = &vtable,
        .impl = impl,
    };
}

test "ImageModelV3 specification_version" {
    try std.testing.expectEqualStrings("v3", ImageModelV3.specification_version);
}
