const std = @import("std");
const json_value = @import("../../../provider/src/json-value/index.zig");

/// OpenAI Chat model IDs
/// https://platform.openai.com/docs/models
pub const OpenAIChatModelId = []const u8;

/// Well-known OpenAI chat model IDs
pub const Models = struct {
    // Reasoning models
    pub const o1 = "o1";
    pub const o1_2024_12_17 = "o1-2024-12-17";
    pub const o3_mini = "o3-mini";
    pub const o3_mini_2025_01_31 = "o3-mini-2025-01-31";
    pub const o3 = "o3";
    pub const o3_2025_04_16 = "o3-2025-04-16";

    // GPT-4 series
    pub const gpt_4_1 = "gpt-4.1";
    pub const gpt_4_1_2025_04_14 = "gpt-4.1-2025-04-14";
    pub const gpt_4_1_mini = "gpt-4.1-mini";
    pub const gpt_4_1_mini_2025_04_14 = "gpt-4.1-mini-2025-04-14";
    pub const gpt_4_1_nano = "gpt-4.1-nano";
    pub const gpt_4_1_nano_2025_04_14 = "gpt-4.1-nano-2025-04-14";

    // GPT-4o series
    pub const gpt_4o = "gpt-4o";
    pub const gpt_4o_2024_05_13 = "gpt-4o-2024-05-13";
    pub const gpt_4o_2024_08_06 = "gpt-4o-2024-08-06";
    pub const gpt_4o_2024_11_20 = "gpt-4o-2024-11-20";
    pub const gpt_4o_mini = "gpt-4o-mini";
    pub const gpt_4o_mini_2024_07_18 = "gpt-4o-mini-2024-07-18";

    // GPT-4 Turbo
    pub const gpt_4_turbo = "gpt-4-turbo";
    pub const gpt_4_turbo_2024_04_09 = "gpt-4-turbo-2024-04-09";

    // GPT-4
    pub const gpt_4 = "gpt-4";
    pub const gpt_4_0613 = "gpt-4-0613";

    // GPT-4.5
    pub const gpt_4_5_preview = "gpt-4.5-preview";
    pub const gpt_4_5_preview_2025_02_27 = "gpt-4.5-preview-2025-02-27";

    // GPT-3.5
    pub const gpt_3_5_turbo = "gpt-3.5-turbo";
    pub const gpt_3_5_turbo_0125 = "gpt-3.5-turbo-0125";
    pub const gpt_3_5_turbo_1106 = "gpt-3.5-turbo-1106";

    // GPT-5 series
    pub const gpt_5 = "gpt-5";
    pub const gpt_5_2025_08_07 = "gpt-5-2025-08-07";
    pub const gpt_5_mini = "gpt-5-mini";
    pub const gpt_5_mini_2025_08_07 = "gpt-5-mini-2025-08-07";
    pub const gpt_5_nano = "gpt-5-nano";
    pub const gpt_5_nano_2025_08_07 = "gpt-5-nano-2025-08-07";
};

