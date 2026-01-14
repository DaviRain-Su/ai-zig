const std = @import("std");
const provider_v3 = @import("provider").provider;
const provider_utils = @import("provider-utils");

const config_mod = @import("deepseek-config.zig");
const chat_model = @import("deepseek-chat-language-model.zig");

/// DeepSeek Provider settings
pub const DeepSeekProviderSettings = struct {
    /// Base URL for API calls
    base_url: ?[]const u8 = null,

    /// API key
    api_key: ?[]const u8 = null,

    /// Custom headers
    headers: ?std.StringHashMap([]const u8) = null,

    /// HTTP client (optional, will create default if not provided)
    http_client: ?provider_utils.HttpClient = null,
};

/// DeepSeek Provider
pub const DeepSeekProvider = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    settings: DeepSeekProviderSettings,
    base_url: []const u8,
    std_http_client: ?provider_utils.http.std_client.StdHttpClient,

    pub const specification_version = "v3";

    /// Create a new DeepSeek provider
    pub fn init(allocator: std.mem.Allocator, settings: DeepSeekProviderSettings) Self {
        const base_url = settings.base_url orelse "https://api.deepseek.com";

        return .{
            .allocator = allocator,
            .settings = settings,
            .base_url = base_url,
            .std_http_client = if (settings.http_client == null) provider_utils.createStdHttpClient(allocator) else null,
        };
    }

    /// Deinitialize the provider
    pub fn deinit(self: *Self) void {
        if (self.std_http_client) |*client| {
            client.deinit();
        }
    }

    /// Get the provider name
    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "deepseek";
    }

    /// Create a language model
    pub fn languageModel(self: *Self, model_id: []const u8) chat_model.DeepSeekChatLanguageModel {
        return chat_model.DeepSeekChatLanguageModel.init(
            self.allocator,
            model_id,
            self.buildConfig("deepseek.chat"),
        );
    }

    /// Create a language model (alias)
    pub fn chat(self: *Self, model_id: []const u8) chat_model.DeepSeekChatLanguageModel {
        return self.languageModel(model_id);
    }

    /// Build config for models
    fn buildConfig(self: *Self, provider_name: []const u8) config_mod.DeepSeekConfig {
        // Get HTTP client - use provided one or create a default
        const http_client = self.settings.http_client orelse blk: {
            if (self.std_http_client) |*client| {
                break :blk client.asInterface();
            }
            break :blk null;
        };

        return .{
            .provider = provider_name,
            .base_url = self.base_url,
            .api_key = self.settings.api_key,
            .headers_fn = getHeadersFn,
            .http_client = http_client,
        };
    }

    /// Convert to ProviderV3 interface
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
        return .{ .success = model.asLanguageModel() };
    }

    fn embeddingModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.EmbeddingModelResult {
        _ = model_id;
        return .{ .failure = error.NoSuchModel };
    }

    fn imageModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.ImageModelResult {
        _ = model_id;
        return .{ .failure = error.NoSuchModel };
    }

    fn speechModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.SpeechModelResult {
        _ = model_id;
        return .{ .failure = error.NoSuchModel };
    }

    fn transcriptionModelVtable(_: *anyopaque, model_id: []const u8) provider_v3.TranscriptionModelResult {
        _ = model_id;
        return .{ .failure = error.NoSuchModel };
    }
};

fn getApiKeyFromEnv() ?[]const u8 {
    return std.posix.getenv("DEEPSEEK_API_KEY");
}

fn getHeadersFn(config: *const config_mod.DeepSeekConfig, allocator: std.mem.Allocator) std.StringHashMap([]const u8) {
    var headers = std.StringHashMap([]const u8).init(allocator);

    headers.put("Content-Type", "application/json") catch {};

    // 优先使用配置中的 API key，然后回退到环境变量
    const api_key = config.api_key orelse getApiKeyFromEnv();
    if (api_key) |key| {
        const auth_header = std.fmt.allocPrint(
            allocator,
            "Bearer {s}",
            .{key},
        ) catch return headers;
        headers.put("Authorization", auth_header) catch {};
    }

    return headers;
}

pub fn createDeepSeek(allocator: std.mem.Allocator) DeepSeekProvider {
    return DeepSeekProvider.init(allocator, .{});
}

pub fn createDeepSeekWithSettings(
    allocator: std.mem.Allocator,
    settings: DeepSeekProviderSettings,
) DeepSeekProvider {
    return DeepSeekProvider.init(allocator, settings);
}

var default_provider: ?DeepSeekProvider = null;

pub fn deepseek() *DeepSeekProvider {
    if (default_provider == null) {
        default_provider = createDeepSeek(std.heap.page_allocator);
    }
    return &default_provider.?;
}

test "DeepSeekProvider basic" {
    const allocator = std.testing.allocator;

    var provider = createDeepSeekWithSettings(allocator, .{});
    defer provider.deinit();

    try std.testing.expectEqualStrings("deepseek", provider.getProvider());
}

test "DeepSeekProvider language model" {
    const allocator = std.testing.allocator;

    var provider = createDeepSeekWithSettings(allocator, .{});
    defer provider.deinit();

    const model = provider.languageModel("deepseek-chat");
    try std.testing.expectEqualStrings("deepseek-chat", model.getModelId());
}
