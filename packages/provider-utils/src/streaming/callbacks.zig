const std = @import("std");

/// Generic streaming callback interface.
/// This provides a type-safe way to handle streaming events.
pub fn StreamCallbacks(comptime T: type) type {
    return struct {
        /// Called for each item in the stream
        on_item: *const fn (ctx: ?*anyopaque, item: T) void,
        /// Called when an error occurs
        on_error: *const fn (ctx: ?*anyopaque, err: anyerror) void,
        /// Called when the stream completes successfully
        on_complete: *const fn (ctx: ?*anyopaque) void,
        /// User context passed to all callbacks
        ctx: ?*anyopaque = null,

        const Self = @This();

        /// Emit an item to the stream
        pub fn emit(self: Self, item: T) void {
            self.on_item(self.ctx, item);
        }

        /// Signal an error
        pub fn fail(self: Self, err: anyerror) void {
            self.on_error(self.ctx, err);
        }

        /// Signal completion
        pub fn complete(self: Self) void {
            self.on_complete(self.ctx);
        }
    };
}

/// Builder pattern for creating stream callbacks
pub fn CallbackBuilder(comptime T: type) type {
    return struct {
        callbacks: StreamCallbacks(T),

        const Self = @This();

        /// Create a new callback builder with no-op defaults
        pub fn init() Self {
            return .{
                .callbacks = .{
                    .on_item = noopItem,
                    .on_error = noopError,
                    .on_complete = noopComplete,
                    .ctx = null,
                },
            };
        }

        /// Set the item handler
        pub fn onItem(self: *Self, handler: *const fn (ctx: ?*anyopaque, item: T) void) *Self {
            self.callbacks.on_item = handler;
            return self;
        }

        /// Set the error handler
        pub fn onError(self: *Self, handler: *const fn (ctx: ?*anyopaque, err: anyerror) void) *Self {
            self.callbacks.on_error = handler;
            return self;
        }

        /// Set the completion handler
        pub fn onComplete(self: *Self, handler: *const fn (ctx: ?*anyopaque) void) *Self {
            self.callbacks.on_complete = handler;
            return self;
        }

        /// Set the context
        pub fn withContext(self: *Self, ctx: *anyopaque) *Self {
            self.callbacks.ctx = ctx;
            return self;
        }

        /// Build the final callbacks struct
        pub fn build(self: Self) StreamCallbacks(T) {
            return self.callbacks;
        }

        fn noopItem(_: ?*anyopaque, _: T) void {}
        fn noopError(_: ?*anyopaque, _: anyerror) void {}
        fn noopComplete(_: ?*anyopaque) void {}
    };
}

/// Streaming text callbacks - specialized for text streaming
pub const TextStreamCallbacks = struct {
    /// Called for each text delta
    on_text: ?*const fn (ctx: ?*anyopaque, text: []const u8) void = null,
    /// Called when all text is complete
    on_text_complete: ?*const fn (ctx: ?*anyopaque, full_text: []const u8) void = null,
    /// Called when an error occurs
    on_error: *const fn (ctx: ?*anyopaque, err: anyerror) void,
    /// Called when the stream completes
    on_complete: *const fn (ctx: ?*anyopaque) void,
    /// User context
    ctx: ?*anyopaque = null,
};

/// Tool call streaming callbacks
pub const ToolCallStreamCallbacks = struct {
    /// Called when a tool call starts
    on_tool_call_start: ?*const fn (ctx: ?*anyopaque, tool_name: []const u8, tool_call_id: []const u8) void = null,
    /// Called for each tool input delta
    on_tool_input_delta: ?*const fn (ctx: ?*anyopaque, tool_call_id: []const u8, delta: []const u8) void = null,
    /// Called when a tool call completes
    on_tool_call_complete: ?*const fn (ctx: ?*anyopaque, tool_call_id: []const u8, input: []const u8) void = null,
    /// Called when an error occurs
    on_error: *const fn (ctx: ?*anyopaque, err: anyerror) void,
    /// Called when the stream completes
    on_complete: *const fn (ctx: ?*anyopaque) void,
    /// User context
    ctx: ?*anyopaque = null,
};

