// OpenAI Image API module
pub const api = @import("openai-image-api.zig");
pub const options = @import("openai-image-options.zig");
pub const model = @import("openai-image-model.zig");

// Re-export main types
pub const OpenAIImageModel = model.OpenAIImageModel;
pub const OpenAIImageResponse = api.OpenAIImageResponse;
pub const OpenAIImageGenerationRequest = api.OpenAIImageGenerationRequest;
pub const OpenAIImageProviderOptions = options.OpenAIImageProviderOptions;
pub const Models = options.Models;
pub const GenerateOptions = model.GenerateOptions;
pub const GenerateResult = model.GenerateResult;

// Re-export enums
pub const ImageSize = options.ImageSize;
pub const ImageQuality = options.ImageQuality;
pub const ImageStyle = options.ImageStyle;
pub const ImageOutputFormat = options.ImageOutputFormat;
pub const ImageBackground = options.ImageBackground;

// Re-export functions
pub const modelMaxImagesPerCall = options.modelMaxImagesPerCall;
pub const hasDefaultResponseFormat = options.hasDefaultResponseFormat;
pub const convertUsage = api.convertUsage;
