const std = @import("std");
const generate_text = @import("generate-text.zig");
const provider_types = @import("provider");

const LanguageModelV3 = provider_types.LanguageModelV3;
const FinishReason = generate_text.FinishReason;
const LanguageModelUsage = generate_text.LanguageModelUsage;
const ToolCall = generate_text.ToolCall;
const ToolResult = generate_text.ToolResult;
const ContentPart = generate_text.ContentPart;
const ResponseMetadata = generate_text.ResponseMetadata;
const StepResult = generate_text.StepResult;
const CallSettings = generate_text.CallSettings;
const Message = generate_text.Message;
const ToolDefinition = generate_text.ToolDefinition;
const ToolChoice = generate_text.ToolChoice;

/// Stream part types emitted during streaming
pub const StreamPart = union(enum) {
    /// Text delta
    text_delta: TextDelta,

    /// Reasoning delta
    reasoning_delta: ReasoningDelta,

    /// Tool call start
    tool_call_start: ToolCallStart,

    /// Tool call delta (streaming arguments)
    tool_call_delta: ToolCallDelta,

    /// Tool call complete
    tool_call_complete: ToolCall,

    /// Tool result
    tool_result: ToolResult,

    /// Step finished
    step_finish: StepFinish,

    /// Stream finished
    finish: StreamFinish,

    /// Error occurred
    @"error": StreamError,
};

pub const TextDelta = struct {
    text: []const u8,
};

pub const ReasoningDelta = struct {
    text: []const u8,
};

pub const ToolCallStart = struct {
    tool_call_id: []const u8,
    tool_name: []const u8,
};

pub const ToolCallDelta = struct {
    tool_call_id: []const u8,
    args_delta: []const u8,
};

pub const StepFinish = struct {
    finish_reason: FinishReason,
    usage: LanguageModelUsage,
    step_type: StepType,
};

pub const StepType = enum {
    initial,
    tool_result,
    @"continue",
};

pub const StreamFinish = struct {
    finish_reason: FinishReason,
    usage: LanguageModelUsage,
    total_usage: LanguageModelUsage,
};

pub const StreamError = struct {
    message: []const u8,
    code: ?[]const u8 = null,
};

/// Callbacks for streaming text generation
pub const StreamCallbacks = struct {
    /// Called for each stream part
    on_part: *const fn (part: StreamPart, context: ?*anyopaque) void,

    /// Called when an error occurs
    on_error: *const fn (err: anyerror, context: ?*anyopaque) void,

    /// Called when streaming completes
    on_complete: *const fn (context: ?*anyopaque) void,

    /// User context passed to callbacks
    context: ?*anyopaque = null,
};

/// Options for streamText
pub const StreamTextOptions = struct {
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

    /// Stream callbacks
    callbacks: StreamCallbacks,
};

/// Result handle for streaming text generation
pub const StreamTextResult = struct {
    allocator: std.mem.Allocator,
    options: StreamTextOptions,

    /// The accumulated text so far
    text: std.array_list.Managed(u8),

    /// The accumulated reasoning text
    reasoning_text: std.array_list.Managed(u8),

    /// Tool calls collected
    tool_calls: std.array_list.Managed(ToolCall),

    /// Tool results collected
    tool_results: std.array_list.Managed(ToolResult),

    /// Steps completed
    steps: std.array_list.Managed(StepResult),

    /// Current finish reason
    finish_reason: ?FinishReason = null,

    /// Current usage
    usage: LanguageModelUsage = .{},

    /// Total usage across all steps
    total_usage: LanguageModelUsage = .{},

    /// Response metadata
    response: ?ResponseMetadata = null,

    /// Whether streaming is complete
    is_complete: bool = false,

    pub fn init(allocator: std.mem.Allocator, options: StreamTextOptions) StreamTextResult {
        return .{
            .allocator = allocator,
            .options = options,
            .text = std.array_list.Managed(u8).init(allocator),
            .reasoning_text = std.array_list.Managed(u8).init(allocator),
            .tool_calls = std.array_list.Managed(ToolCall).init(allocator),
            .tool_results = std.array_list.Managed(ToolResult).init(allocator),
            .steps = std.array_list.Managed(StepResult).init(allocator),
        };
    }

    pub fn deinit(self: *StreamTextResult) void {
        self.text.deinit();
        self.reasoning_text.deinit();
        self.tool_calls.deinit();
        self.tool_results.deinit();
        self.steps.deinit();
    }

    /// Get the accumulated text
    pub fn getText(self: *const StreamTextResult) []const u8 {
        return self.text.items;
    }

    /// Get the accumulated reasoning text
    pub fn getReasoningText(self: *const StreamTextResult) ?[]const u8 {
        if (self.reasoning_text.items.len == 0) return null;
        return self.reasoning_text.items;
    }

    /// Process a stream part (internal use)
    pub fn processPart(self: *StreamTextResult, part: StreamPart) !void {
        switch (part) {
            .text_delta => |delta| {
                try self.text.appendSlice(delta.text);
            },
            .reasoning_delta => |delta| {
                try self.reasoning_text.appendSlice(delta.text);
            },
            .tool_call_complete => |tool_call| {
                try self.tool_calls.append(tool_call);
            },
            .tool_result => |result| {
                try self.tool_results.append(result);
            },
            .step_finish => |step| {
                self.usage = step.usage;
                self.total_usage = self.total_usage.add(step.usage);
            },
            .finish => |finish| {
                self.finish_reason = finish.finish_reason;
                self.usage = finish.usage;
                self.total_usage = finish.total_usage;
                self.is_complete = true;
            },
            else => {},
        }
    }
};

