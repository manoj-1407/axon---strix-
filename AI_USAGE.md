# AI Usage Report

This document details the cooperative development process of building the AXON AI Chat Assistant application, highlighting the interaction between the developer and AI tools.

## AI Tools Used
* **Claude 3.5 Sonnet / Gemini 1.5 Pro**: Used as primary pair-programming agents for architectural design, code generation, refactoring, and code analysis.
* **Flutter CLI / Build Runner**: Automating Dart code generation (Hive adapters).

---

## Prompts Used

Below are typical prompts and conceptual workflows used to collaborate with the AI models during development:

### 1. Project Architecture & Setup
> *"Set up a clean architecture project structure in Flutter with lib/core, lib/data, lib/domain, and lib/presentation. Use GetIt for dependency injection and Hive for local persistence. Generate the folder structure and initial config."*

### 2. BLoC State Management Setup
> *"Create a ChatBloc that handles sending messages, receiving responses, managing loading states, and handling exceptions. I want the bloc to be fully event-driven. Provide the event, state, and bloc files using Equatable."*

### 3. Local Data Persistence Schema
> *"Help me design the Hive adapters for Conversations, Messages, and AI Providers. We need to support nested lists and hot-reloadable configurations. How should we write the TypeAdapters without conflicts?"*

### 4. Server-Sent Events (SSE) Streaming
> *"How do we parse SSE stream data from a Dio HTTP Response stream for both OpenAI (data: {...}) and Google Gemini (generateContent stream)? Write a robust, custom stream controller parser that yields tokens sequentially."*

---

## Generated Code

Portions of the codebase that were generated or heavily assisted by AI templates:

1. **Boilerplate Entities & Models**: Initial fields for `Message`, `Conversation`, and `AiProvider` data models.
2. **Hive Adapters (`.g.dart`)**: Code generated automatically using `build_runner` and `hive_generator` for serialization/deserialization.
3. **Dependency Injection Setup**: Standard service locator registration boilerplate in `lib/core/di/service_locator.dart`.
4. **Theme Preset Config Map**: Hex colors and static style tables located in `lib/core/theme/app_colors.dart`.

---

## Manually Written Code & Custom Refactorings

Crucial core logic, edge cases, and architectural integrations that were manually structured and customized by the developer:

1. **Custom SSE Chunk Parser**: Hand-crafted chunk decoder in `AiRemoteDatasourceImpl` to parse partial JSON buffers and extract individual token deltas cleanly.
2. **Rate Limit 429 Interceptor & Countdown**: Custom exception handling, background periodic timer integration in `ChatBloc`, and the reactive countdown ticker UI in `ChatScreen`.
3. **Keyboard Shortcut Overlays**: Desktop/Web accessibility layer (`FocusNode`, `RawKeyboardListener`) wiring up `Ctrl+K` for the model picker and `Ctrl+/` for cheatsheets.
4. **Micro-Animations & Styles**: UI polish, custom terminal cursor animation (`▍`), and dynamic layout height adjustments for physical mobile devices.
5. **JSON Import/Export Verification**: Custom try-catch blocks verifying file integrity and parsing schemes during settings backups.

---

## Engineering Decisions

1. **Hive over SQLite**: Chosen due to its performance benefits as an offline-first key-value document store. Conversations and lists of messages are stored as document structures, which maps naturally to JSON-like API payloads.
2. **Custom HTTP Stream Parsing**: Bypassed third-party SSE plugins in favor of direct `Dio` stream handling. This minimizes dependency bloat and provides complete control over error interception (e.g. rate limit codes, connection timeouts).
3. **Sealed Bloc States & Immutable Events**: Guaranteed that all presentation views are strictly unidirectional, preventing side effects and making UI debugging straightforward.
