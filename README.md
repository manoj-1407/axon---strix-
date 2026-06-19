# AXON

> A precision AI interface — provider-agnostic, offline-first, bloc-native.

AXON is a production-grade Flutter AI chat client built for engineers who care about architecture. It connects to any OpenAI-compatible API endpoint, Google Gemini, or Anthropic Claude — without vendor lock-in, without telemetry, and without cloud dependency.

---

## Features

### Core Chat
- **Multi-provider support** — OpenAI, Gemini, Anthropic, Ollama, LM Studio, and any OpenAI-compatible endpoint
- **Streaming responses** — token-by-token rendering via SSE with live `▍` cursor
- **Voice input** — speech-to-text via `speech_to_text` with continuous listening mode
- **Image & file attachments** — send screenshots, photos, or documents to vision-capable models (Gemini 1.5, GPT-4o)
- **Message editing** — inline edit of sent messages with `[edited]` indicator
- **Message deletion** — long-press context menu for individual message removal
- **Copy to clipboard** — one-tap copy on any AI response bubble
- **Token usage display** — per-message token count rendered beneath each AI bubble
- **Cost footer** — cumulative session token count and estimated cost shown at the bottom of every chat

### Conversations
- **Pinned conversations** — pin-to-top with push_pin indicator in the tile
- **Unread indicators** — bold title and blue dot for conversations with new AI responses
- **Tags / folders** — assign arbitrary text tags, filter the conversation list by tag
- **Search** — full-text search across conversation titles and message previews
- **Rename & delete** — long-press tile for a context menu with all management actions
- **Sorted list** — pinned conversations always appear above recents

### Model & Persona
- **Model picker** — swap models mid-conversation without leaving the chat screen (Ctrl+K)
- **Model metadata** — param count, release date, and cost per 1M tokens shown in picker
- **System prompt** — editable per-conversation system prompt with collapsible sheet
- **Persona templates** — one-tap presets: Code Reviewer, Creative Writer, Socratic Tutor, Data Analyst, Devil's Advocate

### Settings
- **Provider management** — add, edit, and delete providers with base URL + API key configuration
- **Model selection** — live fetch of available models from any provider's `/models` endpoint
- **Streaming toggle** — switch between streaming and single-shot response modes
- **Export / Import** — backup all provider configurations to a local JSON file and restore on any device

### Reliability
- **Rate-limit handling** — exponential backoff with live countdown display on `429` responses
- **Retry button** — one-tap retry on any failed message
- **Offline detection** — `connectivity_plus` used to surface network state in the status bar
- **Connection test** — verify a new provider configuration before saving

### Keyboard Shortcuts
| Shortcut | Action |
|---|---|
| `Ctrl + K` | Open model picker |
| `Ctrl + /` | Show shortcuts cheatsheet |
| `Esc` | Back to conversations list |

---

## Architecture

AXON uses strict **Clean Architecture** with **BLoC** as the state management layer:

```
lib/
├── core/
│   ├── constants/       # AppConstants (version, timeouts, defaults)
│   ├── di/              # GetIt service locator + injectable setup
│   ├── errors/          # Typed exceptions (RateLimitException, NetworkException, …)
│   └── theme/           # AppColors — single source of truth for the design system
│
├── domain/
│   ├── entities/        # Pure Dart models: Message, Conversation, AiProvider, AiResponse
│   └── repositories/    # Abstract interfaces: AiRepository, ConversationRepository, SettingsRepository
│
├── data/
│   ├── datasources/
│   │   ├── local/       # HiveLocalDatasource — offline-first persistence
│   │   └── remote/      # AiRemoteDatasourceImpl — Dio HTTP + SSE streaming
│   ├── models/          # Hive adapters: MessageModel, ConversationModel (with manual .g.dart)
│   └── repositories/    # Concrete implementations of domain interfaces
│
└── presentation/
    ├── blocs/
    │   ├── chat/         # ChatBloc — sends messages, manages streaming, backoff timers
    │   ├── conversation/ # ConversationBloc — CRUD, search, pin, tags, unread
    │   └── settings/     # SettingsBloc — provider management, export/import, preferences
    ├── screens/          # Full-page StatefulWidget screens
    └── widgets/          # Reusable presentational components
```

### State Flow

```
User tap
  → ChatEvent (e.g. SendMessageStream)
  → ChatBloc._onSendMessageStream()
  → AiRepository.sendMessageStream()
  → AiRemoteDatasourceImpl (Dio SSE)
  → StreamTokenReceived events → ChatStreaming state → UI rebuild
  → StreamCompleted → ChatSuccess state with token count
```

All BLoC events are **immutable** (Equatable), all states are **sealed**, and repositories are **abstract interfaces** — making the full stack unit-testable in isolation.

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.2.0
- Dart SDK ≥ 3.2.0
- An API key from at least one provider (OpenAI, Google AI Studio, Anthropic, or a self-hosted endpoint)

### Setup

```bash
git clone <repo>
cd axon
flutter pub get
flutter run
```

> No `.env` file needed — API keys are stored locally on-device via Hive, entered through the in-app Settings screen.

### First Run
1. Tap the **⚙ settings** icon on the conversation list
2. Under `[PROVIDERS]`, tap `+ add provider`
3. Fill in your provider name, base URL, API key, and model name
4. Tap `test connection` to verify — green means you're ready
5. Return to the list and tap `+ new` to start chatting

---

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management (BLoC pattern) |
| `hive` / `hive_flutter` | Offline-first local storage |
| `dio` | HTTP client with SSE streaming support |
| `get_it` + `injectable` | Dependency injection |
| `flutter_markdown` | Markdown rendering in chat bubbles |
| `google_fonts` | Space Grotesk + JetBrains Mono typography |
| `flutter_animate` | Micro-animations and transitions |
| `speech_to_text` | Voice input |
| `image_picker` | Camera / gallery for attachments |
| `file_picker` | Document attachments |
| `path_provider` | Settings export file path resolution |
| `connectivity_plus` | Network state detection |
| `uuid` | Conversation and message ID generation |
| `equatable` | Value equality for BLoC events/states |
| `intl` | Date formatting in conversation tiles |

---

## Testing

```bash
# Unit tests
flutter test

# Lint
flutter analyze

# With coverage
flutter test --coverage
```

Tests are organized under `test/` mirroring the `lib/` structure:
- `test/domain/` — entity and repository contract tests
- `test/data/` — datasource and model tests (with mocktail mocks)
- `test/presentation/blocs/` — bloc_test driven BLoC tests

---

## Design System

All colors live in [`lib/core/theme/app_colors.dart`](lib/core/theme/app_colors.dart) under the `C` alias. The palette is a **dark monochrome terminal aesthetic** — black backgrounds, white text, green accent — with deliberate restraint:

| Token | Hex | Role |
|---|---|---|
| `C.bg` | `#0A0A0A` | Screen background |
| `C.surface` | `#111111` | Card / input background |
| `C.card` | `#141414` | Elevated surface |
| `C.accent` | `#00FF88` | Primary CTA, active state |
| `C.accentDim` | `#00FF8815` | Accent wash / badge background |
| `C.border` | `#1E1E1E` | All dividers and borders |
| `C.white` | `#F0F0F0` | Primary text |
| `C.grey1` | `#888888` | Secondary text |
| `C.grey2` | `#444444` | Muted / timestamps |
| `C.error` | `#FF4444` | Destructive actions |
| `C.code` | `#00AAFF` | Code block accent |

---
