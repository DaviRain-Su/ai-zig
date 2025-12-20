const std = @import("std");

/// Configuration for Azure OpenAI API
pub const AzureOpenAIConfig = struct {
    /// Provider name
    provider: []const u8 = "azure.chat",

    /// Base URL for API calls
    base_url: []const u8,

    /// API version
    api_version: []const u8 = "v1",

    /// Use deployment-based URLs
    use_deployment_based_urls: bool = false,

    /// Function to get headers
    headers_fn: ?*const fn (*const AzureOpenAIConfig) std.StringHashMap([]const u8) = null,

    /// Custom HTTP client
    http_client: ?*anyopaque = null,

    /// ID generator function
    generate_id: ?*const fn () []const u8 = null,
};

/// Build Azure OpenAI URL
pub fn buildAzureUrl(
    allocator: std.mem.Allocator,
    config: *const AzureOpenAIConfig,
    path: []const u8,
    model_id: []const u8,
) ![]const u8 {
    if (config.use_deployment_based_urls) {
        // Use deployment-based format: {baseURL}/deployments/{deploymentId}{path}?api-version={apiVersion}
        return try std.fmt.allocPrint(
            allocator,
            "{s}/deployments/{s}{s}?api-version={s}",
            .{ config.base_url, model_id, path, config.api_version },
        );
    }

    // Use v1 API format: {baseURL}/v1{path}?api-version={apiVersion}
    return try std.fmt.allocPrint(
        allocator,
        "{s}/v1{s}?api-version={s}",
        .{ config.base_url, path, config.api_version },
    );
}

/// Build base URL from resource name
pub fn buildBaseUrlFromResourceName(allocator: std.mem.Allocator, resource_name: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(
        allocator,
        "https://{s}.openai.azure.com/openai",
        .{resource_name},
    );
}

test "buildAzureUrl with v1 API" {
    const allocator = std.testing.allocator;

    const config = AzureOpenAIConfig{
        .base_url = "https://myresource.openai.azure.com/openai",
        .api_version = "2024-02-15-preview",
        .use_deployment_based_urls = false,
    };

    const url = try buildAzureUrl(allocator, &config, "/chat/completions", "gpt-4");
    defer allocator.free(url);

    try std.testing.expect(std.mem.indexOf(u8, url, "/v1/chat/completions") != null);
    try std.testing.expect(std.mem.indexOf(u8, url, "api-version=2024-02-15-preview") != null);
}

test "buildAzureUrl with deployment-based URLs" {
    const allocator = std.testing.allocator;

    const config = AzureOpenAIConfig{
        .base_url = "https://myresource.openai.azure.com/openai",
        .api_version = "2024-02-15-preview",
        .use_deployment_based_urls = true,
    };

    const url = try buildAzureUrl(allocator, &config, "/chat/completions", "gpt-4");
    defer allocator.free(url);

    try std.testing.expect(std.mem.indexOf(u8, url, "/deployments/gpt-4/chat/completions") != null);
    try std.testing.expect(std.mem.indexOf(u8, url, "api-version=2024-02-15-preview") != null);
}

test "buildBaseUrlFromResourceName" {
    const allocator = std.testing.allocator;

    const url = try buildBaseUrlFromResourceName(allocator, "myresource");
    defer allocator.free(url);

    try std.testing.expectEqualStrings("https://myresource.openai.azure.com/openai", url);
}
