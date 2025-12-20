const std = @import("std");

/// OpenAI Transcription Model IDs
pub const OpenAITranscriptionModelId = []const u8;

/// Well-known OpenAI transcription model IDs
pub const Models = struct {
    pub const whisper_1 = "whisper-1";
    pub const gpt_4o_transcribe = "gpt-4o-transcribe";
    pub const gpt_4o_mini_transcribe = "gpt-4o-mini-transcribe";
};

/// Timestamp granularity options
pub const TimestampGranularity = enum {
    word,
    segment,

    pub fn toString(self: TimestampGranularity) []const u8 {
        return switch (self) {
            .word => "word",
            .segment => "segment",
        };
    }
};

/// Include options for transcription response
pub const Include = enum {
    logprobs,

    pub fn toString(self: Include) []const u8 {
        return switch (self) {
            .logprobs => "logprobs",
        };
    }
};

/// OpenAI Transcription provider options
pub const OpenAITranscriptionProviderOptions = struct {
    /// The language of the input audio (ISO-639-1 format)
    language: ?[]const u8 = null,

    /// An optional text to guide the model's style
    prompt: ?[]const u8 = null,

    /// The sampling temperature (0-1)
    temperature: ?f32 = null,

    /// Timestamp granularities
    timestamp_granularities: ?[]const TimestampGranularity = null,

    /// Additional data to include in the response
    include: ?[]const Include = null,
};

/// Language code mapping
pub const language_map = std.StaticStringMap([]const u8).initComptime(.{
    .{ "afrikaans", "af" },
    .{ "arabic", "ar" },
    .{ "armenian", "hy" },
    .{ "azerbaijani", "az" },
    .{ "belarusian", "be" },
    .{ "bosnian", "bs" },
    .{ "bulgarian", "bg" },
    .{ "catalan", "ca" },
    .{ "chinese", "zh" },
    .{ "croatian", "hr" },
    .{ "czech", "cs" },
    .{ "danish", "da" },
    .{ "dutch", "nl" },
    .{ "english", "en" },
    .{ "estonian", "et" },
    .{ "finnish", "fi" },
    .{ "french", "fr" },
    .{ "galician", "gl" },
    .{ "german", "de" },
    .{ "greek", "el" },
    .{ "hebrew", "he" },
    .{ "hindi", "hi" },
    .{ "hungarian", "hu" },
    .{ "icelandic", "is" },
    .{ "indonesian", "id" },
    .{ "italian", "it" },
    .{ "japanese", "ja" },
    .{ "kannada", "kn" },
    .{ "kazakh", "kk" },
    .{ "korean", "ko" },
    .{ "latvian", "lv" },
    .{ "lithuanian", "lt" },
    .{ "macedonian", "mk" },
    .{ "malay", "ms" },
    .{ "marathi", "mr" },
    .{ "maori", "mi" },
    .{ "nepali", "ne" },
    .{ "norwegian", "no" },
    .{ "persian", "fa" },
    .{ "polish", "pl" },
    .{ "portuguese", "pt" },
    .{ "romanian", "ro" },
    .{ "russian", "ru" },
    .{ "serbian", "sr" },
    .{ "slovak", "sk" },
    .{ "slovenian", "sl" },
    .{ "spanish", "es" },
    .{ "swahili", "sw" },
    .{ "swedish", "sv" },
    .{ "tagalog", "tl" },
    .{ "tamil", "ta" },
    .{ "thai", "th" },
    .{ "turkish", "tr" },
    .{ "ukrainian", "uk" },
    .{ "urdu", "ur" },
    .{ "vietnamese", "vi" },
    .{ "welsh", "cy" },
});

/// Convert language name to ISO code
pub fn languageNameToCode(name: []const u8) ?[]const u8 {
    return language_map.get(name);
}

test "languageNameToCode" {
    try std.testing.expectEqualStrings("en", languageNameToCode("english").?);
    try std.testing.expectEqualStrings("ja", languageNameToCode("japanese").?);
    try std.testing.expect(languageNameToCode("unknown") == null);
}
