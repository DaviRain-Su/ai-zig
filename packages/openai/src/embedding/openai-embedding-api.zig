const std = @import("std");

/// OpenAI Text Embedding Response
pub const OpenAITextEmbeddingResponse = struct {
    object: []const u8,
    data: []const EmbeddingData,
    model: []const u8,
    usage: ?Usage = null,

    pub const EmbeddingData = struct {
        object: []const u8,
        embedding: []const f32,
        index: u32,
    };

    pub const Usage = struct {
        prompt_tokens: u64,
        total_tokens: u64,
    };
};

/// OpenAI Text Embedding Request
pub const OpenAITextEmbeddingRequest = struct {
    model: []const u8,
    input: []const []const u8,
    encoding_format: []const u8 = "float",
    dimensions: ?u32 = null,
    user: ?[]const u8 = null,
};

/// Convert OpenAI embedding usage to standard format
pub const EmbeddingUsage = struct {
    tokens: u64,
};

pub fn convertUsage(usage: ?OpenAITextEmbeddingResponse.Usage) ?EmbeddingUsage {
    if (usage) |u| {
        return .{ .tokens = u.prompt_tokens };
    }
    return null;
}

test "convertUsage" {
    const usage = OpenAITextEmbeddingResponse.Usage{
        .prompt_tokens = 100,
        .total_tokens = 100,
    };
    const result = convertUsage(usage);
    try std.testing.expect(result != null);
    try std.testing.expectEqual(@as(u64, 100), result.?.tokens);

    const null_result = convertUsage(null);
    try std.testing.expect(null_result == null);
}
