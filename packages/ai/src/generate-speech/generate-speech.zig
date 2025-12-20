const std = @import("std");
const provider_types = @import("provider");

const SpeechModelV3 = provider_types.SpeechModelV3;

/// Usage information for speech generation
pub const SpeechGenerationUsage = struct {
    characters: ?u64 = null,
    duration_seconds: ?f64 = null,
};

/// Audio format options
pub const AudioFormat = enum {
    mp3,
    wav,
    ogg,
    flac,
    aac,
    pcm,
    opus,
};

/// Generated audio representation
pub const GeneratedAudio = struct {
    /// Raw audio data
    data: []const u8,

    /// Audio format
    format: AudioFormat,

    /// Sample rate in Hz
    sample_rate: ?u32 = null,

    /// Duration in seconds
    duration_seconds: ?f64 = null,

    /// MIME type
    pub fn getMimeType(self: *const GeneratedAudio) []const u8 {
        return switch (self.format) {
            .mp3 => "audio/mpeg",
            .wav => "audio/wav",
            .ogg => "audio/ogg",
            .flac => "audio/flac",
            .aac => "audio/aac",
            .pcm => "audio/pcm",
            .opus => "audio/opus",
        };
    }
};

/// Response metadata for speech generation
pub const SpeechResponseMetadata = struct {
    id: ?[]const u8 = null,
    model_id: []const u8,
    timestamp: ?i64 = null,
    headers: ?std.StringHashMap([]const u8) = null,
};

/// Result of generateSpeech
pub const GenerateSpeechResult = struct {
    /// The generated audio
    audio: GeneratedAudio,

    /// Usage information
    usage: SpeechGenerationUsage,

    /// Response metadata
    response: SpeechResponseMetadata,

    /// Warnings from the model
    warnings: ?[]const []const u8 = null,

    pub fn deinit(self: *GenerateSpeechResult, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
        // Arena allocator handles cleanup
    }
};

/// Voice characteristics
pub const VoiceSettings = struct {
    /// Speaking speed (0.5 to 2.0, 1.0 is normal)
    speed: ?f64 = null,

    /// Pitch adjustment (-1.0 to 1.0, 0.0 is normal)
    pitch: ?f64 = null,

    /// Volume adjustment (0.0 to 1.0, 1.0 is max)
    volume: ?f64 = null,

    /// Voice stability (provider-specific)
    stability: ?f64 = null,

    /// Voice similarity boost (provider-specific)
    similarity_boost: ?f64 = null,
};

/// Options for generateSpeech
pub const GenerateSpeechOptions = struct {
    /// The speech model to use
    model: *SpeechModelV3,

    /// The text to convert to speech
    text: []const u8,

    /// Voice ID or name
    voice: ?[]const u8 = null,

    /// Voice settings
    voice_settings: VoiceSettings = .{},

    /// Output audio format
    format: AudioFormat = .mp3,

    /// Sample rate in Hz
    sample_rate: ?u32 = null,

    /// Maximum retries on failure
    max_retries: u32 = 2,

    /// Additional headers
    headers: ?std.StringHashMap([]const u8) = null,

    /// Provider-specific options
    provider_options: ?std.json.Value = null,
};

/// Error types for speech generation
pub const GenerateSpeechError = error{
    ModelError,
    NetworkError,
    InvalidText,
    InvalidVoice,
    TextTooLong,
    Cancelled,
    OutOfMemory,
};

/// Generate speech from text using a speech model
pub fn generateSpeech(
    allocator: std.mem.Allocator,
    options: GenerateSpeechOptions,
) GenerateSpeechError!GenerateSpeechResult {
    _ = allocator;

    // Validate input
    if (options.text.len == 0) {
        return GenerateSpeechError.InvalidText;
    }

    // TODO: Call model.doGenerate
    // For now, return a placeholder result

    return GenerateSpeechResult{
        .audio = .{
            .data = &[_]u8{},
            .format = options.format,
        },
        .usage = .{},
        .response = .{
            .model_id = "placeholder",
        },
        .warnings = null,
    };
}

/// Callbacks for streaming speech generation
pub const SpeechStreamCallbacks = struct {
    /// Called for each audio chunk
    on_chunk: *const fn (data: []const u8, context: ?*anyopaque) void,

    /// Called when an error occurs
    on_error: *const fn (err: anyerror, context: ?*anyopaque) void,

    /// Called when streaming completes
    on_complete: *const fn (context: ?*anyopaque) void,

    /// User context passed to callbacks
    context: ?*anyopaque = null,
};

/// Options for streaming speech generation
pub const StreamSpeechOptions = struct {
    /// The speech model to use
    model: *SpeechModelV3,

    /// The text to convert to speech
    text: []const u8,

    /// Voice ID or name
    voice: ?[]const u8 = null,

    /// Voice settings
    voice_settings: VoiceSettings = .{},

    /// Output audio format
    format: AudioFormat = .mp3,

    /// Sample rate in Hz
    sample_rate: ?u32 = null,

    /// Stream callbacks
    callbacks: SpeechStreamCallbacks,
};

/// Stream speech generation using a speech model
pub fn streamSpeech(
    allocator: std.mem.Allocator,
    options: StreamSpeechOptions,
) GenerateSpeechError!void {
    _ = allocator;

    // Validate input
    if (options.text.len == 0) {
        return GenerateSpeechError.InvalidText;
    }

    // TODO: Start actual streaming
    // For now, just call complete callback
    options.callbacks.on_complete(options.callbacks.context);
}

test "GenerateSpeechOptions default values" {
    const model: SpeechModelV3 = undefined;
    const options = GenerateSpeechOptions{
        .model = @constCast(&model),
        .text = "Hello, world!",
    };
    try std.testing.expect(options.format == .mp3);
    try std.testing.expect(options.max_retries == 2);
}

test "GeneratedAudio getMimeType" {
    const mp3_audio = GeneratedAudio{
        .data = &[_]u8{},
        .format = .mp3,
    };
    try std.testing.expectEqualStrings("audio/mpeg", mp3_audio.getMimeType());

    const wav_audio = GeneratedAudio{
        .data = &[_]u8{},
        .format = .wav,
    };
    try std.testing.expectEqualStrings("audio/wav", wav_audio.getMimeType());
}
