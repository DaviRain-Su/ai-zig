const std = @import("std");
const testing = std.testing;
const ai = @import("ai");

// Integration tests for similarity functions

test "cosine similarity - identical vectors" {
    const a = [_]f64{ 1.0, 0.0, 0.0 };
    const b = [_]f64{ 1.0, 0.0, 0.0 };

    const similarity = ai.cosineSimilarity(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 1.0), similarity, 0.0001);
}

test "cosine similarity - orthogonal vectors" {
    const a = [_]f64{ 1.0, 0.0, 0.0 };
    const b = [_]f64{ 0.0, 1.0, 0.0 };

    const similarity = ai.cosineSimilarity(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 0.0), similarity, 0.0001);
}

test "cosine similarity - opposite vectors" {
    const a = [_]f64{ 1.0, 0.0, 0.0 };
    const b = [_]f64{ -1.0, 0.0, 0.0 };

    const similarity = ai.cosineSimilarity(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, -1.0), similarity, 0.0001);
}

test "cosine similarity - arbitrary vectors" {
    const a = [_]f64{ 1.0, 2.0, 3.0 };
    const b = [_]f64{ 4.0, 5.0, 6.0 };

    // Expected: (1*4 + 2*5 + 3*6) / (sqrt(1+4+9) * sqrt(16+25+36))
    //         = 32 / (sqrt(14) * sqrt(77))
    //         = 32 / (3.7417 * 8.7750)
    //         ≈ 0.9746

    const similarity = ai.cosineSimilarity(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 0.9746), similarity, 0.001);
}

test "euclidean distance - same point" {
    const a = [_]f64{ 1.0, 2.0, 3.0 };
    const b = [_]f64{ 1.0, 2.0, 3.0 };

    const distance = ai.euclideanDistance(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 0.0), distance, 0.0001);
}

test "euclidean distance - unit distance" {
    const a = [_]f64{ 0.0, 0.0 };
    const b = [_]f64{ 1.0, 0.0 };

    const distance = ai.euclideanDistance(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 1.0), distance, 0.0001);
}

test "euclidean distance - pythagorean" {
    const a = [_]f64{ 0.0, 0.0 };
    const b = [_]f64{ 3.0, 4.0 };

    const distance = ai.euclideanDistance(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 5.0), distance, 0.0001);
}

test "dot product - simple" {
    const a = [_]f64{ 1.0, 2.0, 3.0 };
    const b = [_]f64{ 4.0, 5.0, 6.0 };

    // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
    const product = ai.dotProduct(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 32.0), product, 0.0001);
}

test "dot product - orthogonal" {
    const a = [_]f64{ 1.0, 0.0 };
    const b = [_]f64{ 0.0, 1.0 };

    const product = ai.dotProduct(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 0.0), product, 0.0001);
}

test "similarity functions - empty vectors" {
    const a = [_]f64{};
    const b = [_]f64{};

    const cosine = ai.cosineSimilarity(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 0.0), cosine, 0.0001);

    const dot = ai.dotProduct(&a, &b);
    try testing.expectApproxEqAbs(@as(f64, 0.0), dot, 0.0001);
}
