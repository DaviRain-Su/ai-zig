const std = @import("std");

/// Groq API configuration
pub const GroqConfig = struct {
    /// Provider name
    provider: []const u8 = "groq",

    /// Base URL for API calls
    base_url: []const u8 = "https://api.groq.com/openai/v1",

    /// Function to get headers
    headers_fn: ?*const fn (*const GroqConfig) std.StringHashMap([]const u8) = null,

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

/// Build the transcriptions URL
pub fn buildTranscriptionsUrl(
    allocator: std.mem.Allocator,
    base_url: []const u8,
) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{s}/audio/transcriptions", .{base_url});
}

test "buildChatCompletionsUrl" {
    const allocator = std.testing.allocator;
    const url = try buildChatCompletionsUrl(allocator, "https://api.groq.com/openai/v1");
    defer allocator.free(url);
    try std.testing.expectEqualStrings("https://api.groq.com/openai/v1/chat/completions", url);
}

test "buildTranscriptionsUrl" {
    const allocator = std.testing.allocator;
    const url = try buildTranscriptionsUrl(allocator, "https://api.groq.com/openai/v1");
    defer allocator.free(url);
    try std.testing.expectEqualStrings("https://api.groq.com/openai/v1/audio/transcriptions", url);
}
