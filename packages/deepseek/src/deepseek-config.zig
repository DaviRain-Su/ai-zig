const std = @import("std");

/// DeepSeek API configuration
pub const DeepSeekConfig = struct {
    /// Provider name
    provider: []const u8 = "deepseek",

    /// Base URL for API calls
    base_url: []const u8 = "https://api.deepseek.com",

    /// Function to get headers
    headers_fn: ?*const fn (*const DeepSeekConfig) std.StringHashMap([]const u8) = null,

    /// HTTP client (optional)
    http_client: ?*anyopaque = null,

    /// ID generator function
    generate_id: ?*const fn () []const u8 = null,
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