/// Error types for stream text
pub const StreamTextError = error{
    ModelError,
    NetworkError,
    InvalidPrompt,
    ToolExecutionError,
    MaxStepsExceeded,
    Cancelled,
    OutOfMemory,
};

/// Stream text generation using a language model
/// This function is non-blocking and uses callbacks for streaming
pub fn streamText(
    allocator: std.mem.Allocator,
    options: StreamTextOptions,
) StreamTextError!*StreamTextResult {
    // Validate options
    if (options.prompt == null and options.messages == null) {
        return StreamTextError.InvalidPrompt;
    }
    if (options.prompt != null and options.messages != null) {
        return StreamTextError.InvalidPrompt;
    }

    // Create result handle
    const result = allocator.create(StreamTextResult) catch return StreamTextError.OutOfMemory;
    result.* = StreamTextResult.init(allocator, options);

    // Build prompt for the language model
    var prompt_messages = std.ArrayList(provider_types.LanguageModelV3Message).initCapacity(allocator, 4) catch return StreamTextError.OutOfMemory;

    // Track user message parts for cleanup
    var user_parts_to_free: ?[]const provider_types.language_model.language_model_v3_prompt.UserPart = null;

    // Add system message if present
    if (options.system) |sys| {
        prompt_messages.append(allocator, .{
            .role = .system,
            .content = .{ .system = sys },
        }) catch return StreamTextError.OutOfMemory;
    }

    // Add user message from prompt
    if (options.prompt) |p| {
        const user_msg = provider_types.language_model.userTextMessage(allocator, p) catch return StreamTextError.OutOfMemory;
        user_parts_to_free = user_msg.content.user;
        prompt_messages.append(allocator, user_msg) catch return StreamTextError.OutOfMemory;
    }

    // Build call options
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

    // Create a wrapper context that bridges model callbacks to user callbacks
    const StreamContext = struct {
        result: *StreamTextResult,
        user_callbacks: StreamCallbacks,
        total_usage: LanguageModelUsage,

        fn onPart(ctx: ?*anyopaque, part: provider_types.LanguageModelV3StreamPart) void {
            const self: *@This() = @ptrCast(@alignCast(ctx.?));

            // Convert provider stream part to our stream part
            const user_part: ?StreamPart = switch (part) {
                .text_delta => |d| .{ .text_delta = .{ .text = d.delta } },
                .text_start => null, // No equivalent
                .text_end => null, // No equivalent
                .finish => |f| blk: {
                    self.total_usage = self.total_usage.add(.{
                        .input_tokens = f.usage.input_tokens.total,
                        .output_tokens = f.usage.output_tokens.total,
                    });
                    break :blk .{
                        .finish = .{
                            .finish_reason = mapFinishReason(f.finish_reason),
                            .usage = .{
                                .input_tokens = f.usage.input_tokens.total,
                                .output_tokens = f.usage.output_tokens.total,
                            },
                            .total_usage = self.total_usage,
                        },
                    };
                },
                else => null,
            };

            if (user_part) |up| {
                self.result.processPart(up) catch {};
                self.user_callbacks.on_part(up, self.user_callbacks.context);
            }
        }

        fn onError(ctx: ?*anyopaque, err: anyerror) void {
            const self: *@This() = @ptrCast(@alignCast(ctx.?));
            self.user_callbacks.on_error(err, self.user_callbacks.context);
        }

        fn onComplete(ctx: ?*anyopaque, _: ?provider_types.LanguageModelV3.StreamCompleteInfo) void {
            const self: *@This() = @ptrCast(@alignCast(ctx.?));
            self.result.is_complete = true;
            self.user_callbacks.on_complete(self.user_callbacks.context);
        }
    };

    var stream_ctx = StreamContext{
        .result = result,
        .user_callbacks = options.callbacks,
        .total_usage = .{},
    };

    // Call the model's doStream method (synchronous in our implementation)
    options.model.doStream(
        call_options,
        allocator,
        .{
            .on_part = StreamContext.onPart,
            .on_error = StreamContext.onError,
            .on_complete = StreamContext.onComplete,
            .ctx = &stream_ctx,
        },
    );

    // Cleanup after streaming completes (doStream is synchronous)
    prompt_messages.deinit(allocator);
    if (user_parts_to_free) |parts| {
        allocator.free(@constCast(parts));
    }

    return result;
}

