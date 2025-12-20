const std = @import("std");
const LanguageModelV3 = @import("../../language-model/v3/index.zig").LanguageModelV3;
const EmbeddingModelV3 = @import("../../embedding-model/v3/index.zig").EmbeddingModelV3;
const ImageModelV3 = @import("../../image-model/v3/index.zig").ImageModelV3;
const SpeechModelV3 = @import("../../speech-model/v3/index.zig").SpeechModelV3;
const TranscriptionModelV3 = @import("../../transcription-model/v3/index.zig").TranscriptionModelV3;

/// Provider for language, text embedding, and image generation models.
pub const ProviderV3 = struct {
    /// VTable for dynamic dispatch
    vtable: *const VTable,
    /// Implementation pointer
    impl: *anyopaque,

    pub const specification_version = "v3";

    /// Virtual function table for provider operations
    pub const VTable = struct {
        /// Get a language model by ID
        languageModel: *const fn (*anyopaque, []const u8) LanguageModelResult,

        /// Get an embedding model by ID
        embeddingModel: *const fn (*anyopaque, []const u8) EmbeddingModelResult,

        /// Get an image model by ID
        imageModel: *const fn (*anyopaque, []const u8) ImageModelResult,

        /// Get a transcription model by ID (optional)
        transcriptionModel: ?*const fn (*anyopaque, []const u8) TranscriptionModelResult = null,

        /// Get a speech model by ID (optional)
        speechModel: ?*const fn (*anyopaque, []const u8) SpeechModelResult = null,
    };

    /// Result types for model retrieval
    pub const LanguageModelResult = union(enum) {
        success: LanguageModelV3,
        no_such_model: []const u8,
        failure: anyerror,
    };

    pub const EmbeddingModelResult = union(enum) {
        success: EmbeddingModelV3,
        no_such_model: []const u8,
        failure: anyerror,
    };

    pub const ImageModelResult = union(enum) {
        success: ImageModelV3,
        no_such_model: []const u8,
        failure: anyerror,
    };

    pub const TranscriptionModelResult = union(enum) {
        success: TranscriptionModelV3,
        no_such_model: []const u8,
        not_supported,
        failure: anyerror,
    };

    pub const SpeechModelResult = union(enum) {
        success: SpeechModelV3,
        no_such_model: []const u8,
        not_supported,
        failure: anyerror,
    };

    const Self = @This();

    /// Returns the language model with the given ID.
    /// @throws NoSuchModelError If no such model exists.
    pub fn languageModel(self: Self, model_id: []const u8) LanguageModelResult {
        return self.vtable.languageModel(self.impl, model_id);
    }

    /// Returns the embedding model with the given ID.
    /// @throws NoSuchModelError If no such model exists.
    pub fn embeddingModel(self: Self, model_id: []const u8) EmbeddingModelResult {
        return self.vtable.embeddingModel(self.impl, model_id);
    }

    /// Returns the image model with the given ID.
    /// @throws NoSuchModelError If no such model exists.
    pub fn imageModel(self: Self, model_id: []const u8) ImageModelResult {
        return self.vtable.imageModel(self.impl, model_id);
    }

    /// Returns the transcription model with the given ID.
    /// Returns not_supported if the provider doesn't support transcription.
    pub fn transcriptionModel(self: Self, model_id: []const u8) TranscriptionModelResult {
        if (self.vtable.transcriptionModel) |func| {
            return func(self.impl, model_id);
        }
        return .not_supported;
    }

    /// Returns the speech model with the given ID.
    /// Returns not_supported if the provider doesn't support speech.
    pub fn speechModel(self: Self, model_id: []const u8) SpeechModelResult {
        if (self.vtable.speechModel) |func| {
            return func(self.impl, model_id);
        }
        return .not_supported;
    }

    /// Check if the provider supports transcription models
    pub fn supportsTranscription(self: Self) bool {
        return self.vtable.transcriptionModel != null;
    }

    /// Check if the provider supports speech models
    pub fn supportsSpeech(self: Self) bool {
        return self.vtable.speechModel != null;
    }
};

/// Helper to implement a provider from a concrete type
pub fn implementProvider(comptime T: type) ProviderV3.VTable {
    return .{
        .languageModel = struct {
            fn languageModel(ptr: *anyopaque, model_id: []const u8) ProviderV3.LanguageModelResult {
                const self: *T = @ptrCast(@alignCast(ptr));
                return self.languageModel(model_id);
            }
        }.languageModel,

        .embeddingModel = struct {
            fn embeddingModel(ptr: *anyopaque, model_id: []const u8) ProviderV3.EmbeddingModelResult {
                const self: *T = @ptrCast(@alignCast(ptr));
                return self.embeddingModel(model_id);
            }
        }.embeddingModel,

        .imageModel = struct {
            fn imageModel(ptr: *anyopaque, model_id: []const u8) ProviderV3.ImageModelResult {
                const self: *T = @ptrCast(@alignCast(ptr));
                return self.imageModel(model_id);
            }
        }.imageModel,

        .transcriptionModel = if (@hasDecl(T, "transcriptionModel")) struct {
            fn transcriptionModel(ptr: *anyopaque, model_id: []const u8) ProviderV3.TranscriptionModelResult {
                const self: *T = @ptrCast(@alignCast(ptr));
                return self.transcriptionModel(model_id);
            }
        }.transcriptionModel else null,

        .speechModel = if (@hasDecl(T, "speechModel")) struct {
            fn speechModel(ptr: *anyopaque, model_id: []const u8) ProviderV3.SpeechModelResult {
                const self: *T = @ptrCast(@alignCast(ptr));
                return self.speechModel(model_id);
            }
        }.speechModel else null,
    };
}

/// Create a ProviderV3 from a concrete implementation
pub fn asProvider(comptime T: type, impl: *T) ProviderV3 {
    const vtable = comptime implementProvider(T);
    return .{
        .vtable = &vtable,
        .impl = impl,
    };
}

test "ProviderV3 specification_version" {
    try std.testing.expectEqualStrings("v3", ProviderV3.specification_version);
}
