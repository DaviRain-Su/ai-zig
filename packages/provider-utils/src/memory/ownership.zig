const std = @import("std");
const arena_mod = @import("arena.zig");

/// Ownership marker for documentation purposes.
/// This enum documents who owns the memory for a given piece of data.
pub const Ownership = enum {
    /// Data owned by request arena, freed when request completes.
    /// Do not store references to this data past the request lifecycle.
    request_owned,

    /// Data owned by response arena, user must call deinit.
    /// This data will persist until the user explicitly frees it.
    user_owned,

    /// Data is a view into existing memory, do not free.
    /// The underlying memory is owned by something else.
    borrowed,

    /// Data is statically allocated.
    /// This memory is valid for the lifetime of the program.
    static,
};

/// A wrapper type that explicitly marks ownership of data.
/// This is primarily for documentation and type safety.
pub fn Owned(comptime T: type, comptime ownership: Ownership) type {
    return struct {
        data: T,

        const Self = @This();
        pub const ownership_type = ownership;

        pub fn init(data: T) Self {
            return .{ .data = data };
        }

        /// Get the underlying data
        pub fn get(self: Self) T {
            return self.data;
        }

        /// Get a mutable reference to the underlying data
        pub fn getMut(self: *Self) *T {
            return &self.data;
        }
    };
}

/// Request-owned data wrapper
pub fn RequestOwned(comptime T: type) type {
    return Owned(T, .request_owned);
}

/// User-owned data wrapper
pub fn UserOwned(comptime T: type) type {
    return Owned(T, .user_owned);
}

/// Borrowed data wrapper
pub fn Borrowed(comptime T: type) type {
    return Owned(T, .borrowed);
}

/// Static data wrapper
pub fn Static(comptime T: type) type {
    return Owned(T, .static);
}

/// Transfer ownership of a slice from request arena to user arena.
/// Returns user-owned data that the caller is responsible for freeing.
pub fn transferOwnership(
    comptime T: type,
    response_arena: *arena_mod.ResponseArena,
    data: []const T,
) ![]T {
    return response_arena.dupe(T, data);
}

/// Transfer ownership of a string from request to user arena.
pub fn transferStringOwnership(
    response_arena: *arena_mod.ResponseArena,
    data: []const u8,
) ![]u8 {
    return response_arena.dupe(u8, data);
}

/// A result type that includes ownership information.
/// The arena field indicates which arena owns the result data.
pub fn OwnedResult(comptime T: type) type {
    return struct {
        value: T,
        arena: *arena_mod.ResponseArena,

        const Self = @This();

        /// Free the result and its associated arena
        pub fn deinit(self: *Self) void {
            self.arena.deinit();
        }
    };
}

/// Create a user-owned copy of data.
/// Use this when you need to return data to the user that outlives the request.
pub fn makeUserOwned(
    comptime T: type,
    allocator: std.mem.Allocator,
    data: T,
) !UserOwned(T) {
    _ = allocator;
    return UserOwned(T).init(data);
}

/// Guidelines for memory management in the SDK:
///
/// 1. Request Lifetime:
///    - Use RequestArena for all temporary allocations during a request
///    - JSON parsing, buffer building, intermediate transformations
///    - Freed automatically when the request completes
///
/// 2. Response Lifetime:
///    - Use ResponseArena for data returned to the user
///    - The user receives the arena or is responsible for freeing
///    - Document clearly what the user needs to free
///
/// 3. Streaming Lifetime:
///    - Use StreamingArena for streaming responses
///    - Each chunk can be processed and released independently
///    - Allows efficient memory usage for long-running streams
///
/// 4. Static Data:
///    - Use for constant strings, schemas, etc.
///    - No need to manage lifecycle
///
/// 5. Borrowed Data:
///    - Views into other data (slices of larger buffers)
///    - Do not free - the owner will handle it
///
/// Example usage:
/// ```zig
/// pub fn generateText(
///     model: LanguageModel,
///     prompt: []const u8,
///     user_allocator: std.mem.Allocator,
/// ) !OwnedResult(GenerateResult) {
///     // Create request arena for temporary allocations
///     var request_arena = RequestArena.init(user_allocator);
///     defer request_arena.deinit();
///
///     // Create response arena for user-owned data
///     var response_arena = ResponseArena.init(user_allocator);
///     errdefer response_arena.deinit();
///
///     // Do work with request_arena...
///     const temp_data = try request_arena.dupe(u8, prompt);
///
///     // Transfer final result to response arena
///     const final_text = try transferStringOwnership(&response_arena, result_text);
///
///     return OwnedResult(GenerateResult){
///         .value = .{ .text = final_text },
///         .arena = &response_arena,
///     };
/// }
/// ```
pub const memory_guidelines = void;

test "Owned wrapper" {
    const data = RequestOwned([]const u8).init("hello");
    try std.testing.expectEqualStrings("hello", data.get());
    try std.testing.expectEqual(Ownership.request_owned, @TypeOf(data).ownership_type);
}

test "UserOwned wrapper" {
    const data = UserOwned(i32).init(42);
    try std.testing.expectEqual(@as(i32, 42), data.get());
    try std.testing.expectEqual(Ownership.user_owned, @TypeOf(data).ownership_type);
}

test "transferOwnership" {
    const backing = std.testing.allocator;

    var request_arena = arena_mod.RequestArena.init(backing);
    defer request_arena.deinit();

    var response_arena = arena_mod.ResponseArena.init(backing);
    defer response_arena.deinit();

    const original = try request_arena.dupe(u8, "original data");
    const transferred = try transferOwnership(u8, &response_arena, original);

    try std.testing.expectEqualStrings("original data", transferred);
}