/// Combined language model stream callbacks
pub const LanguageModelStreamCallbacks = struct {
    /// Text callbacks
    on_text_delta: ?*const fn (ctx: ?*anyopaque, text: []const u8) void = null,
    on_text_complete: ?*const fn (ctx: ?*anyopaque, full_text: []const u8) void = null,

    /// Tool call callbacks
    on_tool_call_start: ?*const fn (ctx: ?*anyopaque, tool_name: []const u8, tool_call_id: []const u8) void = null,
    on_tool_input_delta: ?*const fn (ctx: ?*anyopaque, tool_call_id: []const u8, delta: []const u8) void = null,
    on_tool_call_complete: ?*const fn (ctx: ?*anyopaque, tool_call_id: []const u8, input: []const u8) void = null,

    /// Metadata callbacks
    on_usage: ?*const fn (ctx: ?*anyopaque, input_tokens: u64, output_tokens: u64) void = null,
    on_finish_reason: ?*const fn (ctx: ?*anyopaque, reason: []const u8) void = null,

    /// Error and completion
    on_error: *const fn (ctx: ?*anyopaque, err: anyerror) void,
    on_complete: *const fn (ctx: ?*anyopaque) void,

    /// User context
    ctx: ?*anyopaque = null,

    const Self = @This();

    /// Create with just required callbacks
    pub fn init(
        on_error: *const fn (ctx: ?*anyopaque, err: anyerror) void,
        on_complete: *const fn (ctx: ?*anyopaque) void,
    ) Self {
        return .{
            .on_error = on_error,
            .on_complete = on_complete,
        };
    }
};

/// Accumulator for building up streaming content
pub const StreamAccumulator = struct {
    text: std.ArrayList(u8),
    tool_calls: std.ArrayList(AccumulatedToolCall),
    allocator: std.mem.Allocator,

    pub const AccumulatedToolCall = struct {
        id: []const u8,
        name: []const u8,
        input: std.ArrayList(u8),

        pub fn deinit(self: *AccumulatedToolCall, allocator: std.mem.Allocator) void {
            allocator.free(self.id);
            allocator.free(self.name);
            self.input.deinit();
        }
    };

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .text = std.ArrayList(u8).init(allocator),
            .tool_calls = std.ArrayList(AccumulatedToolCall).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.text.deinit();
        for (self.tool_calls.items) |*tc| {
            tc.deinit(self.allocator);
        }
        self.tool_calls.deinit();
    }

    /// Append text to the accumulator
    pub fn appendText(self: *Self, text: []const u8) !void {
        try self.text.appendSlice(text);
    }

    /// Get the accumulated text
    pub fn getText(self: Self) []const u8 {
        return self.text.items;
    }

    /// Start a new tool call
    pub fn startToolCall(self: *Self, id: []const u8, name: []const u8) !void {
        try self.tool_calls.append(.{
            .id = try self.allocator.dupe(u8, id),
            .name = try self.allocator.dupe(u8, name),
            .input = std.ArrayList(u8).init(self.allocator),
        });
    }

    /// Append to the current tool call input
    pub fn appendToolInput(self: *Self, id: []const u8, delta: []const u8) !void {
        for (self.tool_calls.items) |*tc| {
            if (std.mem.eql(u8, tc.id, id)) {
                try tc.input.appendSlice(delta);
                return;
            }
        }
    }

    /// Get tool calls
    pub fn getToolCalls(self: Self) []AccumulatedToolCall {
        return self.tool_calls.items;
    }
};

test "StreamCallbacks basic" {
    var received_items: usize = 0;
    var completed = false;

    const TestCallbacks = StreamCallbacks(i32);

    const callbacks = TestCallbacks{
        .on_item = struct {
            fn handler(ctx: ?*anyopaque, _: i32) void {
                const count: *usize = @ptrCast(@alignCast(ctx));
                count.* += 1;
            }
        }.handler,
        .on_error = struct {
            fn handler(_: ?*anyopaque, _: anyerror) void {}
        }.handler,
        .on_complete = struct {
            fn handler(ctx: ?*anyopaque) void {
                const flag: *bool = @ptrCast(@alignCast(ctx));
                flag.* = true;
            }
        }.handler,
        .ctx = &received_items,
    };

    callbacks.emit(1);
    callbacks.emit(2);
    callbacks.emit(3);

    // Change context for completion
    var callbacks_for_complete = callbacks;
    callbacks_for_complete.ctx = &completed;
    callbacks_for_complete.complete();

    try std.testing.expectEqual(@as(usize, 3), received_items);
    try std.testing.expect(completed);
}

test "StreamAccumulator" {
    const allocator = std.testing.allocator;

    var acc = StreamAccumulator.init(allocator);
    defer acc.deinit();

    try acc.appendText("Hello ");
    try acc.appendText("world!");

    try std.testing.expectEqualStrings("Hello world!", acc.getText());

    try acc.startToolCall("call-1", "search");
    try acc.appendToolInput("call-1", "{\"query\":");
    try acc.appendToolInput("call-1", "\"test\"}");

    try std.testing.expectEqual(@as(usize, 1), acc.getToolCalls().len);
    try std.testing.expectEqualStrings("search", acc.getToolCalls()[0].name);
    try std.testing.expectEqualStrings("{\"query\":\"test\"}", acc.getToolCalls()[0].input.items);
}
