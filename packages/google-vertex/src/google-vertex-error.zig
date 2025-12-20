const std = @import("std");

/// Google Vertex AI error data structure
pub const GoogleVertexErrorData = struct {
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
    pub fn fromJson(allocator: std.mem.Allocator, json_str: []const u8) !GoogleVertexErrorData {
        const parsed = try std.json.parseFromSlice(GoogleVertexErrorData, allocator, json_str, .{
            .ignore_unknown_fields = true,
        });
        return parsed.value;
    }

    /// Get the error message
    pub fn getMessage(self: *const GoogleVertexErrorData) []const u8 {
        return self.@"error".message;
    }

    /// Check if this error is retryable
    pub fn isRetryable(self: *const GoogleVertexErrorData) bool {
        if (self.@"error".code) |code| {
            return code == 429 or code == 500 or code == 502 or code == 503 or code == 504;
        }
        return std.mem.eql(u8, self.@"error".status, "RESOURCE_EXHAUSTED") or
            std.mem.eql(u8, self.@"error".status, "UNAVAILABLE");
    }
};

test "GoogleVertexErrorData parsing" {
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

    const parsed = try std.json.parseFromSlice(GoogleVertexErrorData, allocator, json, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();

    try std.testing.expectEqual(@as(?i32, 400), parsed.value.@"error".code);
    try std.testing.expectEqualStrings("Invalid request", parsed.value.@"error".message);
}
