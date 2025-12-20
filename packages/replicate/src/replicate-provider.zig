const std = @import("std");
const provider_v3 = @import("../../provider/src/provider/v3/index.zig");

pub const ReplicateProviderSettings = struct {
    base_url: ?[]const u8 = null,
    api_key: ?[]const u8 = null,
    headers: ?std.StringHashMap([]const u8) = null,
    http_client: ?*anyopaque = null,
};

/// Replicate Image Model
pub const ReplicateImageModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    base_url: []const u8,

    pub fn init(allocator: std.mem.Allocator, model_id: []const u8, base_url: []const u8) Self {
        return .{
            .allocator = allocator,
            .model_id = model_id,
            .base_url = base_url,
        };
    }

    pub fn getModelId(self: *const Self) []const u8 {
        return self.model_id;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "replicate.image";
    }
};

pub const ReplicateProvider = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    settings: ReplicateProviderSettings,
    base_url: []const u8,

    pub const specification_version = "v3";

    pub fn init(allocator: std.mem.Allocator, settings: ReplicateProviderSettings) Self {
        return .{
            .allocator = allocator,
            .settings = settings,
            .base_url = settings.base_url orelse "https://api.replicate.com/v1",
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "replicate";
    }

    pub fn imageModel(self: *Self, model_id: []const u8) ReplicateImageModel {
        return ReplicateImageModel.init(
            self.allocator,
            model_id,
            self.base_url,
        );
    }

    pub fn asProvider(self: *Self) provider_v3.ProviderV3 {
        return .{
            .vtable = &vtable,
            .impl = self,
        };
    }

    const vtable = provider_v3.ProviderV3.VTable{
        .languageModel = languageModelVtable,
        .embeddingModel = embeddingModelVtable,
        .imageModel = imageModelVtable,
        .speechModel = speechModelVtable,
        .transcriptionModel = transcriptionModelVtable,
    };

    fn languageModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.LanguageModelResult {
        _ = model_id;
        return .{ .err = error.NoSuchModel };
    }

    fn embeddingModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.EmbeddingModelResult {
        _ = model_id;
        return .{ .err = error.NoSuchModel };
    }

    fn imageModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.ImageModelResult {
        _ = model_id;
        // Note: Image model doesn't implement V3 interface directly
        return .{ .err = error.NoSuchModel };
    }

    fn speechModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.SpeechModelResult {
        _ = model_id;
        return .{ .err = error.NoSuchModel };
    }

    fn transcriptionModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.TranscriptionModelResult {
        _ = model_id;
        return .{ .err = error.NoSuchModel };
    }
};

fn getApiKeyFromEnv() ?[]const u8 {
    return std.posix.getenv("REPLICATE_API_TOKEN");
}

pub fn createReplicate(allocator: std.mem.Allocator) ReplicateProvider {
    return ReplicateProvider.init(allocator, .{});
}

pub fn createReplicateWithSettings(
    allocator: std.mem.Allocator,
    settings: ReplicateProviderSettings,
) ReplicateProvider {
    return ReplicateProvider.init(allocator, settings);
}

var default_provider: ?ReplicateProvider = null;

pub fn replicate() *ReplicateProvider {
    if (default_provider == null) {
        default_provider = createReplicate(std.heap.page_allocator);
    }
    return &default_provider.?;
}

test "ReplicateProvider basic" {
    const allocator = std.testing.allocator;
    var provider = createReplicateWithSettings(allocator, .{});
    defer provider.deinit();
    try std.testing.expectEqualStrings("replicate", provider.getProvider());
}
