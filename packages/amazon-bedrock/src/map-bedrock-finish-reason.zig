const std = @import("std");
const lm = @import("../../provider/src/language-model/v3/index.zig");
const options = @import("bedrock-options.zig");

/// Map Bedrock stop reason to language model finish reason
pub fn mapBedrockFinishReason(
    finish_reason: options.StopReason,
    is_json_response_from_tool: bool,
) lm.LanguageModelV3FinishReason {
    return switch (finish_reason) {
        .stop_sequence, .end_turn => .stop,
        .max_tokens => .length,
        .content_filtered, .guardrail_intervened => .content_filter,
        .tool_use => if (is_json_response_from_tool) .stop else .tool_calls,
    };
}

/// Map Bedrock stop reason string to language model finish reason
pub fn mapBedrockFinishReasonString(
    finish_reason: ?[]const u8,
    is_json_response_from_tool: bool,
) lm.LanguageModelV3FinishReason {
    if (finish_reason == null) return .unknown;
    return mapBedrockFinishReason(
        options.StopReason.fromString(finish_reason.?),
        is_json_response_from_tool,
    );
}

test "mapBedrockFinishReason stop_sequence" {
    const result = mapBedrockFinishReason(.stop_sequence, false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}

test "mapBedrockFinishReason end_turn" {
    const result = mapBedrockFinishReason(.end_turn, false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}

test "mapBedrockFinishReason max_tokens" {
    const result = mapBedrockFinishReason(.max_tokens, false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.length, result);
}

test "mapBedrockFinishReason content_filtered" {
    const result = mapBedrockFinishReason(.content_filtered, false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.content_filter, result);
}

test "mapBedrockFinishReason tool_use without json" {
    const result = mapBedrockFinishReason(.tool_use, false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.tool_calls, result);
}

test "mapBedrockFinishReason tool_use with json" {
    const result = mapBedrockFinishReason(.tool_use, true);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}
