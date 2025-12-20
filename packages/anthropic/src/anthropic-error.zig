const std = @import("std");

/// Anthropic API error data structure
pub const AnthropicErrorData = struct {
    type: []const u8,
    @"error": ErrorObject,

    pub const ErrorObject = struct {
        type: []const u8,
        message: []const u8,
    };

    /// Get the error message
    pub fn getMessage(self: AnthropicErrorData) []const u8 {
        return self.@"error".message;
    }

    /// Get the error type
    pub fn getErrorType(self: AnthropicErrorData) []const u8 {
        return self.@"error".type;
    }

    /// Check if this is a rate limit error
    pub fn isRateLimitError(self: AnthropicErrorData) bool {
        return std.mem.eql(u8, self.@"error".type, "rate_limit_error");
    }

    /// Check if this is an overloaded error
    pub fn isOverloadedError(self: AnthropicErrorData) bool {
        return std.mem.eql(u8, self.@"error".type, "overloaded_error");
    }

    /// Check if the error is retryable
    pub fn isRetryable(self: AnthropicErrorData) bool {
        return self.isRateLimitError() or self.isOverloadedError();
    }
};

/// Anthropic error types
pub const ErrorType = enum {
    invalid_request_error,
    authentication_error,
    permission_error,
    not_found_error,
    rate_limit_error,
    api_error,
    overloaded_error,
    unknown,

    pub fn fromString(s: []const u8) ErrorType {
        if (std.mem.eql(u8, s, "invalid_request_error")) return .invalid_request_error;
        if (std.mem.eql(u8, s, "authentication_error")) return .authentication_error;
        if (std.mem.eql(u8, s, "permission_error")) return .permission_error;
        if (std.mem.eql(u8, s, "not_found_error")) return .not_found_error;
        if (std.mem.eql(u8, s, "rate_limit_error")) return .rate_limit_error;
        if (std.mem.eql(u8, s, "api_error")) return .api_error;
        if (std.mem.eql(u8, s, "overloaded_error")) return .overloaded_error;
        return .unknown;
    }
};

test "AnthropicErrorData isRetryable" {
    const rate_limit_error = AnthropicErrorData{
        .type = "error",
        .@"error" = .{
            .type = "rate_limit_error",
            .message = "Rate limit exceeded",
        },
    };
    try std.testing.expect(rate_limit_error.isRetryable());
    try std.testing.expect(rate_limit_error.isRateLimitError());

    const overloaded_error = AnthropicErrorData{
        .type = "error",
        .@"error" = .{
            .type = "overloaded_error",
            .message = "Server overloaded",
        },
    };
    try std.testing.expect(overloaded_error.isRetryable());
    try std.testing.expect(overloaded_error.isOverloadedError());

    const other_error = AnthropicErrorData{
        .type = "error",
        .@"error" = .{
            .type = "invalid_request_error",
            .message = "Invalid request",
        },
    };
    try std.testing.expect(!other_error.isRetryable());
}
