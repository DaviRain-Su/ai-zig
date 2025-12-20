const std = @import("std");

pub const embedding_model_v3 = @import("embedding-model-v3.zig");
pub const EmbeddingModelV3 = embedding_model_v3.EmbeddingModelV3;
pub const EmbeddingModelCallOptions = embedding_model_v3.EmbeddingModelCallOptions;
pub const implementEmbeddingModel = embedding_model_v3.implementEmbeddingModel;
pub const asEmbeddingModel = embedding_model_v3.asEmbeddingModel;

pub const embedding_model_v3_embedding = @import("embedding-model-v3-embedding.zig");
pub const EmbeddingModelV3Embedding = embedding_model_v3_embedding.EmbeddingModelV3Embedding;
pub const Embedding = embedding_model_v3_embedding.Embedding;

test {
    std.testing.refAllDecls(@This());
}
