const std = @import("std");
const provider_types = @import("provider");
const LanguageModelV3 = provider_types.LanguageModelV3;

/// Finish reasons for text generation
pub const FinishReason = enum {
    stop,
    length,
    tool_calls,
    content_filter,
    other,
    unknown,
};

/// Token usage information
pub const LanguageModelUsage = struct {
    input_tokens: ?u64 = null,
    output_tokens: ?u64 = null,
    total_tokens: ?u64 = null,
    reasoning_tokens: ?u64 = null,
    cached_input_tokens: ?u64 = null,

    pub fn add(self: LanguageModelUsage, other: LanguageModelUsage) LanguageModelUsage {
        return .{
            .input_tokens = addOptional(self.input_tokens, other.input_tokens),
            .output_tokens = addOptional(self.output_tokens, other.output_tokens),
            .total_tokens = addOptional(self.total_tokens, other.total_tokens),
            .reasoning_tokens = addOptional(self.reasoning_tokens, other.reasoning_tokens),
            .cached_input_tokens = addOptional(self.cached_input_tokens, other.cached_input_tokens),
        };
    }

    fn addOptional(a: ?u64, b: ?u64) ?u64 {
        if (a == null and b == null) return null;
        return (a orelse 0) + (b orelse 0);
    }
};

/// Tool call representation
pub const ToolCall = struct {
    tool_call_id: []const u8,
    tool_name: []const u8,
    input: std.json.Value,
};

/// Tool result representation
pub const ToolResult = struct {
    tool_call_id: []const u8,
    tool_name: []const u8,
    output: std.json.Value,
};

/// Content part types
pub const ContentPart = union(enum) {
    text: TextPart,
    tool_call: ToolCall,
    tool_result: ToolResult,
    reasoning: ReasoningPart,
    file: FilePart,
};

pub const TextPart = struct {
    text: []const u8,
};

pub const ReasoningPart = struct {
    text: []const u8,
    signature: ?[]const u8 = null,
};

pub const FilePart = struct {
    data: []const u8,
    mime_type: []const u8,
};

/// Response metadata
pub const ResponseMetadata = struct {
    id: []const u8,
    model_id: []const u8,
    timestamp: i64,
    headers: ?std.StringHashMap([]const u8) = null,
};

/// Step result for multi-step generation
pub const StepResult = struct {
    content: []const ContentPart,
    text: []const u8,
    reasoning_text: ?[]const u8 = null,
    finish_reason: FinishReason,
    usage: LanguageModelUsage,
    tool_calls: []const ToolCall,
    tool_results: []const ToolResult,
    response: ResponseMetadata,
    warnings: ?[]const []const u8 = null,
};

/// Result of generateText
pub const GenerateTextResult = struct {
    /// The generated text from the last step
    text: []const u8,

    /// Reasoning text if available
    reasoning_text: ?[]const u8 = null,

    /// Content parts from the last step
    content: []const ContentPart,

    /// Tool calls made in the last step
    tool_calls: []const ToolCall,

    /// Tool results from the last step
    tool_results: []const ToolResult,

    /// Reason generation finished
    finish_reason: FinishReason,

    /// Token usage for the last step
    usage: LanguageModelUsage,

    /// Total usage across all steps
    total_usage: LanguageModelUsage,

    /// Response metadata
    response: ResponseMetadata,

    /// All steps in multi-step generation
    steps: []const StepResult,

    /// Warnings from the model
    warnings: ?[]const []const u8 = null,

    /// Clean up resources
    pub fn deinit(self: *GenerateTextResult, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
        // Arena allocator handles cleanup
    }
};

/// Call settings for text generation
pub const CallSettings = struct {
    max_output_tokens: ?u32 = null,
    temperature: ?f64 = null,
    top_p: ?f64 = null,
    top_k: ?u32 = null,
    presence_penalty: ?f64 = null,
    frequency_penalty: ?f64 = null,
    stop_sequences: ?[]const []const u8 = null,
    seed: ?u64 = null,
};

/// Message roles
pub const MessageRole = enum {
    system,
    user,
    assistant,
    tool,
};

/// Message content types
pub const MessageContent = union(enum) {
    text: []const u8,
    parts: []const ContentPart,
};

/// A single message in the conversation
pub const Message = struct {
    role: MessageRole,
    content: MessageContent,
};

/// Tool definition
pub const ToolDefinition = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    parameters: std.json.Value,
    execute: ?*const fn (input: std.json.Value, context: ?*anyopaque) anyerror!std.json.Value = null,
};

/// Tool choice options
pub const ToolChoice = union(enum) {
    auto,
    none,
    required,
    tool: []const u8,
};

/// Options for generateText
pub const GenerateTextOptions = struct {
    /// The language model to use
    model: *LanguageModelV3,

    /// System prompt
    system: ?[]const u8 = null,

    /// Simple text prompt (use this OR messages, not both)
    prompt: ?[]const u8 = null,

    /// Conversation messages (use this OR prompt, not both)
    messages: ?[]const Message = null,

    /// Available tools
    tools: ?[]const ToolDefinition = null,

    /// Tool choice strategy
    tool_choice: ToolChoice = .auto,

    /// Call settings
    settings: CallSettings = .{},

    /// Maximum number of steps for tool use loops
    max_steps: u32 = 1,

    /// Maximum retries on failure
    max_retries: u32 = 2,

    /// Context passed to tool execution
    context: ?*anyopaque = null,

    /// Callback when each step finishes
    on_step_finish: ?*const fn (step: StepResult, context: ?*anyopaque) void = null,

    /// Callback context
    callback_context: ?*anyopaque = null,
};