/// Map provider finish reason to our finish reason
fn mapFinishReason(reason: provider_types.LanguageModelV3FinishReason) FinishReason {
    return switch (reason) {
        .stop => .stop,
        .length => .length,
        .tool_calls => .tool_calls,
        .content_filter => .content_filter,
        .@"error" => .other,
        .other => .other,
        .unknown => .unknown,
    };
}

/// Helper to convert streaming result to non-streaming result
pub fn toGenerateTextResult(stream_result: *StreamTextResult) generate_text.GenerateTextResult {
    return .{
        .text = stream_result.getText(),
        .reasoning_text = stream_result.getReasoningText(),
        .content = &[_]ContentPart{},
        .tool_calls = stream_result.tool_calls.items,
        .tool_results = stream_result.tool_results.items,
        .finish_reason = stream_result.finish_reason orelse .stop,
        .usage = stream_result.usage,
        .total_usage = stream_result.total_usage,
        .response = stream_result.response orelse .{
            .id = "",
            .model_id = "",
            .timestamp = 0,
        },
        .steps = stream_result.steps.items,
        .warnings = null,
    };
}

test "StreamTextResult init and deinit" {
    const allocator = std.testing.allocator;
    const callbacks = StreamCallbacks{
        .on_part = struct {
            fn f(_: StreamPart, _: ?*anyopaque) void {}
        }.f,
        .on_error = struct {
            fn f(_: anyerror, _: ?*anyopaque) void {}
        }.f,
        .on_complete = struct {
            fn f(_: ?*anyopaque) void {}
        }.f,
    };

    const model: LanguageModelV3 = undefined;
    var result = StreamTextResult.init(allocator, .{
        .model = @constCast(&model),
        .prompt = "Hello",
        .callbacks = callbacks,
    });
    defer result.deinit();

    try std.testing.expectEqual(@as(usize, 0), result.text.items.len);
}

test "StreamTextResult process text delta" {
    const allocator = std.testing.allocator;
    const callbacks = StreamCallbacks{
        .on_part = struct {
            fn f(_: StreamPart, _: ?*anyopaque) void {}
        }.f,
        .on_error = struct {
            fn f(_: anyerror, _: ?*anyopaque) void {}
        }.f,
        .on_complete = struct {
            fn f(_: ?*anyopaque) void {}
        }.f,
    };

    const model: LanguageModelV3 = undefined;
    var result = StreamTextResult.init(allocator, .{
        .model = @constCast(&model),
        .prompt = "Hello",
        .callbacks = callbacks,
    });
    defer result.deinit();

    try result.processPart(.{ .text_delta = .{ .text = "Hello" } });
    try result.processPart(.{ .text_delta = .{ .text = " World" } });

    try std.testing.expectEqualStrings("Hello World", result.getText());
}
