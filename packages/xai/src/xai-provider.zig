const std = @import("std");
const provider_v3 = @import("../../provider/src/provider/v3/index.zig");
const openai_compat = @import("../../openai-compatible/src/index.zig");

pub const XaiProviderSettings = struct {
    base_url: ?[]const u8 = null,
    api_key: ?[]const u8 = null,
    headers: ?std.StringHashMap([]const u8) = null,
    http_client: ?*anyopaque = null,
};

pub const XaiProvider = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    settings: XaiProviderSettings,
    base_url: []const u8,

    pub const specification_version = "v3";

    pub fn init(allocator: std.mem.Allocator, settings: XaiProviderSettings) Self {
        return .{
            .allocator = allocator,
            .settings = settings,
            .base_url = settings.base_url orelse "https://api.x.ai/v1",
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "xai";
    }

    pub fn languageModel(self: *Self, model_id: []const u8) openai_compat.OpenAICompatibleChatLanguageModel {
        return openai_compat.OpenAICompatibleChatLanguageModel.init(
            self.allocator,
            model_id,
            .{
                .provider = "xai.chat",
                .base_url = self.base_url,
                .headers_fn = getHeadersFn,
                .http_client = self.settings.http_client,
            },
        );
    }

    pub fn chat(self: *Self, model_id: []const u8) openai_compat.OpenAICompatibleChatLanguageModel {
        return self.languageModel(model_id);
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

    fn languageModelVtable(impl: *anyopaque, model_id: []const u8) provider_v3.LanguageModelResult {
        const self: *Self = @ptrCast(@alignCast(impl));
        var model = self.languageModel(model_id);
        return .{ .ok = model.asLanguageModel() };
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
    return std.posix.getenv("XAI_API_KEY");
}

fn getHeadersFn(config: *const openai_compat.OpenAICompatibleConfig) std.StringHashMap([]const u8) {
    _ = config;
    var headers = std.StringHashMap([]const u8).init(std.heap.page_allocator);
    headers.put("Content-Type", "application/json") catch {};

    if (getApiKeyFromEnv()) |api_key| {
        const auth_header = std.fmt.allocPrint(
            std.heap.page_allocator,
            "Bearer {s}",
            .{api_key},
        ) catch return headers;
        headers.put("Authorization", auth_header) catch {};
    }

    return headers;
}

pub fn createXai(allocator: std.mem.Allocator) XaiProvider {
    return XaiProvider.init(allocator, .{});
}

pub fn createXaiWithSettings(
    allocator: std.mem.Allocator,
    settings: XaiProviderSettings,
) XaiProvider {
    return XaiProvider.init(allocator, settings);
}

var default_provider: ?XaiProvider = null;

pub fn xai() *XaiProvider {
    if (default_provider == null) {
        default_provider = createXai(std.heap.page_allocator);
    }
    return &default_provider.?;
}

test "XaiProvider basic" {
    const allocator = std.testing.allocator;
    var provider = createXaiWithSettings(allocator, .{});
    defer provider.deinit();
    try std.testing.expectEqualStrings("xai", provider.getProvider());
}
