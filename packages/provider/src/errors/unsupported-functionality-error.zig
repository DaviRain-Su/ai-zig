const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;
pub const UnsupportedFunctionalityContext = ai_sdk_error.UnsupportedFunctionalityContext;

/// Unsupported Functionality Error - thrown when requested functionality is not supported
pub const UnsupportedFunctionalityError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    pub const Options = struct {
        functionality: []const u8,
        message: ?[]const u8 = null,
    };

    /// Create a new unsupported functionality error
    pub fn init(options: Options) Self {
        const msg = options.message orelse "Functionality not supported";

        return Self{
            .info = .{
                .kind = .unsupported_functionality,
                .message = msg,
                .context = .{ .unsupported_functionality = .{
                    .functionality = options.functionality,
                } },
            },
        };
    }

    /// Get the functionality that is not supported
    pub fn functionality(self: Self) []const u8 {
        if (self.info.context) |ctx| {
            if (ctx == .unsupported_functionality) {
                return ctx.unsupported_functionality.functionality;
            }
        }
        return "";
    }

    /// Get the error message
    pub fn message(self: Self) []const u8 {
        return self.info.message;
    }

    /// Convert to AiSdkError
    pub fn toError(self: Self) AiSdkError {
        _ = self;
        return error.UnsupportedFunctionalityError;
    }
};

test "UnsupportedFunctionalityError creation" {
    const err = UnsupportedFunctionalityError.init(.{
        .functionality = "streaming",
    });

    try std.testing.expectEqualStrings("streaming", err.functionality());
    try std.testing.expectEqualStrings("Functionality not supported", err.message());
}

test "UnsupportedFunctionalityError custom message" {
    const err = UnsupportedFunctionalityError.init(.{
        .functionality = "image generation",
        .message = "This model does not support image generation",
    });

    try std.testing.expectEqualStrings("image generation", err.functionality());
    try std.testing.expectEqualStrings("This model does not support image generation", err.message());
}
