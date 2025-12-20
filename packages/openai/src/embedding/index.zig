// OpenAI Embedding API module
pub const api = @import("openai-embedding-api.zig");
pub const options = @import("openai-embedding-options.zig");
pub const model = @import("openai-embedding-model.zig");

// Re-export main types
pub const OpenAIEmbeddingModel = model.OpenAIEmbeddingModel;
pub const OpenAITextEmbeddingResponse = api.OpenAITextEmbeddingResponse;
pub const OpenAITextEmbeddingRequest = api.OpenAITextEmbeddingRequest;
pub const OpenAIEmbeddingProviderOptions = options.OpenAIEmbeddingProviderOptions;
pub const Models = options.Models;
pub const EmbedOptions = model.EmbedOptions;
pub const EmbedResult = model.EmbedResult;

// Re-export functions
pub const getDefaultDimensions = options.getDefaultDimensions;
pub const supportsCustomDimensions = options.supportsCustomDimensions;
pub const convertUsage = api.convertUsage;
