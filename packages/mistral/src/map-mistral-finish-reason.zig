const std = @import("std");
const lm = @import("../../provider/src/language-model/v3/index.zig");

/// Map Mistral finish reason to language model finish reason
pub fn mapMistralFinishReason(
    finish_reason: ?[]const u8,
) lm.LanguageModelV3FinishReason {
    if (finish_reason == null) return .unknown;

    const reason = finish_reason.?;

    if (std.mem.eql(u8, reason, "stop")) {
        return .stop;
    } else if (std.mem.eql(u8, reason, "length") or std.mem.eql(u8, reason, "model_length")) {
        return .length;
    } else if (std.mem.eql(u8, reason, "tool_calls")) {
        return .tool_calls;
    }

    return .unknown;
}

test "mapMistralFinishReason stop" {
    const result = mapMistralFinishReason("stop");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}

test "mapMistralFinishReason length" {
    const result = mapMistralFinishReason("length");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.length, result);
}

test "mapMistralFinishReason model_length" {
    const result = mapMistralFinishReason("model_length");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.length, result);
}

test "mapMistralFinishReason tool_calls" {
    const result = mapMistralFinishReason("tool_calls");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.tool_calls, result);
}

test "mapMistralFinishReason null" {
    const result = mapMistralFinishReason(null);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.unknown, result);
}
