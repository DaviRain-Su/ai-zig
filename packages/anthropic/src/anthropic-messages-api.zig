const std = @import("std");
const json_value = @import("../../provider/src/json-value/index.zig");
const lm = @import("../../provider/src/language-model/v3/index.zig");

/// Anthropic Messages API Response
pub const AnthropicMessagesResponse = struct {
    id: []const u8,
    type: []const u8,
    role: []const u8,
    content: []const ContentBlock,
    model: []const u8,
    stop_reason: ?[]const u8 = null,
    stop_sequence: ?[]const u8 = null,
    usage: Usage,
    container: ?Container = null,
    context_management: ?ContextManagement = null,

    pub const ContentBlock = union(enum) {
        text: TextBlock,
        thinking: ThinkingBlock,
        redacted_thinking: RedactedThinkingBlock,
        tool_use: ToolUseBlock,
        server_tool_use: ServerToolUseBlock,
        mcp_tool_use: McpToolUseBlock,
        mcp_tool_result: McpToolResultBlock,
        web_search_tool_result: WebSearchToolResultBlock,
        web_fetch_tool_result: WebFetchToolResultBlock,
        code_execution_tool_result: CodeExecutionToolResultBlock,
    };

    pub const TextBlock = struct {
        type: []const u8 = "text",
        text: []const u8,
        citations: ?[]const Citation = null,
    };

    pub const ThinkingBlock = struct {
        type: []const u8 = "thinking",
        thinking: []const u8,
        signature: ?[]const u8 = null,
    };

    pub const RedactedThinkingBlock = struct {
        type: []const u8 = "redacted_thinking",
        data: []const u8,
    };

    pub const ToolUseBlock = struct {
        type: []const u8 = "tool_use",
        id: []const u8,
        name: []const u8,
        input: json_value.JsonValue,
    };

    pub const ServerToolUseBlock = struct {
        type: []const u8 = "server_tool_use",
        id: []const u8,
        name: []const u8,
        input: json_value.JsonValue,
    };

    pub const McpToolUseBlock = struct {
        type: []const u8 = "mcp_tool_use",
        id: []const u8,
        name: []const u8,
        server_name: []const u8,
        input: json_value.JsonValue,
    };

    pub const McpToolResultBlock = struct {
        type: []const u8 = "mcp_tool_result",
        tool_use_id: []const u8,
        is_error: bool,
        content: json_value.JsonValue,
    };

    pub const WebSearchToolResultBlock = struct {
        type: []const u8 = "web_search_tool_result",
        tool_use_id: []const u8,
        content: json_value.JsonValue,
    };

    pub const WebFetchToolResultBlock = struct {
        type: []const u8 = "web_fetch_tool_result",
        tool_use_id: []const u8,
        content: json_value.JsonValue,
    };

    pub const CodeExecutionToolResultBlock = struct {
        type: []const u8 = "code_execution_tool_result",
        tool_use_id: []const u8,
        content: json_value.JsonValue,
    };

    pub const Usage = struct {
        input_tokens: u64,
        output_tokens: u64,
        cache_creation_input_tokens: ?u64 = null,
        cache_read_input_tokens: ?u64 = null,
    };

    pub const Container = struct {
        id: []const u8,
        expires_at: ?[]const u8 = null,
        skills: ?[]const Skill = null,
    };

    pub const Skill = struct {
        type: []const u8,
        skill_id: []const u8,
        version: ?[]const u8 = null,
    };

    pub const ContextManagement = struct {
        applied_edits: []const AppliedEdit,
    };

    pub const AppliedEdit = struct {
        type: []const u8,
        cleared_tool_uses: ?u32 = null,
        cleared_thinking_turns: ?u32 = null,
        cleared_input_tokens: ?u32 = null,
    };
};

/// Citation in text block
pub const Citation = struct {
    type: []const u8,
    document_index: u32,
    document_title: ?[]const u8 = null,
    cited_text: ?[]const u8 = null,
    start_page_number: ?u32 = null,
    end_page_number: ?u32 = null,
    start_char_index: ?u32 = null,
    end_char_index: ?u32 = null,
};

