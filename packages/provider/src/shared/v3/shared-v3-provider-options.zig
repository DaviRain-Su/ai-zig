const std = @import("std");
const json_value = @import("../../json-value/index.zig");

/// Additional provider-specific options.
/// Options are additional input to the provider.
/// They are passed through to the provider from the AI SDK
/// and enable provider-specific functionality
/// that can be fully encapsulated in the provider.
///
/// This enables us to quickly ship provider-specific functionality
/// without affecting the core AI SDK.
///
/// The outer map is keyed by the provider name, and the inner
/// map is keyed by the provider-specific option key.
///
/// Example structure:
/// ```
/// {
///   "anthropic": {
///     "cacheControl": { "type": "ephemeral" }
///   }
/// }
/// ```
pub const SharedV3ProviderOptions = std.StringHashMap(json_value.JsonObject);

/// Create a new empty provider options map
pub fn createProviderOptions(allocator: std.mem.Allocator) SharedV3ProviderOptions {
    return SharedV3ProviderOptions.init(allocator);
}

/// Helper to get options for a specific provider
pub fn getProviderOptions(options: SharedV3ProviderOptions, provider: []const u8) ?json_value.JsonObject {
    return options.get(provider);
}

/// Helper to set options for a specific provider
pub fn setProviderOptions(
    options: *SharedV3ProviderOptions,
    provider: []const u8,
    data: json_value.JsonObject,
) !void {
    try options.put(provider, data);
}

/// Get a specific option value for a provider
pub fn getOption(
    options: SharedV3ProviderOptions,
    provider: []const u8,
    key: []const u8,
) ?json_value.JsonValue {
    if (options.get(provider)) |provider_opts| {
        return provider_opts.get(key);
    }
    return null;
}

test "SharedV3ProviderOptions creation" {
    const allocator = std.testing.allocator;

    var options = createProviderOptions(allocator);
    defer options.deinit();

    var openai_opts = json_value.JsonObject.init(allocator);
    defer openai_opts.deinit();

    try openai_opts.put("organization", json_value.JsonValue{ .string = "org-123" });
    try setProviderOptions(&options, "openai", openai_opts);

    const org = getOption(options, "openai", "organization");
    try std.testing.expect(org != null);
    try std.testing.expectEqualStrings("org-123", org.?.asString().?);
}
