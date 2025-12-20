// Middleware Module for Zig AI SDK
//
// This module provides middleware capabilities:
// - Request/response transformation
// - Logging, rate limiting, caching
// - Custom middleware chains

pub const middleware_mod = @import("middleware.zig");

// Re-export types
pub const RequestMiddleware = middleware_mod.RequestMiddleware;
pub const ResponseMiddleware = middleware_mod.ResponseMiddleware;
pub const MiddlewareRequest = middleware_mod.MiddlewareRequest;
pub const MiddlewareResponse = middleware_mod.MiddlewareResponse;
pub const MiddlewareContext = middleware_mod.MiddlewareContext;
pub const MiddlewareChain = middleware_mod.MiddlewareChain;
pub const DefaultSettingsMiddleware = middleware_mod.DefaultSettingsMiddleware;
pub const RateLimitMiddleware = middleware_mod.RateLimitMiddleware;
pub const RetryConfig = middleware_mod.RetryConfig;
pub const CacheConfig = middleware_mod.CacheConfig;

// Re-export functions
pub const createLoggingMiddleware = middleware_mod.createLoggingMiddleware;

test {
    @import("std").testing.refAllDecls(@This());
}
