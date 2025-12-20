const std = @import("std");
const provider_v3 = @import("../../provider/src/provider/v3/index.zig");

pub const DeepgramProviderSettings = struct {
    base_url: ?[]const u8 = null,
    api_key: ?[]const u8 = null,
    headers: ?std.StringHashMap([]const u8) = null,
    http_client: ?*anyopaque = null,
};

/// Deepgram Transcription Model IDs
pub const TranscriptionModels = struct {
    pub const nova_2 = "nova-2";
    pub const nova_2_general = "nova-2-general";
    pub const nova_2_meeting = "nova-2-meeting";
    pub const nova_2_phonecall = "nova-2-phonecall";
    pub const nova_2_voicemail = "nova-2-voicemail";
    pub const nova_2_finance = "nova-2-finance";
    pub const nova_2_conversational = "nova-2-conversational";
    pub const nova_2_video = "nova-2-video";
    pub const nova_2_medical = "nova-2-medical";
    pub const nova_2_drivethru = "nova-2-drivethru";
    pub const nova_2_automotive = "nova-2-automotive";
    pub const nova = "nova";
    pub const enhanced = "enhanced";
    pub const base = "base";
    pub const whisper = "whisper";
};

/// Deepgram Speech Model IDs (Aura TTS)
pub const SpeechModels = struct {
    pub const aura_asteria_en = "aura-asteria-en";
    pub const aura_luna_en = "aura-luna-en";
    pub const aura_stella_en = "aura-stella-en";
    pub const aura_athena_en = "aura-athena-en";
    pub const aura_hera_en = "aura-hera-en";
    pub const aura_orion_en = "aura-orion-en";
    pub const aura_arcas_en = "aura-arcas-en";
    pub const aura_perseus_en = "aura-perseus-en";
    pub const aura_angus_en = "aura-angus-en";
    pub const aura_orpheus_en = "aura-orpheus-en";
    pub const aura_helios_en = "aura-helios-en";
    pub const aura_zeus_en = "aura-zeus-en";
};

/// Deepgram Transcription Model
pub const DeepgramTranscriptionModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    base_url: []const u8,
    settings: DeepgramProviderSettings,

    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        base_url: []const u8,
        settings: DeepgramProviderSettings,
    ) Self {
        return .{
            .allocator = allocator,
            .model_id = model_id,
            .base_url = base_url,
            .settings = settings,
        };
    }

    pub fn getModelId(self: *const Self) []const u8 {
        return self.model_id;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "deepgram.transcription";
    }

    /// Build query parameters for transcription
    pub fn buildQueryParams(
        self: *const Self,
        options: TranscriptionOptions,
    ) ![]const u8 {
        var params = std.ArrayList(u8).init(self.allocator);
        var writer = params.writer();

        try writer.print("model={s}", .{self.model_id});

        if (options.language) |l| {
            try writer.print("&language={s}", .{l});
        }
        if (options.detect_language) |dl| {
            try writer.print("&detect_language={}", .{dl});
        }
        if (options.punctuate) |p| {
            try writer.print("&punctuate={}", .{p});
        }
        if (options.profanity_filter) |pf| {
            try writer.print("&profanity_filter={}", .{pf});
        }
        if (options.redact) |r| {
            for (r) |item| {
                try writer.print("&redact={s}", .{item});
            }
        }
        if (options.diarize) |d| {
            try writer.print("&diarize={}", .{d});
        }
        if (options.diarize_version) |dv| {
            try writer.print("&diarize_version={s}", .{dv});
        }
        if (options.smart_format) |sf| {
            try writer.print("&smart_format={}", .{sf});
        }
        if (options.filler_words) |fw| {
            try writer.print("&filler_words={}", .{fw});
        }
        if (options.multichannel) |mc| {
            try writer.print("&multichannel={}", .{mc});
        }
        if (options.alternatives) |a| {
            try writer.print("&alternatives={}", .{a});
        }
        if (options.numerals) |n| {
            try writer.print("&numerals={}", .{n});
        }
        if (options.search) |s| {
            for (s) |term| {
                try writer.print("&search={s}", .{term});
            }
        }
        if (options.replace) |r| {
            for (r) |item| {
                try writer.print("&replace={s}", .{item});
            }
        }
        if (options.keywords) |k| {
            for (k) |kw| {
                try writer.print("&keywords={s}", .{kw});
            }
        }
        if (options.utterances) |u| {
            try writer.print("&utterances={}", .{u});
        }
        if (options.utt_split) |us| {
            try writer.print("&utt_split={d}", .{us});
        }
        if (options.paragraphs) |p| {
            try writer.print("&paragraphs={}", .{p});
        }
        if (options.summarize) |s| {
            try writer.print("&summarize={}", .{s});
        }
        if (options.detect_topics) |dt| {
            try writer.print("&detect_topics={}", .{dt});
        }
        if (options.detect_entities) |de| {
            try writer.print("&detect_entities={}", .{de});
        }
        if (options.sentiment) |s| {
            try writer.print("&sentiment={}", .{s});
        }
        if (options.intents) |i| {
            try writer.print("&intents={}", .{i});
        }

        return params.toOwnedSlice();
    }
};

