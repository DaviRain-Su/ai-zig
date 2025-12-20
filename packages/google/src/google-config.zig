const std = @import("std");

/// Configuration for Google Generative AI API
pub const GoogleGenerativeAIConfig = struct {
    /// Provider name
    provider: []const u8 = "google.generative-ai",

    /// Base URL for API calls
    base_url: []const u8 = default_base_url,

    /// Function to get headers
    headers_fn: ?*const fn (*const GoogleGenerativeAIConfig) std.StringHashMap([]const u8) = null,

    /// Custom HTTP client
    http_client: ?*anyopaque = null,

    /// ID generator function
    generate_id: ?*const fn () []const u8 = null,
};

/// Default base URL for Google Generative AI API
pub const default_base_url = "https://generativelanguage.googleapis.com/v1beta";

/// API version string
pub const google_ai_version = "v1beta";

test "GoogleGenerativeAIConfig defaults" {
    const config = GoogleGenerativeAIConfig{};
    try std.testing.expectEqualStrings("google.generative-ai", config.provider);
    try std.testing.expectEqualStrings(default_base_url, config.base_url);
}
