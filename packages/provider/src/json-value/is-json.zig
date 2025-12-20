const std = @import("std");
const json_value = @import("json-value.zig");

pub const JsonValue = json_value.JsonValue;
pub const JsonObject = json_value.JsonObject;
pub const JsonArray = json_value.JsonArray;

/// Check if an arbitrary value can be represented as a JSON value.
/// In Zig, this is primarily used to validate std.json.Value types.
pub fn isJsonValue(value: std.json.Value) bool {
    return switch (value) {
        .null, .bool, .integer, .float, .string => true,
        .number_string => true,
        .array => |arr| {
            for (arr.items) |item| {
                if (!isJsonValue(item)) return false;
            }
            return true;
        },
        .object => |obj| {
            var iter = obj.iterator();
            while (iter.next()) |entry| {
                if (!isJsonValue(entry.value_ptr.*)) return false;
            }
            return true;
        },
    };
}

/// Check if a std.json.Value is an array where all elements are valid JSON values.
pub fn isJsonArray(value: std.json.Value) bool {
    return switch (value) {
        .array => |arr| {
            for (arr.items) |item| {
                if (!isJsonValue(item)) return false;
            }
            return true;
        },
        else => false,
    };
}

/// Check if a std.json.Value is an object where all values are valid JSON values.
pub fn isJsonObject(value: std.json.Value) bool {
    return switch (value) {
        .object => |obj| {
            var iter = obj.iterator();
            while (iter.next()) |entry| {
                if (!isJsonValue(entry.value_ptr.*)) return false;
            }
            return true;
        },
        else => false,
    };
}

/// Validate that a parsed JsonValue contains only valid JSON types.
/// Since our JsonValue type is already well-typed, this always returns true
/// for values created through normal means.
pub fn isValidJsonValue(value: JsonValue) bool {
    return switch (value) {
        .null, .bool, .integer, .float, .string => true,
        .array => |arr| {
            for (arr) |item| {
                if (!isValidJsonValue(item)) return false;
            }
            return true;
        },
        .object => |obj| {
            var iter = obj.iterator();
            while (iter.next()) |entry| {
                if (!isValidJsonValue(entry.value_ptr.*)) return false;
            }
            return true;
        },
    };
}

/// Check if our JsonArray contains only valid JSON values.
pub fn isValidJsonArray(arr: JsonArray) bool {
    for (arr) |item| {
        if (!isValidJsonValue(item)) return false;
    }
    return true;
}

/// Check if our JsonObject contains only valid JSON values.
pub fn isValidJsonObject(obj: JsonObject) bool {
    var iter = obj.iterator();
    while (iter.next()) |entry| {
        if (!isValidJsonValue(entry.value_ptr.*)) return false;
    }
    return true;
}

test "isJsonValue with std.json.Value" {
    const allocator = std.testing.allocator;

    // Test primitives
    try std.testing.expect(isJsonValue(.null));
    try std.testing.expect(isJsonValue(.{ .bool = true }));
    try std.testing.expect(isJsonValue(.{ .integer = 42 }));
    try std.testing.expect(isJsonValue(.{ .float = 3.14 }));
    try std.testing.expect(isJsonValue(.{ .string = "hello" }));

    // Test array
    var arr = std.json.Array.init(allocator);
    defer arr.deinit();
    try arr.append(.{ .integer = 1 });
    try arr.append(.{ .string = "two" });
    try std.testing.expect(isJsonValue(.{ .array = arr }));

    // Test object
    var obj = std.json.ObjectMap.init(allocator);
    defer obj.deinit();
    try obj.put("key", .{ .bool = true });
    try std.testing.expect(isJsonValue(.{ .object = obj }));
}

test "isJsonArray and isJsonObject" {
    const allocator = std.testing.allocator;

    var arr = std.json.Array.init(allocator);
    defer arr.deinit();
    try arr.append(.{ .integer = 1 });

    try std.testing.expect(isJsonArray(.{ .array = arr }));
    try std.testing.expect(!isJsonArray(.{ .integer = 1 }));

    var obj = std.json.ObjectMap.init(allocator);
    defer obj.deinit();
    try obj.put("key", .{ .bool = true });

    try std.testing.expect(isJsonObject(.{ .object = obj }));
    try std.testing.expect(!isJsonObject(.{ .integer = 1 }));
}
