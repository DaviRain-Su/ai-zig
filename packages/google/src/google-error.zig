const std = @import("std");

/// Google API error data structure
pub const GoogleErrorData = struct {
    /// Error details
    @"error": Error,

    pub const Error = struct {
        /// HTTP error code
        code: ?i32 = null,

        /// Error message
        message: []const u8,

        /// Error status
        status: []const u8,
    };

    /// Parse error data from JSON
    pub fn fromJson(allocator: std.mem.Allocator, json_str: []const u8) !GoogleErrorData {
        const parsed = try std.json.parseFromSlice(GoogleErrorData, allocator, json_str, .{
            .ignore_unknown_fields = true,
        });
        return parsed.value;
    }

    /// Get the error message
    pub fn getMessage(self: *const GoogleErrorData) []const u8 {
        return self.@"error".message;
    }

    /// Check if this error is retryable
    pub fn isRetryable(self: *const GoogleErrorData) bool {
        // Google rate limit and server errors are typically retryable
        if (self.@"error".code) |code| {
            return code == 429 or code == 500 or code == 502 or code == 503 or code == 504;
        }
        // Check status string for rate limit
        return std.mem.eql(u8, self.@"error".status, "RESOURCE_EXHAUSTED") or
            std.mem.eql(u8, self.@"error".status, "UNAVAILABLE");
    }
};

/// Google-specific error types
pub const ErrorStatus = enum {
    ok,
    cancelled,
    unknown,
    invalid_argument,
    deadline_exceeded,
    not_found,
    already_exists,
    permission_denied,
    resource_exhausted,
    failed_precondition,
    aborted,
    out_of_range,
    unimplemented,
    internal,
    unavailable,
    data_loss,
    unauthenticated,

    pub fn fromString(status: []const u8) ErrorStatus {
        if (std.mem.eql(u8, status, "OK")) return .ok;
        if (std.mem.eql(u8, status, "CANCELLED")) return .cancelled;
        if (std.mem.eql(u8, status, "UNKNOWN")) return .unknown;
        if (std.mem.eql(u8, status, "INVALID_ARGUMENT")) return .invalid_argument;
        if (std.mem.eql(u8, status, "DEADLINE_EXCEEDED")) return .deadline_exceeded;
        if (std.mem.eql(u8, status, "NOT_FOUND")) return .not_found;
        if (std.mem.eql(u8, status, "ALREADY_EXISTS")) return .already_exists;
        if (std.mem.eql(u8, status, "PERMISSION_DENIED")) return .permission_denied;
        if (std.mem.eql(u8, status, "RESOURCE_EXHAUSTED")) return .resource_exhausted;
        if (std.mem.eql(u8, status, "FAILED_PRECONDITION")) return .failed_precondition;
        if (std.mem.eql(u8, status, "ABORTED")) return .aborted;
        if (std.mem.eql(u8, status, "OUT_OF_RANGE")) return .out_of_range;
        if (std.mem.eql(u8, status, "UNIMPLEMENTED")) return .unimplemented;
        if (std.mem.eql(u8, status, "INTERNAL")) return .internal;
        if (std.mem.eql(u8, status, "UNAVAILABLE")) return .unavailable;
        if (std.mem.eql(u8, status, "DATA_LOSS")) return .data_loss;
        if (std.mem.eql(u8, status, "UNAUTHENTICATED")) return .unauthenticated;
        return .unknown;
    }
};

test "GoogleErrorData parsing" {
    const allocator = std.testing.allocator;

    const json =
        \\{
        \\  "error": {
        \\    "code": 400,
        \\    "message": "Invalid request",
        \\    "status": "INVALID_ARGUMENT"
        \\  }
        \\}
    ;

    const parsed = try std.json.parseFromSlice(GoogleErrorData, allocator, json, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();

    try std.testing.expectEqual(@as(?i32, 400), parsed.value.@"error".code);
    try std.testing.expectEqualStrings("Invalid request", parsed.value.@"error".message);
    try std.testing.expectEqualStrings("INVALID_ARGUMENT", parsed.value.@"error".status);
}

test "ErrorStatus fromString" {
    try std.testing.expectEqual(ErrorStatus.resource_exhausted, ErrorStatus.fromString("RESOURCE_EXHAUSTED"));
    try std.testing.expectEqual(ErrorStatus.invalid_argument, ErrorStatus.fromString("INVALID_ARGUMENT"));
    try std.testing.expectEqual(ErrorStatus.unknown, ErrorStatus.fromString("SOMETHING_ELSE"));
}
