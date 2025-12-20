const std = @import("std");
const json_value = @import("../../json-value/index.zig");
const shared = @import("../../shared/v3/index.zig");
const LanguageModelV3DataContent = @import("language-model-v3-data-content.zig").LanguageModelV3DataContent;

/// A prompt is a list of messages.
/// Note: Not all models and prompt formats support multi-modal inputs and
/// tool calls. The validation happens at runtime.
pub const LanguageModelV3Prompt = []const LanguageModelV3Message;

/// A message in the prompt
pub const LanguageModelV3Message = struct {
    /// The role of the message sender
    role: Role,
    /// The content of the message (varies by role)
    content: MessageContent,
    /// Additional provider-specific options
    provider_options: ?shared.SharedV3ProviderOptions = null,

    pub const Role = enum {
        system,
        user,
        assistant,
        tool,

        pub fn toString(self: Role) []const u8 {
            return switch (self) {
                .system => "system",
                .user => "user",
                .assistant => "assistant",
                .tool => "tool",
            };
        }
    };

    /// Message content varies by role
    pub const MessageContent = union(Role) {
        /// System messages have simple string content
        system: []const u8,
        /// User messages can have text and file parts
        user: []const UserPart,
        /// Assistant messages can have text, files, reasoning, tool calls, and tool results
        assistant: []const AssistantPart,
        /// Tool messages have tool result parts
        tool: []const ToolResultPart,
    };
};

/// Text content part
pub const TextPart = struct {
    type: Type = .text,
    text: []const u8,
    provider_options: ?shared.SharedV3ProviderOptions = null,

    pub const Type = enum { text };
};

/// Reasoning content part
pub const ReasoningPart = struct {
    type: Type = .reasoning,
    text: []const u8,
    provider_options: ?shared.SharedV3ProviderOptions = null,

    pub const Type = enum { reasoning };
};

/// File content part
pub const FilePart = struct {
    type: Type = .file,
    /// Optional filename
    filename: ?[]const u8 = null,
    /// File data - can be binary, base64, or URL
    data: LanguageModelV3DataContent,
    /// IANA media type of the file
    media_type: []const u8,
    provider_options: ?shared.SharedV3ProviderOptions = null,

    pub const Type = enum { file };
};

/// Tool call content part
pub const ToolCallPart = struct {
    type: Type = .tool_call,
    tool_call_id: []const u8,
    tool_name: []const u8,
    input: json_value.JsonValue,
    provider_executed: bool = false,
    provider_options: ?shared.SharedV3ProviderOptions = null,

    pub const Type = enum { tool_call };
};

/// Tool result content part
pub const ToolResultPart = struct {
    type: Type = .tool_result,
    tool_call_id: []const u8,
    tool_name: []const u8,
    output: ToolResultOutput,
    provider_options: ?shared.SharedV3ProviderOptions = null,

    pub const Type = enum { tool_result };
};

/// Tool result output types
pub const ToolResultOutput = union(enum) {
    /// Text output
    text: TextOutput,
    /// JSON output
    json: JsonOutput,
    /// Execution denied
    execution_denied: ExecutionDeniedOutput,
    /// Error text
    error_text: ErrorTextOutput,
    /// Error JSON
    error_json: ErrorJsonOutput,
    /// Rich content output
    content: []const ContentPart,

    pub const TextOutput = struct {
        type: enum { text } = .text,
        value: []const u8,
        provider_options: ?shared.SharedV3ProviderOptions = null,
    };

    pub const JsonOutput = struct {
        type: enum { json } = .json,
        value: json_value.JsonValue,
        provider_options: ?shared.SharedV3ProviderOptions = null,
    };

    pub const ExecutionDeniedOutput = struct {
        type: enum { execution_denied } = .execution_denied,
        reason: ?[]const u8 = null,
        provider_options: ?shared.SharedV3ProviderOptions = null,
    };

    pub const ErrorTextOutput = struct {
        type: enum { error_text } = .error_text,
        value: []const u8,
        provider_options: ?shared.SharedV3ProviderOptions = null,
    };

    pub const ErrorJsonOutput = struct {
        type: enum { error_json } = .error_json,
        value: json_value.JsonValue,
        provider_options: ?shared.SharedV3ProviderOptions = null,
    };
};

