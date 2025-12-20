const std = @import("std");
const json_value = @import("../../json-value/index.zig");

/// Additional provider-specific metadata.
/// Metadata are additional outputs from the provider.
/// They are passed through to the provider from the AI SDK
/// and enable provider-specific functionality
/// that can be fully encapsulated in the provider.
///
/// This enables us to quickly ship provider-specific functionality
/// without affecting the core AI SDK.
///
/// The outer map is keyed by the provider name, and the inner
/// map is keyed by the provider-specific metadata key.
///
/// Example structure:
/// ```
/// {
///   "anthropic": {
///     "cacheControl": { "type": "ephemeral" }
///   }
/// }
/// ```
pub const SharedV3ProviderMetadata = std.StringHashMap(json_value.JsonObject);

/// Create a new empty provider metadata map
pub fn createProviderMetadata(allocator: std.mem.Allocator) SharedV3ProviderMetadata {
    return SharedV3ProviderMetadata.init(allocator);
}

/// Helper to get metadata for a specific provider
pub fn getProviderData(metadata: SharedV3ProviderMetadata, provider: []const u8) ?json_value.JsonObject {
    return metadata.get(provider);
}

/// Helper to set metadata for a specific provider
pub fn setProviderData(
    metadata: *SharedV3ProviderMetadata,
    provider: []const u8,
    data: json_value.JsonObject,
) !void {
    try metadata.put(provider, data);
}

/// Merge two provider metadata maps
/// Values from `other` will override values in `base` for the same keys
pub fn mergeProviderMetadata(
    allocator: std.mem.Allocator,
    base: SharedV3ProviderMetadata,
    other: SharedV3ProviderMetadata,
) !SharedV3ProviderMetadata {
    var result = SharedV3ProviderMetadata.init(allocator);
    errdefer result.deinit();

    // Copy base
    var base_iter = base.iterator();
    while (base_iter.next()) |entry| {
        try result.put(entry.key_ptr.*, entry.value_ptr.*);
    }

    // Merge/override with other
    var other_iter = other.iterator();
    while (other_iter.next()) |entry| {
        try result.put(entry.key_ptr.*, entry.value_ptr.*);
    }

    return result;
}

test "SharedV3ProviderMetadata creation" {
    const allocator = std.testing.allocator;

    var metadata = createProviderMetadata(allocator);
    defer metadata.deinit();

    var anthropic_data = json_value.JsonObject.init(allocator);
    defer anthropic_data.deinit();

    try anthropic_data.put("cacheControl", json_value.JsonValue{ .string = "ephemeral" });
    try setProviderData(&metadata, "anthropic", anthropic_data);

    const retrieved = getProviderData(metadata, "anthropic");
    try std.testing.expect(retrieved != null);
}
