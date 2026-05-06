언어: [영어(English)](README.md) | [한국어](README-ko.md)

# CodexBar 🎚️ - 토큰이 떨어지지 않기를.

AI 코딩 제공자의 사용 한도를 메뉴 막대에 계속 표시하고, 각 사용량 창이 언제 초기화되는지 보여 주는 작은 macOS 14+ 메뉴 막대 앱입니다. CodexBar는 Codex, Claude, Cursor, Gemini, Copilot, z.ai, Kiro, Vertex AI, Augment, OpenRouter, Codebuff 및 여러 최신 코딩 제공자를 지원합니다. 제공자별로 상태 항목을 하나씩 표시하거나, Merge Icons 모드에서 제공자 전환기를 사용할 수 있습니다. 설정에서 사용하는 제공자만 활성화하세요. Dock 아이콘 없이 최소한의 UI와 동적인 메뉴 막대 아이콘을 제공합니다.

<img src="codexbar.png" alt="CodexBar 메뉴 스크린샷" width="520" />

## 설치

### 요구 사항
- macOS 14+(Sonoma)

### GitHub Releases
다운로드: <https://github.com/steipete/CodexBar/releases>

### Homebrew
```bash
brew install --cask steipete/tap/codexbar
```

### CLI Tarballs(macOS/Linux)
Homebrew formula(현재 Linux):
```bash
brew install steipete/tap/codexbar
```
또는 GitHub Releases에서 release tarball을 다운로드하세요.
- macOS: `CodexBarCLI-v<tag>-macos-arm64.tar.gz`, `CodexBarCLI-v<tag>-macos-x86_64.tar.gz`
- Linux: `CodexBarCLI-v<tag>-linux-aarch64.tar.gz`, `CodexBarCLI-v<tag>-linux-x86_64.tar.gz`

### 첫 실행
- Settings → Providers를 열고 사용하는 제공자를 활성화하세요.
- 제공자에 따라 CLI, 브라우저 세션, OAuth/device flow, API 키, 로컬 앱 파일 또는 제공자 앱 등 의존하는 제공자 소스를 설치하거나 로그인하세요.
- 선택 사항: Settings → Providers → Codex → OpenAI cookies(Automatic 또는 Manual)에서 대시보드 추가 정보를 활성화할 수 있습니다.

## 제공자

- [Codex](docs/codex.md) — OAuth API 또는 로컬 Codex CLI, 선택적 OpenAI 웹 대시보드 추가 정보.
- [Claude](docs/claude.md) — OAuth API, 브라우저 쿠키 또는 CLI PTY fallback. 가능한 경우 세션 및 주간 사용량.
- [Cursor](docs/cursor.md) — 요금제, 사용량, 결제 초기화 정보를 위한 브라우저 세션 쿠키.
- [OpenCode](docs/opencode.md) — workspace subscription 사용량을 위한 브라우저 쿠키.
- [OpenCode Go](docs/opencode.md) — Go 사용량 창을 위한 브라우저 쿠키.
- [Alibaba Coding Plan](docs/alibaba-coding-plan.md) — coding-plan quota를 위한 웹 쿠키 또는 API 키.
- [Gemini](docs/gemini.md) — Gemini CLI 자격 증명을 사용하는 OAuth 기반 quota API(브라우저 쿠키 없음).
- [Antigravity](docs/antigravity.md) — 로컬 language server probe(실험적). 외부 인증 없음.
- [Droid](docs/factory.md) — Factory 사용량 및 결제를 위한 브라우저 쿠키 + WorkOS 토큰 흐름.
- [Copilot](docs/copilot.md) — GitHub device flow + Copilot 내부 사용량 API.
- [z.ai](docs/zai.md) — quota + MCP windows를 위한 API 토큰.
- [MiniMax](docs/minimax.md) — coding-plan 사용량을 위한 API 토큰, cookie header 또는 브라우저 쿠키.
- [Kimi](docs/kimi.md) — 주간 quota + 5시간 rate limit을 위한 인증 토큰(`kimi-auth` 쿠키의 JWT).
- [Kimi K2](docs/kimi-k2.md) — credit 기반 사용량 합계를 위한 API 키.
- [Kilo](docs/kilo.md) — Kilo Pass 사용량을 위한 API 토큰과 CLI 인증 fallback.
- [Kiro](docs/kiro.md) — CLI 기반 사용량. 월간 credits + bonus credits.
- [Vertex AI](docs/vertexai.md) — 로컬 Claude 로그의 token cost tracking을 포함한 Google Cloud gcloud OAuth.
- [Augment](docs/augment.md) — credits 추적 및 사용량 모니터링을 위한 Augment CLI 또는 브라우저 쿠키.
- [Amp](docs/amp.md) — Amp Free 사용량 추적을 위한 브라우저 쿠키 기반 인증.
- [Ollama](docs/ollama.md) — Ollama Cloud 사용량 창을 위한 브라우저 쿠키.
- [JetBrains AI](docs/jetbrains.md) — JetBrains IDE 설정의 로컬 XML 기반 quota. 월간 credits 추적.
- [Warp](docs/warp.md) — GraphQL request limit 및 월간 credits를 위한 API 토큰.
- [OpenRouter](docs/openrouter.md) — 여러 AI 제공자에 걸친 credit 기반 사용량 추적용 API 토큰.
- Perplexity — Perplexity 사용량 데이터의 계정 사용 credits.
- [Abacus AI](docs/abacus.md) — ChatLLM/RouteLLM compute credit 추적을 위한 브라우저 쿠키 인증.
- Mistral — 월간 spend 추적을 위한 브라우저 쿠키.
- [DeepSeek](docs/deepseek.md) — credit 잔액 추적을 위한 API 키(유료/지급분 구분).
- [Codebuff](docs/codebuff.md) — credit 잔액 + 주간 rate limit을 위한 API 토큰 또는 `~/.config/manicode/credentials.json`.
- 새 제공자 추가를 환영합니다: [provider authoring guide](docs/provider.md).

