const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;

/// No Content Generated Error - thrown when the AI provider fails to generate any content
pub const NoContentGeneratedError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    /// Create a new no content generated error
    pub fn init(message: ?[]const u8) Self {
        return Self{
            .info = .{
                .kind = .no_content_generated,
                .message = message orelse "No content generated.",
            },
        };
    }

    /// Get the error message
    pub fn message(self: Self) []const u8 {
        return self.info.message;
    }

    /// Convert to AiSdkError
    pub fn toError(self: Self) AiSdkError {
        _ = self;
        return error.NoContentGeneratedError;
    }
};

test "NoContentGeneratedError default message" {
    const err = NoContentGeneratedError.init(null);
    try std.testing.expectEqualStrings("No content generated.", err.message());
}

test "NoContentGeneratedError custom message" {
    const err = NoContentGeneratedError.init("Model returned empty response");
    try std.testing.expectEqualStrings("Model returned empty response", err.message());
}
