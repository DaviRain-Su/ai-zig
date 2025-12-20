const std = @import("std");

/// Mistral chat model IDs
pub const ChatModels = struct {
    // Premier models
    pub const ministral_3b_latest = "ministral-3b-latest";
    pub const ministral_8b_latest = "ministral-8b-latest";
    pub const mistral_large_latest = "mistral-large-latest";
    pub const mistral_medium_latest = "mistral-medium-latest";
    pub const mistral_medium_2508 = "mistral-medium-2508";
    pub const mistral_medium_2505 = "mistral-medium-2505";
    pub const mistral_small_latest = "mistral-small-latest";
    pub const pixtral_large_latest = "pixtral-large-latest";

    // Reasoning models
    pub const magistral_small_2507 = "magistral-small-2507";
    pub const magistral_medium_2507 = "magistral-medium-2507";
    pub const magistral_small_2506 = "magistral-small-2506";
    pub const magistral_medium_2506 = "magistral-medium-2506";

    // Free models
    pub const pixtral_12b_2409 = "pixtral-12b-2409";

    // Legacy models
    pub const open_mistral_7b = "open-mistral-7b";
    pub const open_mixtral_8x7b = "open-mixtral-8x7b";
    pub const open_mixtral_8x22b = "open-mixtral-8x22b";
};

/// Mistral embedding model IDs
pub const EmbeddingModels = struct {
    pub const mistral_embed = "mistral-embed";
};

/// Mistral language model options
pub const MistralLanguageModelOptions = struct {
    /// Whether to inject a safety prompt before all conversations
    safe_prompt: ?bool = null,

    /// Document image limit
    document_image_limit: ?u32 = null,

    /// Document page limit
    document_page_limit: ?u32 = null,

    /// Whether to use structured outputs (default: true)
    structured_outputs: ?bool = null,

    /// Whether to use strict JSON schema validation (default: false)
    strict_json_schema: ?bool = null,

    /// Whether to enable parallel function calling during tool use (default: true)
    parallel_tool_calls: ?bool = null,
};

/// Tool choice options
pub const MistralToolChoice = enum {
    auto,
    none,
    any,

    pub fn toString(self: MistralToolChoice) []const u8 {
        return switch (self) {
            .auto => "auto",
            .none => "none",
            .any => "any",
        };
    }

    pub fn fromString(s: []const u8) MistralToolChoice {
        if (std.mem.eql(u8, s, "auto")) return .auto;
        if (std.mem.eql(u8, s, "none")) return .none;
        if (std.mem.eql(u8, s, "any")) return .any;
        return .auto;
    }
};

/// Response format types
pub const ResponseFormatType = enum {
    text,
    json_object,
    json_schema,

    pub fn toString(self: ResponseFormatType) []const u8 {
        return switch (self) {
            .text => "text",
            .json_object => "json_object",
            .json_schema => "json_schema",
        };
    }
};

/// Check if a model supports reasoning (thinking)
pub fn supportsReasoning(model_id: []const u8) bool {
    return std.mem.indexOf(u8, model_id, "magistral") != null;
}

/// Check if a model supports vision (Pixtral models)
pub fn supportsVision(model_id: []const u8) bool {
    return std.mem.indexOf(u8, model_id, "pixtral") != null;
}

test "supportsReasoning" {
    try std.testing.expect(supportsReasoning("magistral-small-2507"));
    try std.testing.expect(supportsReasoning("magistral-medium-2507"));
    try std.testing.expect(!supportsReasoning("mistral-large-latest"));
}

test "supportsVision" {
    try std.testing.expect(supportsVision("pixtral-large-latest"));
    try std.testing.expect(supportsVision("pixtral-12b-2409"));
    try std.testing.expect(!supportsVision("mistral-large-latest"));
}
