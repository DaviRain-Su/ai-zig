const std = @import("std");

pub const speech_model_v3 = @import("speech-model-v3.zig");
pub const SpeechModelV3 = speech_model_v3.SpeechModelV3;
pub const SpeechModelV3CallOptions = speech_model_v3.SpeechModelV3CallOptions;
pub const implementSpeechModel = speech_model_v3.implementSpeechModel;
pub const asSpeechModel = speech_model_v3.asSpeechModel;

test {
    std.testing.refAllDecls(@This());
}
