const std = @import("std");
const lm = @import("../../provider/src/language-model/v3/index.zig");

/// Map Google Generative AI finish reason to language model finish reason
pub fn mapGoogleGenerativeAIFinishReason(
    finish_reason: ?[]const u8,
    has_tool_calls: bool,
) lm.LanguageModelV3FinishReason {
    const reason = finish_reason orelse return .unknown;

    if (std.mem.eql(u8, reason, "STOP")) {
        return if (has_tool_calls) .tool_calls else .stop;
    }
    if (std.mem.eql(u8, reason, "MAX_TOKENS")) {
        return .length;
    }
    if (std.mem.eql(u8, reason, "IMAGE_SAFETY") or
        std.mem.eql(u8, reason, "RECITATION") or
        std.mem.eql(u8, reason, "SAFETY") or
        std.mem.eql(u8, reason, "BLOCKLIST") or
        std.mem.eql(u8, reason, "PROHIBITED_CONTENT") or
        std.mem.eql(u8, reason, "SPII"))
    {
        return .content_filter;
    }
    if (std.mem.eql(u8, reason, "FINISH_REASON_UNSPECIFIED") or
        std.mem.eql(u8, reason, "OTHER"))
    {
        return .other;
    }
    if (std.mem.eql(u8, reason, "MALFORMED_FUNCTION_CALL")) {
        return .@"error";
    }

    return .unknown;
}

test "mapGoogleGenerativeAIFinishReason STOP without tool calls" {
    const result = mapGoogleGenerativeAIFinishReason("STOP", false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}

test "mapGoogleGenerativeAIFinishReason STOP with tool calls" {
    const result = mapGoogleGenerativeAIFinishReason("STOP", true);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.tool_calls, result);
}

test "mapGoogleGenerativeAIFinishReason MAX_TOKENS" {
    const result = mapGoogleGenerativeAIFinishReason("MAX_TOKENS", false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.length, result);
}

test "mapGoogleGenerativeAIFinishReason SAFETY" {
    const result = mapGoogleGenerativeAIFinishReason("SAFETY", false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.content_filter, result);
}

test "mapGoogleGenerativeAIFinishReason RECITATION" {
    const result = mapGoogleGenerativeAIFinishReason("RECITATION", false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.content_filter, result);
}

test "mapGoogleGenerativeAIFinishReason MALFORMED_FUNCTION_CALL" {
    const result = mapGoogleGenerativeAIFinishReason("MALFORMED_FUNCTION_CALL", false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.@"error", result);
}

test "mapGoogleGenerativeAIFinishReason null" {
    const result = mapGoogleGenerativeAIFinishReason(null, false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.unknown, result);
}

test "mapGoogleGenerativeAIFinishReason unknown" {
    const result = mapGoogleGenerativeAIFinishReason("SOMETHING_ELSE", false);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.unknown, result);
}
