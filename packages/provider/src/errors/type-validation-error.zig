const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");
const json_value = @import("../json-value/index.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;
pub const TypeValidationContext = ai_sdk_error.TypeValidationContext;

/// Type Validation Error - thrown when a value fails type validation
pub const TypeValidationError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    pub const Options = struct {
        value: ?json_value.JsonValue = null,
        cause: ?*const AiSdkErrorInfo = null,
        message: ?[]const u8 = null,
    };

    /// Create a new type validation error
    pub fn init(options: Options) Self {
        const msg = options.message orelse "Type validation failed";

        return Self{
            .info = .{
                .kind = .type_validation,
                .message = msg,
                .cause = options.cause,
                .context = .{ .type_validation = .{
                    .value = options.value,
                } },
            },
        };
    }

    /// Get the value that failed validation
    pub fn value(self: Self) ?json_value.JsonValue {
        if (self.info.context) |ctx| {
            if (ctx == .type_validation) {
                return ctx.type_validation.value;
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
        return error.TypeValidationError;
    }

    /// Wrap an existing error into a TypeValidationError
    /// If the cause is already a TypeValidationError, returns it unchanged
    pub fn wrap(options: Options) Self {
        // In Zig, we just create a new error since we can't easily check
        // if the cause is the same type
        return init(options);
    }
};

test "TypeValidationError creation" {
    const err = TypeValidationError.init(.{
        .message = "Expected string, got number",
    });

    try std.testing.expectEqualStrings("Expected string, got number", err.message());
}
