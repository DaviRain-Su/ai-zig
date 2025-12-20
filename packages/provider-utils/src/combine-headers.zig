const std = @import("std");
const http_client = @import("http/client.zig");

/// Combine multiple header maps into a single map.
/// Later headers override earlier ones with the same name.
pub fn combineHeaders(
    allocator: std.mem.Allocator,
    header_sets: []const ?[]const http_client.HttpClient.Header,
) ![]http_client.HttpClient.Header {
    var result = std.StringHashMap([]const u8).init(allocator);
    defer result.deinit();

    // Merge all header sets
    for (header_sets) |maybe_headers| {
        if (maybe_headers) |headers| {
            for (headers) |header| {
                try result.put(header.name, header.value);
            }
        }
    }

    // Convert to slice
    var list = std.ArrayList(http_client.HttpClient.Header).init(allocator);
    var iter = result.iterator();
    while (iter.next()) |entry| {
        try list.append(.{
            .name = entry.key_ptr.*,
            .value = entry.value_ptr.*,
        });
    }

    return list.toOwnedSlice();
}

/// Combine headers from slices without allocation (returns iterator)
pub const HeaderIterator = struct {
    header_sets: []const ?[]const http_client.HttpClient.Header,
    current_set: usize,
    current_idx: usize,
    seen: std.StringHashMap(void),

    pub fn init(
        allocator: std.mem.Allocator,
        header_sets: []const ?[]const http_client.HttpClient.Header,
    ) HeaderIterator {
        return .{
            .header_sets = header_sets,
            .current_set = 0,
            .current_idx = 0,
            .seen = std.StringHashMap(void).init(allocator),
        };
    }

    pub fn deinit(self: *HeaderIterator) void {
        self.seen.deinit();
    }

    pub fn next(self: *HeaderIterator) ?http_client.HttpClient.Header {
        while (self.current_set < self.header_sets.len) {
            if (self.header_sets[self.current_set]) |headers| {
                while (self.current_idx < headers.len) {
                    const header = headers[self.current_idx];
                    self.current_idx += 1;

                    // Skip if already seen (earlier takes precedence in reverse order)
                    if (!self.seen.contains(header.name)) {
                        self.seen.put(header.name, {}) catch continue;
                        return header;
                    }
                }
            }
            self.current_set += 1;
            self.current_idx = 0;
        }
        return null;
    }
};

/// Create combined headers with specific content type
pub fn combineHeadersWithContentType(
    allocator: std.mem.Allocator,
    content_type: []const u8,
    custom_headers: ?[]const http_client.HttpClient.Header,
) ![]http_client.HttpClient.Header {
    const content_type_header = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = content_type },
    };

    return combineHeaders(allocator, &.{
        &content_type_header,
        custom_headers,
    });
}

/// Add authorization header to existing headers
pub fn addAuthorizationHeader(
    allocator: std.mem.Allocator,
    existing_headers: ?[]const http_client.HttpClient.Header,
    auth_type: []const u8,
    token: []const u8,
) ![]http_client.HttpClient.Header {
    const auth_value = try std.fmt.allocPrint(allocator, "{s} {s}", .{ auth_type, token });

    const auth_header = [_]http_client.HttpClient.Header{
        .{ .name = "Authorization", .value = auth_value },
    };

    return combineHeaders(allocator, &.{
        existing_headers,
        &auth_header,
    });
}

/// Add bearer token authorization
pub fn addBearerToken(
    allocator: std.mem.Allocator,
    existing_headers: ?[]const http_client.HttpClient.Header,
    token: []const u8,
) ![]http_client.HttpClient.Header {
    return addAuthorizationHeader(allocator, existing_headers, "Bearer", token);
}

test "combineHeaders basic" {
    const allocator = std.testing.allocator;

    const headers1 = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = "application/json" },
        .{ .name = "Accept", .value = "application/json" },
    };

    const headers2 = [_]http_client.HttpClient.Header{
        .{ .name = "Authorization", .value = "Bearer token" },
    };

    const combined = try combineHeaders(allocator, &.{ &headers1, &headers2 });
    defer allocator.free(combined);

    try std.testing.expectEqual(@as(usize, 3), combined.len);
}

test "combineHeaders override" {
    const allocator = std.testing.allocator;

    const headers1 = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = "text/plain" },
    };

    const headers2 = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = "application/json" },
    };

    const combined = try combineHeaders(allocator, &.{ &headers1, &headers2 });
    defer allocator.free(combined);

    try std.testing.expectEqual(@as(usize, 1), combined.len);
    try std.testing.expectEqualStrings("application/json", combined[0].value);
}

test "combineHeaders with null" {
    const allocator = std.testing.allocator;

    const headers1 = [_]http_client.HttpClient.Header{
        .{ .name = "Content-Type", .value = "application/json" },
    };

    const combined = try combineHeaders(allocator, &.{ &headers1, null });
    defer allocator.free(combined);

    try std.testing.expectEqual(@as(usize, 1), combined.len);
}
