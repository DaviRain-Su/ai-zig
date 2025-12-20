const std = @import("std");

/// Cohere chat model IDs
pub const ChatModels = struct {
    pub const command_a_03_2025 = "command-a-03-2025";
    pub const command_a_reasoning_08_2025 = "command-a-reasoning-08-2025";
    pub const command_r7b_12_2024 = "command-r7b-12-2024";
    pub const command_r_plus_04_2024 = "command-r-plus-04-2024";
    pub const command_r_plus = "command-r-plus";
    pub const command_r_08_2024 = "command-r-08-2024";
    pub const command_r_03_2024 = "command-r-03-2024";
    pub const command_r = "command-r";
    pub const command = "command";
    pub const command_nightly = "command-nightly";
    pub const command_light = "command-light";
    pub const command_light_nightly = "command-light-nightly";
};

/// Cohere embedding model IDs
pub const EmbeddingModels = struct {
    pub const embed_english_v3_0 = "embed-english-v3.0";
    pub const embed_multilingual_v3_0 = "embed-multilingual-v3.0";
    pub const embed_english_light_v3_0 = "embed-english-light-v3.0";
    pub const embed_multilingual_light_v3_0 = "embed-multilingual-light-v3.0";
    pub const embed_english_v2_0 = "embed-english-v2.0";
    pub const embed_english_light_v2_0 = "embed-english-light-v2.0";
    pub const embed_multilingual_v2_0 = "embed-multilingual-v2.0";
};

/// Cohere reranking model IDs
pub const RerankingModels = struct {
    pub const rerank_v3_5 = "rerank-v3.5";
    pub const rerank_english_v3_0 = "rerank-english-v3.0";
    pub const rerank_multilingual_v3_0 = "rerank-multilingual-v3.0";
};

/// Thinking configuration for reasoning models
pub const ThinkingConfig = struct {
    type: ThinkingType = .enabled,
    token_budget: ?u32 = null,
};

/// Thinking type
pub const ThinkingType = enum {
    enabled,
    disabled,

    pub fn toString(self: ThinkingType) []const u8 {
        return switch (self) {
            .enabled => "enabled",
            .disabled => "disabled",
        };
    }
};

/// Cohere chat model options
pub const CohereChatModelOptions = struct {
    /// Configuration for reasoning features
    thinking: ?ThinkingConfig = null,
};

/// Embedding input type
pub const EmbeddingInputType = enum {
    search_document,
    search_query,
    classification,
    clustering,

    pub fn toString(self: EmbeddingInputType) []const u8 {
        return switch (self) {
            .search_document => "search_document",
            .search_query => "search_query",
            .classification => "classification",
            .clustering => "clustering",
        };
    }
};

/// Embedding truncation mode
pub const EmbeddingTruncate = enum {
    none,
    start,
    end,

    pub fn toString(self: EmbeddingTruncate) []const u8 {
        return switch (self) {
            .none => "NONE",
            .start => "START",
            .end => "END",
        };
    }
};

/// Cohere embedding options
pub const CohereEmbeddingOptions = struct {
    /// Specifies the type of input passed to the model
    input_type: ?EmbeddingInputType = null,

    /// Specifies how the API will handle inputs longer than the maximum token length
    truncate: ?EmbeddingTruncate = null,
};

/// Cohere reranking options
pub const CohereRerankingOptions = struct {
    /// Maximum tokens per document (default: 4096)
    max_tokens_per_doc: ?u32 = null,

    /// Request priority (default: 0)
    priority: ?u32 = null,
};

/// Check if a model supports reasoning
pub fn supportsReasoning(model_id: []const u8) bool {
    return std.mem.indexOf(u8, model_id, "reasoning") != null;
}

test "supportsReasoning" {
    try std.testing.expect(supportsReasoning("command-a-reasoning-08-2025"));
    try std.testing.expect(!supportsReasoning("command-r-plus"));
}
