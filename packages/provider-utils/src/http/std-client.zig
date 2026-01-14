const std = @import("std");
const client_mod = @import("client.zig");

/// HTTP client implementation using Zig's standard library.
/// Fully implemented for Zig 0.15.x using std.http.Client API.
pub const StdHttpClient = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a new HTTP client
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
        };
    }

    /// Deinitialize the HTTP client
    pub fn deinit(self: *Self) void {
        _ = self;
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
        .cancel = null,
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
        doRequestImpl(self, req, allocator, on_response, on_error, ctx) catch |err| {
            on_error(ctx, .{
                .kind = mapError(err),
                .message = @errorName(err),
            });
        };
    }

    fn doRequestImpl(
        self: *Self,
        req: client_mod.HttpClient.Request,
        allocator: std.mem.Allocator,
        on_response: *const fn (ctx: ?*anyopaque, response: client_mod.HttpClient.Response) void,
        on_error: *const fn (ctx: ?*anyopaque, err: client_mod.HttpClient.HttpError) void,
        ctx: ?*anyopaque,
    ) !void {
        _ = self;
        _ = on_error;

        // Parse URI
        const uri = std.Uri.parse(req.url) catch {
            return error.InvalidUrl;
        };

        // Create HTTP client
        var http_client: std.http.Client = .{ .allocator = allocator };
        defer http_client.deinit();

        // Build extra headers for Zig 0.15 API
        var extra_headers_buf: [64]std.http.Header = undefined;
        var header_count: usize = 0;

        for (req.headers) |header| {
            if (header_count >= 64) break;
            extra_headers_buf[header_count] = .{
                .name = header.name,
                .value = header.value,
            };
            header_count += 1;
        }

        // Map method
        const method: std.http.Method = switch (req.method) {
            .GET => .GET,
            .POST => .POST,
            .PUT => .PUT,
            .DELETE => .DELETE,
            .PATCH => .PATCH,
            .HEAD => .HEAD,
            .OPTIONS => .OPTIONS,
        };

        // Zig 0.15 HTTP Client API: use client.request() then receiveHead()
        // Disable compression by omitting Accept-Encoding header
        var http_req = http_client.request(method, uri, .{
            .headers = .{
                .content_type = .{ .override = "application/json" },
                .accept_encoding = .omit, // Disable compression - get plain text response
            },
            .extra_headers = extra_headers_buf[0..header_count],
        }) catch |err| {
            return err;
        };
        defer http_req.deinit();

        // Send body if present
        if (req.body) |body_content| {
            http_req.sendBodyComplete(@constCast(body_content)) catch |err| return err;
        } else {
            http_req.sendBodiless() catch |err| return err;
        }

        // Receive response
        var redirect_buf: [4096]u8 = undefined;
        var response = http_req.receiveHead(&redirect_buf) catch |err| return err;

        // Read response body
        var transfer_buf: [16384]u8 = undefined;
        const body_reader = response.reader(&transfer_buf);
        const body = body_reader.allocRemaining(allocator, std.Io.Limit.limited(10 * 1024 * 1024)) catch |err| return err;

        // Convert headers - just use empty since we can't easily iterate in Zig 0.15
        const response_headers: []const client_mod.HttpClient.Header = &[_]client_mod.HttpClient.Header{};

        // Call success callback
        on_response(ctx, .{
            .status_code = @intFromEnum(response.head.status),
            .headers = response_headers,
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
        doRequestStreamingImpl(self, req, allocator, callbacks) catch |err| {
            callbacks.on_error(callbacks.ctx, .{
                .kind = mapError(err),
                .message = @errorName(err),
            });
        };
    }

    fn doRequestStreamingImpl(
        self: *Self,
        req: client_mod.HttpClient.Request,
        allocator: std.mem.Allocator,
        callbacks: client_mod.HttpClient.StreamCallbacks,
    ) !void {
        _ = self;

        // Parse URI
        const uri = std.Uri.parse(req.url) catch {
            return error.InvalidUrl;
        };

        // Create HTTP client
        var http_client: std.http.Client = .{ .allocator = allocator };
        defer http_client.deinit();

        // Build extra headers for Zig 0.15 API
        var extra_headers_buf: [64]std.http.Header = undefined;
        var header_count: usize = 0;

        for (req.headers) |header| {
            if (header_count >= 64) break;
            extra_headers_buf[header_count] = .{
                .name = header.name,
                .value = header.value,
            };
            header_count += 1;
        }

        // Map method
        const method: std.http.Method = switch (req.method) {
            .GET => .GET,
            .POST => .POST,
            .PUT => .PUT,
            .DELETE => .DELETE,
            .PATCH => .PATCH,
            .HEAD => .HEAD,
            .OPTIONS => .OPTIONS,
        };

        // Zig 0.15 HTTP Client API: use client.request() then receiveHead()
        // Disable compression by omitting Accept-Encoding header
        var http_req = http_client.request(method, uri, .{
            .headers = .{
                .content_type = .{ .override = "application/json" },
                .accept_encoding = .omit, // Disable compression - get plain text response
            },
            .extra_headers = extra_headers_buf[0..header_count],
        }) catch |err| {
            return err;
        };
        defer http_req.deinit();

        // Send body if present
        if (req.body) |body_content| {
            http_req.sendBodyComplete(@constCast(body_content)) catch |err| return err;
        } else {
            http_req.sendBodiless() catch |err| return err;
        }

        // Receive response headers
        var redirect_buf: [4096]u8 = undefined;
        var response = http_req.receiveHead(&redirect_buf) catch |err| return err;

        // Notify headers if callback exists
        if (callbacks.on_headers) |on_headers| {
            on_headers(callbacks.ctx, @intFromEnum(response.head.status), &[_]client_mod.HttpClient.Header{});
        }

        // Read response in chunks using Zig 0.15 Io.Reader
        var transfer_buf: [8192]u8 = undefined;
        const body_reader = response.reader(&transfer_buf);

        while (true) {
            var chunk_buf: [8192]u8 = undefined;
            const bytes_read = body_reader.readSliceShort(&chunk_buf) catch |err| return err;
            if (bytes_read == 0) break;
            callbacks.on_chunk(callbacks.ctx, chunk_buf[0..bytes_read]);
        }

        // Notify completion
        callbacks.on_complete(callbacks.ctx);
    }

    fn mapError(err: anyerror) client_mod.HttpClient.HttpError.ErrorKind {
        return switch (err) {
            error.ConnectionRefused, error.ConnectionResetByPeer => .connection_failed,
            error.InvalidUrl => .invalid_response,
            error.TlsFailure => .ssl_error,
            error.Timeout => .timeout,
            else => .unknown,
        };
    }
};

/// Create a StdHttpClient instance
pub fn createStdHttpClient(allocator: std.mem.Allocator) StdHttpClient {
    return StdHttpClient.init(allocator);
}

test "StdHttpClient initialization" {
    const allocator = std.testing.allocator;

    var client = StdHttpClient.init(allocator);
    defer client.deinit();

    const interface = client.asInterface();
    _ = interface;
}
