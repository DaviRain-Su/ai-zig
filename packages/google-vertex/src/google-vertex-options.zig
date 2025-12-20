const std = @import("std");

/// Google Vertex AI model identifiers
pub const Models = struct {
    // Stable models
    pub const gemini_2_5_pro = "gemini-2.5-pro";
    pub const gemini_2_5_flash = "gemini-2.5-flash";
    pub const gemini_2_5_flash_lite = "gemini-2.5-flash-lite";
    pub const gemini_2_0_flash_lite = "gemini-2.0-flash-lite";
    pub const gemini_2_0_flash = "gemini-2.0-flash";
    pub const gemini_2_0_flash_001 = "gemini-2.0-flash-001";
    pub const gemini_1_5_flash = "gemini-1.5-flash";
    pub const gemini_1_5_flash_001 = "gemini-1.5-flash-001";
    pub const gemini_1_5_flash_002 = "gemini-1.5-flash-002";
    pub const gemini_1_5_pro = "gemini-1.5-pro";
    pub const gemini_1_5_pro_001 = "gemini-1.5-pro-001";
    pub const gemini_1_5_pro_002 = "gemini-1.5-pro-002";
    pub const gemini_1_0_pro_001 = "gemini-1.0-pro-001";
    pub const gemini_1_0_pro_vision_001 = "gemini-1.0-pro-vision-001";
    pub const gemini_1_0_pro = "gemini-1.0-pro";
    pub const gemini_1_0_pro_002 = "gemini-1.0-pro-002";

    // Preview models
    pub const gemini_2_0_flash_lite_preview = "gemini-2.0-flash-lite-preview-02-05";
    pub const gemini_2_5_flash_lite_preview = "gemini-2.5-flash-lite-preview-09-2025";
    pub const gemini_2_5_flash_preview = "gemini-2.5-flash-preview-09-2025";
    pub const gemini_3_pro_preview = "gemini-3-pro-preview";
    pub const gemini_3_pro_image_preview = "gemini-3-pro-image-preview";
    pub const gemini_3_flash_preview = "gemini-3-flash-preview";

    // Experimental models
    pub const gemini_2_0_pro_exp = "gemini-2.0-pro-exp-02-05";
    pub const gemini_2_0_flash_exp = "gemini-2.0-flash-exp";
};

/// Vertex AI embedding model identifiers
pub const EmbeddingModels = struct {
    pub const text_embedding_004 = "text-embedding-004";
    pub const text_embedding_005 = "text-embedding-005";
    pub const text_multilingual_embedding_002 = "text-multilingual-embedding-002";
    pub const textembedding_gecko_001 = "textembedding-gecko@001";
    pub const textembedding_gecko_002 = "textembedding-gecko@002";
    pub const textembedding_gecko_003 = "textembedding-gecko@003";
    pub const textembedding_gecko_multilingual_001 = "textembedding-gecko-multilingual@001";
};

/// Vertex AI image model identifiers
pub const ImageModels = struct {
    pub const imagen_3_0_generate_001 = "imagen-3.0-generate-001";
    pub const imagen_3_0_fast_generate_001 = "imagen-3.0-fast-generate-001";
    pub const imagen_4_0_generate_001 = "imagen-4.0-generate-001";
    pub const imagegeneration_005 = "imagegeneration@005";
    pub const imagegeneration_006 = "imagegeneration@006";
};

/// Embedding task type
pub const TaskType = enum {
    retrieval_query,
    retrieval_document,
    semantic_similarity,
    classification,
    clustering,
    question_answering,
    fact_verification,
    code_retrieval_query,

    pub fn toString(self: TaskType) []const u8 {
        return switch (self) {
            .retrieval_query => "RETRIEVAL_QUERY",
            .retrieval_document => "RETRIEVAL_DOCUMENT",
            .semantic_similarity => "SEMANTIC_SIMILARITY",
            .classification => "CLASSIFICATION",
            .clustering => "CLUSTERING",
            .question_answering => "QUESTION_ANSWERING",
            .fact_verification => "FACT_VERIFICATION",
            .code_retrieval_query => "CODE_RETRIEVAL_QUERY",
        };
    }
};

