// OpenAI-compatible Provider for Zig AI SDK
//
// This module provides a base implementation for providers that follow
// the OpenAI API format, including:
// - Chat completions
// - Embeddings
// - Images
//
// Used by: Fireworks, xAI, Together AI, DeepInfra, Cerebras, etc.

// Configuration
pub const config = @import("openai-compatible-config.zig");
pub const OpenAICompatibleConfig = config.OpenAICompatibleConfig;
pub const buildChatCompletionsUrl = config.buildChatCompletionsUrl;
pub const buildCompletionsUrl = config.buildCompletionsUrl;
pub const buildEmbeddingsUrl = config.buildEmbeddingsUrl;
pub const buildImagesGenerationsUrl = config.buildImagesGenerationsUrl;

// Language model
pub const chat_model = @import("openai-compatible-chat-language-model.zig");
pub const OpenAICompatibleChatLanguageModel = chat_model.OpenAICompatibleChatLanguageModel;

// Embedding model
pub const embed_model = @import("openai-compatible-embedding-model.zig");
pub const OpenAICompatibleEmbeddingModel = embed_model.OpenAICompatibleEmbeddingModel;

test {
    @import("std").testing.refAllDecls(@This());
}
