---
name: sequence-diagrams
description: Generate Mermaid sequence diagrams for PR descriptions and technical docs. Use when the user asks for sequence diagrams, flow diagrams, architecture diagrams, or when creating PR descriptions that need visual documentation of a feature flow.
---

# Sequence Diagrams

Generate clear, focused Mermaid sequence diagrams for PR descriptions and technical documentation. Always produce **two separate diagrams** — one for UI interactions and one for service architecture — unless the user explicitly asks for only one.

## Before Drawing

1. **Ask the user** which flow to document and what the entry/end points are
2. **Explore the code** — trace the actual call chain using search tools before drawing. Never guess
3. **Confirm participants** — if the user doesn't specify, propose 3-5 participants per diagram and ask for approval before generating

## Diagram Types

### UI Diagram

Shows what the user **sees and interacts with**. Participants are visual surfaces, not code modules.

**Allowed participants:**
- `actor User` (always required)
- Screens, bottom sheets, modals, toasts — named by their visual role
- Use `<br/>` for context: `participant BS as Bottom Sheet UI<br/>(Wallet Created)`

**Forbidden:** Redux, Saga, selectors, presenters, hooks, stores, any internal code module.

**Include:**
- User taps, gestures, and choices (`alt` blocks)
- Visual transitions: animations, loading states, timing constraints
- Error states shown to the user (toasts, error screens)

### Service Diagram

Shows what **external systems and APIs** are called. Participants are process boundaries.

**Allowed participants:**
- `actor User` (always required)
- Our highest service layer that wraps everything internal (e.g., `DefiWalletService`)
- External SDKs, APIs, native modules, backends — one participant per external boundary

**Forbidden:** Redux, Saga, RTK Query, selectors, internal modules below the service layer (no `DeFiAuthModule`, `DynamicAuthProvider` — these collapse into the service).

**Participant selection rule:** Walk the call chain outward from the entry point. Every time you cross a **process boundary** (HTTP call, SDK bridge, WebView message, native module), that becomes a participant. Everything on our side collapses into a single service participant.

**Include:**
- HTTP methods + endpoint paths: `GET /sdk/{envId}/users/passkeys/register`
- Data shapes in responses: `Registration options (challenge, RP info)`
- Native prompts shown to the user: `Native WebAuthn prompt (iOS/Android)`
- Retry logic (`loop`), conditional paths (`alt`), optional steps (`opt`)

## Styling Conventions

- **Max 3-5 participants** per diagram. If you need more, split into two diagrams
- **Max ~25 lines** of diagram code. Longer means too many participants or too much detail
- **Always use aliases**: `participant WS as DefiWalletService`
- **Section with Notes**: `Note over X,Y: Phase Title` to separate major phases
- **Name the data, not the variable**: write `Registration options (challenge, RP info)` not `passkeyRegistrationOptions`
- **Error handling** at the end as `alt` or `opt` block — never skip it

## Anti-Patterns

- Including Redux/Saga/store in any diagram
- Showing internal module-to-module calls (e.g., AuthModule -> AuthProvider -> SDK)
- Exceeding 5 participants — collapse internal layers
- Omitting the User from service diagrams
- Mixing UI and service concerns in one diagram
- Using variable names instead of human-readable descriptions

## Examples

For detailed examples of both diagram types, see [examples.md](examples.md).
