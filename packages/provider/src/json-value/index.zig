// JSON Value types and utilities
// Re-exports from json-value and is-json modules

pub const json_value = @import("json-value.zig");
pub const is_json = @import("is-json.zig");

// Type exports
pub const JsonValue = json_value.JsonValue;
pub const JsonObject = json_value.JsonObject;
pub const JsonArray = json_value.JsonArray;

// Helper function
pub const jsonValue = json_value.jsonValue;

// Validation functions
pub const isJsonValue = is_json.isJsonValue;
pub const isJsonArray = is_json.isJsonArray;
pub const isJsonObject = is_json.isJsonObject;
pub const isValidJsonValue = is_json.isValidJsonValue;
pub const isValidJsonArray = is_json.isValidJsonArray;
pub const isValidJsonObject = is_json.isValidJsonObject;

test {
    // Run all tests from submodules
    @import("std").testing.refAllDecls(@This());
}
