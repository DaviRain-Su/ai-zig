# Zig AI SDK

A comprehensive AI SDK for Zig, ported from the Vercel AI SDK. This SDK provides a unified interface for interacting with various AI providers.

## Features

- **Multiple Providers**: Support for 30+ AI providers
- **Streaming**: Callback-based streaming for real-time responses
- **Tool Calling**: Full support for function/tool calling
- **Structured Output**: Generate structured JSON objects
- **Embeddings**: Text embedding generation with similarity functions
- **Image Generation**: Create images from text prompts
- **Speech Synthesis**: Text-to-speech capabilities
- **Transcription**: Speech-to-text capabilities
- **Middleware**: Extensible request/response transformation
- **Memory Safe**: Uses arena allocators for efficient memory management

## Supported Providers

### Language Models
- **OpenAI** - GPT-4, GPT-4o, o1, o3
- **Anthropic** - Claude 3.5, Claude 4
- **Google** - Gemini 2.0, Gemini 1.5
- **Google Vertex AI** - Gemini on Vertex
- **Azure OpenAI** - Azure-hosted OpenAI models
- **Amazon Bedrock** - Claude, Titan, Llama
- **Mistral** - Mistral Large, Codestral
- **Cohere** - Command R+
- **Groq** - Llama, Mixtral (fast inference)
- **DeepSeek** - DeepSeek Chat, Reasoner
- **xAI** - Grok
- **Perplexity** - Online search models
- **Together AI** - Various open models
- **Fireworks** - Fast inference
- **Cerebras** - Fast inference
- **DeepInfra** - Various open models
- **Replicate** - Model hosting
- **HuggingFace** - Inference API
- **OpenAI Compatible** - Any OpenAI-compatible API

### Image Generation
- **OpenAI** - DALL-E 3
- **Fal** - FLUX, Stable Diffusion
- **Luma** - Dream Machine
- **Black Forest Labs** - FLUX Pro/Dev/Schnell
- **Replicate** - Various models

### Speech & Audio
- **OpenAI** - TTS, Whisper
- **ElevenLabs** - High-quality TTS
- **LMNT** - Aurora, Blizzard voices
- **Hume** - Empathic voice
- **Deepgram** - Nova 2, Aura TTS
- **AssemblyAI** - Transcription + LeMUR
- **Gladia** - Transcription
- **Rev AI** - Transcription

## Installation

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .@"zig-ai-sdk" = .{
        .url = "https://github.com/your-org/zig-ai-sdk/archive/v0.1.0.tar.gz",
        .hash = "...",
    },
},
```

## Quick Start

```zig
const std = @import("std");
const ai = @import("ai");
const openai = @import("openai");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create provider
    var provider = openai.createOpenAI(allocator);
    defer provider.deinit();

    // Get model
    var model = provider.languageModel("gpt-4o");

    // Generate text
    const result = try ai.generateText(allocator, .{
        .model = &model,
        .prompt = "What is the meaning of life?",
    });

    std.debug.print("{s}\n", .{result.text});
}
```

## Streaming Example

```zig
const callbacks = ai.StreamCallbacks{
    .on_part = struct {
        fn f(part: ai.StreamPart, _: ?*anyopaque) void {
            switch (part) {
                .text_delta => |delta| {
                    std.debug.print("{s}", .{delta.text});
                },
                else => {},
            }
        }
    }.f,
    .on_error = struct {
        fn f(err: anyerror, _: ?*anyopaque) void {
            std.debug.print("Error: {}\n", .{err});
        }
    }.f,
    .on_complete = struct {
        fn f(_: ?*anyopaque) void {
            std.debug.print("\nDone!\n", .{});
        }
    }.f,
};

const result = try ai.streamText(allocator, .{
    .model = &model,
    .prompt = "Tell me a story",
    .callbacks = callbacks,
});
defer result.deinit();
```

## Tool Calling Example

```zig
const tool = ai.Tool.create(.{
    .name = "get_weather",
    .description = "Get the weather for a location",
    .parameters = weather_schema,
    .execute = struct {
        fn f(input: std.json.Value, _: ai.ToolExecutionContext) !ai.ToolExecutionResult {
            // Process weather request
            return .{ .success = std.json.Value{ .string = "Sunny, 72°F" } };
        }
    }.f,
});

const result = try ai.generateText(allocator, .{
    .model = &model,
    .prompt = "What's the weather in San Francisco?",
    .tools = &[_]ai.Tool{tool},
    .max_steps = 5,
});
```

## Embeddings Example

```zig
const embed = @import("ai").embed;

// Generate embedding
const result = try embed(allocator, .{
    .model = &embedding_model,
    .value = "Hello, world!",
});

// Calculate similarity
const similarity = ai.cosineSimilarity(result.embedding.values, other_embedding);
```

## Building

```bash
# Build all packages
zig build

# Run tests
zig build test

# Run example
zig build run-example
```

## Architecture

The SDK uses several key patterns:

1. **Arena Allocators**: Request-scoped memory management
2. **Vtable Pattern**: Interface abstraction for models
3. **Callback-based Streaming**: Non-blocking I/O
4. **Provider Abstraction**: Unified interface across providers

## Memory Management

```zig
// Arena allocator for request scope
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();

// Use arena for request processing
const result = try processRequest(arena.allocator());

// Data is automatically freed when arena is deinitialized
```

## Project Structure

```
zig-ai-sdk/
├── build.zig           # Root build configuration
├── build.zig.zon       # Package manifest
├── packages/
│   ├── ai/             # High-level API (generateText, streamText, etc.)
│   ├── provider/       # Core provider interfaces and types
│   ├── provider-utils/ # HTTP client, streaming utilities
│   ├── openai/         # OpenAI provider
│   ├── anthropic/      # Anthropic provider
│   ├── google/         # Google AI provider
│   ├── google-vertex/  # Google Vertex AI provider
│   ├── azure/          # Azure OpenAI provider
│   ├── amazon-bedrock/ # Amazon Bedrock provider
│   ├── mistral/        # Mistral provider
│   ├── cohere/         # Cohere provider
│   ├── groq/           # Groq provider
│   ├── deepseek/       # DeepSeek provider
│   ├── xai/            # xAI (Grok) provider
│   ├── perplexity/     # Perplexity provider
│   ├── togetherai/     # Together AI provider
│   ├── fireworks/      # Fireworks provider
│   ├── cerebras/       # Cerebras provider
│   ├── deepinfra/      # DeepInfra provider
│   ├── replicate/      # Replicate provider
│   ├── huggingface/    # HuggingFace provider
│   ├── openai-compatible/ # OpenAI-compatible base
│   ├── elevenlabs/     # ElevenLabs speech provider
│   ├── lmnt/           # LMNT speech provider
│   ├── hume/           # Hume AI provider
│   ├── deepgram/       # Deepgram transcription provider
│   ├── assemblyai/     # AssemblyAI transcription provider
│   ├── gladia/         # Gladia transcription provider
│   ├── revai/          # Rev AI transcription provider
│   ├── fal/            # Fal image provider
│   ├── luma/           # Luma image provider
│   └── black-forest-labs/ # Black Forest Labs (FLUX) provider
├── examples/
│   └── simple.zig      # Example usage
└── tests/
    └── integration/    # Integration tests
```

## Requirements

- Zig 0.13.0 or later

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License
