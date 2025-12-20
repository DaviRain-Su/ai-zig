const std = @import("std");

/// Reason why a language model finished generating a response.
pub const LanguageModelV3FinishReason = enum {
    /// Model generated stop sequence
    stop,
    /// Model generated maximum number of tokens
    length,
    /// Content filter violation stopped the model
    content_filter,
    /// Model triggered tool calls
    tool_calls,
    /// Model stopped because of an error
    @"error",
    /// Model stopped for other reasons
    other,
    /// The model has not transmitted a finish reason
    unknown,

    const Self = @This();

    /// Convert to string representation
    pub fn toString(self: Self) []const u8 {
        return switch (self) {
            .stop => "stop",
            .length => "length",
            .content_filter => "content-filter",
            .tool_calls => "tool-calls",
            .@"error" => "error",
            .other => "other",
            .unknown => "unknown",
        };
    }

    /// Parse from string representation
    pub fn fromString(s: []const u8) Self {
        if (std.mem.eql(u8, s, "stop")) return .stop;
        if (std.mem.eql(u8, s, "length")) return .length;
        if (std.mem.eql(u8, s, "content-filter")) return .content_filter;
        if (std.mem.eql(u8, s, "tool-calls")) return .tool_calls;
        if (std.mem.eql(u8, s, "error")) return .@"error";
        if (std.mem.eql(u8, s, "other")) return .other;
        return .unknown;
    }

    /// Check if the generation completed normally (stop or tool_calls)
    pub fn isComplete(self: Self) bool {
        return self == .stop or self == .tool_calls;
    }

    /// Check if there was an issue
    pub fn hasIssue(self: Self) bool {
        return self == .@"error" or self == .content_filter;
    }
};

test "LanguageModelV3FinishReason toString" {
    try std.testing.expectEqualStrings("stop", LanguageModelV3FinishReason.stop.toString());
    try std.testing.expectEqualStrings("tool-calls", LanguageModelV3FinishReason.tool_calls.toString());
    try std.testing.expectEqualStrings("content-filter", LanguageModelV3FinishReason.content_filter.toString());
}

test "LanguageModelV3FinishReason fromString" {
    try std.testing.expectEqual(LanguageModelV3FinishReason.stop, LanguageModelV3FinishReason.fromString("stop"));
    try std.testing.expectEqual(LanguageModelV3FinishReason.tool_calls, LanguageModelV3FinishReason.fromString("tool-calls"));
    try std.testing.expectEqual(LanguageModelV3FinishReason.unknown, LanguageModelV3FinishReason.fromString("invalid"));
}

test "LanguageModelV3FinishReason helpers" {
    try std.testing.expect(LanguageModelV3FinishReason.stop.isComplete());
    try std.testing.expect(LanguageModelV3FinishReason.tool_calls.isComplete());
    try std.testing.expect(!LanguageModelV3FinishReason.@"error".isComplete());

    try std.testing.expect(LanguageModelV3FinishReason.@"error".hasIssue());
    try std.testing.expect(LanguageModelV3FinishReason.content_filter.hasIssue());
    try std.testing.expect(!LanguageModelV3FinishReason.stop.hasIssue());
}