## 아이콘 및 스크린샷
메뉴 막대 아이콘은 작은 usage meter입니다. 막대의 의미는 제공자별로 다르며, 오류나 오래된 데이터가 있으면 아이콘이 흐려지거나 incident indicator가 표시될 수 있습니다.

## 기능
- 제공자별 토글이 있는 멀티 제공자 메뉴 막대(Settings → Providers).
- reset countdown이 포함된 제공자별 usage meter.
- 선택적 Codex 웹 대시보드 보강 정보(code review 잔여량, 사용량 breakdown, credits 기록).
- Codex + Claude 로컬 비용 사용량 scan(최근 30일).
- 메뉴와 아이콘 overlay에 incident badge를 표시하는 제공자 status polling.
- 여러 제공자를 하나의 status item + switcher로 결합하는 Merge Icons 모드.
- 제공자 아이콘, label, bar, reset-time style, highest-usage auto-selection을 위한 display controls.
- refresh cadence preset(수동, 1m, 2m, 5m, 15m).
- scripts와 CI를 위한 번들 CLI(`codexbar`). 로컬 비용 사용량을 위한 `codexbar cost --provider codex`, `claude` 또는 `both` 포함. macOS 및 Linux CLI build 제공.
- 지원 제공자를 위한 WidgetKit widgets.
- 선택적 session quota 알림 및 weekly-reset confetti.
- privacy-first: 기본적으로 on-device parsing을 사용하며, 브라우저 쿠키는 opt-in으로 재사용됩니다(비밀번호 저장 없음).

