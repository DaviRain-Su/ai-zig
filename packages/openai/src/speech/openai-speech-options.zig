const std = @import("std");

/// OpenAI Speech Model IDs
pub const OpenAISpeechModelId = []const u8;

/// Well-known OpenAI speech model IDs
pub const Models = struct {
    pub const tts_1 = "tts-1";
    pub const tts_1_hd = "tts-1-hd";
    pub const gpt_4o_mini_tts = "gpt-4o-mini-tts";
};

/// OpenAI Voice options
pub const Voice = enum {
    alloy,
    ash,
    ballad,
    coral,
    echo,
    fable,
    onyx,
    nova,
    sage,
    shimmer,
    verse,

    pub fn toString(self: Voice) []const u8 {
        return switch (self) {
            .alloy => "alloy",
            .ash => "ash",
            .ballad => "ballad",
            .coral => "coral",
            .echo => "echo",
            .fable => "fable",
            .onyx => "onyx",
            .nova => "nova",
            .sage => "sage",
            .shimmer => "shimmer",
            .verse => "verse",
        };
    }

    pub fn fromString(s: []const u8) ?Voice {
        if (std.mem.eql(u8, s, "alloy")) return .alloy;
        if (std.mem.eql(u8, s, "ash")) return .ash;
        if (std.mem.eql(u8, s, "ballad")) return .ballad;
        if (std.mem.eql(u8, s, "coral")) return .coral;
        if (std.mem.eql(u8, s, "echo")) return .echo;
        if (std.mem.eql(u8, s, "fable")) return .fable;
        if (std.mem.eql(u8, s, "onyx")) return .onyx;
        if (std.mem.eql(u8, s, "nova")) return .nova;
        if (std.mem.eql(u8, s, "sage")) return .sage;
        if (std.mem.eql(u8, s, "shimmer")) return .shimmer;
        if (std.mem.eql(u8, s, "verse")) return .verse;
        return null;
    }
};

/// OpenAI Speech output format options
pub const OutputFormat = enum {
    mp3,
    opus,
    aac,
    flac,
    wav,
    pcm,

    pub fn toString(self: OutputFormat) []const u8 {
        return switch (self) {
            .mp3 => "mp3",
            .opus => "opus",
            .aac => "aac",
            .flac => "flac",
            .wav => "wav",
            .pcm => "pcm",
        };
    }

    pub fn fromString(s: []const u8) ?OutputFormat {
        if (std.mem.eql(u8, s, "mp3")) return .mp3;
        if (std.mem.eql(u8, s, "opus")) return .opus;
        if (std.mem.eql(u8, s, "aac")) return .aac;
        if (std.mem.eql(u8, s, "flac")) return .flac;
        if (std.mem.eql(u8, s, "wav")) return .wav;
        if (std.mem.eql(u8, s, "pcm")) return .pcm;
        return null;
    }
};

/// OpenAI Speech provider options
pub const OpenAISpeechProviderOptions = struct {
    /// Speed of speech (0.25 to 4.0)
    speed: ?f32 = null,
};

/// Check if output format is supported
pub fn isSupportedOutputFormat(format: []const u8) bool {
    return OutputFormat.fromString(format) != null;
}

test "Voice fromString" {
    try std.testing.expect(Voice.fromString("alloy") == .alloy);
    try std.testing.expect(Voice.fromString("echo") == .echo);
    try std.testing.expect(Voice.fromString("unknown") == null);
}

test "OutputFormat fromString" {
    try std.testing.expect(OutputFormat.fromString("mp3") == .mp3);
    try std.testing.expect(OutputFormat.fromString("wav") == .wav);
    try std.testing.expect(OutputFormat.fromString("unknown") == null);
}
