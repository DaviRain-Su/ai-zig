const std = @import("std");

/// Usage information for an image model call.
pub const ImageModelV3Usage = struct {
    /// The number of input (prompt) tokens used.
    input_tokens: ?u64 = null,

    /// The number of output tokens used, if reported by the provider.
    output_tokens: ?u64 = null,

    /// The total number of tokens as reported by the provider.
    total_tokens: ?u64 = null,

    const Self = @This();

    /// Create empty usage
    pub fn init() Self {
        return .{};
    }

    /// Create usage with values
    pub fn initWithValues(input: ?u64, output: ?u64, total: ?u64) Self {
        return .{
            .input_tokens = input,
            .output_tokens = output,
            .total_tokens = total,
        };
    }

    /// Get total tokens, computing from parts if needed
    pub fn getTotalTokens(self: Self) u64 {
        if (self.total_tokens) |t| return t;
        const input = self.input_tokens orelse 0;
        const output = self.output_tokens orelse 0;
        return input + output;
    }
};

test "ImageModelV3Usage basic" {
    const usage = ImageModelV3Usage.init();
    try std.testing.expect(usage.input_tokens == null);
    try std.testing.expectEqual(@as(u64, 0), usage.getTotalTokens());
}

test "ImageModelV3Usage with values" {
    const usage = ImageModelV3Usage.initWithValues(100, 50, null);
    try std.testing.expectEqual(@as(u64, 150), usage.getTotalTokens());
}
