// Tool Module for Zig AI SDK
//
// This module provides tool/function calling capabilities:
// - Tool: Define tools that models can call
// - DynamicTool: Runtime-created tools
// - Tool execution and approval

pub const tool_mod = @import("tool.zig");

// Re-export types
pub const Tool = tool_mod.Tool;
pub const ToolConfig = tool_mod.ToolConfig;
pub const DynamicTool = tool_mod.DynamicTool;
pub const ParameterSchema = tool_mod.ParameterSchema;
pub const ToolExecutionContext = tool_mod.ToolExecutionContext;
pub const ToolExecutionResult = tool_mod.ToolExecutionResult;
pub const ToolError = tool_mod.ToolError;
pub const ExecuteFn = tool_mod.ExecuteFn;
pub const OnInputAvailableFn = tool_mod.OnInputAvailableFn;
pub const ApprovalRequirement = tool_mod.ApprovalRequirement;

// Re-export functions
pub const toLanguageModelTool = tool_mod.toLanguageModelTool;
pub const createParameterSchema = tool_mod.createParameterSchema;

test {
    @import("std").testing.refAllDecls(@This());
}