/// OpenAI Chat language model options
pub const OpenAIChatLanguageModelOptions = struct {
    /// Modify the likelihood of specified tokens appearing in the completion.
    /// Maps token IDs to bias values from -100 to 100.
    logit_bias: ?std.StringHashMap(f32) = null,

    /// Return the log probabilities of the tokens.
    /// true: return log probabilities
    /// number: return log probabilities of top n tokens
    logprobs: ?LogprobsOption = null,

    /// Whether to enable parallel function calling during tool use.
    parallel_tool_calls: ?bool = null,

    /// A unique identifier representing your end-user.
    user: ?[]const u8 = null,

    /// Reasoning effort for reasoning models.
    reasoning_effort: ?ReasoningEffort = null,

    /// Maximum number of completion tokens to generate.
    max_completion_tokens: ?u32 = null,

    /// Whether to enable persistence in responses API.
    store: ?bool = null,

    /// Metadata to associate with the request.
    metadata: ?std.StringHashMap([]const u8) = null,

    /// Parameters for prediction mode.
    prediction: ?json_value.JsonObject = null,

    /// Service tier for the request.
    service_tier: ?ServiceTier = null,

    /// Whether to use strict JSON schema validation.
    strict_json_schema: bool = true,

    /// Controls the verbosity of the model's responses.
    text_verbosity: ?TextVerbosity = null,

    /// A cache key for prompt caching.
    prompt_cache_key: ?[]const u8 = null,

    /// The retention policy for the prompt cache.
    prompt_cache_retention: ?PromptCacheRetention = null,

    /// A stable identifier used to help detect users violating usage policies.
    safety_identifier: ?[]const u8 = null,

    /// Override the system message mode for this model.
    system_message_mode: ?SystemMessageMode = null,

    /// Force treating this model as a reasoning model.
    force_reasoning: bool = false,

    pub const LogprobsOption = union(enum) {
        enabled: bool,
        top_n: u32,
    };

    pub const ReasoningEffort = enum {
        none,
        minimal,
        low,
        medium,
        high,
        xhigh,

        pub fn toString(self: ReasoningEffort) []const u8 {
            return switch (self) {
                .none => "none",
                .minimal => "minimal",
                .low => "low",
                .medium => "medium",
                .high => "high",
                .xhigh => "xhigh",
            };
        }
    };

    pub const ServiceTier = enum {
        auto,
        flex,
        priority,
        default,

        pub fn toString(self: ServiceTier) []const u8 {
            return switch (self) {
                .auto => "auto",
                .flex => "flex",
                .priority => "priority",
                .default => "default",
            };
        }
    };

    pub const TextVerbosity = enum {
        low,
        medium,
        high,

        pub fn toString(self: TextVerbosity) []const u8 {
            return switch (self) {
                .low => "low",
                .medium => "medium",
                .high => "high",
            };
        }
    };

    pub const PromptCacheRetention = enum {
        in_memory,
        @"24h",

        pub fn toString(self: PromptCacheRetention) []const u8 {
            return switch (self) {
                .in_memory => "in_memory",
                .@"24h" => "24h",
            };
        }
    };

    pub const SystemMessageMode = enum {
        system,
        developer,
        remove,

        pub fn toString(self: SystemMessageMode) []const u8 {
            return switch (self) {
                .system => "system",
                .developer => "developer",
                .remove => "remove",
            };
        }
    };
};

/// Check if a model ID is a reasoning model
pub fn isReasoningModel(model_id: []const u8) bool {
    // o1, o3 series are reasoning models
    if (std.mem.startsWith(u8, model_id, "o1")) return true;
    if (std.mem.startsWith(u8, model_id, "o3")) return true;
    return false;
}

/// Check if a model ID supports flex processing
pub fn supportsFlexProcessing(model_id: []const u8) bool {
    if (std.mem.startsWith(u8, model_id, "o3")) return true;
    if (std.mem.startsWith(u8, model_id, "o4-mini")) return true;
    if (std.mem.startsWith(u8, model_id, "gpt-5")) return true;
    return false;
}

/// Check if a model ID supports priority processing
pub fn supportsPriorityProcessing(model_id: []const u8) bool {
    if (std.mem.startsWith(u8, model_id, "gpt-4")) return true;
    if (std.mem.startsWith(u8, model_id, "gpt-5")) return true;
    if (std.mem.startsWith(u8, model_id, "o3")) return true;
    if (std.mem.startsWith(u8, model_id, "o4-mini")) return true;
    // gpt-5-nano is not supported
    if (std.mem.eql(u8, model_id, "gpt-5-nano")) return false;
    return false;
}

/// Get the default system message mode for a model
pub fn getDefaultSystemMessageMode(model_id: []const u8) OpenAIChatLanguageModelOptions.SystemMessageMode {
    if (isReasoningModel(model_id)) {
        return .developer;
    }
    return .system;
}

test "isReasoningModel" {
    try std.testing.expect(isReasoningModel("o1"));
    try std.testing.expect(isReasoningModel("o1-2024-12-17"));
    try std.testing.expect(isReasoningModel("o3-mini"));
    try std.testing.expect(!isReasoningModel("gpt-4o"));
    try std.testing.expect(!isReasoningModel("gpt-4-turbo"));
}

test "supportsFlexProcessing" {
    try std.testing.expect(supportsFlexProcessing("o3"));
    try std.testing.expect(supportsFlexProcessing("o3-mini"));
    try std.testing.expect(supportsFlexProcessing("gpt-5"));
    try std.testing.expect(!supportsFlexProcessing("gpt-4o"));
}

test "getDefaultSystemMessageMode" {
    try std.testing.expectEqual(
        OpenAIChatLanguageModelOptions.SystemMessageMode.developer,
        getDefaultSystemMessageMode("o1"),
    );
    try std.testing.expectEqual(
        OpenAIChatLanguageModelOptions.SystemMessageMode.system,
        getDefaultSystemMessageMode("gpt-4o"),
    );
}