/// Embedding provider options
pub const GoogleVertexEmbeddingProviderOptions = struct {
    /// Output dimensionality
    output_dimensionality: ?u32 = null,

    /// Task type
    task_type: ?TaskType = null,

    /// Title for the embedding
    title: ?[]const u8 = null,

    /// Auto truncate
    auto_truncate: ?bool = null,
};

/// Image edit mode
pub const EditMode = enum {
    inpaint_insertion,
    inpaint_removal,
    outpaint,
    controlled_editing,
    product_image,
    bgswap,

    pub fn toString(self: EditMode) []const u8 {
        return switch (self) {
            .inpaint_insertion => "EDIT_MODE_INPAINT_INSERTION",
            .inpaint_removal => "EDIT_MODE_INPAINT_REMOVAL",
            .outpaint => "EDIT_MODE_OUTPAINT",
            .controlled_editing => "EDIT_MODE_CONTROLLED_EDITING",
            .product_image => "EDIT_MODE_PRODUCT_IMAGE",
            .bgswap => "EDIT_MODE_BGSWAP",
        };
    }
};

/// Mask mode for image editing
pub const MaskMode = enum {
    default,
    user_provided,
    detection_box,
    clothing_area,
    parsed_person,

    pub fn toString(self: MaskMode) []const u8 {
        return switch (self) {
            .default => "MASK_MODE_DEFAULT",
            .user_provided => "MASK_MODE_USER_PROVIDED",
            .detection_box => "MASK_MODE_DETECTION_BOX",
            .clothing_area => "MASK_MODE_CLOTHING_AREA",
            .parsed_person => "MASK_MODE_PARSED_PERSON",
        };
    }
};

/// Image edit configuration
pub const ImageEditConfig = struct {
    /// Edit mode
    mode: ?EditMode = null,

    /// Number of base steps for sampling
    base_steps: ?u32 = null,

    /// Mask mode
    mask_mode: ?MaskMode = null,

    /// Mask dilation (0.0 to 1.0)
    mask_dilation: ?f32 = null,
};

/// Person generation setting
pub const PersonGeneration = enum {
    dont_allow,
    allow_adult,
    allow_all,

    pub fn toString(self: PersonGeneration) []const u8 {
        return switch (self) {
            .dont_allow => "dont_allow",
            .allow_adult => "allow_adult",
            .allow_all => "allow_all",
        };
    }
};

/// Safety setting for image generation
pub const SafetySetting = enum {
    block_low_and_above,
    block_medium_and_above,
    block_only_high,
    block_none,

    pub fn toString(self: SafetySetting) []const u8 {
        return switch (self) {
            .block_low_and_above => "block_low_and_above",
            .block_medium_and_above => "block_medium_and_above",
            .block_only_high => "block_only_high",
            .block_none => "block_none",
        };
    }
};

/// Sample image size
pub const SampleImageSize = enum {
    @"1K",
    @"2K",

    pub fn toString(self: SampleImageSize) []const u8 {
        return switch (self) {
            .@"1K" => "1K",
            .@"2K" => "2K",
        };
    }
};

/// Image provider options
pub const GoogleVertexImageProviderOptions = struct {
    /// Negative prompt
    negative_prompt: ?[]const u8 = null,

    /// Person generation setting
    person_generation: ?PersonGeneration = null,

    /// Safety setting
    safety_setting: ?SafetySetting = null,

    /// Add watermark
    add_watermark: ?bool = null,

    /// Storage URI for output
    storage_uri: ?[]const u8 = null,

    /// Sample image size
    sample_image_size: ?SampleImageSize = null,

    /// Edit configuration
    edit: ?ImageEditConfig = null,
};

test "Models constants" {
    try std.testing.expectEqualStrings("gemini-2.5-pro", Models.gemini_2_5_pro);
    try std.testing.expectEqualStrings("gemini-2.0-flash", Models.gemini_2_0_flash);
}

test "TaskType toString" {
    try std.testing.expectEqualStrings("RETRIEVAL_QUERY", TaskType.retrieval_query.toString());
    try std.testing.expectEqualStrings("SEMANTIC_SIMILARITY", TaskType.semantic_similarity.toString());
}

test "EditMode toString" {
    try std.testing.expectEqualStrings("EDIT_MODE_INPAINT_INSERTION", EditMode.inpaint_insertion.toString());
    try std.testing.expectEqualStrings("EDIT_MODE_BGSWAP", EditMode.bgswap.toString());
}
