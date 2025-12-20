const std = @import("std");
const provider_v3 = @import("../../provider/src/provider/v3/index.zig");
const openai_compat = @import("../../openai-compatible/src/index.zig");

pub const HuggingFaceProviderSettings = struct {
    base_url: ?[]const u8 = null,
    api_key: ?[]const u8 = null,
    headers: ?std.StringHashMap([]const u8) = null,
    http_client: ?*anyopaque = null,
};

pub const HuggingFaceProvider = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    settings: HuggingFaceProviderSettings,
    base_url: []const u8,

    pub const specification_version = "v3";

    pub fn init(allocator: std.mem.Allocator, settings: HuggingFaceProviderSettings) Self {
        return .{
            .allocator = allocator,
            .settings = settings,
            .base_url = settings.base_url orelse "https://api-inference.huggingface.co",
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "huggingface";
    }

    pub fn languageModel(self: *Self, model_id: []const u8) openai_compat.OpenAICompatibleChatLanguageModel {
        return openai_compat.OpenAICompatibleChatLanguageModel.init(
            self.allocator,
            model_id,
            .{
                .provider = "huggingface.chat",
                .base_url = self.base_url,
                .headers_fn = getHeadersFn,
                .http_client = self.settings.http_client,
            },
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
    return std.posix.getenv("HUGGINGFACE_API_KEY");
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

pub fn createHuggingFace(allocator: std.mem.Allocator) HuggingFaceProvider {
    return HuggingFaceProvider.init(allocator, .{});
}

pub fn createHuggingFaceWithSettings(
    allocator: std.mem.Allocator,
    settings: HuggingFaceProviderSettings,
) HuggingFaceProvider {
    return HuggingFaceProvider.init(allocator, settings);
}

var default_provider: ?HuggingFaceProvider = null;

pub fn huggingface() *HuggingFaceProvider {
    if (default_provider == null) {
        default_provider = createHuggingFace(std.heap.page_allocator);
    }
    return &default_provider.?;
}

test "HuggingFaceProvider basic" {
    const allocator = std.testing.allocator;
    var provider = createHuggingFaceWithSettings(allocator, .{});
    defer provider.deinit();
    try std.testing.expectEqualStrings("huggingface", provider.getProvider());
}
