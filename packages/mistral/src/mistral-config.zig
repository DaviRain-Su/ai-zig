const std = @import("std");

/// Mistral API configuration
pub const MistralConfig = struct {
    /// Provider name
    provider: []const u8 = "mistral",

    /// Base URL for API calls
    base_url: []const u8 = "https://api.mistral.ai/v1",

    /// Function to get headers
    headers_fn: ?*const fn (*const MistralConfig) std.StringHashMap([]const u8) = null,

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

/// Build the embeddings URL
pub fn buildEmbeddingsUrl(
    allocator: std.mem.Allocator,
    base_url: []const u8,
) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{s}/embeddings", .{base_url});
}

test "buildChatCompletionsUrl" {
    const allocator = std.testing.allocator;
    const url = try buildChatCompletionsUrl(allocator, "https://api.mistral.ai/v1");
    defer allocator.free(url);
    try std.testing.expectEqualStrings("https://api.mistral.ai/v1/chat/completions", url);
}

test "buildEmbeddingsUrl" {
    const allocator = std.testing.allocator;
    const url = try buildEmbeddingsUrl(allocator, "https://api.mistral.ai/v1");
    defer allocator.free(url);
    try std.testing.expectEqualStrings("https://api.mistral.ai/v1/embeddings", url);
}
