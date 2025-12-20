const std = @import("std");

/// Google Generative AI prompt structure
pub const GoogleGenerativeAIPrompt = struct {
    /// System instruction
    system_instruction: ?SystemInstruction = null,

    /// Message contents
    contents: []GoogleGenerativeAIContent,

    pub const SystemInstruction = struct {
        parts: []const TextPart,

        pub const TextPart = struct {
            text: []const u8,
        };
    };
};

/// Google Generative AI content (message)
pub const GoogleGenerativeAIContent = struct {
    /// Role: "user" or "model"
    role: []const u8,

    /// Content parts
    parts: []GoogleGenerativeAIContentPart,
};

/// Google Generative AI content part (tagged union)
pub const GoogleGenerativeAIContentPart = union(enum) {
    /// Text content
    text: TextPart,

    /// Inline data (images, etc.)
    inline_data: InlineData,

    /// File data (URLs)
    file_data: FileData,

    /// Function call
    function_call: FunctionCall,

    /// Function response
    function_response: FunctionResponse,

    /// Executable code
    executable_code: ExecutableCode,

    /// Code execution result
    code_execution_result: CodeExecutionResult,

    pub const TextPart = struct {
        text: []const u8,
        thought: ?bool = null,
        thought_signature: ?[]const u8 = null,
    };

    pub const InlineData = struct {
        mime_type: []const u8,
        data: []const u8,
        thought_signature: ?[]const u8 = null,
    };

    pub const FileData = struct {
        mime_type: []const u8,
        file_uri: []const u8,
    };

    pub const FunctionCall = struct {
        name: []const u8,
        args: std.json.Value,
        thought_signature: ?[]const u8 = null,
    };

    pub const FunctionResponse = struct {
        name: []const u8,
        response: Response,

        pub const Response = struct {
            name: []const u8,
            content: []const u8,
        };
    };

    pub const ExecutableCode = struct {
        language: []const u8,
        code: []const u8,
    };

    pub const CodeExecutionResult = struct {
        outcome: []const u8,
        output: []const u8,
    };
};

/// Serialize content part to JSON object
pub fn serializeContentPart(
    allocator: std.mem.Allocator,
    part: GoogleGenerativeAIContentPart,
) !std.json.Value {
    var obj = std.json.ObjectMap.init(allocator);

    switch (part) {
        .text => |t| {
            try obj.put("text", .{ .string = t.text });
            if (t.thought) |thought| {
                try obj.put("thought", .{ .bool = thought });
            }
            if (t.thought_signature) |sig| {
                try obj.put("thoughtSignature", .{ .string = sig });
            }
        },
        .inline_data => |d| {
            var inline_obj = std.json.ObjectMap.init(allocator);
            try inline_obj.put("mimeType", .{ .string = d.mime_type });
            try inline_obj.put("data", .{ .string = d.data });
            try obj.put("inlineData", .{ .object = inline_obj });
            if (d.thought_signature) |sig| {
                try obj.put("thoughtSignature", .{ .string = sig });
            }
        },
        .file_data => |f| {
            var file_obj = std.json.ObjectMap.init(allocator);
            try file_obj.put("mimeType", .{ .string = f.mime_type });
            try file_obj.put("fileUri", .{ .string = f.file_uri });
            try obj.put("fileData", .{ .object = file_obj });
        },
        .function_call => |fc| {
            var call_obj = std.json.ObjectMap.init(allocator);
            try call_obj.put("name", .{ .string = fc.name });
            try call_obj.put("args", fc.args);
            try obj.put("functionCall", .{ .object = call_obj });
            if (fc.thought_signature) |sig| {
                try obj.put("thoughtSignature", .{ .string = sig });
            }
        },
        .function_response => |fr| {
            var resp_inner = std.json.ObjectMap.init(allocator);
            try resp_inner.put("name", .{ .string = fr.response.name });
            try resp_inner.put("content", .{ .string = fr.response.content });

            var resp_obj = std.json.ObjectMap.init(allocator);
            try resp_obj.put("name", .{ .string = fr.name });
            try resp_obj.put("response", .{ .object = resp_inner });
            try obj.put("functionResponse", .{ .object = resp_obj });
        },
        .executable_code => |ec| {
            var code_obj = std.json.ObjectMap.init(allocator);
            try code_obj.put("language", .{ .string = ec.language });
            try code_obj.put("code", .{ .string = ec.code });
            try obj.put("executableCode", .{ .object = code_obj });
        },
        .code_execution_result => |cer| {
            var result_obj = std.json.ObjectMap.init(allocator);
            try result_obj.put("outcome", .{ .string = cer.outcome });
            try result_obj.put("output", .{ .string = cer.output });
            try obj.put("codeExecutionResult", .{ .object = result_obj });
        },
    }

    return .{ .object = obj };
}

test "GoogleGenerativeAIContentPart text" {
    const part = GoogleGenerativeAIContentPart{
        .text = .{
            .text = "Hello, world!",
            .thought = false,
        },
    };
    try std.testing.expectEqualStrings("Hello, world!", part.text.text);
}

test "GoogleGenerativeAIContentPart inline_data" {
    const part = GoogleGenerativeAIContentPart{
        .inline_data = .{
            .mime_type = "image/png",
            .data = "base64data",
        },
    };
    try std.testing.expectEqualStrings("image/png", part.inline_data.mime_type);
}
