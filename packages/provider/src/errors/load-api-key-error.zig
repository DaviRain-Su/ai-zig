const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;

/// Load API Key Error - thrown when API key cannot be loaded
pub const LoadApiKeyError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    /// Create a new load API key error
    pub fn init(msg: []const u8) Self {
        return Self{
            .info = .{
                .kind = .load_api_key,
                .message = msg,
            },
        };
    }

    /// Create error for missing API key
    pub fn missing(provider: []const u8, env_var: []const u8) Self {
        // Note: In real usage, you'd want to format this with an allocator
        _ = provider;
        _ = env_var;
        return Self{
            .info = .{
                .kind = .load_api_key,
                .message = "API key is missing. Set the environment variable or pass it directly.",
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
        return error.LoadApiKeyError;
    }
};

test "LoadApiKeyError creation" {
    const err = LoadApiKeyError.init("OpenAI API key is missing");
    try std.testing.expectEqualStrings("OpenAI API key is missing", err.message());
}
