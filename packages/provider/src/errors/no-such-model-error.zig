const std = @import("std");
const ai_sdk_error = @import("ai-sdk-error.zig");

pub const AiSdkError = ai_sdk_error.AiSdkError;
pub const AiSdkErrorInfo = ai_sdk_error.AiSdkErrorInfo;
pub const NoSuchModelContext = ai_sdk_error.NoSuchModelContext;
pub const ModelType = NoSuchModelContext.ModelType;

/// No Such Model Error - thrown when a requested model doesn't exist
pub const NoSuchModelError = struct {
    info: AiSdkErrorInfo,

    const Self = @This();

    pub const Options = struct {
        model_id: []const u8,
        model_type: ModelType,
        message: ?[]const u8 = null,
    };

    /// Create a new no such model error
    pub fn init(options: Options) Self {
        const msg = options.message orelse "Model not found";

        return Self{
            .info = .{
                .kind = .no_such_model,
                .message = msg,
                .context = .{ .no_such_model = .{
                    .model_id = options.model_id,
                    .model_type = options.model_type,
                } },
            },
        };
    }

    /// Get the model ID that wasn't found
    pub fn modelId(self: Self) []const u8 {
        if (self.info.context) |ctx| {
            if (ctx == .no_such_model) {
                return ctx.no_such_model.model_id;
            }
        }
        return "";
    }

    /// Get the model type
    pub fn modelType(self: Self) ?ModelType {
        if (self.info.context) |ctx| {
            if (ctx == .no_such_model) {
                return ctx.no_such_model.model_type;
            }
        }
        return null;
    }

    /// Get the error message
    pub fn message(self: Self) []const u8 {
        return self.info.message;
    }

    /// Convert to AiSdkError
    pub fn toError(self: Self) AiSdkError {
        _ = self;
        return error.NoSuchModelError;
    }

    /// Get model type as string
    pub fn modelTypeString(self: Self) []const u8 {
        if (self.modelType()) |mt| {
            return switch (mt) {
                .language_model => "languageModel",
                .embedding_model => "embeddingModel",
                .image_model => "imageModel",
                .transcription_model => "transcriptionModel",
                .speech_model => "speechModel",
                .reranking_model => "rerankingModel",
            };
        }
        return "unknown";
    }
};

test "NoSuchModelError creation" {
    const err = NoSuchModelError.init(.{
        .model_id = "gpt-5-turbo",
        .model_type = .language_model,
    });

    try std.testing.expectEqualStrings("gpt-5-turbo", err.modelId());
    try std.testing.expectEqual(ModelType.language_model, err.modelType().?);
    try std.testing.expectEqualStrings("languageModel", err.modelTypeString());
}
