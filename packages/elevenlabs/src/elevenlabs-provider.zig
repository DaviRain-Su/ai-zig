const std = @import("std");
const provider_v3 = @import("../../provider/src/provider/v3/index.zig");

pub const ElevenLabsProviderSettings = struct {
    base_url: ?[]const u8 = null,
    api_key: ?[]const u8 = null,
    headers: ?std.StringHashMap([]const u8) = null,
    http_client: ?*anyopaque = null,
};

/// ElevenLabs Speech Model
pub const ElevenLabsSpeechModel = struct {
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
        return "elevenlabs.speech";
    }
};

/// ElevenLabs Transcription Model
pub const ElevenLabsTranscriptionModel = struct {
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
        return "elevenlabs.transcription";
    }
};

pub const ElevenLabsProvider = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    settings: ElevenLabsProviderSettings,
    base_url: []const u8,

    pub const specification_version = "v3";

    pub fn init(allocator: std.mem.Allocator, settings: ElevenLabsProviderSettings) Self {
        return .{
            .allocator = allocator,
            .settings = settings,
            .base_url = settings.base_url orelse "https://api.elevenlabs.io",
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "elevenlabs";
    }

    pub fn speechModel(self: *Self, model_id: []const u8) ElevenLabsSpeechModel {
        return ElevenLabsSpeechModel.init(self.allocator, model_id, self.base_url);
    }

    pub fn speech(self: *Self, model_id: []const u8) ElevenLabsSpeechModel {
        return self.speechModel(model_id);
    }

    pub fn transcriptionModel(self: *Self, model_id: []const u8) ElevenLabsTranscriptionModel {
        return ElevenLabsTranscriptionModel.init(self.allocator, model_id, self.base_url);
    }

    pub fn transcription(self: *Self, model_id: []const u8) ElevenLabsTranscriptionModel {
        return self.transcriptionModel(model_id);
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
    return std.posix.getenv("ELEVENLABS_API_KEY");
}

pub fn createElevenLabs(allocator: std.mem.Allocator) ElevenLabsProvider {
    return ElevenLabsProvider.init(allocator, .{});
}

pub fn createElevenLabsWithSettings(
    allocator: std.mem.Allocator,
    settings: ElevenLabsProviderSettings,
) ElevenLabsProvider {
    return ElevenLabsProvider.init(allocator, settings);
}

var default_provider: ?ElevenLabsProvider = null;

pub fn elevenlabs() *ElevenLabsProvider {
    if (default_provider == null) {
        default_provider = createElevenLabs(std.heap.page_allocator);
    }
    return &default_provider.?;
}

test "ElevenLabsProvider basic" {
    const allocator = std.testing.allocator;
    var provider = createElevenLabsWithSettings(allocator, .{});
    defer provider.deinit();
    try std.testing.expectEqualStrings("elevenlabs", provider.getProvider());
}
