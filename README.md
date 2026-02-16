# Prayer List v2 - Flutter Migration

React Native → Flutter migration of Prayer List application.

## Quick Start

1. **Read**: [AGENTS.md](AGENTS.md) - Main guide for AI agents
2. **Understand**: [docs/background/legacy-app.md](docs/background/legacy-app.md) - What we're migrating
3. **Implement**: Follow step-by-step guides in [docs/implementation/](docs/implementation/)

## Documentation Structure

```
AGENTS.md                        ← START HERE (main guide)
docs/
├── background/                  ← Understanding
│   ├── legacy-app.md           - React Native app overview
│   ├── architecture.md         - Flutter clean architecture
│   └── colors.md               - Exact color values
│
├── setup/                       ← Initial configuration
│   └── dependencies.md         - Package list
│
├── implementation/              ← Step-by-step guides
│   ├── step1-setup.md          - Project setup
│   ├── step2-colors-theme.md   - Theme system
│   ├── step3-data-models.md    - Prayer models
│   ├── step4-database.md       - Supabase integration
│   └── step5-auth.md           - Kakao login
│
└── reference/                   ← Quick lookup
    ├── checklist.md            - Complete task list
    └── file-structure.md       - Important files
```

## Current Status

**Phase**: Setup
**Next**: Follow `docs/implementation/step1-setup.md`

## For AI Coding Agents

**Read documents in this order**:
1. `AGENTS.md` (overview)
2. `docs/background/legacy-app.md` (what to preserve)
3. `docs/implementation/stepX-xxx.md` (specific task)
4. `docs/reference/` (as needed)

**All documents are SHORT** (~100-300 lines each) for easy consumption.

## Commands

```bash
# Install
flutter pub get

# Run
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=KAKAO_APP_KEY=$KAKAO_APP_KEY

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Test
flutter test
```

## Key Principles

- **PRESERVE**: All UI, colors (exact hex), logic, database
- **IMPROVE**: Performance, code quality
- **APPROACH**: Test-driven, incremental, clean architecture

## Legacy Codebase

React Native source: `/Users/kim-yoochan/coding/pray_list_web`
