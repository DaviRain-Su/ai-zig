const std = @import("std");

/// Mistral API error data
pub const MistralErrorData = struct {
    /// Object type (always "error")
    object: []const u8 = "error",

    /// Error message
    message: []const u8,

    /// Error type
    type: []const u8,

    /// Parameter that caused the error (nullable)
    param: ?[]const u8 = null,

    /// Error code (nullable)
    code: ?[]const u8 = null,
};

/// Parse Mistral error from JSON
pub fn parseMistralError(allocator: std.mem.Allocator, json_str: []const u8) !MistralErrorData {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_str, .{});
    defer parsed.deinit();

    const obj = parsed.value.object;

    return MistralErrorData{
        .object = if (obj.get("object")) |v| v.string else "error",
        .message = if (obj.get("message")) |v| v.string else "Unknown error",
        .type = if (obj.get("type")) |v| v.string else "unknown",
        .param = if (obj.get("param")) |v| if (v == .string) v.string else null else null,
        .code = if (obj.get("code")) |v| if (v == .string) v.string else null else null,
    };
}

/// Format Mistral error as string
pub fn formatMistralError(allocator: std.mem.Allocator, err: MistralErrorData) ![]const u8 {
    if (err.code) |code| {
        return std.fmt.allocPrint(allocator, "Mistral API error [{s}]: {s}", .{ code, err.message });
    }
    return std.fmt.allocPrint(allocator, "Mistral API error: {s}", .{err.message});
}

test "parseMistralError" {
    const allocator = std.testing.allocator;
    const json =
        \\{"object":"error","message":"Invalid API key","type":"authentication_error","param":null,"code":"invalid_api_key"}
    ;
    const err = try parseMistralError(allocator, json);
    try std.testing.expectEqualStrings("error", err.object);
    try std.testing.expectEqualStrings("Invalid API key", err.message);
    try std.testing.expectEqualStrings("authentication_error", err.type);
}