## 개인정보 참고
CodexBar가 디스크를 scan하는지 궁금하신가요? CodexBar는 파일시스템을 크롤링하지 않습니다. 관련 기능이 활성화된 경우에만 알려진 일부 위치(브라우저 쿠키/로컬 저장소, 제공자 config files, 로컬 JSONL 로그)를 읽습니다. 제공자 토큰과 token-account 설정은 제한적인 파일 권한으로 `~/.codexbar/config.json`에 저장됩니다. 자세한 논의와 audit notes는 [issue #12](https://github.com/steipete/CodexBar/issues/12)를 참고하세요.

## macOS 권한(필요한 이유)
- **Full Disk Access(선택 사항)**: 웹 기반 제공자의 Safari 쿠키/로컬 저장소를 읽을 때만 필요합니다. 권한을 부여하지 않으면 다른 지원 브라우저, manual cookies/API keys, OAuth 또는 해당 제공자가 지원하는 CLI/local sources를 사용하세요.
- **Keychain access(macOS가 표시하는 prompt)**:
  - Chromium cookie import는 쿠키 복호화를 위해 브라우저의 “Safe Storage” 키가 필요합니다.
  - CodexBar에 사용 가능한 cached credentials가 없을 때 Claude OAuth bootstrap이 Claude CLI Keychain 항목을 읽을 수 있습니다.
  - CodexBar는 브라우저 쿠키 복호화, cached cookie headers, 그리고 해당 소스가 요구하는 OAuth/device-flow credentials에 Keychain을 사용할 수 있습니다.
  - **이 keychain 알림을 막으려면 어떻게 하나요?**
    - **Keychain Access.app** → login keychain을 열고 prompt에 나온 항목을 검색하세요. Claude OAuth의 경우 보통 “Claude Code-credentials”입니다.
    - 항목을 열고 **Access Control** → “Always allow access by these applications” 아래에 `CodexBar.app`을 추가하세요.
    - 가능하면 CodexBar만 추가하세요. 넓게 허용하려는 경우가 아니라면 “Allow all applications”는 피하는 것이 좋습니다.
    - 저장 후 CodexBar를 다시 실행하세요.
    - 참고 스크린샷: ![Keychain access control](docs/keychain-allow.png)
  - **브라우저도 같은 방식으로 처리하려면?**
    - 브라우저의 “Safe Storage” 키를 찾으세요. 예: “Chrome Safe Storage”, “Brave Safe Storage”, “Microsoft Edge Safe Storage”.
    - 항목을 열고 **Access Control** → “Always allow access by these applications” 아래에 `CodexBar.app`을 추가하세요.
    - 이렇게 하면 CodexBar가 해당 브라우저의 쿠키를 복호화할 때 prompt가 사라집니다.
- **Files & Folders prompts(폴더/볼륨 접근)**: CodexBar는 일부 제공자를 위해 제공자 CLI와 로컬 probe를 실행합니다. 이 helper들이 프로젝트 디렉터리나 외장 드라이브를 읽으면 macOS가 CodexBar에 해당 폴더/볼륨 권한을 요청할 수 있습니다. 예: Desktop 또는 외장 볼륨. 이는 백그라운드 디스크 scan이 아니라 helper의 작업 디렉터리 때문에 발생합니다.
- **백그라운드에서 요청하지 않는 권한**: Screen Recording 또는 Accessibility 권한은 요청하지 않습니다. 사용자가 실행한 helper action은 Terminal을 열기 위해 macOS Automation 권한을 요청할 수 있습니다. 비밀번호는 저장하지 않습니다(브라우저 쿠키는 opt-in 시 재사용).

## 문서
- 제공자 개요: [docs/providers.md](docs/providers.md)
- 제공자 작성: [docs/provider.md](docs/provider.md)
- issue labeling guide: [docs/ISSUE_LABELING.md](docs/ISSUE_LABELING.md)
- UI 및 아이콘 notes: [docs/ui.md](docs/ui.md)
- CLI reference: [docs/cli.md](docs/cli.md)
- Configuration: [docs/configuration.md](docs/configuration.md)
- Widgets: [docs/widgets.md](docs/widgets.md)
- Architecture: [docs/architecture.md](docs/architecture.md)
- Refresh loop: [docs/refresh-loop.md](docs/refresh-loop.md)
- Status polling: [docs/status.md](docs/status.md)
- Sparkle updates: [docs/sparkle.md](docs/sparkle.md)
- Packaging: [docs/packaging.md](docs/packaging.md)
- Development: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- Release checklist: [docs/RELEASING.md](docs/RELEASING.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)

## 시작하기(dev)
- 저장소를 clone하고 Xcode에서 열거나 scripts를 직접 실행하세요.
- 한 번 실행한 뒤 Settings → Providers에서 제공자를 토글하세요.
- 의존하는 제공자 소스(CLI, 브라우저 쿠키, OAuth/device flow, API 키 또는 로컬 앱/config 파일)에 설치/로그인하세요.
- 선택 사항: Codex 대시보드 추가 정보를 위해 OpenAI cookies(Automatic 또는 Manual)를 설정하세요.

## 소스에서 build
macOS 14+ 및 Swift 6.2+가 필요합니다.

```bash
./Scripts/package_app.sh        # CodexBar.app을 현재 위치에 build
CODEXBAR_SIGNING=adhoc ./Scripts/package_app.sh  # ad-hoc signing(Apple Developer 계정 없음)
open CodexBar.app
```

Dev loop:
```bash
./Scripts/compile_and_run.sh
./Scripts/compile_and_run.sh --test  # packaging/relaunch 전에 swift test도 실행
pnpm check                           # SwiftFormat + SwiftLint
pnpm docs:list                       # frontmatter summary와 함께 docs 목록 표시
```

CLI install:
```bash
# /Applications에 CodexBar.app을 설치한 뒤
./bin/install-codexbar-cli.sh
```

## 관련 프로젝트
- ✂️ [Trimmy](https://github.com/steipete/Trimmy) — “Paste once, run once.” 여러 줄 shell snippet을 붙여넣고 바로 실행되도록 평탄화합니다.
- 🧳 [MCPorter](https://mcporter.dev) — Model Context Protocol 서버를 위한 TypeScript toolkit + CLI.
- 🧿 [oracle](https://askoracle.dev) — 막혔을 때 oracle에게 물어보세요. custom context와 files로 GPT-5 Pro를 호출합니다.

## Windows 버전을 찾고 있나요?
- [Win-CodexBar](https://github.com/Finesssee/Win-CodexBar)

## Credits
[ccusage](https://github.com/ryoppippi/ccusage)(MIT), 특히 비용 사용량 추적에서 영감을 받았습니다.

## License
MIT • Peter Steinberger([steipete](https://twitter.com/steipete))
