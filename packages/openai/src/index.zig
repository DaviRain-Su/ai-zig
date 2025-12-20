// OpenAI Provider for Zig AI SDK
//
// This module provides OpenAI API integration including:
// - Chat completions (GPT-4o, GPT-4, o1, o3, etc.)
// - Embeddings (text-embedding-3-small, text-embedding-3-large)
// - Image generation (DALL-E 2, DALL-E 3, gpt-image-1)
// - Speech synthesis (TTS-1, TTS-1-HD)
// - Transcription (Whisper, GPT-4o-transcribe)

// Provider
pub const provider = @import("openai-provider.zig");
pub const OpenAIProvider = provider.OpenAIProvider;
pub const OpenAIProviderSettings = provider.OpenAIProviderSettings;
pub const createOpenAI = provider.createOpenAI;
pub const createOpenAIWithSettings = provider.createOpenAIWithSettings;
pub const openai = provider.openai;

// Configuration
pub const config = @import("openai-config.zig");
pub const OpenAIConfig = config.OpenAIConfig;

// Error handling
pub const errors = @import("openai-error.zig");
pub const OpenAIErrorData = errors.OpenAIErrorData;

// Chat module
pub const chat = @import("chat/index.zig");
pub const OpenAIChatLanguageModel = chat.OpenAIChatLanguageModel;
pub const OpenAIChatRequest = chat.OpenAIChatRequest;
pub const OpenAIChatResponse = chat.OpenAIChatResponse;
pub const OpenAIChatChunk = chat.OpenAIChatChunk;
pub const ChatModels = chat.Models;

// Embedding module
pub const embedding = @import("embedding/index.zig");
pub const OpenAIEmbeddingModel = embedding.OpenAIEmbeddingModel;
pub const EmbeddingModels = embedding.Models;

// Image module
pub const image = @import("image/index.zig");
pub const OpenAIImageModel = image.OpenAIImageModel;
pub const ImageModels = image.Models;

// Speech module
pub const speech = @import("speech/index.zig");
pub const OpenAISpeechModel = speech.OpenAISpeechModel;
pub const SpeechModels = speech.Models;
pub const Voice = speech.Voice;

// Transcription module
pub const transcription = @import("transcription/index.zig");
pub const OpenAITranscriptionModel = transcription.OpenAITranscriptionModel;
pub const TranscriptionModels = transcription.Models;

// Re-export commonly used functions
pub const isReasoningModel = chat.isReasoningModel;
pub const mapOpenAIFinishReason = chat.mapOpenAIFinishReason;
pub const convertOpenAIChatUsage = chat.convertOpenAIChatUsage;

test {
    // Run all module tests
    @import("std").testing.refAllDecls(@This());
}
