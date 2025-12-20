const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");
const json_value = @import("../json-value/index.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;
pub const InvalidPromptContext = ai_sdk_error.InvalidPromptContext;

/// Invalid Prompt Error - thrown when a prompt is invalid
pub const InvalidPromptError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    pub const Options = struct {
        prompt: ?json_value.JsonValue = null,
        message: []const u8,
        cause: ?*const AiSdkErrorInfo = null,
    };

    /// Create a new invalid prompt error
    pub fn init(options: Options) Self {
        return Self{
            .info = .{
                .kind = .invalid_prompt,
                .message = options.message,
                .cause = options.cause,
                .context = .{ .invalid_prompt = .{
                    .prompt = options.prompt,
                } },
            },
        };
    }

    /// Get the invalid prompt
    pub fn prompt(self: Self) ?json_value.JsonValue {
        if (self.info.context) |ctx| {
            if (ctx == .invalid_prompt) {
                return ctx.invalid_prompt.prompt;
            }
        }
        return null;
    }

    /// Get the error message
    pub fn message(self: Self) []const u8 {
        return self.info.message;
    }

    /// Convert to AiSdkError
    pub fn toError(self: Self) AiSdkError {
        _ = self;
        return error.InvalidPromptError;
    }
};

test "InvalidPromptError creation" {
    const err = InvalidPromptError.init(.{
        .message = "Prompt contains invalid characters",
    });

    try std.testing.expectEqualStrings("Prompt contains invalid characters", err.message());
}
