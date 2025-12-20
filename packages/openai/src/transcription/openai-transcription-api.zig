const std = @import("std");

/// OpenAI Transcription Response
pub const OpenAITranscriptionResponse = struct {
    text: []const u8,
    language: ?[]const u8 = null,
    duration: ?f64 = null,
    segments: ?[]const Segment = null,
    words: ?[]const Word = null,

    pub const Segment = struct {
        id: u32,
        seek: u32,
        start: f64,
        end: f64,
        text: []const u8,
        tokens: []const u32,
        temperature: f64,
        avg_logprob: f64,
        compression_ratio: f64,
        no_speech_prob: f64,
    };

    pub const Word = struct {
        word: []const u8,
        start: f64,
        end: f64,
    };
};

/// OpenAI Transcription Request (multipart form)
pub const OpenAITranscriptionRequest = struct {
    model: []const u8,
    language: ?[]const u8 = null,
    prompt: ?[]const u8 = null,
    response_format: []const u8 = "verbose_json",
    temperature: ?f32 = null,
};

/// Transcription segment for standard format
pub const TranscriptionSegment = struct {
    text: []const u8,
    start_second: f64,
    end_second: f64,
};

/// Convert OpenAI response to standard segments
pub fn convertSegments(allocator: std.mem.Allocator, response: OpenAITranscriptionResponse) ![]TranscriptionSegment {
    if (response.segments) |segments| {
        var result = try allocator.alloc(TranscriptionSegment, segments.len);
        for (segments, 0..) |seg, i| {
            result[i] = .{
                .text = seg.text,
                .start_second = seg.start,
                .end_second = seg.end,
            };
        }
        return result;
    }

    if (response.words) |words| {
        var result = try allocator.alloc(TranscriptionSegment, words.len);
        for (words, 0..) |word, i| {
            result[i] = .{
                .text = word.word,
                .start_second = word.start,
                .end_second = word.end,
            };
        }
        return result;
    }

    return &[_]TranscriptionSegment{};
}

test "convertSegments empty" {
    const allocator = std.testing.allocator;
    const response = OpenAITranscriptionResponse{
        .text = "Hello world",
    };
    const segments = try convertSegments(allocator, response);
    try std.testing.expectEqual(@as(usize, 0), segments.len);
}