/// Content part types for rich tool result output
pub const ContentPart = union(enum) {
    text: ContentTextPart,
    file_data: FileDataPart,
    file_url: FileUrlPart,
    file_id: FileIdPart,
    image_data: ImageDataPart,
    image_url: ImageUrlPart,
    image_file_id: ImageFileIdPart,
    custom: CustomPart,
};

pub const ContentTextPart = struct {
    type: enum { text } = .text,
    text: []const u8,
    provider_options: ?shared.SharedV3ProviderOptions = null,
};

pub const FileDataPart = struct {
    type: enum { file_data } = .file_data,
    data: []const u8, // base64 encoded
    media_type: []const u8,
    filename: ?[]const u8 = null,
    provider_options: ?shared.SharedV3ProviderOptions = null,
};

pub const FileUrlPart = struct {
    type: enum { file_url } = .file_url,
    url: []const u8,
    provider_options: ?shared.SharedV3ProviderOptions = null,
};

pub const FileIdPart = struct {
    type: enum { file_id } = .file_id,
    file_id: FileIdValue,
    provider_options: ?shared.SharedV3ProviderOptions = null,
};

pub const ImageDataPart = struct {
    type: enum { image_data } = .image_data,
    data: []const u8, // base64 encoded
    media_type: []const u8,
    provider_options: ?shared.SharedV3ProviderOptions = null,
};

pub const ImageUrlPart = struct {
    type: enum { image_url } = .image_url,
    url: []const u8,
    provider_options: ?shared.SharedV3ProviderOptions = null,
};

pub const ImageFileIdPart = struct {
    type: enum { image_file_id } = .image_file_id,
    file_id: FileIdValue,
    provider_options: ?shared.SharedV3ProviderOptions = null,
};

pub const CustomPart = struct {
    type: enum { custom } = .custom,
    provider_options: ?shared.SharedV3ProviderOptions = null,
};

/// File ID can be a single string or a map of provider-specific IDs
pub const FileIdValue = union(enum) {
    single: []const u8,
    by_provider: std.StringHashMap([]const u8),
};

/// User message part types
pub const UserPart = union(enum) {
    text: TextPart,
    file: FilePart,
};

/// Assistant message part types
pub const AssistantPart = union(enum) {
    text: TextPart,
    file: FilePart,
    reasoning: ReasoningPart,
    tool_call: ToolCallPart,
    tool_result: ToolResultPart,
};

/// Helper to create a system message
pub fn systemMessage(content: []const u8) LanguageModelV3Message {
    return .{
        .role = .system,
        .content = .{ .system = content },
    };
}

/// Helper to create a user text message
pub fn userTextMessage(allocator: std.mem.Allocator, text: []const u8) !LanguageModelV3Message {
    var parts = try allocator.alloc(UserPart, 1);
    parts[0] = .{ .text = .{ .text = text } };
    return .{
        .role = .user,
        .content = .{ .user = parts },
    };
}

/// Helper to create an assistant text message
pub fn assistantTextMessage(allocator: std.mem.Allocator, text: []const u8) !LanguageModelV3Message {
    var parts = try allocator.alloc(AssistantPart, 1);
    parts[0] = .{ .text = .{ .text = text } };
    return .{
        .role = .assistant,
        .content = .{ .assistant = parts },
    };
}

test "LanguageModelV3Message system" {
    const msg = systemMessage("You are a helpful assistant.");
    try std.testing.expectEqual(LanguageModelV3Message.Role.system, msg.role);
    try std.testing.expectEqualStrings("You are a helpful assistant.", msg.content.system);
}

test "LanguageModelV3Message user" {
    const allocator = std.testing.allocator;
    const msg = try userTextMessage(allocator, "Hello!");
    defer allocator.free(msg.content.user);

    try std.testing.expectEqual(LanguageModelV3Message.Role.user, msg.role);
    try std.testing.expectEqual(@as(usize, 1), msg.content.user.len);
}
