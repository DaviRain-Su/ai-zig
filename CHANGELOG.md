# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-19

### Added

- Initial release of the Zig AI SDK
- Core provider interfaces:
  - `LanguageModelV3` - Language model interface with vtable pattern
  - `EmbeddingModelV3` - Embedding model interface
  - `ImageModelV3` - Image generation model interface
  - `SpeechModelV3` - Speech synthesis model interface
  - `TranscriptionModelV3` - Transcription model interface
  - `ProviderV3` - Unified provider interface

- High-level API functions (`packages/ai`):
  - `generateText` / `streamText` - Text generation with tool calling support
  - `generateObject` / `streamObject` - Structured JSON output generation
  - `embed` / `embedMany` - Text embedding generation
  - `generateImage` - Image generation from text prompts
  - `generateSpeech` / `streamSpeech` - Text-to-speech synthesis
  - `transcribe` - Speech-to-text transcription

- Provider implementations (32 providers):
  - **OpenAI** - GPT-4, GPT-4o, o1, DALL-E, Whisper, TTS
  - **Anthropic** - Claude 3.5, Claude 4
  - **Google** - Gemini 2.0, Gemini 1.5
  - **Google Vertex AI** - Gemini on Vertex
  - **Azure OpenAI** - Azure-hosted OpenAI models
  - **Amazon Bedrock** - Claude, Titan, Llama
  - **Mistral** - Mistral Large, Codestral, Magistral
  - **Cohere** - Command R+, reranking
  - **Groq** - Llama, Mixtral (fast inference)
  - **DeepSeek** - DeepSeek Chat, DeepSeek Reasoner
  - **xAI** - Grok
  - **Perplexity** - Online search models
  - **Together AI** - Various open models
  - **Fireworks** - Fast inference
  - **Cerebras** - Fast inference
  - **DeepInfra** - Various open models
  - **Replicate** - Model hosting
  - **HuggingFace** - Inference API
  - **OpenAI Compatible** - Base for OpenAI-compatible APIs
  - **ElevenLabs** - High-quality TTS
  - **LMNT** - Aurora, Blizzard voices
  - **Hume** - Empathic voice interface
  - **Deepgram** - Nova 2 transcription, Aura TTS
  - **AssemblyAI** - Transcription + LeMUR
  - **Gladia** - Transcription with translation
  - **Rev AI** - Transcription
  - **Fal** - FLUX, Stable Diffusion
  - **Luma** - Dream Machine
  - **Black Forest Labs** - FLUX Pro/Dev/Schnell

- Utility features:
  - Tool/function calling with approval workflows
  - Middleware system for request/response transformation
  - Similarity functions (cosine, euclidean, dot product)
  - ID generation utilities

- Memory management:
  - Arena-based allocation for request lifecycle
  - Callback-based streaming (non-async)
  - Vtable pattern for interface abstraction

- Build system:
  - Root `build.zig` with all provider modules
  - `build.zig.zon` package manifest
  - Example application
  - Integration tests

### Architecture

- Uses Zig's comptime features for type safety
- Arena allocators for efficient memory management
- Callback-based streaming instead of async/await
- Vtable pattern for provider interfaces
- JSON handling via `std.json`
