// OpenAI Speech API module
pub const api = @import("openai-speech-api.zig");
pub const options = @import("openai-speech-options.zig");
pub const model = @import("openai-speech-model.zig");

// Re-export main types
pub const OpenAISpeechModel = model.OpenAISpeechModel;
pub const OpenAISpeechRequest = api.OpenAISpeechRequest;
pub const OpenAISpeechProviderOptions = options.OpenAISpeechProviderOptions;
pub const Models = options.Models;
pub const GenerateOptions = model.GenerateOptions;
pub const GenerateResult = model.GenerateResult;

// Re-export enums
pub const Voice = options.Voice;
pub const OutputFormat = options.OutputFormat;

// Re-export functions
pub const isSupportedOutputFormat = options.isSupportedOutputFormat;
