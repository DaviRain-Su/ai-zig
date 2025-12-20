const std = @import("std");

/// An embedding is a vector, i.e. an array of numbers.
/// It is used to represent text as a vector of word embeddings.
pub const EmbeddingModelV3Embedding = []const f32;

/// Helper functions for working with embeddings
pub const Embedding = struct {
    /// Calculate the dot product of two embeddings
    pub fn dotProduct(a: EmbeddingModelV3Embedding, b: EmbeddingModelV3Embedding) f32 {
        if (a.len != b.len) return 0;

        var sum: f32 = 0;
        for (a, b) |av, bv| {
            sum += av * bv;
        }
        return sum;
    }

    /// Calculate the magnitude (L2 norm) of an embedding
    pub fn magnitude(embedding: EmbeddingModelV3Embedding) f32 {
        var sum: f32 = 0;
        for (embedding) |v| {
            sum += v * v;
        }
        return @sqrt(sum);
    }

    /// Calculate cosine similarity between two embeddings
    pub fn cosineSimilarity(a: EmbeddingModelV3Embedding, b: EmbeddingModelV3Embedding) f32 {
        const dot = dotProduct(a, b);
        const mag_a = magnitude(a);
        const mag_b = magnitude(b);

        if (mag_a == 0 or mag_b == 0) return 0;
        return dot / (mag_a * mag_b);
    }

    /// Calculate Euclidean distance between two embeddings
    pub fn euclideanDistance(a: EmbeddingModelV3Embedding, b: EmbeddingModelV3Embedding) f32 {
        if (a.len != b.len) return std.math.inf(f32);

        var sum: f32 = 0;
        for (a, b) |av, bv| {
            const diff = av - bv;
            sum += diff * diff;
        }
        return @sqrt(sum);
    }

    /// Normalize an embedding to unit length (in-place)
    pub fn normalize(embedding: []f32) void {
        const mag = magnitude(embedding);
        if (mag == 0) return;

        for (embedding) |*v| {
            v.* /= mag;
        }
    }

    /// Clone an embedding
    pub fn clone(allocator: std.mem.Allocator, embedding: EmbeddingModelV3Embedding) ![]f32 {
        return try allocator.dupe(f32, embedding);
    }
};

test "Embedding dotProduct" {
    const a = &[_]f32{ 1.0, 2.0, 3.0 };
    const b = &[_]f32{ 4.0, 5.0, 6.0 };
    const result = Embedding.dotProduct(a, b);
    try std.testing.expectApproxEqAbs(@as(f32, 32.0), result, 0.001);
}

test "Embedding magnitude" {
    const embedding = &[_]f32{ 3.0, 4.0 };
    const result = Embedding.magnitude(embedding);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), result, 0.001);
}

test "Embedding cosineSimilarity" {
    const a = &[_]f32{ 1.0, 0.0 };
    const b = &[_]f32{ 1.0, 0.0 };
    const result = Embedding.cosineSimilarity(a, b);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), result, 0.001);
}

test "Embedding normalize" {
    var embedding = [_]f32{ 3.0, 4.0 };
    Embedding.normalize(&embedding);
    try std.testing.expectApproxEqAbs(@as(f32, 0.6), embedding[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.8), embedding[1], 0.001);
}
