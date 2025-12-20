const std = @import("std");

/// Request-scoped arena for allocations that live for a single API call.
/// All allocations made with this arena are freed when the request completes.
/// This is ideal for temporary buffers, parsed JSON, and intermediate data.
pub const RequestArena = struct {
    arena: std.heap.ArenaAllocator,

    const Self = @This();

    /// Initialize a new request arena with the given backing allocator
    pub fn init(backing_allocator: std.mem.Allocator) Self {
        return .{
            .arena = std.heap.ArenaAllocator.init(backing_allocator),
        };
    }

    /// Get the allocator for this arena
    pub fn allocator(self: *Self) std.mem.Allocator {
        return self.arena.allocator();
    }

    /// Reset the arena for reuse (e.g., in connection pools).
    /// This keeps the allocated capacity but marks all memory as free.
    pub fn reset(self: *Self) void {
        _ = self.arena.reset(.retain_capacity);
    }

    /// Free all memory and deinitialize the arena
    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    /// Duplicate a slice of items into the arena
    pub fn dupe(self: *Self, comptime T: type, data: []const T) ![]T {
        return self.allocator().dupe(T, data);
    }

    /// Duplicate a null-terminated string into the arena
    pub fn dupeZ(self: *Self, data: []const u8) ![:0]u8 {
        return self.allocator().dupeZ(u8, data);
    }
};

/// Response arena for user-owned data that outlives the request.
/// Use this to allocate data that will be returned to the user.
/// The user is responsible for calling deinit when they're done with the data.
pub const ResponseArena = struct {
    arena: std.heap.ArenaAllocator,

    const Self = @This();

    /// Initialize a new response arena with the given backing allocator
    pub fn init(backing_allocator: std.mem.Allocator) Self {
        return .{
            .arena = std.heap.ArenaAllocator.init(backing_allocator),
        };
    }

    /// Get the allocator for this arena
    pub fn allocator(self: *Self) std.mem.Allocator {
        return self.arena.allocator();
    }

    /// Free all memory and deinitialize the arena
    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    /// Duplicate data from a request arena to this response arena for user ownership.
    /// This is the primary mechanism for transferring ownership of data to the user.
    pub fn dupe(self: *Self, comptime T: type, data: []const T) ![]T {
        return self.allocator().dupe(T, data);
    }

    /// Duplicate a null-terminated string for user ownership
    pub fn dupeZ(self: *Self, data: []const u8) ![:0]u8 {
        return self.allocator().dupeZ(u8, data);
    }

    /// Create a single item in the response arena
    pub fn create(self: *Self, comptime T: type) !*T {
        return self.allocator().create(T);
    }
};

/// Streaming arena that manages multiple streaming chunk allocations.
/// Each chunk can be allocated and freed independently while maintaining
/// efficient memory usage for streaming operations.
pub const StreamingArena = struct {
    /// List of chunk arenas - each chunk gets its own arena
    chunk_arenas: std.ArrayList(std.heap.ArenaAllocator),
    /// The backing allocator for creating new arenas
    backing_allocator: std.mem.Allocator,
    /// Index of the current chunk being written to
    current_chunk: usize,

    const Self = @This();

    /// Initialize a new streaming arena
    pub fn init(backing_allocator: std.mem.Allocator) Self {
        return .{
            .chunk_arenas = std.ArrayList(std.heap.ArenaAllocator).init(backing_allocator),
            .backing_allocator = backing_allocator,
            .current_chunk = 0,
        };
    }

    /// Get an allocator for the current chunk.
    /// Creates a new chunk arena if needed.
    pub fn chunkAllocator(self: *Self) !std.mem.Allocator {
        if (self.current_chunk >= self.chunk_arenas.items.len) {
            try self.chunk_arenas.append(std.heap.ArenaAllocator.init(self.backing_allocator));
        }
        return self.chunk_arenas.items[self.current_chunk].allocator();
    }

    /// Advance to the next chunk.
    /// Previous chunk data remains valid until explicitly released.
    pub fn nextChunk(self: *Self) void {
        self.current_chunk += 1;
    }

    /// Release all chunks up to (but not including) the specified index.
    /// This resets the memory but retains capacity for reuse.
    pub fn releaseProcessedChunks(self: *Self, up_to: usize) void {
        const end = @min(up_to, self.chunk_arenas.items.len);
        for (self.chunk_arenas.items[0..end]) |*arena| {
            _ = arena.reset(.retain_capacity);
        }
    }

    /// Get the total number of allocated chunks
    pub fn chunkCount(self: Self) usize {
        return self.chunk_arenas.items.len;
    }

    /// Free all memory and deinitialize the streaming arena
    pub fn deinit(self: *Self) void {
        for (self.chunk_arenas.items) |*arena| {
            arena.deinit();
        }
        self.chunk_arenas.deinit();
    }

    /// Duplicate data into the current chunk
    pub fn dupe(self: *Self, comptime T: type, data: []const T) ![]T {
        const alloc = try self.chunkAllocator();
        return alloc.dupe(T, data);
    }
};

/// A scoped arena that automatically deinits when it goes out of scope.
/// Useful for RAII-style resource management.
pub fn ScopedArena(comptime ArenaType: type) type {
    return struct {
        arena: ArenaType,

        const Self = @This();

        pub fn init(backing_allocator: std.mem.Allocator) Self {
            return .{
                .arena = ArenaType.init(backing_allocator),
            };
        }

        pub fn allocator(self: *Self) std.mem.Allocator {
            return self.arena.allocator();
        }

        /// Automatically called when the scoped arena goes out of scope
        pub fn deinit(self: *Self) void {
            self.arena.deinit();
        }
    };
}

/// Convenience type for a scoped request arena
pub const ScopedRequestArena = ScopedArena(RequestArena);

/// Convenience type for a scoped response arena
pub const ScopedResponseArena = ScopedArena(ResponseArena);

test "RequestArena basic usage" {
    const backing = std.testing.allocator;

    var arena = RequestArena.init(backing);
    defer arena.deinit();

    const data = try arena.dupe(u8, "hello world");
    try std.testing.expectEqualStrings("hello world", data);

    // Reset and reuse
    arena.reset();

    const data2 = try arena.dupe(u8, "goodbye");
    try std.testing.expectEqualStrings("goodbye", data2);
}

test "ResponseArena data transfer" {
    const backing = std.testing.allocator;

    var request_arena = RequestArena.init(backing);
    defer request_arena.deinit();

    var response_arena = ResponseArena.init(backing);
    defer response_arena.deinit();

    // Allocate in request arena
    const temp_data = try request_arena.dupe(u8, "temporary data");

    // Transfer to response arena for user ownership
    const user_data = try response_arena.dupe(u8, temp_data);

    try std.testing.expectEqualStrings("temporary data", user_data);
}

test "StreamingArena chunk management" {
    const backing = std.testing.allocator;

    var arena = StreamingArena.init(backing);
    defer arena.deinit();

    // First chunk
    const chunk1 = try arena.dupe(u8, "chunk 1");
    try std.testing.expectEqualStrings("chunk 1", chunk1);

    arena.nextChunk();

    // Second chunk
    const chunk2 = try arena.dupe(u8, "chunk 2");
    try std.testing.expectEqualStrings("chunk 2", chunk2);

    try std.testing.expectEqual(@as(usize, 2), arena.chunkCount());

    // Release first chunk
    arena.releaseProcessedChunks(1);
}
