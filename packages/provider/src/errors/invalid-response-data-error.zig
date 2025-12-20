const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");
const json_value = @import("../json-value/index.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;
pub const InvalidResponseDataContext = ai_sdk_error.InvalidResponseDataContext;

/// Invalid Response Data Error - thrown when server returns invalid data
pub const InvalidResponseDataError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    pub const Options = struct {
        data: ?json_value.JsonValue = null,
        message: ?[]const u8 = null,
    };

    /// Create a new invalid response data error
    pub fn init(options: Options) Self {
        const msg = options.message orelse "Invalid response data";

        return Self{
            .info = .{
                .kind = .invalid_response_data,
                .message = msg,
                .context = .{ .invalid_response_data = .{
                    .data = options.data,
                } },
            },
        };
    }

    /// Get the invalid data
    pub fn data(self: Self) ?json_value.JsonValue {
        if (self.info.context) |ctx| {
            if (ctx == .invalid_response_data) {
                return ctx.invalid_response_data.data;
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
        return error.InvalidResponseDataError;
    }
};

test "InvalidResponseDataError creation" {
    const err = InvalidResponseDataError.init(.{
        .message = "Missing required field 'content'",
    });

    try std.testing.expectEqualStrings("Missing required field 'content'", err.message());
}
