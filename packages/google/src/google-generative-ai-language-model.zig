const std = @import("std");
const lm = @import("../../provider/src/language-model/v3/index.zig");
const shared = @import("../../provider/src/shared/v3/index.zig");
const provider_utils = @import("../../provider-utils/src/index.zig");

const config_mod = @import("google-config.zig");
const options_mod = @import("google-generative-ai-options.zig");
const convert = @import("convert-to-google-generative-ai-messages.zig");
const prepare_tools = @import("google-prepare-tools.zig");
const map_finish = @import("map-google-generative-ai-finish-reason.zig");

/// Google Generative AI Language Model
pub const GoogleGenerativeAILanguageModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    config: config_mod.GoogleGenerativeAIConfig,

    /// Create a new Google Generative AI language model
    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        config: config_mod.GoogleGenerativeAIConfig,
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

    /// Get the model path for API calls
    pub fn getModelPath(self: *const Self) []const u8 {
        // For tuned models, use the full path
        if (std.mem.startsWith(u8, self.model_id, "tunedModels/")) {
            return self.model_id;
        }
        return self.model_id;
    }

    /// Generate content (non-streaming)
    pub fn doGenerate(
        self: *Self,
        call_options: lm.LanguageModelV3CallOptions,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?lm.LanguageModelV3.GenerateResult, ?anyerror, ?*anyopaque) void,
        callback_context: ?*anyopaque,
    ) void {
        // Use arena for request processing
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const request_allocator = arena.allocator();

        // Build the request
        const request_body = self.buildRequestBody(request_allocator, call_options) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Make the API call
        const url = std.fmt.allocPrint(
            request_allocator,
            "{s}/models/{s}:generateContent",
            .{ self.config.base_url, self.getModelPath() },
        ) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Get headers
        var headers = std.StringHashMap([]const u8).init(request_allocator);
        if (self.config.headers_fn) |headers_fn| {
            headers = headers_fn(&self.config);
        }

        // Serialize request body
        var body_buffer = std.ArrayList(u8).init(request_allocator);
        std.json.stringify(request_body, .{}, body_buffer.writer()) catch |err| {
            callback(null, err, callback_context);
            return;
        };

        // Make HTTP request (simplified - actual implementation would use http client)
        _ = url;
        _ = headers;
        _ = body_buffer;

        // For now, return a placeholder result
        // Actual implementation would parse the response
        const result = lm.LanguageModelV3.GenerateResult{
            .content = &[_]lm.LanguageModelV3Content{},
            .finish_reason = .stop,
            .usage = .{
                .prompt_tokens = 0,
                .completion_tokens = 0,
            },
            .warnings = &[_]shared.SharedV3Warning{},
        };

        // Clone result to result_allocator
        _ = result_allocator;
        callback(result, null, callback_context);
    }

    /// Stream content
    pub fn doStream(
        self: *Self,
        call_options: lm.LanguageModelV3CallOptions,
        result_allocator: std.mem.Allocator,
        callbacks: lm.LanguageModelV3.StreamCallbacks,
    ) void {
        // Use arena for request processing
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const request_allocator = arena.allocator();

        // Build the request
        const request_body = self.buildRequestBody(request_allocator, call_options) catch |err| {
            callbacks.on_error(err, callbacks.context);
            return;
        };

        // Make the streaming API call
        const url = std.fmt.allocPrint(
            request_allocator,
            "{s}/models/{s}:streamGenerateContent?alt=sse",
            .{ self.config.base_url, self.getModelPath() },
        ) catch |err| {
            callbacks.on_error(err, callbacks.context);
            return;
        };

        _ = url;
        _ = request_body;
        _ = result_allocator;

        // Emit stream start
        callbacks.on_part(.{ .stream_start = .{} }, callbacks.context);

        // For now, emit completion
        // Actual implementation would stream from the API
        callbacks.on_part(.{
            .finish = .{
                .finish_reason = .stop,
                .usage = .{
                    .prompt_tokens = 0,
                    .completion_tokens = 0,
                },
            },
        }, callbacks.context);

        callbacks.on_complete(callbacks.context);
    }

    /// Build the request body for the API call
    fn buildRequestBody(
        self: *Self,
        allocator: std.mem.Allocator,
        call_options: lm.LanguageModelV3CallOptions,
    ) !std.json.Value {
        var body = std.json.ObjectMap.init(allocator);

        // Convert messages
        const is_gemma = options_mod.isGemmaModel(self.model_id);
        const converted = try convert.convertToGoogleGenerativeAIMessages(
            allocator,
            call_options.prompt,
            .{ .is_gemma_model = is_gemma },
        );

        // Add contents
        var contents_array = std.json.Array.init(allocator);
        for (converted.contents) |content| {
            var content_obj = std.json.ObjectMap.init(allocator);
            try content_obj.put("role", .{ .string = content.role });

            var parts_array = std.json.Array.init(allocator);
            for (content.parts) |part| {
                const part_json = try @import("google-generative-ai-prompt.zig").serializeContentPart(allocator, part);
                try parts_array.append(part_json);
            }
            try content_obj.put("parts", .{ .array = parts_array });

            try contents_array.append(.{ .object = content_obj });
        }
        try body.put("contents", .{ .array = contents_array });

        // Add system instruction if present
        if (converted.system_instruction) |sys| {
            var sys_obj = std.json.ObjectMap.init(allocator);
            var sys_parts = std.json.Array.init(allocator);
            for (sys.parts) |part| {
                var part_obj = std.json.ObjectMap.init(allocator);
                try part_obj.put("text", .{ .string = part.text });
                try sys_parts.append(.{ .object = part_obj });
            }
            try sys_obj.put("parts", .{ .array = sys_parts });
            try body.put("systemInstruction", .{ .object = sys_obj });
        }

        // Add generation config
        var gen_config = std.json.ObjectMap.init(allocator);

        if (call_options.max_output_tokens) |max_tokens| {
            try gen_config.put("maxOutputTokens", .{ .integer = @intCast(max_tokens) });
        }
        if (call_options.temperature) |temp| {
            try gen_config.put("temperature", .{ .float = temp });
        }
        if (call_options.top_p) |top_p| {
            try gen_config.put("topP", .{ .float = top_p });
        }
        if (call_options.top_k) |top_k| {
            try gen_config.put("topK", .{ .integer = @intCast(top_k) });
        }
        if (call_options.frequency_penalty) |freq| {
            try gen_config.put("frequencyPenalty", .{ .float = freq });
        }
        if (call_options.presence_penalty) |pres| {
            try gen_config.put("presencePenalty", .{ .float = pres });
        }
        if (call_options.seed) |seed| {
            try gen_config.put("seed", .{ .integer = @intCast(seed) });
        }
        if (call_options.stop_sequences) |stops| {
            var stops_array = std.json.Array.init(allocator);
            for (stops) |stop| {
                try stops_array.append(.{ .string = stop });
            }
            try gen_config.put("stopSequences", .{ .array = stops_array });
        }

        // Add response format
        if (call_options.response_format) |format| {
            switch (format) {
                .json => {
                    try gen_config.put("responseMimeType", .{ .string = "application/json" });
                    if (format.json.schema) |schema| {
                        try gen_config.put("responseSchema", schema);
                    }
                },
                .text => {},
            }
        }

        if (gen_config.count() > 0) {
            try body.put("generationConfig", .{ .object = gen_config });
        }

        // Add tools
        const tools_result = try prepare_tools.prepareTools(
            allocator,
            call_options.tools,
            call_options.tool_choice,
            self.model_id,
        );

        if (tools_result.function_declarations) |decls| {
            var tools_array = std.json.Array.init(allocator);
            var func_decls_obj = std.json.ObjectMap.init(allocator);
            var func_decls_array = std.json.Array.init(allocator);

            for (decls) |decl| {
                var decl_obj = std.json.ObjectMap.init(allocator);
                try decl_obj.put("name", .{ .string = decl.name });
                try decl_obj.put("description", .{ .string = decl.description });
                try decl_obj.put("parameters", decl.parameters);
                try func_decls_array.append(.{ .object = decl_obj });
            }

            try func_decls_obj.put("functionDeclarations", .{ .array = func_decls_array });
            try tools_array.append(.{ .object = func_decls_obj });
            try body.put("tools", .{ .array = tools_array });
        }

        if (tools_result.provider_tools) |prov_tools| {
            var tools_array = std.json.Array.init(allocator);
            for (prov_tools) |prov_tool| {
                var tool_obj = std.json.ObjectMap.init(allocator);
                switch (prov_tool) {
                    .google_search => {
                        try tool_obj.put("googleSearch", .{ .object = std.json.ObjectMap.init(allocator) });
                    },
                    .code_execution => {
                        try tool_obj.put("codeExecution", .{ .object = std.json.ObjectMap.init(allocator) });
                    },
                    .url_context => {
                        try tool_obj.put("urlContext", .{ .object = std.json.ObjectMap.init(allocator) });
                    },
                    .google_maps => {
                        try tool_obj.put("googleMaps", .{ .object = std.json.ObjectMap.init(allocator) });
                    },
                    else => {},
                }
                try tools_array.append(.{ .object = tool_obj });
            }
            try body.put("tools", .{ .array = tools_array });
        }

        if (tools_result.tool_config) |tc| {
            var tc_obj = std.json.ObjectMap.init(allocator);
            if (tc.function_calling_config) |fcc| {
                var fcc_obj = std.json.ObjectMap.init(allocator);
                try fcc_obj.put("mode", .{ .string = fcc.mode.toString() });
                if (fcc.allowed_function_names) |names| {
                    var names_array = std.json.Array.init(allocator);
                    for (names) |name| {
                        try names_array.append(.{ .string = name });
                    }
                    try fcc_obj.put("allowedFunctionNames", .{ .array = names_array });
                }
                try tc_obj.put("functionCallingConfig", .{ .object = fcc_obj });
            }
            try body.put("toolConfig", .{ .object = tc_obj });
        }

        return .{ .object = body };
    }

    /// Convert to LanguageModelV3 interface
    pub fn asLanguageModel(self: *Self) lm.LanguageModelV3 {
        return .{
            .vtable = &vtable,
            .impl = self,
        };
    }

    const vtable = lm.LanguageModelV3.VTable{
        .doGenerate = doGenerateVtable,
        .doStream = doStreamVtable,
        .getModelId = getModelIdVtable,
        .getProvider = getProviderVtable,
    };

    fn doGenerateVtable(
        impl: *anyopaque,
        call_options: lm.LanguageModelV3CallOptions,
        result_allocator: std.mem.Allocator,
        callback: *const fn (?lm.LanguageModelV3.GenerateResult, ?anyerror, ?*anyopaque) void,
        callback_context: ?*anyopaque,
    ) void {
        const self: *Self = @ptrCast(@alignCast(impl));
        self.doGenerate(call_options, result_allocator, callback, callback_context);
    }

    fn doStreamVtable(
        impl: *anyopaque,
        call_options: lm.LanguageModelV3CallOptions,
        result_allocator: std.mem.Allocator,
        callbacks: lm.LanguageModelV3.StreamCallbacks,
    ) void {
        const self: *Self = @ptrCast(@alignCast(impl));
        self.doStream(call_options, result_allocator, callbacks);
    }

    fn getModelIdVtable(impl: *anyopaque) []const u8 {
        const self: *Self = @ptrCast(@alignCast(impl));
        return self.getModelId();
    }

    fn getProviderVtable(impl: *anyopaque) []const u8 {
        const self: *Self = @ptrCast(@alignCast(impl));
        return self.getProvider();
    }
};

test "GoogleGenerativeAILanguageModel init" {
    const allocator = std.testing.allocator;

    var model = GoogleGenerativeAILanguageModel.init(
        allocator,
        "gemini-2.0-flash",
        .{},
    );

    try std.testing.expectEqualStrings("gemini-2.0-flash", model.getModelId());
    try std.testing.expectEqualStrings("google.generative-ai", model.getProvider());
}

test "GoogleGenerativeAILanguageModel getModelPath" {
    const allocator = std.testing.allocator;

    var model = GoogleGenerativeAILanguageModel.init(
        allocator,
        "gemini-2.0-flash",
        .{},
    );

    try std.testing.expectEqualStrings("gemini-2.0-flash", model.getModelPath());

    // Test tuned model
    var tuned_model = GoogleGenerativeAILanguageModel.init(
        allocator,
        "tunedModels/my-model",
        .{},
    );

    try std.testing.expectEqualStrings("tunedModels/my-model", tuned_model.getModelPath());
}
