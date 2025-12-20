// OpenAI Chat API module
pub const api = @import("openai-chat-api.zig");
pub const options = @import("openai-chat-options.zig");
pub const convert = @import("convert-to-openai-chat-messages.zig");
pub const prepare_tools = @import("openai-chat-prepare-tools.zig");
pub const map_finish = @import("map-openai-finish-reason.zig");
pub const language_model = @import("openai-chat-language-model.zig");

// Re-export main types
pub const OpenAIChatLanguageModel = language_model.OpenAIChatLanguageModel;
pub const OpenAIChatRequest = api.OpenAIChatRequest;
pub const OpenAIChatResponse = api.OpenAIChatResponse;
pub const OpenAIChatChunk = api.OpenAIChatChunk;
pub const OpenAIChatLanguageModelOptions = options.OpenAIChatLanguageModelOptions;
pub const Models = options.Models;

// Re-export functions
pub const convertToOpenAIChatMessages = convert.convertToOpenAIChatMessages;
pub const prepareChatTools = prepare_tools.prepareChatTools;
pub const mapOpenAIFinishReason = map_finish.mapOpenAIFinishReason;
pub const convertOpenAIChatUsage = api.convertOpenAIChatUsage;
pub const isReasoningModel = options.isReasoningModel;
