const std = @import("std");

/// Bedrock chat model identifiers
pub const ChatModels = struct {
    // Amazon Titan
    pub const titan_tg1_large = "amazon.titan-tg1-large";
    pub const titan_text_express_v1 = "amazon.titan-text-express-v1";
    pub const titan_text_lite_v1 = "amazon.titan-text-lite-v1";

    // Amazon Nova
    pub const nova_premier_v1 = "us.amazon.nova-premier-v1:0";
    pub const nova_pro_v1 = "us.amazon.nova-pro-v1:0";
    pub const nova_micro_v1 = "us.amazon.nova-micro-v1:0";
    pub const nova_lite_v1 = "us.amazon.nova-lite-v1:0";

    // Anthropic Claude
    pub const claude_v2 = "anthropic.claude-v2";
    pub const claude_v2_1 = "anthropic.claude-v2:1";
    pub const claude_instant_v1 = "anthropic.claude-instant-v1";
    pub const claude_3_sonnet = "anthropic.claude-3-sonnet-20240229-v1:0";
    pub const claude_3_haiku = "anthropic.claude-3-haiku-20240307-v1:0";
    pub const claude_3_opus = "anthropic.claude-3-opus-20240229-v1:0";
    pub const claude_3_5_sonnet = "anthropic.claude-3-5-sonnet-20241022-v2:0";
    pub const claude_3_5_haiku = "anthropic.claude-3-5-haiku-20241022-v1:0";
    pub const claude_3_7_sonnet = "anthropic.claude-3-7-sonnet-20250219-v1:0";
    pub const claude_4_sonnet = "anthropic.claude-sonnet-4-20250514-v1:0";
    pub const claude_4_opus = "anthropic.claude-opus-4-20250514-v1:0";
    pub const claude_4_5_haiku = "anthropic.claude-haiku-4-5-20251001-v1:0";
    pub const claude_4_5_sonnet = "anthropic.claude-sonnet-4-5-20250929-v1:0";
    pub const claude_4_1_opus = "anthropic.claude-opus-4-1-20250805-v1:0";

    // Cohere
    pub const command_text_v14 = "cohere.command-text-v14";
    pub const command_light_text_v14 = "cohere.command-light-text-v14";
    pub const command_r_v1 = "cohere.command-r-v1:0";
    pub const command_r_plus_v1 = "cohere.command-r-plus-v1:0";

    // Meta Llama
    pub const llama3_70b = "meta.llama3-70b-instruct-v1:0";
    pub const llama3_8b = "meta.llama3-8b-instruct-v1:0";
    pub const llama3_1_405b = "meta.llama3-1-405b-instruct-v1:0";
    pub const llama3_1_70b = "meta.llama3-1-70b-instruct-v1:0";
    pub const llama3_1_8b = "meta.llama3-1-8b-instruct-v1:0";
    pub const llama3_2_90b = "meta.llama3-2-90b-instruct-v1:0";
    pub const llama3_2_11b = "meta.llama3-2-11b-instruct-v1:0";
    pub const llama3_2_3b = "meta.llama3-2-3b-instruct-v1:0";
    pub const llama3_2_1b = "meta.llama3-2-1b-instruct-v1:0";
    pub const llama3_3_70b = "us.meta.llama3-3-70b-instruct-v1:0";
    pub const llama4_scout_17b = "us.meta.llama4-scout-17b-instruct-v1:0";
    pub const llama4_maverick_17b = "us.meta.llama4-maverick-17b-instruct-v1:0";

    // Mistral
    pub const mistral_7b = "mistral.mistral-7b-instruct-v0:2";
    pub const mixtral_8x7b = "mistral.mixtral-8x7b-instruct-v0:1";
    pub const mistral_large = "mistral.mistral-large-2402-v1:0";
    pub const mistral_small = "mistral.mistral-small-2402-v1:0";

    // DeepSeek
    pub const deepseek_r1 = "us.deepseek.r1-v1:0";
};

/// Bedrock embedding model identifiers
pub const EmbeddingModels = struct {
    pub const titan_embed_text_v1 = "amazon.titan-embed-text-v1";
    pub const titan_embed_text_v2 = "amazon.titan-embed-text-v2:0";
    pub const titan_embed_image_v1 = "amazon.titan-embed-image-v1";
    pub const cohere_embed_english_v3 = "cohere.embed-english-v3";
    pub const cohere_embed_multilingual_v3 = "cohere.embed-multilingual-v3";
};

