const std = @import("std");

/// HTTP client interface for making API requests.
/// This interface allows for different HTTP client implementations to be used.
pub const HttpClient = struct {
    vtable: *const VTable,
    impl: *anyopaque,

    pub const VTable = struct {
        /// Make a non-streaming HTTP request
        request: *const fn (
            impl: *anyopaque,
            req: Request,
            allocator: std.mem.Allocator,
            on_response: *const fn (ctx: ?*anyopaque, response: Response) void,
            on_error: *const fn (ctx: ?*anyopaque, err: HttpError) void,
            ctx: ?*anyopaque,
        ) void,

        /// Make a streaming HTTP request
        requestStreaming: *const fn (
            impl: *anyopaque,
            req: Request,
            allocator: std.mem.Allocator,
            callbacks: StreamCallbacks,
        ) void,

        /// Cancel an ongoing request
        cancel: ?*const fn (impl: *anyopaque) void,
    };

    /// HTTP request configuration
    pub const Request = struct {
        method: Method,
        url: []const u8,
        headers: []const Header,
        body: ?[]const u8 = null,
        timeout_ms: ?u64 = null,
    };

    /// HTTP methods
    pub const Method = enum {
        GET,
        POST,
        PUT,
        DELETE,
        PATCH,
        HEAD,
        OPTIONS,

        pub fn toString(self: Method) []const u8 {
            return switch (self) {
                .GET => "GET",
                .POST => "POST",
                .PUT => "PUT",
                .DELETE => "DELETE",
                .PATCH => "PATCH",
                .HEAD => "HEAD",
                .OPTIONS => "OPTIONS",
            };
        }
    };

    /// HTTP header
    pub const Header = struct {
        name: []const u8,
        value: []const u8,
    };

    /// HTTP response
    pub const Response = struct {
        status_code: u16,
        headers: []const Header,
        body: []const u8,

        /// Check if the response indicates success (2xx status)
        pub fn isSuccess(self: Response) bool {
            return self.status_code >= 200 and self.status_code < 300;
        }

        /// Check if the response is a client error (4xx status)
        pub fn isClientError(self: Response) bool {
            return self.status_code >= 400 and self.status_code < 500;
        }

        /// Check if the response is a server error (5xx status)
        pub fn isServerError(self: Response) bool {
            return self.status_code >= 500;
        }

        /// Get a header value by name (case-insensitive)
        pub fn getHeader(self: Response, name: []const u8) ?[]const u8 {
            for (self.headers) |header| {
                if (std.ascii.eqlIgnoreCase(header.name, name)) {
                    return header.value;
                }
            }
            return null;
        }
    };

    /// HTTP error information
    pub const HttpError = struct {
        kind: ErrorKind,
        message: []const u8,
        status_code: ?u16 = null,
        response_body: ?[]const u8 = null,

        pub const ErrorKind = enum {
            connection_failed,
            timeout,
            ssl_error,
            invalid_response,
            server_error,
            aborted,
            dns_error,
            too_many_redirects,
            unknown,
        };

        /// Check if the error is retryable
        pub fn isRetryable(self: HttpError) bool {
            return switch (self.kind) {
                .timeout, .connection_failed, .server_error => true,
                else => {
                    if (self.status_code) |code| {
                        return code == 408 or code == 429 or code >= 500;
                    }
                    return false;
                },
            };
        }
    };

    /// Callbacks for streaming responses
    pub const StreamCallbacks = struct {
        /// Called when response headers are received
        on_headers: ?*const fn (ctx: ?*anyopaque, status_code: u16, headers: []const Header) void = null,
        /// Called for each chunk of data received
        on_chunk: *const fn (ctx: ?*anyopaque, chunk: []const u8) void,
        /// Called when the stream completes successfully
        on_complete: *const fn (ctx: ?*anyopaque) void,
        /// Called when an error occurs
        on_error: *const fn (ctx: ?*anyopaque, err: HttpError) void,
        /// User context passed to all callbacks
        ctx: ?*anyopaque = null,
    };

    /// Make a non-streaming HTTP request
    pub fn request(
        self: HttpClient,
        req: Request,
        allocator: std.mem.Allocator,
        on_response: *const fn (ctx: ?*anyopaque, response: Response) void,
        on_error: *const fn (ctx: ?*anyopaque, err: HttpError) void,
        ctx: ?*anyopaque,
    ) void {
        self.vtable.request(self.impl, req, allocator, on_response, on_error, ctx);
    }

    /// Make a streaming HTTP request
    pub fn requestStreaming(
        self: HttpClient,
        req: Request,
        allocator: std.mem.Allocator,
        callbacks: StreamCallbacks,
    ) void {
        self.vtable.requestStreaming(self.impl, req, allocator, callbacks);
    }

    /// Cancel an ongoing request (if supported)
    pub fn cancel(self: HttpClient) void {
        if (self.vtable.cancel) |cancel_fn| {
            cancel_fn(self.impl);
        }
    }
};

/// Builder for constructing HTTP requests
pub const RequestBuilder = struct {
    request: HttpClient.Request,
    headers_list: std.ArrayList(HttpClient.Header),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .request = .{
                .method = .GET,
                .url = "",
                .headers = &.{},
            },
            .headers_list = std.ArrayList(HttpClient.Header).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.headers_list.deinit();
    }

    pub fn method(self: *Self, m: HttpClient.Method) *Self {
        self.request.method = m;
        return self;
    }

    pub fn url(self: *Self, u: []const u8) *Self {
        self.request.url = u;
        return self;
    }

    pub fn header(self: *Self, name: []const u8, value: []const u8) !*Self {
        try self.headers_list.append(.{ .name = name, .value = value });
        self.request.headers = self.headers_list.items;
        return self;
    }

    pub fn body(self: *Self, b: []const u8) *Self {
        self.request.body = b;
        return self;
    }

    pub fn timeout(self: *Self, ms: u64) *Self {
        self.request.timeout_ms = ms;
        return self;
    }

    pub fn build(self: *Self) HttpClient.Request {
        self.request.headers = self.headers_list.items;
        return self.request;
    }
};

test "RequestBuilder" {
    const allocator = std.testing.allocator;

    var builder = RequestBuilder.init(allocator);
    defer builder.deinit();

    _ = try builder.method(.POST)
        .url("https://api.example.com/v1/chat")
        .header("Content-Type", "application/json")
        .header("Authorization", "Bearer token123");
    _ = builder.body("{\"message\": \"hello\"}")
        .timeout(30000);

    const req = builder.build();

    try std.testing.expectEqual(HttpClient.Method.POST, req.method);
    try std.testing.expectEqualStrings("https://api.example.com/v1/chat", req.url);
    try std.testing.expectEqual(@as(usize, 2), req.headers.len);
    try std.testing.expectEqual(@as(?u64, 30000), req.timeout_ms);
}

test "Response helpers" {
    const response = HttpClient.Response{
        .status_code = 200,
        .headers = &.{
            .{ .name = "Content-Type", .value = "application/json" },
            .{ .name = "X-Request-Id", .value = "abc123" },
        },
        .body = "{}",
    };

    try std.testing.expect(response.isSuccess());
    try std.testing.expect(!response.isClientError());
    try std.testing.expect(!response.isServerError());
    try std.testing.expectEqualStrings("application/json", response.getHeader("content-type").?);
    try std.testing.expectEqualStrings("abc123", response.getHeader("X-Request-Id").?);
    try std.testing.expect(response.getHeader("X-Missing") == null);
}
