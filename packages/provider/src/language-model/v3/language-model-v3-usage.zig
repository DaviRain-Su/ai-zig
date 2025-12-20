const std = @import("std");
const json_value = @import("../../json-value/index.zig");

/// Usage information for a language model call.
pub const LanguageModelV3Usage = struct {
    /// Information about the input tokens.
    input_tokens: InputTokens,

    /// Information about the output tokens.
    output_tokens: OutputTokens,

    /// Raw usage information from the provider.
    /// This is the usage information in the shape that the provider returns.
    /// It can include additional information that is not part of the standard usage information.
    raw: ?json_value.JsonObject = null,

    /// Input token information
    pub const InputTokens = struct {
        /// The total number of input (prompt) tokens used.
        total: ?u64 = null,

        /// The number of non-cached input (prompt) tokens used.
        no_cache: ?u64 = null,

        /// The number of cached input (prompt) tokens read.
        cache_read: ?u64 = null,

        /// The number of cached input (prompt) tokens written.
        cache_write: ?u64 = null,

        /// Get total tokens, defaulting to 0 if not available
        pub fn totalOrZero(self: InputTokens) u64 {
            return self.total orelse 0;
        }
    };

    /// Output token information
    pub const OutputTokens = struct {
        /// The total number of output (completion) tokens used.
        total: ?u64 = null,

        /// The number of text tokens used.
        text: ?u64 = null,

        /// The number of reasoning tokens used.
        reasoning: ?u64 = null,

        /// Get total tokens, defaulting to 0 if not available
        pub fn totalOrZero(self: OutputTokens) u64 {
            return self.total orelse 0;
        }
    };

    const Self = @This();

    /// Create empty usage
    pub fn init() Self {
        return .{
            .input_tokens = .{},
            .output_tokens = .{},
        };
    }

    /// Create usage with just totals
    pub fn initWithTotals(input_total: ?u64, output_total: ?u64) Self {
        return .{
            .input_tokens = .{ .total = input_total },
            .output_tokens = .{ .total = output_total },
        };
    }

    /// Get total token count (input + output)
    pub fn totalTokens(self: Self) u64 {
        return self.input_tokens.totalOrZero() + self.output_tokens.totalOrZero();
    }

    /// Clone the usage info
    pub fn clone(self: Self, allocator: std.mem.Allocator) !Self {
        return .{
            .input_tokens = self.input_tokens,
            .output_tokens = self.output_tokens,
            .raw = if (self.raw) |r| try r.clone(allocator) else null,
        };
    }

    /// Free memory allocated for raw data
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.raw) |*r| {
            r.deinit(allocator);
        }
    }
};

test "LanguageModelV3Usage basic" {
    const usage = LanguageModelV3Usage.initWithTotals(100, 50);
    try std.testing.expectEqual(@as(u64, 100), usage.input_tokens.totalOrZero());
    try std.testing.expectEqual(@as(u64, 50), usage.output_tokens.totalOrZero());
    try std.testing.expectEqual(@as(u64, 150), usage.totalTokens());
}

test "LanguageModelV3Usage empty" {
    const usage = LanguageModelV3Usage.init();
    try std.testing.expectEqual(@as(u64, 0), usage.input_tokens.totalOrZero());
    try std.testing.expectEqual(@as(u64, 0), usage.output_tokens.totalOrZero());
    try std.testing.expectEqual(@as(u64, 0), usage.totalTokens());
}
