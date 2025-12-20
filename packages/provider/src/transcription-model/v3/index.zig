const std = @import("std");

pub const transcription_model_v3 = @import("transcription-model-v3.zig");
pub const TranscriptionModelV3 = transcription_model_v3.TranscriptionModelV3;
pub const TranscriptionModelV3CallOptions = transcription_model_v3.TranscriptionModelV3CallOptions;
pub const TranscriptionSegment = transcription_model_v3.TranscriptionSegment;
pub const implementTranscriptionModel = transcription_model_v3.implementTranscriptionModel;
pub const asTranscriptionModel = transcription_model_v3.asTranscriptionModel;

test {
    std.testing.refAllDecls(@This());
}
