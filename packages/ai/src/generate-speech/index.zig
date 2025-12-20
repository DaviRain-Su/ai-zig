// Generate Speech Module for Zig AI SDK
//
// This module provides text-to-speech capabilities:
// - generateSpeech: Generate audio from text
// - streamSpeech: Stream audio generation with callbacks

pub const generate_speech_mod = @import("generate-speech.zig");

// Re-export types
pub const generateSpeech = generate_speech_mod.generateSpeech;
pub const streamSpeech = generate_speech_mod.streamSpeech;
pub const GenerateSpeechResult = generate_speech_mod.GenerateSpeechResult;
pub const GenerateSpeechOptions = generate_speech_mod.GenerateSpeechOptions;
pub const StreamSpeechOptions = generate_speech_mod.StreamSpeechOptions;
pub const GenerateSpeechError = generate_speech_mod.GenerateSpeechError;
pub const GeneratedAudio = generate_speech_mod.GeneratedAudio;
pub const SpeechGenerationUsage = generate_speech_mod.SpeechGenerationUsage;
pub const SpeechResponseMetadata = generate_speech_mod.SpeechResponseMetadata;
pub const AudioFormat = generate_speech_mod.AudioFormat;
pub const VoiceSettings = generate_speech_mod.VoiceSettings;
pub const SpeechStreamCallbacks = generate_speech_mod.SpeechStreamCallbacks;

test {
    @import("std").testing.refAllDecls(@This());
}
