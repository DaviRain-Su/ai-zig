const std = @import("std");

const config_mod = @import("groq-config.zig");
const options_mod = @import("groq-options.zig");

/// Groq Transcription Model
pub const GroqTranscriptionModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    config: config_mod.GroqConfig,

    /// Create a new Groq transcription model
    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        config: config_mod.GroqConfig,
    ) Self {
        return .{
            .allocator = allocator,
            .model_id = model_id,
            .config = config,
        };
    }

    /// Get the model ID
    pub fn getModelId(self: *const Self) []const u8 {
        return self.model_id;
    }

    /// Get the provider name
    pub fn getProvider(self: *const Self) []const u8 {
        return self.config.provider;
    }

    /// Transcription result
    pub const TranscriptionResult = struct {
        text: []const u8,
        segments: ?[]const Segment = null,
        language: ?[]const u8 = null,
        duration: ?f64 = null,
    };

    /// Transcription segment
    pub const Segment = struct {
        id: usize,
        start: f64,
        end: f64,
        text: []const u8,
    };

    /// Transcription options
    pub const TranscriptionOptions = struct {
        /// The language of the audio (ISO 639-1)
        language: ?[]const u8 = null,

        /// The format of the transcript output
        response_format: ?ResponseFormat = null,

        /// Temperature for sampling
        temperature: ?f32 = null,

        /// A prompt to guide the transcription
        prompt: ?[]const u8 = null,
    };

    /// Response format options
    pub const ResponseFormat = enum {
        json,
        text,
        srt,
        verbose_json,
        vtt,

        pub fn toString(self: ResponseFormat) []const u8 {
            return switch (self) {
                .json => "json",
                .text => "text",
                .srt => "srt",
                .verbose_json => "verbose_json",
                .vtt => "vtt",
            };
        }
    };

    /// Transcribe audio
    pub fn doTranscribe(
        self: *Self,
        audio_data: []const u8,
        options: TranscriptionOptions,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?TranscriptionResult, ?anyerror, ?*anyopaque) void,
        callback_context: ?*anyopaque,
    ) void {
        // Use arena for request processing
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const request_allocator = arena.allocator();

        // Build URL
        const url = config_mod.buildTranscriptionsUrl(
            request_allocator,
            self.config.base_url,
        ) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        _ = url;
        _ = audio_data;
        _ = options;

        // For now, return placeholder result
        const text = result_allocator.dupe(u8, "Transcription placeholder") catch |err| {
            callback(null, err, callback_context);
            return;
        };

        const result = TranscriptionResult{
            .text = text,
            .segments = null,
            .language = null,
            .duration = null,
        };

        callback(result, null, callback_context);
    }
};

test "GroqTranscriptionModel init" {
    const allocator = std.testing.allocator;

    var model = GroqTranscriptionModel.init(
        allocator,
        "whisper-large-v3-turbo",
        .{ .base_url = "https://api.groq.com/openai/v1" },
    );

    try std.testing.expectEqualStrings("whisper-large-v3-turbo", model.getModelId());
}
