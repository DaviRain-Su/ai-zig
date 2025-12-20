// OpenAI Transcription API module
pub const api = @import("openai-transcription-api.zig");
pub const options = @import("openai-transcription-options.zig");
pub const model = @import("openai-transcription-model.zig");

// Re-export main types
pub const OpenAITranscriptionModel = model.OpenAITranscriptionModel;
pub const OpenAITranscriptionResponse = api.OpenAITranscriptionResponse;
pub const OpenAITranscriptionProviderOptions = options.OpenAITranscriptionProviderOptions;
pub const Models = options.Models;
pub const GenerateOptions = model.GenerateOptions;
pub const GenerateResult = model.GenerateResult;
pub const TranscriptionSegment = api.TranscriptionSegment;

// Re-export enums
pub const TimestampGranularity = options.TimestampGranularity;
pub const Include = options.Include;

// Re-export functions
pub const languageNameToCode = options.languageNameToCode;
pub const convertSegments = api.convertSegments;
