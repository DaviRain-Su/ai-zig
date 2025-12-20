const std = @import("std");

// Core language model interface
pub const language_model_v3 = @import("language-model-v3.zig");
pub const LanguageModelV3 = language_model_v3.LanguageModelV3;
pub const implementLanguageModel = language_model_v3.implementLanguageModel;
pub const asLanguageModel = language_model_v3.asLanguageModel;

// Call options
pub const language_model_v3_call_options = @import("language-model-v3-call-options.zig");
pub const LanguageModelV3CallOptions = language_model_v3_call_options.LanguageModelV3CallOptions;

// Content types
pub const language_model_v3_content = @import("language-model-v3-content.zig");
pub const LanguageModelV3Content = language_model_v3_content.LanguageModelV3Content;
pub const textContent = language_model_v3_content.textContent;
pub const reasoningContent = language_model_v3_content.reasoningContent;
pub const toolCallContent = language_model_v3_content.toolCallContent;

// Data content
pub const language_model_v3_data_content = @import("language-model-v3-data-content.zig");
pub const LanguageModelV3DataContent = language_model_v3_data_content.LanguageModelV3DataContent;

// File
pub const language_model_v3_file = @import("language-model-v3-file.zig");
pub const LanguageModelV3File = language_model_v3_file.LanguageModelV3File;

// Finish reason
pub const language_model_v3_finish_reason = @import("language-model-v3-finish-reason.zig");
pub const LanguageModelV3FinishReason = language_model_v3_finish_reason.LanguageModelV3FinishReason;

// Function tool
pub const language_model_v3_function_tool = @import("language-model-v3-function-tool.zig");
pub const LanguageModelV3FunctionTool = language_model_v3_function_tool.LanguageModelV3FunctionTool;

// Prompt
pub const language_model_v3_prompt = @import("language-model-v3-prompt.zig");
pub const LanguageModelV3Prompt = language_model_v3_prompt.LanguageModelV3Prompt;
pub const LanguageModelV3Message = language_model_v3_prompt.LanguageModelV3Message;
pub const systemMessage = language_model_v3_prompt.systemMessage;
pub const userTextMessage = language_model_v3_prompt.userTextMessage;
pub const assistantTextMessage = language_model_v3_prompt.assistantTextMessage;

// Provider tool
pub const language_model_v3_provider_tool = @import("language-model-v3-provider-tool.zig");
pub const LanguageModelV3ProviderTool = language_model_v3_provider_tool.LanguageModelV3ProviderTool;

// Reasoning
pub const language_model_v3_reasoning = @import("language-model-v3-reasoning.zig");
pub const LanguageModelV3Reasoning = language_model_v3_reasoning.LanguageModelV3Reasoning;

// Response metadata
pub const language_model_v3_response_metadata = @import("language-model-v3-response-metadata.zig");
pub const LanguageModelV3ResponseMetadata = language_model_v3_response_metadata.LanguageModelV3ResponseMetadata;

// Source
pub const language_model_v3_source = @import("language-model-v3-source.zig");
pub const LanguageModelV3Source = language_model_v3_source.LanguageModelV3Source;

// Stream part
pub const language_model_v3_stream_part = @import("language-model-v3-stream-part.zig");
pub const LanguageModelV3StreamPart = language_model_v3_stream_part.LanguageModelV3StreamPart;
pub const textStart = language_model_v3_stream_part.textStart;
pub const textDelta = language_model_v3_stream_part.textDelta;
pub const textEnd = language_model_v3_stream_part.textEnd;
pub const finish = language_model_v3_stream_part.finish;
pub const streamError = language_model_v3_stream_part.streamError;

// Text
pub const language_model_v3_text = @import("language-model-v3-text.zig");
pub const LanguageModelV3Text = language_model_v3_text.LanguageModelV3Text;

// Tool call
pub const language_model_v3_tool_call = @import("language-model-v3-tool-call.zig");
pub const LanguageModelV3ToolCall = language_model_v3_tool_call.LanguageModelV3ToolCall;

// Tool choice
pub const language_model_v3_tool_choice = @import("language-model-v3-tool-choice.zig");
pub const LanguageModelV3ToolChoice = language_model_v3_tool_choice.LanguageModelV3ToolChoice;

// Tool result
pub const language_model_v3_tool_result = @import("language-model-v3-tool-result.zig");
pub const LanguageModelV3ToolResult = language_model_v3_tool_result.LanguageModelV3ToolResult;

// Usage
pub const language_model_v3_usage = @import("language-model-v3-usage.zig");
pub const LanguageModelV3Usage = language_model_v3_usage.LanguageModelV3Usage;

test {
    std.testing.refAllDecls(@This());
}