/// Bedrock image model identifiers
pub const ImageModels = struct {
    pub const titan_image_generator_v1 = "amazon.titan-image-generator-v1";
    pub const titan_image_generator_v2 = "amazon.titan-image-generator-v2:0";
    pub const stable_diffusion_xl_v1 = "stability.stable-diffusion-xl-v1";
};

/// Bedrock reranking model identifiers
pub const RerankingModels = struct {
    pub const cohere_rerank_v3 = "cohere.rerank-v3-5:0";
    pub const amazon_rerank_v1 = "amazon.rerank-v1:0";
};

/// Bedrock stop reasons
pub const StopReason = enum {
    stop_sequence,
    end_turn,
    max_tokens,
    content_filtered,
    guardrail_intervened,
    tool_use,

    pub fn fromString(s: []const u8) StopReason {
        if (std.mem.eql(u8, s, "stop_sequence")) return .stop_sequence;
        if (std.mem.eql(u8, s, "end_turn")) return .end_turn;
        if (std.mem.eql(u8, s, "max_tokens")) return .max_tokens;
        if (std.mem.eql(u8, s, "content_filtered")) return .content_filtered;
        if (std.mem.eql(u8, s, "guardrail_intervened")) return .guardrail_intervened;
        if (std.mem.eql(u8, s, "tool_use")) return .tool_use;
        return .end_turn;
    }
};

/// Reasoning configuration for models that support extended thinking
pub const ReasoningConfig = struct {
    /// Type: enabled or disabled
    type: ?ReasoningType = null,

    /// Budget tokens for reasoning
    budget_tokens: ?u32 = null,

    /// Maximum reasoning effort level
    max_reasoning_effort: ?ReasoningEffort = null,

    pub const ReasoningType = enum {
        enabled,
        disabled,

        pub fn toString(self: ReasoningType) []const u8 {
            return switch (self) {
                .enabled => "enabled",
                .disabled => "disabled",
            };
        }
    };

    pub const ReasoningEffort = enum {
        low,
        medium,
        high,

        pub fn toString(self: ReasoningEffort) []const u8 {
            return switch (self) {
                .low => "low",
                .medium => "medium",
                .high => "high",
            };
        }
    };
};

/// Bedrock provider options
pub const BedrockProviderOptions = struct {
    /// Additional inference parameters
    additional_model_request_fields: ?std.json.Value = null,

    /// Reasoning configuration
    reasoning_config: ?ReasoningConfig = null,

    /// Anthropic beta features
    anthropic_beta: ?[]const []const u8 = null,
};

/// Check if a model is an Anthropic model
pub fn isAnthropicModel(model_id: []const u8) bool {
    return std.mem.indexOf(u8, model_id, "anthropic") != null;
}

/// Check if a model is a Nova model
pub fn isNovaModel(model_id: []const u8) bool {
    return std.mem.indexOf(u8, model_id, "nova") != null;
}

/// Check if a model supports reasoning/thinking
pub fn supportsReasoning(model_id: []const u8) bool {
    return std.mem.indexOf(u8, model_id, "claude-3-7") != null or
        std.mem.indexOf(u8, model_id, "claude-sonnet-4") != null or
        std.mem.indexOf(u8, model_id, "claude-opus-4") != null or
        std.mem.indexOf(u8, model_id, "nova") != null;
}

test "ChatModels constants" {
    try std.testing.expectEqualStrings("anthropic.claude-3-5-sonnet-20241022-v2:0", ChatModels.claude_3_5_sonnet);
    try std.testing.expectEqualStrings("meta.llama3-1-70b-instruct-v1:0", ChatModels.llama3_1_70b);
}

test "isAnthropicModel" {
    try std.testing.expect(isAnthropicModel("anthropic.claude-3-5-sonnet-20241022-v2:0"));
    try std.testing.expect(isAnthropicModel("us.anthropic.claude-3-sonnet-20240229-v1:0"));
    try std.testing.expect(!isAnthropicModel("meta.llama3-1-70b-instruct-v1:0"));
}

test "supportsReasoning" {
    try std.testing.expect(supportsReasoning("anthropic.claude-3-7-sonnet-20250219-v1:0"));
    try std.testing.expect(supportsReasoning("us.amazon.nova-pro-v1:0"));
    try std.testing.expect(!supportsReasoning("anthropic.claude-3-5-sonnet-20241022-v2:0"));
}
