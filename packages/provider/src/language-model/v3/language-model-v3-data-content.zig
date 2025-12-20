const std = @import("std");

/// Data content. Can be binary data, base64 encoded data as a string, or a URL.
pub const LanguageModelV3DataContent = union(enum) {
    /// Binary data (Uint8Array equivalent)
    binary: []const u8,
    /// Base64 encoded data as a string
    base64: []const u8,
    /// URL reference
    url: []const u8,

    const Self = @This();

    /// Create from binary data
    pub fn fromBinary(data: []const u8) Self {
        return .{ .binary = data };
    }

    /// Create from base64 encoded string
    pub fn fromBase64(data: []const u8) Self {
        return .{ .base64 = data };
    }

    /// Create from URL
    pub fn fromUrl(url: []const u8) Self {
        return .{ .url = url };
    }

    /// Check if this is a URL reference
    pub fn isUrl(self: Self) bool {
        return self == .url;
    }

    /// Check if this is binary data
    pub fn isBinary(self: Self) bool {
        return self == .binary;
    }

    /// Check if this is base64 encoded
    pub fn isBase64(self: Self) bool {
        return self == .base64;
    }

    /// Get the raw bytes (for binary, just returns; for base64, decodes; for URL, returns null)
    pub fn getBytes(self: Self, allocator: std.mem.Allocator) !?[]const u8 {
        return switch (self) {
            .binary => |data| try allocator.dupe(u8, data),
            .base64 => |b64| {
                const decoder = std.base64.standard.Decoder;
                const decoded_len = decoder.calcSizeForSlice(b64) catch return error.InvalidBase64;
                const decoded = try allocator.alloc(u8, decoded_len);
                decoder.decode(decoded, b64) catch {
                    allocator.free(decoded);
                    return error.InvalidBase64;
                };
                return decoded;
            },
            .url => null, // URLs need to be fetched separately
        };
    }

    /// Get as base64 string (for binary, encodes; for base64, returns as-is; for URL, returns null)
    pub fn getBase64(self: Self, allocator: std.mem.Allocator) !?[]const u8 {
        return switch (self) {
            .binary => |data| {
                const encoder = std.base64.standard.Encoder;
                const encoded_len = encoder.calcSize(data.len);
                const encoded = try allocator.alloc(u8, encoded_len);
                _ = encoder.encode(encoded, data);
                return encoded;
            },
            .base64 => |b64| try allocator.dupe(u8, b64),
            .url => null,
        };
    }

    /// Get URL if this is a URL reference
    pub fn getUrl(self: Self) ?[]const u8 {
        return switch (self) {
            .url => |u| u,
            else => null,
        };
    }

    /// Clone the data content
    pub fn clone(self: Self, allocator: std.mem.Allocator) !Self {
        return switch (self) {
            .binary => |data| .{ .binary = try allocator.dupe(u8, data) },
            .base64 => |b64| .{ .base64 = try allocator.dupe(u8, b64) },
            .url => |u| .{ .url = try allocator.dupe(u8, u) },
        };
    }

    /// Free memory
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .binary => |data| allocator.free(data),
            .base64 => |b64| allocator.free(b64),
            .url => |u| allocator.free(u),
        }
    }
};

test "LanguageModelV3DataContent binary" {
    const content = LanguageModelV3DataContent.fromBinary(&[_]u8{ 1, 2, 3 });
    try std.testing.expect(content.isBinary());
    try std.testing.expect(!content.isUrl());
}

test "LanguageModelV3DataContent url" {
    const content = LanguageModelV3DataContent.fromUrl("https://example.com/image.png");
    try std.testing.expect(content.isUrl());
    try std.testing.expectEqualStrings("https://example.com/image.png", content.getUrl().?);
}

test "LanguageModelV3DataContent base64" {
    const allocator = std.testing.allocator;
    const content = LanguageModelV3DataContent.fromBase64("SGVsbG8=");
    try std.testing.expect(content.isBase64());

    const bytes = try content.getBytes(allocator);
    defer if (bytes) |b| allocator.free(b);
    try std.testing.expectEqualStrings("Hello", bytes.?);
}
