const std = @import("std");
const lm = @import("provider").language_model;

/// Map DeepSeek finish reason to language model finish reason
pub fn mapDeepSeekFinishReason(
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
    } else if (std.mem.eql(u8, reason, "tool_calls")) {
        return .tool_calls;
    } else if (std.mem.eql(u8, reason, "insufficient_system_resource")) {
        return .@"error";
    }

    return .unknown;
}

test "mapDeepSeekFinishReason stop" {
    const result = mapDeepSeekFinishReason("stop");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}

test "mapDeepSeekFinishReason length" {
    const result = mapDeepSeekFinishReason("length");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.length, result);
}

test "mapDeepSeekFinishReason tool_calls" {
    const result = mapDeepSeekFinishReason("tool_calls");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.tool_calls, result);
}

test "mapDeepSeekFinishReason insufficient_system_resource" {
    const result = mapDeepSeekFinishReason("insufficient_system_resource");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.@"error", result);
}
