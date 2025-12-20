const std = @import("std");

/// OpenAI Speech API Request
pub const OpenAISpeechRequest = struct {
    model: []const u8,
    input: []const u8,
    voice: []const u8 = "alloy",
    response_format: []const u8 = "mp3",
    speed: ?f32 = null,
    instructions: ?[]const u8 = null,
};

/// OpenAI Speech API Types (for provider options mapping)
pub const OpenAISpeechAPITypes = struct {
    speed: ?f32 = null,
};

test "OpenAISpeechRequest default voice" {
    const request = OpenAISpeechRequest{
        .model = "tts-1",
        .input = "Hello world",
    };
    try std.testing.expectEqualStrings("alloy", request.voice);
    try std.testing.expectEqualStrings("mp3", request.response_format);
}
