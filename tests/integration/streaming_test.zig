const std = @import("std");
const testing = std.testing;
const ai = @import("ai");

// Integration tests for streaming functionality

test "StreamTextResult accumulates text" {
    const allocator = testing.allocator;

    // Create mock callbacks
    const callbacks = ai.StreamCallbacks{
        .on_part = struct {
            fn f(_: ai.StreamPart, _: ?*anyopaque) void {}
        }.f,
        .on_error = struct {
            fn f(_: anyerror, _: ?*anyopaque) void {}
        }.f,
        .on_complete = struct {
            fn f(_: ?*anyopaque) void {}
        }.f,
    };

    // Initialize stream result with mock model
    const provider = @import("provider");
    const LanguageModelV3 = provider.language_model_v3.LanguageModelV3;
    const model: LanguageModelV3 = undefined;

    var result = ai.StreamTextResult.init(allocator, .{
        .model = @constCast(&model),
        .prompt = "Test prompt",
        .callbacks = callbacks,
    });
    defer result.deinit();

    // Simulate text deltas
    try result.processPart(.{ .text_delta = .{ .text = "Hello" } });
    try result.processPart(.{ .text_delta = .{ .text = " " } });
    try result.processPart(.{ .text_delta = .{ .text = "World" } });
    try result.processPart(.{ .text_delta = .{ .text = "!" } });

    try testing.expectEqualStrings("Hello World!", result.getText());
}

test "StreamTextResult processes finish event" {
    const allocator = testing.allocator;

    const callbacks = ai.StreamCallbacks{
        .on_part = struct {
            fn f(_: ai.StreamPart, _: ?*anyopaque) void {}
        }.f,
        .on_error = struct {
            fn f(_: anyerror, _: ?*anyopaque) void {}
        }.f,
        .on_complete = struct {
            fn f(_: ?*anyopaque) void {}
        }.f,
    };

    const provider = @import("provider");
    const LanguageModelV3 = provider.language_model_v3.LanguageModelV3;
    const model: LanguageModelV3 = undefined;

    var result = ai.StreamTextResult.init(allocator, .{
        .model = @constCast(&model),
        .prompt = "Test prompt",
        .callbacks = callbacks,
    });
    defer result.deinit();

    // Process finish event
    try result.processPart(.{
        .finish = .{
            .finish_reason = .stop,
            .usage = .{ .input_tokens = 10, .output_tokens = 20 },
            .total_usage = .{ .input_tokens = 10, .output_tokens = 20 },
        },
    });

    try testing.expect(result.is_complete);
    try testing.expectEqual(ai.FinishReason.stop, result.finish_reason.?);
    try testing.expectEqual(@as(?u64, 10), result.usage.input_tokens);
    try testing.expectEqual(@as(?u64, 20), result.usage.output_tokens);
}

test "StreamTextResult accumulates reasoning" {
    const allocator = testing.allocator;

    const callbacks = ai.StreamCallbacks{
        .on_part = struct {
            fn f(_: ai.StreamPart, _: ?*anyopaque) void {}
        }.f,
        .on_error = struct {
            fn f(_: anyerror, _: ?*anyopaque) void {}
        }.f,
        .on_complete = struct {
            fn f(_: ?*anyopaque) void {}
        }.f,
    };

    const provider = @import("provider");
    const LanguageModelV3 = provider.language_model_v3.LanguageModelV3;
    const model: LanguageModelV3 = undefined;

    var result = ai.StreamTextResult.init(allocator, .{
        .model = @constCast(&model),
        .prompt = "Test prompt",
        .callbacks = callbacks,
    });
    defer result.deinit();

    // Simulate reasoning deltas
    try result.processPart(.{ .reasoning_delta = .{ .text = "Let me think" } });
    try result.processPart(.{ .reasoning_delta = .{ .text = " about this..." } });

    try testing.expectEqualStrings("Let me think about this...", result.getReasoningText().?);
}
