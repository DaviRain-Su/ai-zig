// Generate Object Module for Zig AI SDK
//
// This module provides structured object generation capabilities:
// - generateObject: Non-streaming object generation
// - streamObject: Streaming object generation with callbacks

pub const generate_object_mod = @import("generate-object.zig");
pub const stream_object_mod = @import("stream-object.zig");

// Re-export generateObject types
pub const generateObject = generate_object_mod.generateObject;
pub const GenerateObjectResult = generate_object_mod.GenerateObjectResult;
pub const GenerateObjectOptions = generate_object_mod.GenerateObjectOptions;
pub const GenerateObjectError = generate_object_mod.GenerateObjectError;
pub const Schema = generate_object_mod.Schema;
pub const OutputMode = generate_object_mod.OutputMode;
pub const parseJsonOutput = generate_object_mod.parseJsonOutput;
pub const validateAgainstSchema = generate_object_mod.validateAgainstSchema;

// Re-export streamObject types
pub const streamObject = stream_object_mod.streamObject;
pub const StreamObjectResult = stream_object_mod.StreamObjectResult;
pub const StreamObjectOptions = stream_object_mod.StreamObjectOptions;
pub const StreamObjectError = stream_object_mod.StreamObjectError;
pub const ObjectStreamCallbacks = stream_object_mod.ObjectStreamCallbacks;
pub const ObjectStreamPart = stream_object_mod.ObjectStreamPart;
pub const PartialDelta = stream_object_mod.PartialDelta;
pub const ObjectUpdate = stream_object_mod.ObjectUpdate;
pub const ObjectFinish = stream_object_mod.ObjectFinish;
pub const ObjectError = stream_object_mod.ObjectError;

test {
    @import("std").testing.refAllDecls(@This());
}
