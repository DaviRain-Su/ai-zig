const std = @import("std");
const client_mod = @import("client.zig");

/// HTTP client implementation using Zig's standard library.
/// This provides a basic HTTP client that can be used for API requests.
pub const StdHttpClient = struct {
    allocator: std.mem.Allocator,
    http_client: std.http.Client,

    const Self = @This();

    /// Initialize a new HTTP client
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .http_client = std.http.Client{ .allocator = allocator },
        };
    }

    /// Deinitialize the HTTP client
    pub fn deinit(self: *Self) void {
        self.http_client.deinit();
    }

    /// Get the HttpClient interface for this implementation
    pub fn asInterface(self: *Self) client_mod.HttpClient {
        return .{
            .vtable = &vtable,
            .impl = self,
        };
    }

    const vtable = client_mod.HttpClient.VTable{
        .request = doRequest,
        .requestStreaming = doRequestStreaming,
        .cancel = null, // TODO: Implement cancellation
    };

    fn doRequest(
        impl: *anyopaque,
        req: client_mod.HttpClient.Request,
        allocator: std.mem.Allocator,
        on_response: *const fn (ctx: ?*anyopaque, response: client_mod.HttpClient.Response) void,
        on_error: *const fn (ctx: ?*anyopaque, err: client_mod.HttpClient.HttpError) void,
        ctx: ?*anyopaque,
    ) void {
        const self: *Self = @ptrCast(@alignCast(impl));
        _ = self;

        // Parse the URL
        const uri = std.Uri.parse(req.url) catch {
            on_error(ctx, .{
                .kind = .invalid_response,
                .message = "Invalid URL",
            });
            return;
        };

        // Create the request
        var server_header_buffer: [16 * 1024]u8 = undefined;
        var http_request = std.http.Client.open(
            &self.http_client,
            switch (req.method) {
                .GET => .GET,
                .POST => .POST,
                .PUT => .PUT,
                .DELETE => .DELETE,
                .PATCH => .PATCH,
                .HEAD => .HEAD,
                .OPTIONS => .OPTIONS,
            },
            uri,
            .{
                .server_header_buffer = &server_header_buffer,
                .extra_headers = convertHeaders(req.headers, allocator) catch {
                    on_error(ctx, .{
                        .kind = .unknown,
                        .message = "Failed to convert headers",
                    });
                    return;
                },
            },
        ) catch |err| {
            on_error(ctx, .{
                .kind = mapError(err),
                .message = "Failed to open connection",
            });
            return;
        };
        defer http_request.deinit();

        // Send the request body if present
        if (req.body) |body| {
            http_request.write(body) catch |err| {
                on_error(ctx, .{
                    .kind = mapError(err),
                    .message = "Failed to write request body",
                });
                return;
            };
        }

        // Finish sending and wait for response
        http_request.finish() catch |err| {
            on_error(ctx, .{
                .kind = mapError(err),
                .message = "Failed to finish request",
            });
            return;
        };

        http_request.wait() catch |err| {
            on_error(ctx, .{
                .kind = mapError(err),
                .message = "Failed to receive response",
            });
            return;
        };

        // Read the response body
        const body = http_request.reader().readAllAlloc(allocator, 10 * 1024 * 1024) catch |err| {
            on_error(ctx, .{
                .kind = mapError(err),
                .message = "Failed to read response body",
            });
            return;
        };

        // Build response headers
        var response_headers = std.ArrayList(client_mod.HttpClient.Header).init(allocator);
        defer response_headers.deinit();

        var header_iter = http_request.response.iterateHeaders();
        while (header_iter.next()) |header| {
            response_headers.append(.{
                .name = allocator.dupe(u8, header.name) catch continue,
                .value = allocator.dupe(u8, header.value) catch continue,
            }) catch continue;
        }

        on_response(ctx, .{
            .status_code = @intFromEnum(http_request.response.status),
            .headers = response_headers.toOwnedSlice() catch &.{},
            .body = body,
        });
    }

    fn doRequestStreaming(
        impl: *anyopaque,
        req: client_mod.HttpClient.Request,
        allocator: std.mem.Allocator,
        callbacks: client_mod.HttpClient.StreamCallbacks,
    ) void {
        const self: *Self = @ptrCast(@alignCast(impl));
        _ = self;

        // Parse the URL
        const uri = std.Uri.parse(req.url) catch {
            callbacks.on_error(callbacks.ctx, .{
                .kind = .invalid_response,
                .message = "Invalid URL",
            });
            return;
        };

        // Create the request
        var server_header_buffer: [16 * 1024]u8 = undefined;
        var http_request = std.http.Client.open(
            &self.http_client,
            switch (req.method) {
                .GET => .GET,
                .POST => .POST,
                .PUT => .PUT,
                .DELETE => .DELETE,
                .PATCH => .PATCH,
                .HEAD => .HEAD,
                .OPTIONS => .OPTIONS,
            },
            uri,
            .{
                .server_header_buffer = &server_header_buffer,
                .extra_headers = convertHeaders(req.headers, allocator) catch {
                    callbacks.on_error(callbacks.ctx, .{
                        .kind = .unknown,
                        .message = "Failed to convert headers",
                    });
                    return;
                },
            },
        ) catch |err| {
            callbacks.on_error(callbacks.ctx, .{
                .kind = mapError(err),
                .message = "Failed to open connection",
            });
            return;
        };
        defer http_request.deinit();

        // Send request body if present
        if (req.body) |body| {
            http_request.write(body) catch |err| {
                callbacks.on_error(callbacks.ctx, .{
                    .kind = mapError(err),
                    .message = "Failed to write request body",
                });
                return;
            };
        }

        // Finish sending
        http_request.finish() catch |err| {
            callbacks.on_error(callbacks.ctx, .{
                .kind = mapError(err),
                .message = "Failed to finish request",
            });
            return;
        };

        http_request.wait() catch |err| {
            callbacks.on_error(callbacks.ctx, .{
                .kind = mapError(err),
                .message = "Failed to receive response headers",
            });
            return;
        };

        // Notify headers if callback is set
        if (callbacks.on_headers) |on_headers| {
            var response_headers = std.ArrayList(client_mod.HttpClient.Header).init(allocator);
            defer response_headers.deinit();

            var header_iter = http_request.response.iterateHeaders();
            while (header_iter.next()) |header| {
                response_headers.append(.{
                    .name = allocator.dupe(u8, header.name) catch continue,
                    .value = allocator.dupe(u8, header.value) catch continue,
                }) catch continue;
            }

            on_headers(
                callbacks.ctx,
                @intFromEnum(http_request.response.status),
                response_headers.items,
            );
        }

        // Read response body in chunks
        var buffer: [8192]u8 = undefined;
        while (true) {
            const bytes_read = http_request.reader().read(&buffer) catch |err| {
                callbacks.on_error(callbacks.ctx, .{
                    .kind = mapError(err),
                    .message = "Failed to read response chunk",
                });
                return;
            };

            if (bytes_read == 0) break;

            callbacks.on_chunk(callbacks.ctx, buffer[0..bytes_read]);
        }

        callbacks.on_complete(callbacks.ctx);
    }

    fn convertHeaders(
        headers: []const client_mod.HttpClient.Header,
        allocator: std.mem.Allocator,
    ) ![]std.http.Header {
        var result = try allocator.alloc(std.http.Header, headers.len);
        for (headers, 0..) |h, i| {
            result[i] = .{
                .name = h.name,
                .value = h.value,
            };
        }
        return result;
    }

    fn mapError(err: anyerror) client_mod.HttpClient.HttpError.ErrorKind {
        return switch (err) {
            error.ConnectionRefused, error.ConnectionResetByPeer => .connection_failed,
            error.Timeout => .timeout,
            error.TlsFailure, error.CertificateIssue => .ssl_error,
            else => .unknown,
        };
    }
};

test "StdHttpClient initialization" {
    const allocator = std.testing.allocator;

    var client = StdHttpClient.init(allocator);
    defer client.deinit();

    const interface = client.asInterface();
    _ = interface;
}
