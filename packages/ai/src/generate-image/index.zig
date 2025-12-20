// Generate Image Module for Zig AI SDK
//
// This module provides image generation capabilities:
// - generateImage: Generate images from text prompts

pub const generate_image_mod = @import("generate-image.zig");

// Re-export types
pub const generateImage = generate_image_mod.generateImage;
pub const GenerateImageResult = generate_image_mod.GenerateImageResult;
pub const GenerateImageOptions = generate_image_mod.GenerateImageOptions;
pub const GenerateImageError = generate_image_mod.GenerateImageError;
pub const GeneratedImage = generate_image_mod.GeneratedImage;
pub const ImageGenerationUsage = generate_image_mod.ImageGenerationUsage;
pub const ImageResponseMetadata = generate_image_mod.ImageResponseMetadata;
pub const ImageSize = generate_image_mod.ImageSize;
pub const PresetSize = generate_image_mod.PresetSize;
pub const CustomSize = generate_image_mod.CustomSize;
pub const ImageQuality = generate_image_mod.ImageQuality;
pub const ImageStyle = generate_image_mod.ImageStyle;
pub const getPresetDimensions = generate_image_mod.getPresetDimensions;

test {
    @import("std").testing.refAllDecls(@This());
}
