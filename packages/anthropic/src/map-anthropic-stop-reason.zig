const std = @import("std");
const LanguageModelV3FinishReason = @import("provider").language_model.LanguageModelV3FinishReason;

/// Map Anthropic stop reason to language model finish reason
pub fn mapAnthropicStopReason(
    stop_reason: ?[]const u8,
    is_json_response_from_tool: bool,
) LanguageModelV3FinishReason {
    const reason = stop_reason orelse return .unknown;

    if (std.mem.eql(u8, reason, "pause_turn") or
        std.mem.eql(u8, reason, "end_turn") or
        std.mem.eql(u8, reason, "stop_sequence"))
    {
        return .stop;
    }

    if (std.mem.eql(u8, reason, "refusal")) {
        return .content_filter;
    }

    if (std.mem.eql(u8, reason, "tool_use")) {
        return if (is_json_response_from_tool) .stop else .tool_calls;
    }

    if (std.mem.eql(u8, reason, "max_tokens") or
        std.mem.eql(u8, reason, "model_context_window_exceeded"))
    {
        return .length;
    }

    return .unknown;
}

/// Map language model finish reason back to Anthropic stop reason
pub fn toAnthropicStopReason(reason: LanguageModelV3FinishReason) ?[]const u8 {
    return switch (reason) {
        .stop => "end_turn",
        .length => "max_tokens",
        .content_filter => "refusal",
        .tool_calls => "tool_use",
        .@"error" => null,
        .other => null,
        .unknown => null,
    };
}

test "mapAnthropicStopReason" {
    try std.testing.expectEqual(LanguageModelV3FinishReason.stop, mapAnthropicStopReason("end_turn", false));
    try std.testing.expectEqual(LanguageModelV3FinishReason.stop, mapAnthropicStopReason("pause_turn", false));
    try std.testing.expectEqual(LanguageModelV3FinishReason.stop, mapAnthropicStopReason("stop_sequence", false));
    try std.testing.expectEqual(LanguageModelV3FinishReason.content_filter, mapAnthropicStopReason("refusal", false));
    try std.testing.expectEqual(LanguageModelV3FinishReason.tool_calls, mapAnthropicStopReason("tool_use", false));
    try std.testing.expectEqual(LanguageModelV3FinishReason.stop, mapAnthropicStopReason("tool_use", true));
    try std.testing.expectEqual(LanguageModelV3FinishReason.length, mapAnthropicStopReason("max_tokens", false));
    try std.testing.expectEqual(LanguageModelV3FinishReason.unknown, mapAnthropicStopReason(null, false));
}

test "toAnthropicStopReason" {
    try std.testing.expectEqualStrings("end_turn", toAnthropicStopReason(.stop).?);
    try std.testing.expectEqualStrings("max_tokens", toAnthropicStopReason(.length).?);
    try std.testing.expectEqualStrings("tool_use", toAnthropicStopReason(.tool_calls).?);
    try std.testing.expect(toAnthropicStopReason(.unknown) == null);
}
