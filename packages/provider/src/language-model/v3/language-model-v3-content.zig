const std = @import("std");
const LanguageModelV3Text = @import("language-model-v3-text.zig").LanguageModelV3Text;
const LanguageModelV3Reasoning = @import("language-model-v3-reasoning.zig").LanguageModelV3Reasoning;
const LanguageModelV3File = @import("language-model-v3-file.zig").LanguageModelV3File;
const LanguageModelV3Source = @import("language-model-v3-source.zig").LanguageModelV3Source;
const LanguageModelV3ToolCall = @import("language-model-v3-tool-call.zig").LanguageModelV3ToolCall;
const LanguageModelV3ToolResult = @import("language-model-v3-tool-result.zig").LanguageModelV3ToolResult;

/// Content types that can be part of a language model response.
pub const LanguageModelV3Content = union(enum) {
    /// Text content
    text: LanguageModelV3Text,
    /// Reasoning content (chain of thought)
    reasoning: LanguageModelV3Reasoning,
    /// File content (generated files)
    file: LanguageModelV3File,
    /// Source references
    source: LanguageModelV3Source,
    /// Tool call
    tool_call: LanguageModelV3ToolCall,
    /// Tool result (from provider-executed tools)
    tool_result: LanguageModelV3ToolResult,

    const Self = @This();

    /// Get the type string for this content
    pub fn getType(self: Self) []const u8 {
        return switch (self) {
            .text => "text",
            .reasoning => "reasoning",
            .file => "file",
            .source => "source",
            .tool_call => "tool-call",
            .tool_result => "tool-result",
        };
    }

    /// Check if this is text content
    pub fn isText(self: Self) bool {
        return self == .text;
    }

    /// Check if this is a tool call
    pub fn isToolCall(self: Self) bool {
        return self == .tool_call;
    }

    /// Check if this is a tool result
    pub fn isToolResult(self: Self) bool {
        return self == .tool_result;
    }

    /// Get as text if this is text content
    pub fn asText(self: Self) ?LanguageModelV3Text {
        return switch (self) {
            .text => |t| t,
            else => null,
        };
    }

    /// Get as tool call if this is a tool call
    pub fn asToolCall(self: Self) ?LanguageModelV3ToolCall {
        return switch (self) {
            .tool_call => |tc| tc,
            else => null,
        };
    }

    /// Get as tool result if this is a tool result
    pub fn asToolResult(self: Self) ?LanguageModelV3ToolResult {
        return switch (self) {
            .tool_result => |tr| tr,
            else => null,
        };
    }

    /// Clone the content
    pub fn clone(self: Self, allocator: std.mem.Allocator) !Self {
        return switch (self) {
            .text => |t| .{ .text = try t.clone(allocator) },
            .reasoning => |r| .{ .reasoning = try r.clone(allocator) },
            .file => |f| .{ .file = try f.clone(allocator) },
            .source => |s| .{ .source = try s.clone(allocator) },
            .tool_call => |tc| .{ .tool_call = try tc.clone(allocator) },
            .tool_result => |tr| .{ .tool_result = try tr.clone(allocator) },
        };
    }

    /// Free memory allocated for this content
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .text => |*t| t.deinit(allocator),
            .reasoning => |*r| r.deinit(allocator),
            .file => |*f| f.deinit(allocator),
            .source => |*s| s.deinit(allocator),
            .tool_call => |*tc| tc.deinit(allocator),
            .tool_result => |*tr| tr.deinit(allocator),
        }
    }
};

/// Helper to create text content
pub fn textContent(text: []const u8) LanguageModelV3Content {
    return .{ .text = LanguageModelV3Text.init(text) };
}

/// Helper to create reasoning content
pub fn reasoningContent(text: []const u8) LanguageModelV3Content {
    return .{ .reasoning = LanguageModelV3Reasoning.init(text) };
}

/// Helper to create tool call content
pub fn toolCallContent(tool_call_id: []const u8, tool_name: []const u8, input: []const u8) LanguageModelV3Content {
    return .{ .tool_call = LanguageModelV3ToolCall.init(tool_call_id, tool_name, input) };
}

test "LanguageModelV3Content text" {
    const content = textContent("Hello, world!");
    try std.testing.expect(content.isText());
    try std.testing.expectEqualStrings("text", content.getType());
    try std.testing.expectEqualStrings("Hello, world!", content.asText().?.text);
}

test "LanguageModelV3Content tool_call" {
    const content = toolCallContent("call-1", "search", "{}");
    try std.testing.expect(content.isToolCall());
    try std.testing.expectEqualStrings("tool-call", content.getType());
    try std.testing.expectEqualStrings("search", content.asToolCall().?.tool_name);
}