/// Anthropic Messages API Request
pub const AnthropicMessagesRequest = struct {
    model: []const u8,
    messages: []const RequestMessage,
    max_tokens: u32,
    system: ?[]const SystemContent = null,
    temperature: ?f32 = null,
    top_p: ?f32 = null,
    top_k: ?u32 = null,
    stop_sequences: ?[]const []const u8 = null,
    stream: ?bool = null,
    tools: ?[]const Tool = null,
    tool_choice: ?ToolChoice = null,
    thinking: ?ThinkingConfig = null,
    output_format: ?OutputFormat = null,

    pub const RequestMessage = struct {
        role: []const u8,
        content: []const MessageContent,
    };

    pub const MessageContent = union(enum) {
        text: TextContent,
        image: ImageContent,
        tool_use: ToolUseContent,
        tool_result: ToolResultContent,
    };

    pub const TextContent = struct {
        type: []const u8 = "text",
        text: []const u8,
        cache_control: ?CacheControl = null,
    };

    pub const ImageContent = struct {
        type: []const u8 = "image",
        source: ImageSource,
        cache_control: ?CacheControl = null,
    };

    pub const ImageSource = struct {
        type: []const u8,
        media_type: []const u8,
        data: []const u8,
    };

    pub const ToolUseContent = struct {
        type: []const u8 = "tool_use",
        id: []const u8,
        name: []const u8,
        input: json_value.JsonValue,
    };

    pub const ToolResultContent = struct {
        type: []const u8 = "tool_result",
        tool_use_id: []const u8,
        content: []const u8,
        is_error: ?bool = null,
    };

    pub const SystemContent = struct {
        type: []const u8 = "text",
        text: []const u8,
        cache_control: ?CacheControl = null,
    };

    pub const CacheControl = struct {
        type: []const u8 = "ephemeral",
        ttl: ?[]const u8 = null,
    };

    pub const Tool = struct {
        name: []const u8,
        description: ?[]const u8 = null,
        input_schema: json_value.JsonValue,
        cache_control: ?CacheControl = null,
    };

    pub const ToolChoice = union(enum) {
        auto: AutoToolChoice,
        any: AnyToolChoice,
        tool: SpecificToolChoice,
        none: NoneToolChoice,
    };

    pub const AutoToolChoice = struct {
        type: []const u8 = "auto",
        disable_parallel_tool_use: ?bool = null,
    };

    pub const AnyToolChoice = struct {
        type: []const u8 = "any",
        disable_parallel_tool_use: ?bool = null,
    };

    pub const SpecificToolChoice = struct {
        type: []const u8 = "tool",
        name: []const u8,
        disable_parallel_tool_use: ?bool = null,
    };

    pub const NoneToolChoice = struct {
        type: []const u8 = "none",
    };

    pub const ThinkingConfig = struct {
        type: []const u8,
        budget_tokens: ?u32 = null,
    };

    pub const OutputFormat = struct {
        type: []const u8 = "json_schema",
        schema: json_value.JsonValue,
    };
};

/// Anthropic Messages streaming chunk
pub const AnthropicMessagesChunk = struct {
    type: []const u8,
    index: ?u32 = null,
    message: ?MessageStart = null,
    content_block: ?ContentBlockStart = null,
    delta: ?Delta = null,
    usage: ?UsageDelta = null,
    @"error": ?ErrorChunk = null,

    pub const MessageStart = struct {
        id: ?[]const u8 = null,
        type: ?[]const u8 = null,
        role: ?[]const u8 = null,
        model: ?[]const u8 = null,
        usage: AnthropicMessagesResponse.Usage,
    };

    pub const ContentBlockStart = union(enum) {
        text: TextBlockStart,
        thinking: ThinkingBlockStart,
        redacted_thinking: RedactedThinkingBlockStart,
        tool_use: ToolUseBlockStart,
        server_tool_use: ServerToolUseBlockStart,
    };

    pub const TextBlockStart = struct {
        type: []const u8 = "text",
        text: []const u8 = "",
    };

    pub const ThinkingBlockStart = struct {
        type: []const u8 = "thinking",
        thinking: []const u8 = "",
    };

    pub const RedactedThinkingBlockStart = struct {
        type: []const u8 = "redacted_thinking",
        data: []const u8,
    };

    pub const ToolUseBlockStart = struct {
        type: []const u8 = "tool_use",
        id: []const u8,
        name: []const u8,
    };

    pub const ServerToolUseBlockStart = struct {
        type: []const u8 = "server_tool_use",
        id: []const u8,
        name: []const u8,
    };

    pub const Delta = union(enum) {
        text_delta: TextDelta,
        thinking_delta: ThinkingDelta,
        input_json_delta: InputJsonDelta,
        signature_delta: SignatureDelta,
        citations_delta: CitationsDelta,
        message_delta: MessageDelta,
    };

    pub const TextDelta = struct {
        type: []const u8 = "text_delta",
        text: []const u8,
    };

    pub const ThinkingDelta = struct {
        type: []const u8 = "thinking_delta",
        thinking: []const u8,
    };

    pub const InputJsonDelta = struct {
        type: []const u8 = "input_json_delta",
        partial_json: []const u8,
    };

    pub const SignatureDelta = struct {
        type: []const u8 = "signature_delta",
        signature: []const u8,
    };

    pub const CitationsDelta = struct {
        type: []const u8 = "citations_delta",
        citation: Citation,
    };

    pub const MessageDelta = struct {
        type: []const u8 = "message_delta",
        stop_reason: ?[]const u8 = null,
        stop_sequence: ?[]const u8 = null,
        container: ?AnthropicMessagesResponse.Container = null,
        context_management: ?AnthropicMessagesResponse.ContextManagement = null,
    };

    pub const UsageDelta = struct {
        output_tokens: u64,
    };

    pub const ErrorChunk = struct {
        type: []const u8,
        message: []const u8,
    };
};

/// Convert Anthropic usage to language model usage
pub fn convertAnthropicMessagesUsage(usage: AnthropicMessagesResponse.Usage) lm.LanguageModelV3Usage {
    return .{
        .input_tokens = .{
            .total = usage.input_tokens,
            .cache_read = usage.cache_read_input_tokens,
            .cache_creation = usage.cache_creation_input_tokens,
        },
        .output_tokens = .{
            .total = usage.output_tokens,
        },
    };
}

test "convertAnthropicMessagesUsage" {
    const usage = AnthropicMessagesResponse.Usage{
        .input_tokens = 100,
        .output_tokens = 50,
        .cache_read_input_tokens = 20,
        .cache_creation_input_tokens = 10,
    };

    const result = convertAnthropicMessagesUsage(usage);
    try std.testing.expectEqual(@as(u64, 100), result.input_tokens.total.?);
    try std.testing.expectEqual(@as(u64, 50), result.output_tokens.total.?);
    try std.testing.expectEqual(@as(u64, 20), result.input_tokens.cache_read.?);
    try std.testing.expectEqual(@as(u64, 10), result.input_tokens.cache_creation.?);
}
