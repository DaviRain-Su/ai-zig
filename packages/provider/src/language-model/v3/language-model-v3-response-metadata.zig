const std = @import("std");

/// Response metadata for a language model call.
pub const LanguageModelV3ResponseMetadata = struct {
    /// ID for the generated response, if the provider sends one.
    id: ?[]const u8 = null,

    /// Timestamp for the start of the generated response, if the provider sends one.
    timestamp: ?i64 = null,

    /// The ID of the response model that was used to generate the response,
    /// if the provider sends one.
    model_id: ?[]const u8 = null,

    const Self = @This();

    /// Create empty response metadata
    pub fn init() Self {
        return .{};
    }

    /// Create response metadata with ID
    pub fn initWithId(id: []const u8) Self {
        return .{
            .id = id,
        };
    }

    /// Create full response metadata
    pub fn initFull(id: ?[]const u8, timestamp: ?i64, model_id: ?[]const u8) Self {
        return .{
            .id = id,
            .timestamp = timestamp,
            .model_id = model_id,
        };
    }

    /// Clone the response metadata
    pub fn clone(self: Self, allocator: std.mem.Allocator) !Self {
        return .{
            .id = if (self.id) |i| try allocator.dupe(u8, i) else null,
            .timestamp = self.timestamp,
            .model_id = if (self.model_id) |m| try allocator.dupe(u8, m) else null,
        };
    }

    /// Free memory allocated for this response metadata
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.id) |i| allocator.free(i);
        if (self.model_id) |m| allocator.free(m);
    }
};

test "LanguageModelV3ResponseMetadata basic" {
    const metadata = LanguageModelV3ResponseMetadata.init();
    try std.testing.expect(metadata.id == null);
    try std.testing.expect(metadata.timestamp == null);
    try std.testing.expect(metadata.model_id == null);
}

test "LanguageModelV3ResponseMetadata with values" {
    const metadata = LanguageModelV3ResponseMetadata.initFull(
        "resp-123",
        1700000000000,
        "gpt-4",
    );
    try std.testing.expectEqualStrings("resp-123", metadata.id.?);
    try std.testing.expectEqual(@as(i64, 1700000000000), metadata.timestamp.?);
    try std.testing.expectEqualStrings("gpt-4", metadata.model_id.?);
}
