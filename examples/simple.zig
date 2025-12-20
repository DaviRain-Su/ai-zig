const std = @import("std");
const ai = @import("ai");
const openai = @import("openai");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Example 1: Create an OpenAI provider
    std.debug.print("Zig AI SDK Example\n", .{});
    std.debug.print("==================\n\n", .{});

    // Create provider with default settings
    var provider = openai.createOpenAI(allocator);
    defer provider.deinit();

    std.debug.print("Created OpenAI provider: {s}\n", .{provider.getProvider()});

    // Get a language model
    var model = provider.languageModel("gpt-4o");
    std.debug.print("Created language model: {s}\n", .{model.getModelId()});

    // Example 2: Using similarity functions
    std.debug.print("\nSimilarity Functions Example\n", .{});
    std.debug.print("----------------------------\n", .{});

    const vec_a = [_]f64{ 1.0, 0.0, 0.0 };
    const vec_b = [_]f64{ 0.707, 0.707, 0.0 };
    const vec_c = [_]f64{ 0.0, 1.0, 0.0 };

    const sim_ab = ai.cosineSimilarity(&vec_a, &vec_b);
    const sim_ac = ai.cosineSimilarity(&vec_a, &vec_c);
    const sim_bc = ai.cosineSimilarity(&vec_b, &vec_c);

    std.debug.print("Cosine similarity A-B: {d:.4}\n", .{sim_ab});
    std.debug.print("Cosine similarity A-C: {d:.4}\n", .{sim_ac});
    std.debug.print("Cosine similarity B-C: {d:.4}\n", .{sim_bc});

    const dist_ab = ai.euclideanDistance(&vec_a, &vec_b);
    std.debug.print("Euclidean distance A-B: {d:.4}\n", .{dist_ab});

    // Example 3: Generate ID
    std.debug.print("\nID Generation Example\n", .{});
    std.debug.print("---------------------\n", .{});

    const id1 = try ai.generateId(allocator);
    defer allocator.free(id1);
    std.debug.print("Generated ID 1: {s}\n", .{id1});

    const id2 = try ai.createId(allocator, "msg");
    defer allocator.free(id2);
    std.debug.print("Generated ID 2: {s}\n", .{id2});

    // Example 4: Provider info
    std.debug.print("\nAvailable Providers\n", .{});
    std.debug.print("-------------------\n", .{});
    std.debug.print("- OpenAI (GPT-4, GPT-4o, o1, DALL-E, Whisper, TTS)\n", .{});
    std.debug.print("- Anthropic (Claude 3.5, Claude 4)\n", .{});
    std.debug.print("- Google (Gemini)\n", .{});
    std.debug.print("- Azure OpenAI\n", .{});
    std.debug.print("- Amazon Bedrock\n", .{});
    std.debug.print("- Mistral\n", .{});
    std.debug.print("- Cohere\n", .{});
    std.debug.print("- Groq\n", .{});
    std.debug.print("- DeepSeek\n", .{});
    std.debug.print("- xAI (Grok)\n", .{});
    std.debug.print("- Perplexity\n", .{});
    std.debug.print("- Together AI\n", .{});
    std.debug.print("- Fireworks\n", .{});
    std.debug.print("- ElevenLabs (Speech)\n", .{});
    std.debug.print("- Deepgram (Transcription)\n", .{});
    std.debug.print("- Black Forest Labs (FLUX)\n", .{});
    std.debug.print("- And more...\n", .{});

    std.debug.print("\nExample complete!\n", .{});
}
