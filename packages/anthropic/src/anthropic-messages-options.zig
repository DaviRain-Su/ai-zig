const std = @import("std");

/// Anthropic Messages Model IDs
pub const AnthropicMessagesModelId = []const u8;

/// Well-known Anthropic model IDs
pub const Models = struct {
    // Claude 3.5 Haiku
    pub const claude_3_5_haiku_20241022 = "claude-3-5-haiku-20241022";
    pub const claude_3_5_haiku_latest = "claude-3-5-haiku-latest";

    // Claude 3.7 Sonnet
    pub const claude_3_7_sonnet_20250219 = "claude-3-7-sonnet-20250219";
    pub const claude_3_7_sonnet_latest = "claude-3-7-sonnet-latest";

    // Claude 3 Haiku
    pub const claude_3_haiku_20240307 = "claude-3-haiku-20240307";

    // Claude Haiku 4.5
    pub const claude_haiku_4_5_20251001 = "claude-haiku-4-5-20251001";
    pub const claude_haiku_4_5 = "claude-haiku-4-5";

    // Claude Opus 4
    pub const claude_opus_4_0 = "claude-opus-4-0";
    pub const claude_opus_4_1_20250805 = "claude-opus-4-1-20250805";
    pub const claude_opus_4_1 = "claude-opus-4-1";
    pub const claude_opus_4_20250514 = "claude-opus-4-20250514";

    // Claude Opus 4.5
    pub const claude_opus_4_5 = "claude-opus-4-5";
    pub const claude_opus_4_5_20251101 = "claude-opus-4-5-20251101";

    // Claude Sonnet 4
    pub const claude_sonnet_4_0 = "claude-sonnet-4-0";
    pub const claude_sonnet_4_20250514 = "claude-sonnet-4-20250514";

    // Claude Sonnet 4.5
    pub const claude_sonnet_4_5_20250929 = "claude-sonnet-4-5-20250929";
    pub const claude_sonnet_4_5 = "claude-sonnet-4-5";
};

/// Thinking configuration
pub const ThinkingConfig = struct {
    type: ThinkingType,
    budget_tokens: ?u32 = null,

    pub const ThinkingType = enum {
        enabled,
        disabled,
    };
};

/// Structured output mode
pub const StructuredOutputMode = enum {
    output_format,
    json_tool,
    auto,
};

/// Effort level for model responses
pub const Effort = enum {
    low,
    medium,
    high,

    pub fn toString(self: Effort) []const u8 {
        return switch (self) {
            .low => "low",
            .medium => "medium",
            .high => "high",
        };
    }
};

/// Anthropic provider options
pub const AnthropicProviderOptions = struct {
    /// Whether to send reasoning to the model
    send_reasoning: ?bool = null,

    /// Structured output mode
    structured_output_mode: ?StructuredOutputMode = null,

    /// Extended thinking configuration
    thinking: ?ThinkingConfig = null,

    /// Whether to disable parallel function calling
    disable_parallel_tool_use: ?bool = null,

    /// Tool streaming enabled
    tool_streaming: ?bool = null,

    /// Effort level
    effort: ?Effort = null,
};

/// Get model capabilities
pub const ModelCapabilities = struct {
    max_output_tokens: u32,
    supports_structured_output: bool,
    is_known_model: bool,
};

pub fn getModelCapabilities(model_id: []const u8) ModelCapabilities {
    if (std.mem.indexOf(u8, model_id, "claude-sonnet-4-5") != null or
        std.mem.indexOf(u8, model_id, "claude-opus-4-5") != null)
    {
        return .{
            .max_output_tokens = 64000,
            .supports_structured_output = true,
            .is_known_model = true,
        };
    } else if (std.mem.indexOf(u8, model_id, "claude-opus-4-1") != null) {
        return .{
            .max_output_tokens = 32000,
            .supports_structured_output = true,
            .is_known_model = true,
        };
    } else if (std.mem.indexOf(u8, model_id, "claude-sonnet-4-") != null or
        std.mem.indexOf(u8, model_id, "claude-3-7-sonnet") != null or
        std.mem.indexOf(u8, model_id, "claude-haiku-4-5") != null)
    {
        return .{
            .max_output_tokens = 64000,
            .supports_structured_output = false,
            .is_known_model = true,
        };
    } else if (std.mem.indexOf(u8, model_id, "claude-opus-4-") != null) {
        return .{
            .max_output_tokens = 32000,
            .supports_structured_output = false,
            .is_known_model = true,
        };
    } else if (std.mem.indexOf(u8, model_id, "claude-3-5-haiku") != null) {
        return .{
            .max_output_tokens = 8192,
            .supports_structured_output = false,
            .is_known_model = true,
        };
    } else if (std.mem.indexOf(u8, model_id, "claude-3-haiku") != null) {
        return .{
            .max_output_tokens = 4096,
            .supports_structured_output = false,
            .is_known_model = true,
        };
    }

    return .{
        .max_output_tokens = 4096,
        .supports_structured_output = false,
        .is_known_model = false,
    };
}

test "getModelCapabilities" {
    const sonnet_4_5 = getModelCapabilities("claude-sonnet-4-5-20250929");
    try std.testing.expectEqual(@as(u32, 64000), sonnet_4_5.max_output_tokens);
    try std.testing.expect(sonnet_4_5.supports_structured_output);

    const opus_4_1 = getModelCapabilities("claude-opus-4-1");
    try std.testing.expectEqual(@as(u32, 32000), opus_4_1.max_output_tokens);
    try std.testing.expect(opus_4_1.supports_structured_output);

    const haiku = getModelCapabilities("claude-3-5-haiku-latest");
    try std.testing.expectEqual(@as(u32, 8192), haiku.max_output_tokens);
    try std.testing.expect(!haiku.supports_structured_output);
}
