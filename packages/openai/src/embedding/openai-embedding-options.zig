const std = @import("std");

/// OpenAI Embedding Model IDs
pub const OpenAIEmbeddingModelId = []const u8;

/// Well-known OpenAI embedding model IDs
pub const Models = struct {
    pub const text_embedding_3_small = "text-embedding-3-small";
    pub const text_embedding_3_large = "text-embedding-3-large";
    pub const text_embedding_ada_002 = "text-embedding-ada-002";
};

/// OpenAI Embedding provider options
pub const OpenAIEmbeddingProviderOptions = struct {
    /// The number of dimensions the resulting output embeddings should have.
    /// Only supported in text-embedding-3 and later models.
    dimensions: ?u32 = null,

    /// A unique identifier representing your end-user.
    user: ?[]const u8 = null,
};

/// Get the default dimensions for a model
pub fn getDefaultDimensions(model_id: []const u8) ?u32 {
    if (std.mem.eql(u8, model_id, Models.text_embedding_3_small)) {
        return 1536;
    }
    if (std.mem.eql(u8, model_id, Models.text_embedding_3_large)) {
        return 3072;
    }
    if (std.mem.eql(u8, model_id, Models.text_embedding_ada_002)) {
        return 1536;
    }
    return null;
}

/// Check if a model supports custom dimensions
pub fn supportsCustomDimensions(model_id: []const u8) bool {
    return std.mem.startsWith(u8, model_id, "text-embedding-3");
}

test "getDefaultDimensions" {
    try std.testing.expectEqual(@as(?u32, 1536), getDefaultDimensions("text-embedding-3-small"));
    try std.testing.expectEqual(@as(?u32, 3072), getDefaultDimensions("text-embedding-3-large"));
    try std.testing.expectEqual(@as(?u32, 1536), getDefaultDimensions("text-embedding-ada-002"));
    try std.testing.expectEqual(@as(?u32, null), getDefaultDimensions("unknown-model"));
}

test "supportsCustomDimensions" {
    try std.testing.expect(supportsCustomDimensions("text-embedding-3-small"));
    try std.testing.expect(supportsCustomDimensions("text-embedding-3-large"));
    try std.testing.expect(!supportsCustomDimensions("text-embedding-ada-002"));
}
