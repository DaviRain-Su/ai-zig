const std = @import("std");
const provider_v3 = @import("../../provider/src/provider/v3/index.zig");
const lm = @import("../../provider/src/language-model/v3/index.zig");

const config_mod = @import("azure-config.zig");

// Import OpenAI models (Azure reuses them)
const openai_chat = @import("../../openai/src/chat/openai-chat-language-model.zig");
const openai_embed = @import("../../openai/src/embedding/openai-embedding-model.zig");
const openai_image = @import("../../openai/src/image/openai-image-model.zig");
const openai_speech = @import("../../openai/src/speech/openai-speech-model.zig");
const openai_transcription = @import("../../openai/src/transcription/openai-transcription-model.zig");
const openai_config = @import("../../openai/src/openai-config.zig");

/// Azure OpenAI Provider settings
pub const AzureOpenAIProviderSettings = struct {
    /// Azure resource name (used if baseURL not provided)
    resource_name: ?[]const u8 = null,

    /// Base URL for API calls (overrides resource_name)
    base_url: ?[]const u8 = null,

    /// API key for authentication
    api_key: ?[]const u8 = null,

    /// Custom headers
    headers: ?std.StringHashMap([]const u8) = null,

    /// API version (defaults to "v1")
    api_version: ?[]const u8 = null,

    /// Use deployment-based URLs
    use_deployment_based_urls: ?bool = null,

    /// HTTP client
    http_client: ?*anyopaque = null,

    /// ID generator function
    generate_id: ?*const fn () []const u8 = null,
};

/// Azure OpenAI Provider
pub const AzureOpenAIProvider = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    settings: AzureOpenAIProviderSettings,
    config: config_mod.AzureOpenAIConfig,

    pub const specification_version = "v3";

    /// Create a new Azure OpenAI provider
    pub fn init(allocator: std.mem.Allocator, settings: AzureOpenAIProviderSettings) Self {
        // Build base URL
        const base_url = settings.base_url orelse blk: {
            const resource_name = settings.resource_name orelse getResourceNameFromEnv() orelse "default";
            break :blk config_mod.buildBaseUrlFromResourceName(allocator, resource_name) catch "https://azure.openai.com/openai";
        };

        return .{
            .allocator = allocator,
            .settings = settings,
            .config = .{
                .provider = "azure",
                .base_url = base_url,
                .api_version = settings.api_version orelse "v1",
                .use_deployment_based_urls = settings.use_deployment_based_urls orelse false,
                .headers_fn = getHeadersFn,
                .http_client = settings.http_client,
                .generate_id = settings.generate_id,
            },
        };
    }

    /// Deinitialize the provider
    pub fn deinit(self: *Self) void {
        _ = self;
        // Clean up any allocated resources
    }

    /// Get the provider name
    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "azure";
    }

    // -- Language Models --

    /// Create a chat language model
    pub fn chat(self: *Self, deployment_id: []const u8) openai_chat.OpenAIChatLanguageModel {
        return openai_chat.OpenAIChatLanguageModel.init(
            self.allocator,
            deployment_id,
            self.buildOpenAIConfig("azure.chat"),
        );
    }

    /// Create a language model (alias for responses)
    pub fn languageModel(self: *Self, deployment_id: []const u8) openai_chat.OpenAIChatLanguageModel {
        return self.chat(deployment_id);
    }

    // -- Embedding Models --

    /// Create an embedding model
    pub fn embeddingModel(self: *Self, deployment_id: []const u8) openai_embed.OpenAIEmbeddingModel {
        return openai_embed.OpenAIEmbeddingModel.init(
            self.allocator,
            deployment_id,
            self.buildOpenAIConfig("azure.embeddings"),
        );
    }

    /// Create an embedding model (alias)
    pub fn embedding(self: *Self, deployment_id: []const u8) openai_embed.OpenAIEmbeddingModel {
        return self.embeddingModel(deployment_id);
    }

    /// Create a text embedding model (deprecated alias)
    pub fn textEmbedding(self: *Self, deployment_id: []const u8) openai_embed.OpenAIEmbeddingModel {
        return self.embeddingModel(deployment_id);
    }

    /// Create a text embedding model (deprecated alias)
    pub fn textEmbeddingModel(self: *Self, deployment_id: []const u8) openai_embed.OpenAIEmbeddingModel {
        return self.embeddingModel(deployment_id);
    }

    // -- Image Models --

    /// Create an image model
    pub fn imageModel(self: *Self, deployment_id: []const u8) openai_image.OpenAIImageModel {
        return openai_image.OpenAIImageModel.init(
            self.allocator,
            deployment_id,
            self.buildOpenAIConfig("azure.image"),
        );
    }

    /// Create an image model (alias)
    pub fn image(self: *Self, deployment_id: []const u8) openai_image.OpenAIImageModel {
        return self.imageModel(deployment_id);
    }

    // -- Speech Models --

    /// Create a speech model
    pub fn speech(self: *Self, deployment_id: []const u8) openai_speech.OpenAISpeechModel {
        return openai_speech.OpenAISpeechModel.init(
            self.allocator,
            deployment_id,
            self.buildOpenAIConfig("azure.speech"),
        );
    }

    // -- Transcription Models --

    /// Create a transcription model
    pub fn transcription(self: *Self, deployment_id: []const u8) openai_transcription.OpenAITranscriptionModel {
        return openai_transcription.OpenAITranscriptionModel.init(
            self.allocator,
            deployment_id,
            self.buildOpenAIConfig("azure.transcription"),
        );
    }

    /// Build OpenAI config for models
    fn buildOpenAIConfig(self: *Self, provider_name: []const u8) openai_config.OpenAIConfig {
        return .{
            .provider = provider_name,
            .base_url = self.config.base_url,
            .headers_fn = getOpenAIHeadersFn,
            .http_client = self.config.http_client,
            .generate_id = self.config.generate_id,
        };
    }

    // -- ProviderV3 Interface --

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
        return .{ .ok = model.asLanguageModel() };
    }

    fn embeddingModelVtable(impl: *anyopaque, model_id: []const u8) provider_v3.EmbeddingModelResult {
        const self: *Self = @ptrCast(@alignCast(impl));
        var model = self.embeddingModel(model_id);
        return .{ .ok = model.asEmbeddingModel() };
    }

    fn imageModelVtable(impl: *anyopaque, model_id: []const u8) provider_v3.ImageModelResult {
        const self: *Self = @ptrCast(@alignCast(impl));
        var model = self.imageModel(model_id);
        return .{ .ok = model.asImageModel() };
    }

    fn speechModelVtable(impl: *anyopaque, model_id: []const u8) provider_v3.SpeechModelResult {
        const self: *Self = @ptrCast(@alignCast(impl));
        var model = self.speech(model_id);
        return .{ .ok = model.asSpeechModel() };
    }

    fn transcriptionModelVtable(impl: *anyopaque, model_id: []const u8) provider_v3.TranscriptionModelResult {
        const self: *Self = @ptrCast(@alignCast(impl));
        var model = self.transcription(model_id);
        return .{ .ok = model.asTranscriptionModel() };
    }
};

