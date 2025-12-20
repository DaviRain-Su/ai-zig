const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;

/// Empty Response Body Error - thrown when API returns an empty response
pub const EmptyResponseBodyError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    /// Create a new empty response body error
    pub fn init(message: ?[]const u8) Self {
        return Self{
            .info = .{
                .kind = .empty_response_body,
                .message = message orelse "Empty response body",
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
        return error.EmptyResponseBodyError;
    }
};

test "EmptyResponseBodyError default message" {
    const err = EmptyResponseBodyError.init(null);
    try std.testing.expectEqualStrings("Empty response body", err.message());
}

test "EmptyResponseBodyError custom message" {
    const err = EmptyResponseBodyError.init("Custom empty body message");
    try std.testing.expectEqualStrings("Custom empty body message", err.message());
}
