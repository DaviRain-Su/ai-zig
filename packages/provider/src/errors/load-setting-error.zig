const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;

/// Load Setting Error - thrown when a setting cannot be loaded
pub const LoadSettingError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    /// Create a new load setting error
    pub fn init(msg: []const u8) Self {
        return Self{
            .info = .{
                .kind = .load_setting,
                .message = msg,
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
        return error.LoadSettingError;
    }
};

test "LoadSettingError creation" {
    const err = LoadSettingError.init("Failed to load base URL setting");
    try std.testing.expectEqualStrings("Failed to load base URL setting", err.message());
}
