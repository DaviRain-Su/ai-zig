const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;
pub const InvalidArgumentContext = ai_sdk_error.InvalidArgumentContext;

/// Invalid Argument Error - thrown when a function argument is invalid
pub const InvalidArgumentError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    pub const Options = struct {
        argument: []const u8,
        message: []const u8,
        cause: ?*const AiSdkErrorInfo = null,
    };

    /// Create a new invalid argument error
    pub fn init(options: Options) Self {
        return Self{
            .info = .{
                .kind = .invalid_argument,
                .message = options.message,
                .cause = options.cause,
                .context = .{ .invalid_argument = .{
                    .argument = options.argument,
                } },
            },
        };
    }

    /// Get the argument name that was invalid
    pub fn argument(self: Self) []const u8 {
        if (self.info.context) |ctx| {
            if (ctx == .invalid_argument) {
                return ctx.invalid_argument.argument;
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
        return error.InvalidArgumentError;
    }
};

test "InvalidArgumentError creation" {
    const err = InvalidArgumentError.init(.{
        .argument = "temperature",
        .message = "Temperature must be between 0 and 2",
    });

    try std.testing.expectEqualStrings("temperature", err.argument());
    try std.testing.expectEqualStrings("Temperature must be between 0 and 2", err.message());
}
