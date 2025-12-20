// Transcribe Module for Zig AI SDK
//
// This module provides speech-to-text capabilities:
// - transcribe: Convert audio to text

pub const transcribe_mod = @import("transcribe.zig");

// Re-export types
pub const transcribe = transcribe_mod.transcribe;
pub const TranscribeResult = transcribe_mod.TranscribeResult;
pub const TranscribeOptions = transcribe_mod.TranscribeOptions;
pub const TranscribeError = transcribe_mod.TranscribeError;
pub const TranscriptionUsage = transcribe_mod.TranscriptionUsage;
pub const TranscriptionWord = transcribe_mod.TranscriptionWord;
pub const TranscriptionSegment = transcribe_mod.TranscriptionSegment;
pub const TranscriptionResponseMetadata = transcribe_mod.TranscriptionResponseMetadata;
pub const AudioSource = transcribe_mod.AudioSource;
pub const AudioData = transcribe_mod.AudioData;
pub const TimestampGranularity = transcribe_mod.TimestampGranularity;
pub const TranscriptionFormat = transcribe_mod.TranscriptionFormat;
pub const parseSrt = transcribe_mod.parseSrt;

test {
    @import("std").testing.refAllDecls(@This());
}
