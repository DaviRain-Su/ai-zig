const std = @import("std");
const LanguageModelV3FinishReason = @import("../../../provider/src/language-model/v3/index.zig").LanguageModelV3FinishReason;

/// Map OpenAI finish reason to language model finish reason
pub fn mapOpenAIFinishReason(finish_reason: ?[]const u8) LanguageModelV3FinishReason {
    const reason = finish_reason orelse return .unknown;

    if (std.mem.eql(u8, reason, "stop")) {
        return .stop;
    }
    if (std.mem.eql(u8, reason, "length")) {
        return .length;
    }
    if (std.mem.eql(u8, reason, "content_filter")) {
        return .content_filter;
    }
    if (std.mem.eql(u8, reason, "tool_calls")) {
        return .tool_calls;
    }
    if (std.mem.eql(u8, reason, "function_call")) {
        // Legacy function_call maps to tool_calls
        return .tool_calls;
    }

    return .other;
}

/// Map language model finish reason back to OpenAI format
pub fn toOpenAIFinishReason(reason: LanguageModelV3FinishReason) ?[]const u8 {
    return switch (reason) {
        .stop => "stop",
        .length => "length",
        .content_filter => "content_filter",
        .tool_calls => "tool_calls",
        .@"error" => null,
        .other => null,
        .unknown => null,
    };
}

test "mapOpenAIFinishReason" {
    try std.testing.expectEqual(LanguageModelV3FinishReason.stop, mapOpenAIFinishReason("stop"));
    try std.testing.expectEqual(LanguageModelV3FinishReason.length, mapOpenAIFinishReason("length"));
    try std.testing.expectEqual(LanguageModelV3FinishReason.content_filter, mapOpenAIFinishReason("content_filter"));
    try std.testing.expectEqual(LanguageModelV3FinishReason.tool_calls, mapOpenAIFinishReason("tool_calls"));
    try std.testing.expectEqual(LanguageModelV3FinishReason.tool_calls, mapOpenAIFinishReason("function_call"));
    try std.testing.expectEqual(LanguageModelV3FinishReason.other, mapOpenAIFinishReason("something_else"));
    try std.testing.expectEqual(LanguageModelV3FinishReason.unknown, mapOpenAIFinishReason(null));
}

test "toOpenAIFinishReason" {
    try std.testing.expectEqualStrings("stop", toOpenAIFinishReason(.stop).?);
    try std.testing.expectEqualStrings("length", toOpenAIFinishReason(.length).?);
    try std.testing.expectEqualStrings("tool_calls", toOpenAIFinishReason(.tool_calls).?);
    try std.testing.expect(toOpenAIFinishReason(.unknown) == null);
}
