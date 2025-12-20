const std = @import("std");
const lm = @import("provider").language_model;

/// Map Cohere finish reason to language model finish reason
pub fn mapCohereFinishReason(
    finish_reason: ?[]const u8,
) lm.LanguageModelV3FinishReason {
    if (finish_reason == null) return .unknown;

    const reason = finish_reason.?;

    if (std.mem.eql(u8, reason, "COMPLETE") or std.mem.eql(u8, reason, "STOP_SEQUENCE")) {
        return .stop;
    } else if (std.mem.eql(u8, reason, "MAX_TOKENS")) {
        return .length;
    } else if (std.mem.eql(u8, reason, "ERROR")) {
        return .@"error";
    } else if (std.mem.eql(u8, reason, "TOOL_CALL")) {
        return .tool_calls;
    }

    return .unknown;
}

test "mapCohereFinishReason COMPLETE" {
    const result = mapCohereFinishReason("COMPLETE");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}

test "mapCohereFinishReason STOP_SEQUENCE" {
    const result = mapCohereFinishReason("STOP_SEQUENCE");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.stop, result);
}

test "mapCohereFinishReason MAX_TOKENS" {
    const result = mapCohereFinishReason("MAX_TOKENS");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.length, result);
}

test "mapCohereFinishReason TOOL_CALL" {
    const result = mapCohereFinishReason("TOOL_CALL");
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.tool_calls, result);
}

test "mapCohereFinishReason null" {
    const result = mapCohereFinishReason(null);
    try std.testing.expectEqual(lm.LanguageModelV3FinishReason.unknown, result);
}