/// Get resource name from environment
fn getResourceNameFromEnv() ?[]const u8 {
    return std.posix.getenv("AZURE_RESOURCE_NAME");
}

/// Get API key from environment
fn getApiKeyFromEnv() ?[]const u8 {
    return std.posix.getenv("AZURE_API_KEY");
}

/// Headers function for Azure config
fn getHeadersFn(config: *const config_mod.AzureOpenAIConfig) std.StringHashMap([]const u8) {
    _ = config;
    var headers = std.StringHashMap([]const u8).init(std.heap.page_allocator);

    // Add API key header
    if (getApiKeyFromEnv()) |api_key| {
        headers.put("api-key", api_key) catch {};
    }

    // Add content-type
    headers.put("Content-Type", "application/json") catch {};

    return headers;
}

/// Headers function for OpenAI config (used by models)
fn getOpenAIHeadersFn(config: *const openai_config.OpenAIConfig) std.StringHashMap([]const u8) {
    _ = config;
    var headers = std.StringHashMap([]const u8).init(std.heap.page_allocator);

    // Add API key header (Azure uses api-key instead of Authorization)
    if (getApiKeyFromEnv()) |api_key| {
        headers.put("api-key", api_key) catch {};
    }

    // Add content-type
    headers.put("Content-Type", "application/json") catch {};

    return headers;
}

/// Create a new Azure OpenAI provider with default settings
pub fn createAzure(allocator: std.mem.Allocator) AzureOpenAIProvider {
    return AzureOpenAIProvider.init(allocator, .{});
}

/// Create a new Azure OpenAI provider with custom settings
pub fn createAzureWithSettings(
    allocator: std.mem.Allocator,
    settings: AzureOpenAIProviderSettings,
) AzureOpenAIProvider {
    return AzureOpenAIProvider.init(allocator, settings);
}

/// Default Azure OpenAI provider instance (created lazily)
var default_provider: ?AzureOpenAIProvider = null;

/// Get the default Azure OpenAI provider
pub fn azure() *AzureOpenAIProvider {
    if (default_provider == null) {
        default_provider = createAzure(std.heap.page_allocator);
    }
    return &default_provider.?;
}

test "AzureOpenAIProvider basic" {
    const allocator = std.testing.allocator;

    var provider = createAzureWithSettings(allocator, .{
        .base_url = "https://myresource.openai.azure.com/openai",
    });
    defer provider.deinit();

    try std.testing.expectEqualStrings("azure", provider.getProvider());
}

test "AzureOpenAIProvider with resource name" {
    const allocator = std.testing.allocator;

    var provider = createAzureWithSettings(allocator, .{
        .resource_name = "myresource",
    });
    defer provider.deinit();

    try std.testing.expectEqualStrings("azure", provider.getProvider());
}

test "AzureOpenAIProvider chat model" {
    const allocator = std.testing.allocator;

    var provider = createAzureWithSettings(allocator, .{
        .base_url = "https://myresource.openai.azure.com/openai",
    });
    defer provider.deinit();

    const model = provider.chat("gpt-4");
    try std.testing.expectEqualStrings("gpt-4", model.getModelId());
}

test "AzureOpenAIProvider embedding model" {
    const allocator = std.testing.allocator;

    var provider = createAzureWithSettings(allocator, .{
        .base_url = "https://myresource.openai.azure.com/openai",
    });
    defer provider.deinit();

    const model = provider.embeddingModel("text-embedding-ada-002");
    try std.testing.expectEqualStrings("text-embedding-ada-002", model.getModelId());
}
