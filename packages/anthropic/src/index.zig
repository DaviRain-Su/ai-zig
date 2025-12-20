// Anthropic Provider for Zig AI SDK
//
// This module provides Anthropic API integration including:
// - Messages API (Claude 3.5 Haiku, Claude 3.7 Sonnet, Claude 4 Opus, Claude 4.5 Sonnet, etc.)
// - Extended thinking support
// - Tool use / function calling
// - Web search, code execution, and other provider tools

// Provider
pub const provider = @import("anthropic-provider.zig");
pub const AnthropicProvider = provider.AnthropicProvider;
pub const AnthropicProviderSettings = provider.AnthropicProviderSettings;
pub const createAnthropic = provider.createAnthropic;
pub const createAnthropicWithSettings = provider.createAnthropicWithSettings;
pub const anthropic = provider.anthropic;

// Configuration
pub const config = @import("anthropic-config.zig");
pub const AnthropicConfig = config.AnthropicConfig;
pub const anthropic_version = config.anthropic_version;
pub const default_base_url = config.default_base_url;

// Error handling
pub const errors = @import("anthropic-error.zig");
pub const AnthropicErrorData = errors.AnthropicErrorData;
pub const ErrorType = errors.ErrorType;

// Messages model
pub const messages_model = @import("anthropic-messages-language-model.zig");
pub const AnthropicMessagesLanguageModel = messages_model.AnthropicMessagesLanguageModel;
pub const GenerateResult = messages_model.GenerateResult;

// Messages API
pub const messages_api = @import("anthropic-messages-api.zig");
pub const AnthropicMessagesResponse = messages_api.AnthropicMessagesResponse;
pub const AnthropicMessagesRequest = messages_api.AnthropicMessagesRequest;
pub const AnthropicMessagesChunk = messages_api.AnthropicMessagesChunk;
pub const convertAnthropicMessagesUsage = messages_api.convertAnthropicMessagesUsage;

// Options
pub const options = @import("anthropic-messages-options.zig");
pub const Models = options.Models;
pub const AnthropicProviderOptions = options.AnthropicProviderOptions;
pub const ThinkingConfig = options.ThinkingConfig;
pub const Effort = options.Effort;
pub const getModelCapabilities = options.getModelCapabilities;

// Message conversion
pub const convert = @import("convert-to-anthropic-messages-prompt.zig");
pub const convertToAnthropicMessagesPrompt = convert.convertToAnthropicMessagesPrompt;

// Tool preparation
pub const prepare_tools = @import("anthropic-prepare-tools.zig");
pub const prepareTools = prepare_tools.prepareTools;

// Stop reason mapping
pub const map_stop = @import("map-anthropic-stop-reason.zig");
pub const mapAnthropicStopReason = map_stop.mapAnthropicStopReason;

test {
    // Run all module tests
    @import("std").testing.refAllDecls(@This());
}
