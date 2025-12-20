const std = @import("std");
const lm = @import("../../provider/src/language-model/v3/index.zig");

/// Map Groq finish reason to language model finish reason
pub fn mapGroqFinishReason(
    finish_reason: ?[]const u8,
) lm.LanguageModelV3FinishReason {
    if (finish_reason == null) return .unknown;

    const reason = finish_reason.?;

    if (std.mem.eql(u8, reason, "stop")) {
        return .stop;
    } else if (std.mem.eql(u8, reason, "length")) {
        return .length;
    } else if (std.mem.eql(u8, reason, "content_filter")) {
        return .content_filter;
    } else if (std.mem.eql(u8, reason, "function_call") or std.mem.eql(u8, reason, "tool_calls")) {
        return .tool_calls;
    }

    return .unknown;
}

test "mapGroqFinishReason stop" {
    const result = mapGroqFinishReason("stop");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}

test "mapGroqFinishReason length" {
    const result = mapGroqFinishReason("length");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.length, result);
}

test "mapGroqFinishReason content_filter" {
    const result = mapGroqFinishReason("content_filter");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.content_filter, result);
}

test "mapGroqFinishReason tool_calls" {
    const result = mapGroqFinishReason("tool_calls");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.tool_calls, result);
}

test "mapGroqFinishReason null" {
    const result = mapGroqFinishReason(null);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.unknown, result);
}