/// Error types for text generation
pub const GenerateTextError = error{
    ModelError,
    NetworkError,
    InvalidPrompt,
    ToolExecutionError,
    MaxStepsExceeded,
    Cancelled,
    OutOfMemory,
};

/// Generate text using a language model
pub fn generateText(
    allocator: std.mem.Allocator,
    options: GenerateTextOptions,
) GenerateTextError!GenerateTextResult {
    // Validate options
    if (options.prompt == null and options.messages == null) {
        return GenerateTextError.InvalidPrompt;
    }
    if (options.prompt != null and options.messages != null) {
        return GenerateTextError.InvalidPrompt;
    }

    // Build prompt for the language model
    var prompt_messages: std.ArrayList(provider_types.LanguageModelV3Message) = .empty;
    defer prompt_messages.deinit(allocator);
    var user_parts_to_free: ?[]const provider_types.language_model.language_model_v3_prompt.UserPart = null;
    defer {
        if (user_parts_to_free) |parts| {
            allocator.free(@constCast(parts));
        }
    }

    // Add system message if present
    if (options.system) |sys| {
        try prompt_messages.append(allocator, .{
            .role = .system,
            .content = .{ .system = sys },
        });
    }

    // Add user message from prompt
    if (options.prompt) |p| {
        const user_message = try provider_types.language_model.userTextMessage(allocator, p);
        user_parts_to_free = user_message.content.user;
        try prompt_messages.append(allocator, user_message);
    }

    // Build call options - temperature needs to be f32
    const temp_f32: ?f32 = if (options.settings.temperature) |t| @floatCast(t) else null;
    const top_p_f32: ?f32 = if (options.settings.top_p) |t| @floatCast(t) else null;

    const call_options = provider_types.LanguageModelV3CallOptions{
        .prompt = prompt_messages.items,
        .max_output_tokens = options.settings.max_output_tokens,
        .temperature = temp_f32,
        .top_p = top_p_f32,
        .top_k = options.settings.top_k,
        .stop_sequences = options.settings.stop_sequences,
    };

    // Context to capture the result from callback
    const ResultCapture = struct {
        result: ?LanguageModelV3.GenerateResult = null,
        completed: bool = false,
    };
    var capture = ResultCapture{};

    // Call the model's doGenerate with a callback that captures the result
    options.model.doGenerate(
        call_options,
        allocator,
        struct {
            fn callback(ctx: ?*anyopaque, result: LanguageModelV3.GenerateResult) void {
                const c: *ResultCapture = @ptrCast(@alignCast(ctx.?));
                c.result = result;
                c.completed = true;
            }
        }.callback,
        &capture,
    );

    // Check if we got a result
    if (!capture.completed or capture.result == null) {
        return GenerateTextError.ModelError;
    }

    // Handle result
    switch (capture.result.?) {
        .success => |success| {
            // Extract text from content
            var text_parts: std.ArrayList([]const u8) = .empty;
            defer text_parts.deinit(allocator);

            for (success.content) |content| {
                switch (content) {
                    .text => |t| {
                        try text_parts.append(allocator, t.text);
                    },
                    else => {},
                }
            }

            const combined_text = if (text_parts.items.len > 0)
                try std.mem.join(allocator, "", text_parts.items)
            else
                try allocator.dupe(u8, "");

            for (success.content) |content| {
                var owned_content = content;
                owned_content.deinit(allocator);
            }
            if (success.content.len > 0) {
                allocator.free(@constCast(success.content));
            }

            // Map finish reason
            const finish_reason: FinishReason = switch (success.finish_reason) {
                .stop => .stop,
                .length => .length,
                .tool_calls => .tool_calls,
                .content_filter => .content_filter,
                .@"error" => .other,
                .other => .other,
                .unknown => .unknown,
            };

            // Build usage
            const usage = LanguageModelUsage{
                .input_tokens = success.usage.input_tokens.total,
                .output_tokens = success.usage.output_tokens.total,
            };

            return GenerateTextResult{
                .text = combined_text,
                .reasoning_text = null,
                .content = &[_]ContentPart{},
                .tool_calls = &[_]ToolCall{},
                .tool_results = &[_]ToolResult{},
                .finish_reason = finish_reason,
                .usage = usage,
                .total_usage = usage,
                .response = .{
                    .id = "response",
                    .model_id = options.model.getModelId(),
                    .timestamp = std.time.timestamp(),
                },
                .steps = &[_]StepResult{},
                .warnings = null,
            };
        },
        .failure => |err| {
            return switch (err) {
                error.HttpError => GenerateTextError.NetworkError,
                error.OutOfMemory => GenerateTextError.OutOfMemory,
                error.InvalidResponse => GenerateTextError.ModelError,
                error.EmptyResponse => GenerateTextError.ModelError,
                else => GenerateTextError.ModelError,
            };
        },
    }
}

test "GenerateTextOptions default values" {
    const model: LanguageModelV3 = undefined;
    const options = GenerateTextOptions{
        .model = @constCast(&model),
        .prompt = "Hello",
    };
    try std.testing.expect(options.max_steps == 1);
    try std.testing.expect(options.max_retries == 2);
}

test "LanguageModelUsage add" {
    const usage1 = LanguageModelUsage{
        .input_tokens = 100,
        .output_tokens = 50,
    };
    const usage2 = LanguageModelUsage{
        .input_tokens = 200,
        .output_tokens = 100,
    };
    const total = usage1.add(usage2);
    try std.testing.expectEqual(@as(?u64, 300), total.input_tokens);
    try std.testing.expectEqual(@as(?u64, 150), total.output_tokens);
}
