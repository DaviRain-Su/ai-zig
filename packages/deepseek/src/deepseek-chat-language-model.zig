const std = @import("std");
const lm = @import("provider").language_model;
const shared = @import("provider").shared;
const provider_utils = @import("provider-utils");

const config_mod = @import("deepseek-config.zig");
const options_mod = @import("deepseek-options.zig");
const map_finish = @import("map-deepseek-finish-reason.zig");

/// DeepSeek Chat Language Model
/// Uses OpenAI-compatible API
pub const DeepSeekChatLanguageModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    config: config_mod.DeepSeekConfig,

    /// Create a new DeepSeek chat language model
    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        config: config_mod.DeepSeekConfig,
    ) Self {
        return .{
            .allocator = allocator,
            .model_id = model_id,
            .config = config,
        };
    }

    /// Get the model ID
    pub fn getModelId(self: *const Self) []const u8 {
        return self.model_id;
    }

    /// Get the provider name
    pub fn getProvider(self: *const Self) []const u8 {
        return self.config.provider;
    }

    /// Generate content (non-streaming)
    pub fn doGenerate(
        self: *const Self,
        call_options: lm.LanguageModelV3CallOptions,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?*anyopaque, lm.LanguageModelV3.GenerateResult) void,
        callback_context: ?*anyopaque,
    ) void {
        // Check if HTTP client is available
        const http_client = self.config.http_client orelse {
            callback(callback_context, .{ .failure = error.NoHttpClient });
            return;
        };

        var arena = std.heap.ArenaAllocator.init(self.allocator);
        const request_allocator = arena.allocator();

        // Build request body
        const request_body = self.buildRequestBody(request_allocator, call_options) catch |err| {
            arena.deinit();
            callback(callback_context, .{ .failure = err });
            return;
        };

        // Serialize to JSON using std.json.Stringify.valueAlloc
        const body_json = std.json.Stringify.valueAlloc(request_allocator, request_body, .{}) catch |err| {
            arena.deinit();
            callback(callback_context, .{ .failure = err });
            return;
        };

        // Build URL
        const url = config_mod.buildChatCompletionsUrl(
            request_allocator,
            self.config.base_url,
        ) catch |err| {
            arena.deinit();
            callback(callback_context, .{ .failure = err });
            return;
        };

        // Get headers
        var headers = self.config.getHeaders(request_allocator);

        // Convert headers to slice
        var header_list: [64]provider_utils.HttpHeader = undefined;
        var header_count: usize = 0;
        var headers_iter = headers.iterator();
        while (headers_iter.next()) |entry| {
            if (header_count >= 64) break;
            header_list[header_count] = .{
                .name = entry.key_ptr.*,
                .value = entry.value_ptr.*,
            };
            header_count += 1;
        }

        // Build HTTP request
        const req = provider_utils.HttpRequest{
            .method = .POST,
            .url = url,
            .headers = header_list[0..header_count],
            .body = body_json,
        };

        // Create callback context that stores all necessary data
        const CallbackCtx = struct {
            arena: std.heap.ArenaAllocator,
            result_allocator: std.mem.Allocator,
            callback: *const fn (?*anyopaque, lm.LanguageModelV3.GenerateResult) void,
            callback_context: ?*anyopaque,
        };

        const ctx_ptr = request_allocator.create(CallbackCtx) catch {
            arena.deinit();
            callback(callback_context, .{ .failure = error.OutOfMemory });
            return;
        };
        ctx_ptr.* = .{
            .arena = arena,
            .result_allocator = result_allocator,
            .callback = callback,
            .callback_context = callback_context,
        };

        // Make request
        http_client.request(
            req,
            request_allocator,
            struct {
                fn onResponse(ctx: ?*anyopaque, response: provider_utils.HttpResponse) void {
                    const c: *CallbackCtx = @ptrCast(@alignCast(ctx));
                    defer c.arena.deinit();

                    // Check status
                    if (!response.isSuccess()) {
                        c.callback(c.callback_context, .{ .failure = error.HttpError });
                        return;
                    }

                    // Parse response
                    const parsed = std.json.parseFromSlice(DeepSeekResponse, c.result_allocator, response.body, .{
                        .ignore_unknown_fields = true,
                    }) catch {
                        c.callback(c.callback_context, .{ .failure = error.InvalidResponse });
                        return;
                    };
                    const deep_response = parsed.value;

                    // Extract content from first choice
                    if (deep_response.choices.len == 0) {
                        c.callback(c.callback_context, .{ .failure = error.EmptyResponse });
                        return;
                    }

                    const first_choice = deep_response.choices[0];
                    const message_content = first_choice.message.content orelse "";

                    // Allocate content in result allocator
                    var content_list: std.ArrayList(lm.LanguageModelV3Content) = .empty;
                    const text_copy = c.result_allocator.dupe(u8, message_content) catch {
                        c.callback(c.callback_context, .{ .failure = error.OutOfMemory });
                        return;
                    };
                    content_list.append(c.result_allocator, .{
                        .text = .{ .text = text_copy },
                    }) catch {
                        c.callback(c.callback_context, .{ .failure = error.OutOfMemory });
                        return;
                    };

                    // Map finish reason
                    const finish_reason = map_finish.mapDeepSeekFinishReason(first_choice.finish_reason);

                    // Build usage
                    var usage = lm.LanguageModelV3Usage.init();
                    if (deep_response.usage) |u| {
                        usage.input_tokens = .{ .total = u.prompt_tokens };
                        usage.output_tokens = .{ .total = u.completion_tokens };
                    }

                    c.callback(c.callback_context, .{
                        .success = .{
                            .content = content_list.items,
                            .finish_reason = finish_reason,
                            .usage = usage,
                            .warnings = &[_]shared.SharedV3Warning{},
                        },
                    });
                }
            }.onResponse,
            struct {
                fn onError(ctx: ?*anyopaque, err: provider_utils.HttpError) void {
                    _ = err;
                    const c: *CallbackCtx = @ptrCast(@alignCast(ctx));
                    defer c.arena.deinit();
                    c.callback(c.callback_context, .{ .failure = error.HttpError });
                }
            }.onError,
            ctx_ptr,
        );
    }

    /// DeepSeek API response structure (OpenAI-compatible format)
    const DeepSeekResponse = struct {
        id: []const u8 = "",
        object: []const u8 = "",
        created: i64 = 0,
        model: []const u8 = "",
        choices: []const DeepSeekChoice = &[_]DeepSeekChoice{},
        usage: ?DeepSeekUsage = null,
    };

    const DeepSeekChoice = struct {
        index: u32 = 0,
        message: DeepSeekMessage = .{},
        finish_reason: ?[]const u8 = null,
    };

    const DeepSeekMessage = struct {
        role: []const u8 = "",
        content: ?[]const u8 = null,
    };

    const DeepSeekUsage = struct {
        prompt_tokens: u64 = 0,
        completion_tokens: u64 = 0,
        total_tokens: u64 = 0,
    };

    /// Stream content
    pub fn doStream(
        self: *const Self,
        call_options: lm.LanguageModelV3CallOptions,
        result_allocator: std.mem.Allocator,
        callbacks: lm.LanguageModelV3.StreamCallbacks,
    ) void {
        // Check if HTTP client is available
        const http_client = self.config.http_client orelse {
            callbacks.on_error(callbacks.ctx, error.NoHttpClient);
            return;
        };

        var arena = std.heap.ArenaAllocator.init(self.allocator);
        const request_allocator = arena.allocator();

        // Build request body with stream: true
        var request_body = self.buildRequestBody(request_allocator, call_options) catch |err| {
            arena.deinit();
            callbacks.on_error(callbacks.ctx, err);
            return;
        };

        if (request_body == .object) {
            request_body.object.put("stream", .{ .bool = true }) catch |err| {
                arena.deinit();
                callbacks.on_error(callbacks.ctx, err);
                return;
            };
        }

        // Serialize to JSON
        const body_json = std.json.Stringify.valueAlloc(request_allocator, request_body, .{}) catch |err| {
            arena.deinit();
            callbacks.on_error(callbacks.ctx, err);
            return;
        };

        // Build URL
        const url = config_mod.buildChatCompletionsUrl(
            request_allocator,
            self.config.base_url,
        ) catch |err| {
            arena.deinit();
            callbacks.on_error(callbacks.ctx, err);
            return;
        };

        // Get headers
        var headers = self.config.getHeaders(request_allocator);

        // Convert headers to slice
        var header_list: [64]provider_utils.HttpHeader = undefined;
        var header_count: usize = 0;
        var headers_iter = headers.iterator();
        while (headers_iter.next()) |entry| {
            if (header_count >= 64) break;
            header_list[header_count] = .{
                .name = entry.key_ptr.*,
                .value = entry.value_ptr.*,
            };
            header_count += 1;
        }

        // Build HTTP request
        const req = provider_utils.HttpRequest{
            .method = .POST,
            .url = url,
            .headers = header_list[0..header_count],
            .body = body_json,
        };

        // Create stream state to track progress
        const StreamState = struct {
            arena: std.heap.ArenaAllocator,
            result_allocator: std.mem.Allocator,
            callbacks: lm.LanguageModelV3.StreamCallbacks,
            sse_parser: provider_utils.EventSourceParser,
            is_text_active: bool,
            finish_reason: lm.LanguageModelV3FinishReason,
            usage: ?lm.LanguageModelV3Usage,

            fn init(
                allocator: std.mem.Allocator,
                ar: std.heap.ArenaAllocator,
                res_allocator: std.mem.Allocator,
                cbs: lm.LanguageModelV3.StreamCallbacks,
            ) @This() {
                return .{
                    .arena = ar,
                    .result_allocator = res_allocator,
                    .callbacks = cbs,
                    .sse_parser = provider_utils.EventSourceParser.init(allocator),
                    .is_text_active = false,
                    .finish_reason = .unknown,
                    .usage = null,
                };
            }

            fn deinit(state: *@This()) void {
                state.sse_parser.deinit();
                state.arena.deinit();
            }

            fn processChunk(state: *@This(), chunk_data: []const u8) void {
                state.sse_parser.feed(chunk_data, handleSSEEvent, state) catch {};
            }

            fn handleSSEEvent(ctx: ?*anyopaque, event: provider_utils.EventSourceParser.Event) void {
                const state: *@This() = @ptrCast(@alignCast(ctx));

                // Parse the JSON data from SSE
                const parsed = std.json.parseFromSlice(
                    DeepSeekStreamChunk,
                    state.result_allocator,
                    event.data,
                    .{ .ignore_unknown_fields = true },
                ) catch return;
                defer parsed.deinit(); // Free parsed JSON after processing
                const chunk = parsed.value;

                // Process choices
                if (chunk.choices.len == 0) return;
                const choice = chunk.choices[0];

                // Update finish reason
                if (choice.finish_reason) |reason| {
                    state.finish_reason = map_finish.mapDeepSeekFinishReason(reason);
                }

                // Process delta content
                if (choice.delta.content) |content| {
                    if (!state.is_text_active) {
                        state.callbacks.on_part(state.callbacks.ctx, .{
                            .text_start = .{ .id = "0" },
                        });
                        state.is_text_active = true;
                    }

                    state.callbacks.on_part(state.callbacks.ctx, .{
                        .text_delta = .{
                            .id = "0",
                            .delta = content,
                        },
                    });
                }

                // Handle usage if present
                if (chunk.usage) |u| {
                    state.usage = lm.LanguageModelV3Usage.init();
                    if (state.usage) |*usage| {
                        usage.input_tokens = .{ .total = u.prompt_tokens };
                        usage.output_tokens = .{ .total = u.completion_tokens };
                    }
                }
            }

            fn finish(state: *@This()) void {
                // End text if active
                if (state.is_text_active) {
                    state.callbacks.on_part(state.callbacks.ctx, .{
                        .text_end = .{ .id = "0" },
                    });
                }

                // Emit finish
                state.callbacks.on_part(state.callbacks.ctx, .{
                    .finish = .{
                        .finish_reason = state.finish_reason,
                        .usage = state.usage orelse lm.LanguageModelV3Usage.init(),
                    },
                });

                // Call complete callback
                state.callbacks.on_complete(state.callbacks.ctx, null);

                // Cleanup
                state.deinit();
            }

            fn handleError(state: *@This(), err: provider_utils.HttpError) void {
                _ = err;
                state.callbacks.on_error(state.callbacks.ctx, error.HttpError);
                state.deinit();
            }
        };

        const state_ptr = request_allocator.create(StreamState) catch {
            arena.deinit();
            callbacks.on_error(callbacks.ctx, error.OutOfMemory);
            return;
        };
        state_ptr.* = StreamState.init(request_allocator, arena, result_allocator, callbacks);

        // Make streaming request
        http_client.requestStreaming(req, request_allocator, .{
            .on_chunk = struct {
                fn onChunk(ctx: ?*anyopaque, chunk: []const u8) void {
                    const state: *StreamState = @ptrCast(@alignCast(ctx.?));
                    state.processChunk(chunk);
                }
            }.onChunk,
            .on_complete = struct {
                fn onComplete(ctx: ?*anyopaque) void {
                    const state: *StreamState = @ptrCast(@alignCast(ctx.?));
                    state.finish();
                }
            }.onComplete,
            .on_error = struct {
                fn onError(ctx: ?*anyopaque, err: provider_utils.HttpError) void {
                    const state: *StreamState = @ptrCast(@alignCast(ctx.?));
                    state.handleError(err);
                }
            }.onError,
            .ctx = state_ptr,
        });
    }

    /// DeepSeek streaming chunk structure (OpenAI-compatible)
    const DeepSeekStreamChunk = struct {
        id: []const u8 = "",
        object: []const u8 = "",
        created: i64 = 0,
        model: []const u8 = "",
        choices: []const DeepSeekStreamChoice = &[_]DeepSeekStreamChoice{},
        usage: ?DeepSeekUsage = null,
    };

    const DeepSeekStreamChoice = struct {
        index: u32 = 0,
        delta: DeepSeekDelta = .{},
        finish_reason: ?[]const u8 = null,
    };

    const DeepSeekDelta = struct {
        role: ?[]const u8 = null,
        content: ?[]const u8 = null,
    };

    /// Build the request body (OpenAI format)
    fn buildRequestBody(
        self: *const Self,
        allocator: std.mem.Allocator,
        call_options: lm.LanguageModelV3CallOptions,
    ) !std.json.Value {
        var body = std.json.ObjectMap.init(allocator);

        try body.put("model", .{ .string = self.model_id });

        var messages = std.json.Array.init(allocator);

        for (call_options.prompt) |msg| {
            switch (msg.role) {
                .system => {
                    var message = std.json.ObjectMap.init(allocator);
                    try message.put("role", .{ .string = "system" });
                    try message.put("content", .{ .string = msg.content.system });
                    try messages.append(.{ .object = message });
                },
                .user => {
                    var message = std.json.ObjectMap.init(allocator);
                    try message.put("role", .{ .string = "user" });

                    var text_parts: std.ArrayList([]const u8) = .empty;
                    defer text_parts.deinit(allocator);
                    for (msg.content.user) |part| {
                        switch (part) {
                            .text => |t| try text_parts.append(allocator, t.text),
                            else => {},
                        }
                    }
                    const joined = try std.mem.join(allocator, "", text_parts.items);
                    try message.put("content", .{ .string = joined });

                    try messages.append(.{ .object = message });
                },
                .assistant => {
                    var message = std.json.ObjectMap.init(allocator);
                    try message.put("role", .{ .string = "assistant" });

                    var text_content: std.ArrayList([]const u8) = .empty;
                    defer text_content.deinit(allocator);
                    var tool_calls = std.json.Array.init(allocator);

                    for (msg.content.assistant) |part| {
                        switch (part) {
                            .text => |t| try text_content.append(allocator, t.text),
                            .tool_call => |tc| {
                                var tool_call = std.json.ObjectMap.init(allocator);
                                try tool_call.put("id", .{ .string = tc.tool_call_id });
                                try tool_call.put("type", .{ .string = "function" });

                                var func = std.json.ObjectMap.init(allocator);
                                try func.put("name", .{ .string = tc.tool_name });
                                // tc.input is JsonValue, stringify it for DeepSeek API
                                const input_str = try tc.input.stringify(allocator);
                                try func.put("arguments", .{ .string = input_str });
                                try tool_call.put("function", .{ .object = func });

                                try tool_calls.append(.{ .object = tool_call });
                            },
                            else => {},
                        }
                    }

                    if (text_content.items.len > 0) {
                        const joined = try std.mem.join(allocator, "", text_content.items);
                        try message.put("content", .{ .string = joined });
                    }
                    if (tool_calls.items.len > 0) {
                        try message.put("tool_calls", .{ .array = tool_calls });
                    }

                    try messages.append(.{ .object = message });
                },
                .tool => {
                    for (msg.content.tool) |part| {
                        var message = std.json.ObjectMap.init(allocator);
                        try message.put("role", .{ .string = "tool" });
                        try message.put("tool_call_id", .{ .string = part.tool_call_id });

                        const output_text = switch (part.output) {
                            .text => |t| t.value,
                            .json => |j| try j.value.stringify(allocator),
                            .error_text => |e| e.value,
                            .error_json => |e| try e.value.stringify(allocator),
                            .execution_denied => |d| d.reason orelse "Execution denied",
                            .content => "Content output not yet supported",
                        };
                        try message.put("content", .{ .string = output_text });

                        try messages.append(.{ .object = message });
                    }
                },
            }
        }

        try body.put("messages", .{ .array = messages });

        if (call_options.max_output_tokens) |max_tokens| {
            try body.put("max_tokens", .{ .integer = @intCast(max_tokens) });
        }
        if (call_options.temperature) |temp| {
            try body.put("temperature", .{ .float = temp });
        }
        if (call_options.top_p) |top_p| {
            try body.put("top_p", .{ .float = top_p });
        }

        if (call_options.stop_sequences) |stops| {
            var stops_array = std.json.Array.init(allocator);
            for (stops) |stop| {
                try stops_array.append(.{ .string = stop });
            }
            try body.put("stop", .{ .array = stops_array });
        }

        if (call_options.tools) |tools| {
            var tools_array = std.json.Array.init(allocator);
            for (tools) |tool| {
                switch (tool) {
                    .function => |func| {
                        var tool_obj = std.json.ObjectMap.init(allocator);
                        try tool_obj.put("type", .{ .string = "function" });

                        var func_obj = std.json.ObjectMap.init(allocator);
                        try func_obj.put("name", .{ .string = func.name });
                        if (func.description) |desc| {
                            try func_obj.put("description", .{ .string = desc });
                        }
                        // func.input_schema is JsonValue, convert to std.json.Value
                        try func_obj.put("parameters", try func.input_schema.toStdJson(allocator));

                        try tool_obj.put("function", .{ .object = func_obj });
                        try tools_array.append(.{ .object = tool_obj });
                    },
                    else => {},
                }
            }
            try body.put("tools", .{ .array = tools_array });
        }

        return .{ .object = body };
    }

    /// Get supported URLs (stub implementation)
    pub fn getSupportedUrls(
        self: *const Self,
        allocator: std.mem.Allocator,
        callback: *const fn (?*anyopaque, lm.LanguageModelV3.SupportedUrlsResult) void,
        ctx: ?*anyopaque,
    ) void {
        _ = self;
        callback(ctx, .{ .success = std.StringHashMap([]const []const u8).init(allocator) });
    }

    /// Convert to LanguageModelV3 interface
    pub fn asLanguageModel(self: *Self) lm.LanguageModelV3 {
        return lm.asLanguageModel(Self, self);
    }
};

test "DeepSeekChatLanguageModel init" {
    const allocator = std.testing.allocator;

    var model = DeepSeekChatLanguageModel.init(
        allocator,
        "deepseek-chat",
        .{ .base_url = "https://api.deepseek.com" },
    );

    try std.testing.expectEqualStrings("deepseek-chat", model.getModelId());
    try std.testing.expectEqualStrings("deepseek", model.getProvider());
}
