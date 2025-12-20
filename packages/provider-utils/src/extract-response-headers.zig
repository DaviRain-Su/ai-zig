const std = @import("std");
const http_client = @import("http/client.zig");

/// Extract headers from a response into a hash map.
/// Returns a map of header name to value pairs.
pub fn extractResponseHeaders(
    allocator: std.mem.Allocator,
    headers: []const http_client.HttpClient.Header,
) !std.StringHashMap([]const u8) {
    var result = std.StringHashMap([]const u8).init(allocator);
    errdefer result.deinit();

    for (headers) |header| {
        // Duplicate the strings to ensure they're owned by the allocator
        const name = try allocator.dupe(u8, header.name);
        errdefer allocator.free(name);
        const value = try allocator.dupe(u8, header.value);

        try result.put(name, value);
    }

    return result;
}

/// Extract headers from a response into a slice of Header structs.
/// This is useful when you want to preserve the original format.
pub fn extractResponseHeadersSlice(
    allocator: std.mem.Allocator,
    headers: []const http_client.HttpClient.Header,
) ![]http_client.HttpClient.Header {
    var result = try allocator.alloc(http_client.HttpClient.Header, headers.len);
    errdefer allocator.free(result);

    for (headers, 0..) |header, i| {
        result[i] = .{
            .name = try allocator.dupe(u8, header.name),
            .value = try allocator.dupe(u8, header.value),
        };
    }

    return result;
}

/// Get a specific header value by name (case-insensitive).
pub fn getHeaderValue(
    headers: []const http_client.HttpClient.Header,
    name: []const u8,
) ?[]const u8 {
    for (headers) |header| {
        if (std.ascii.eqlIgnoreCase(header.name, name)) {
            return header.value;
        }
    }
    return null;
}

/// Get the Content-Type header value
pub fn getContentType(
    headers: []const http_client.HttpClient.Header,
) ?[]const u8 {
    return getHeaderValue(headers, "Content-Type");
}

/// Get the Content-Length header value as an integer
pub fn getContentLength(
    headers: []const http_client.HttpClient.Header,
) ?u64 {
    if (getHeaderValue(headers, "Content-Length")) |value| {
        return std.fmt.parseInt(u64, value, 10) catch null;
    }
    return null;
}

/// Check if the response has a specific content type
pub fn hasContentType(
    headers: []const http_client.HttpClient.Header,
    content_type: []const u8,
) bool {
    if (getContentType(headers)) |ct| {
        // Check if content type starts with the expected type
        // This handles cases like "application/json; charset=utf-8"
        return std.mem.startsWith(u8, ct, content_type);
    }
    return false;
}

/// Check if the response is JSON
pub fn isJsonResponse(
    headers: []const http_client.HttpClient.Header,
) bool {
    return hasContentType(headers, "application/json");
}

/// Check if the response is a server-sent events stream
pub fn isEventStreamResponse(
    headers: []const http_client.HttpClient.Header,
) bool {
    return hasContentType(headers, "text/event-stream");
}

/// Extract common response metadata
pub const ResponseMetadata = struct {
    content_type: ?[]const u8,
    content_length: ?u64,
    request_id: ?[]const u8,
    rate_limit_remaining: ?u32,
    rate_limit_reset: ?i64,
};

pub fn extractResponseMetadata(
    headers: []const http_client.HttpClient.Header,
) ResponseMetadata {
    return .{
        .content_type = getContentType(headers),
        .content_length = getContentLength(headers),
        .request_id = getHeaderValue(headers, "X-Request-Id") orelse
            getHeaderValue(headers, "x-request-id"),
        .rate_limit_remaining = if (getHeaderValue(headers, "X-RateLimit-Remaining")) |v|
            std.fmt.parseInt(u32, v, 10) catch null
        else
            null,
        .rate_limit_reset = if (getHeaderValue(headers, "X-RateLimit-Reset")) |v|
            std.fmt.parseInt(i64, v, 10) catch null
        else
            null,
    };
}

test "extractResponseHeaders" {
    const allocator = std.testing.allocator;

    const headers = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = "application/json" },
        .{ .name = "X-Request-Id", .value = "abc123" },
    };

    var extracted = try extractResponseHeaders(allocator, &headers);
    defer {
        var iter = extracted.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.*);
        }
        extracted.deinit();
    }

    try std.testing.expectEqualStrings("application/json", extracted.get("Content-Type").?);
    try std.testing.expectEqualStrings("abc123", extracted.get("X-Request-Id").?);
}

test "getHeaderValue case insensitive" {
    const headers = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = "application/json" },
    };

    try std.testing.expectEqualStrings(
        "application/json",
        getHeaderValue(&headers, "content-type").?,
    );
    try std.testing.expectEqualStrings(
        "application/json",
        getHeaderValue(&headers, "CONTENT-TYPE").?,
    );
}

test "isJsonResponse" {
    const headers = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = "application/json; charset=utf-8" },
    };

    try std.testing.expect(isJsonResponse(&headers));
    try std.testing.expect(!isEventStreamResponse(&headers));
}

test "isEventStreamResponse" {
    const headers = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = "text/event-stream" },
    };

    try std.testing.expect(isEventStreamResponse(&headers));
    try std.testing.expect(!isJsonResponse(&headers));
}
