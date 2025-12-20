const std = @import("std");

/// Groq chat model IDs
pub const ChatModels = struct {
    // Production models
    pub const gemma2_9b_it = "gemma2-9b-it";
    pub const llama_3_1_8b_instant = "llama-3.1-8b-instant";
    pub const llama_3_3_70b_versatile = "llama-3.3-70b-versatile";
    pub const llama_guard_4_12b = "meta-llama/llama-guard-4-12b";
    pub const gpt_oss_120b = "openai/gpt-oss-120b";
    pub const gpt_oss_20b = "openai/gpt-oss-20b";

    // Preview models
    pub const deepseek_r1_distill_llama_70b = "deepseek-r1-distill-llama-70b";
    pub const llama_4_maverick_17b = "meta-llama/llama-4-maverick-17b-128e-instruct";
    pub const llama_4_scout_17b = "meta-llama/llama-4-scout-17b-16e-instruct";
    pub const kimi_k2_instruct = "moonshotai/kimi-k2-instruct-0905";
    pub const qwen3_32b = "qwen/qwen3-32b";
    pub const llama_guard_3_8b = "llama-guard-3-8b";
    pub const llama3_70b_8192 = "llama3-70b-8192";
    pub const llama3_8b_8192 = "llama3-8b-8192";
    pub const mixtral_8x7b_32768 = "mixtral-8x7b-32768";
    pub const qwen_qwq_32b = "qwen-qwq-32b";
    pub const qwen_2_5_32b = "qwen-2.5-32b";
    pub const deepseek_r1_distill_qwen_32b = "deepseek-r1-distill-qwen-32b";
};

/// Groq transcription model IDs
pub const TranscriptionModels = struct {
    pub const whisper_large_v3_turbo = "whisper-large-v3-turbo";
    pub const whisper_large_v3 = "whisper-large-v3";
};

/// Reasoning format options
pub const ReasoningFormat = enum {
    parsed,
    raw,
    hidden,

    pub fn toString(self: ReasoningFormat) []const u8 {
        return switch (self) {
            .parsed => "parsed",
            .raw => "raw",
            .hidden => "hidden",
        };
    }
};

/// Reasoning effort levels
pub const ReasoningEffort = enum {
    none,
    default,
    low,
    medium,
    high,

    pub fn toString(self: ReasoningEffort) []const u8 {
        return switch (self) {
            .none => "none",
            .default => "default",
            .low => "low",
            .medium => "medium",
            .high => "high",
        };
    }
};

/// Service tier options
pub const ServiceTier = enum {
    on_demand,
    flex,
    auto,

    pub fn toString(self: ServiceTier) []const u8 {
        return switch (self) {
            .on_demand => "on_demand",
            .flex => "flex",
            .auto => "auto",
        };
    }
};

/// Groq provider options
pub const GroqProviderOptions = struct {
    /// Reasoning format for model inference
    reasoning_format: ?ReasoningFormat = null,

    /// Reasoning effort level for model inference
    reasoning_effort: ?ReasoningEffort = null,

    /// Whether to enable parallel function calling during tool use
    parallel_tool_calls: ?bool = null,

    /// A unique identifier representing your end-user
    user: ?[]const u8 = null,

    /// Whether to use structured outputs (default: true)
    structured_outputs: ?bool = null,

    /// Service tier for the request
    service_tier: ?ServiceTier = null,
};

/// Check if a model supports reasoning
pub fn supportsReasoning(model_id: []const u8) bool {
    return std.mem.indexOf(u8, model_id, "deepseek-r1") != null or
        std.mem.indexOf(u8, model_id, "qwq") != null;
}

test "supportsReasoning" {
    try std.testing.expect(supportsReasoning("deepseek-r1-distill-llama-70b"));
    try std.testing.expect(supportsReasoning("qwen-qwq-32b"));
    try std.testing.expect(!supportsReasoning("llama-3.3-70b-versatile"));
}
