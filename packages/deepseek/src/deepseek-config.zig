const std = @import("std");
const provider_utils = @import("provider-utils");

/// DeepSeek API configuration
pub const DeepSeekConfig = struct {
    /// Provider name
    provider: []const u8 = "deepseek",

    /// Base URL for API calls
    base_url: []const u8 = "https://api.deepseek.com",

    /// API key (takes precedence over environment variable)
    api_key: ?[]const u8 = null,

    /// Function to get headers
    headers_fn: ?*const fn (*const DeepSeekConfig, std.mem.Allocator) std.StringHashMap([]const u8) = null,

    /// HTTP client
    http_client: ?provider_utils.HttpClient = null,

    /// ID generator function
    generate_id: ?*const fn () []const u8 = null,

    /// Get headers using the headers_fn or default headers
    pub fn getHeaders(self: *const DeepSeekConfig, allocator: std.mem.Allocator) std.StringHashMap([]const u8) {
        if (self.headers_fn) |headers_fn| {
            return headers_fn(self, allocator);
        }
        // Default headers
        var headers = std.StringHashMap([]const u8).init(allocator);
        headers.put("Content-Type", "application/json") catch {};
        if (self.api_key) |key| {
            const auth_header = std.fmt.allocPrint(allocator, "Bearer {s}", .{key}) catch return headers;
            headers.put("Authorization", auth_header) catch {};
        }
        return headers;
    }
};

/// Build the chat completions URL
pub fn buildChatCompletionsUrl(
    allocator: std.mem.Allocator,
    base_url: []const u8,
) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{s}/chat/completions", .{base_url});
}

test "buildChatCompletionsUrl" {
    const allocator = std.testing.allocator;
    const url = try buildChatCompletionsUrl(allocator, "https://api.deepseek.com");
    defer allocator.free(url);
    try std.testing.expectEqualStrings("https://api.deepseek.com/chat/completions", url);
}
