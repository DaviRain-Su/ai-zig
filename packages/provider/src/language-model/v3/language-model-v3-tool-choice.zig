const std = @import("std");

/// Specifies how the tool should be selected.
pub const LanguageModelV3ToolChoice = union(enum) {
    /// The tool selection is automatic (can be no tool)
    auto,
    /// No tool must be selected
    none,
    /// One of the available tools must be selected
    required,
    /// A specific tool must be selected
    tool: ToolChoice,

    pub const ToolChoice = struct {
        tool_name: []const u8,
    };

    const Self = @This();

    /// Create auto tool choice
    pub fn autoChoice() Self {
        return .auto;
    }

    /// Create none tool choice
    pub fn noneChoice() Self {
        return .none;
    }

    /// Create required tool choice
    pub fn requiredChoice() Self {
        return .required;
    }

    /// Create specific tool choice
    pub fn toolChoice(tool_name: []const u8) Self {
        return .{ .tool = .{ .tool_name = tool_name } };
    }

    /// Get the type string
    pub fn getType(self: Self) []const u8 {
        return switch (self) {
            .auto => "auto",
            .none => "none",
            .required => "required",
            .tool => "tool",
        };
    }

    /// Get the tool name if this is a specific tool choice
    pub fn getToolName(self: Self) ?[]const u8 {
        return switch (self) {
            .tool => |t| t.tool_name,
            else => null,
        };
    }

    /// Clone the tool choice
    pub fn clone(self: Self, allocator: std.mem.Allocator) !Self {
        return switch (self) {
            .auto => .auto,
            .none => .none,
            .required => .required,
            .tool => |t| .{ .tool = .{ .tool_name = try allocator.dupe(u8, t.tool_name) } },
        };
    }

    /// Free memory if needed
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .tool => |t| allocator.free(t.tool_name),
            else => {},
        }
    }
};

test "LanguageModelV3ToolChoice auto" {
    const choice = LanguageModelV3ToolChoice.autoChoice();
    try std.testing.expectEqualStrings("auto", choice.getType());
    try std.testing.expect(choice.getToolName() == null);
}

test "LanguageModelV3ToolChoice tool" {
    const choice = LanguageModelV3ToolChoice.toolChoice("search");
    try std.testing.expectEqualStrings("tool", choice.getType());
    try std.testing.expectEqualStrings("search", choice.getToolName().?);
}