pub const TranscriptionOptions = struct {
    language: ?[]const u8 = null,
    detect_language: ?bool = null,
    punctuate: ?bool = null,
    profanity_filter: ?bool = null,
    redact: ?[]const []const u8 = null, // "pci", "numbers", "ssn", etc.
    diarize: ?bool = null,
    diarize_version: ?[]const u8 = null,
    smart_format: ?bool = null,
    filler_words: ?bool = null,
    multichannel: ?bool = null,
    alternatives: ?u32 = null,
    numerals: ?bool = null,
    search: ?[]const []const u8 = null,
    replace: ?[]const []const u8 = null,
    keywords: ?[]const []const u8 = null,
    utterances: ?bool = null,
    utt_split: ?f64 = null,
    paragraphs: ?bool = null,
    summarize: ?bool = null,
    detect_topics: ?bool = null,
    detect_entities: ?bool = null,
    sentiment: ?bool = null,
    intents: ?bool = null,
};

/// Deepgram Speech Model (Aura TTS)
pub const DeepgramSpeechModel = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    model_id: []const u8,
    base_url: []const u8,
    settings: DeepgramProviderSettings,

    pub fn init(
        allocator: std.mem.Allocator,
        model_id: []const u8,
        base_url: []const u8,
        settings: DeepgramProviderSettings,
    ) Self {
        return .{
            .allocator = allocator,
            .model_id = model_id,
            .base_url = base_url,
            .settings = settings,
        };
    }

    pub fn getModelId(self: *const Self) []const u8 {
        return self.model_id;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "deepgram.speech";
    }

    /// Build request body for speech synthesis
    pub fn buildRequestBody(
        self: *const Self,
        text: []const u8,
        options: SpeechOptions,
    ) !std.json.Value {
        var obj = std.json.ObjectMap.init(self.allocator);

        try obj.put("text", std.json.Value{ .string = text });

        if (options.encoding) |e| {
            try obj.put("encoding", std.json.Value{ .string = e });
        }
        if (options.container) |c| {
            try obj.put("container", std.json.Value{ .string = c });
        }
        if (options.sample_rate) |sr| {
            try obj.put("sample_rate", std.json.Value{ .integer = @intCast(sr) });
        }
        if (options.bit_rate) |br| {
            try obj.put("bit_rate", std.json.Value{ .integer = @intCast(br) });
        }

        return std.json.Value{ .object = obj };
    }
};

pub const SpeechOptions = struct {
    encoding: ?[]const u8 = null, // "linear16", "mulaw", "alaw", "mp3", "opus", "flac", "aac"
    container: ?[]const u8 = null, // "wav", "mp3", "ogg", etc.
    sample_rate: ?u32 = null,
    bit_rate: ?u32 = null,
};

pub const DeepgramProvider = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    settings: DeepgramProviderSettings,
    base_url: []const u8,

    pub const specification_version = "v3";

    pub fn init(allocator: std.mem.Allocator, settings: DeepgramProviderSettings) Self {
        return .{
            .allocator = allocator,
            .settings = settings,
            .base_url = settings.base_url orelse "https://api.deepgram.com",
        };
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn getProvider(self: *const Self) []const u8 {
        _ = self;
        return "deepgram";
    }

    pub fn transcriptionModel(self: *Self, model_id: []const u8) DeepgramTranscriptionModel {
        return DeepgramTranscriptionModel.init(self.allocator, model_id, self.base_url, self.settings);
    }

    pub fn transcription(self: *Self, model_id: []const u8) DeepgramTranscriptionModel {
        return self.transcriptionModel(model_id);
    }

    pub fn speechModel(self: *Self, model_id: []const u8) DeepgramSpeechModel {
        return DeepgramSpeechModel.init(self.allocator, model_id, self.base_url, self.settings);
    }

    pub fn speech(self: *Self, model_id: []const u8) DeepgramSpeechModel {
        return self.speechModel(model_id);
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
    return std.posix.getenv("DEEPGRAM_API_KEY");
}

pub fn createDeepgram(allocator: std.mem.Allocator) DeepgramProvider {
    return DeepgramProvider.init(allocator, .{});
}

pub fn createDeepgramWithSettings(
    allocator: std.mem.Allocator,
    settings: DeepgramProviderSettings,
) DeepgramProvider {
    return DeepgramProvider.init(allocator, settings);
}

var default_provider: ?DeepgramProvider = null;

pub fn deepgram() *DeepgramProvider {
    if (default_provider == null) {
        default_provider = createDeepgram(std.heap.page_allocator);
    }
    return &default_provider.?;
}

test "DeepgramProvider basic" {
    const allocator = std.testing.allocator;
    var prov = createDeepgramWithSettings(allocator, .{});
    defer prov.deinit();
    try std.testing.expectEqualStrings("deepgram", prov.getProvider());
}
