# Sequence Diagram Examples

Real examples from the project, organized by type and complexity.

## UI Diagrams

### Simple — Single bottom sheet with user choices

```mermaid
sequenceDiagram
    actor User
    participant UI as Bottom Sheet UI
    participant Saga as DeFiWalletSaga

    User->>Saga: Tap "Create Wallet" → createWallet.requested()
    Saga->>UI: Show CREATING_WALLET bottom sheet
    UI->>UI: Display dots animation + "Creating your DeFi Wallet"

    Saga->>UI: Wallet created
    UI->>UI: Fade out "Creating" content (300ms)
    UI->>UI: Fade in "Wallet Created" content (400ms)
    UI->>UI: Spring animate illustration + haptic feedback

    alt User taps "Setup Passkey"
        User->>UI: Tap → hide bottom sheet
    else User taps "Perhaps later"
        User->>UI: Tap → hide bottom sheet
    end

    Note over Saga,UI: Error Handling
    alt API call fails
        Saga->>UI: Hide bottom sheet
        Saga->>User: Show error toast
    end
```

### Medium — Multiple UI surfaces with entry points

```mermaid
sequenceDiagram
    actor User
    participant WalletCreated as Bottom Sheet UI<br/>(Wallet Created)
    participant EmptyState as Screen UI<br/>(No Passkey Empty State)
    participant PasskeyCreated as Bottom Sheet UI<br/>(Passkey Created)

    alt Trigger: Wallet Created bottom sheet
        User->>WalletCreated: Tap "Setup Passkey"
        WalletCreated->>WalletCreated: Hide bottom sheet
    else Trigger: DeFiWallet no-passkey empty state
        User->>EmptyState: Tap "Create Passkey"
    end

    Note over User,PasskeyCreated: Passkey creation in progress (native flow)

    User->>PasskeyCreated: Passkey created successfully
    PasskeyCreated->>PasskeyCreated: Show success illustration, title, description

    alt User taps "Continue"
        User->>PasskeyCreated: Tap "Continue"
        PasskeyCreated->>PasskeyCreated: Hide bottom sheet
    else User taps "Add Funds"
        User->>PasskeyCreated: Tap "Add Funds"
        PasskeyCreated->>PasskeyCreated: Hide bottom sheet
    end
```

## Service Diagrams

### Simple — Single external SDK (3-4 participants)

Best for flows that touch one external system.

```mermaid
sequenceDiagram
    actor User
    participant WS as DefiWalletService
    participant WebView as Dynamic SDK WebView
    participant API as Dynamic API

    User->>WS: Tap "Setup Passkey" / "Create Passkey"
    WS->>WebView: passkey.register()

    WebView->>API: GET /sdk/{envId}/users/passkeys/register
    API-->>WebView: Registration options (challenge, RP info)

    WebView->>User: Native WebAuthn prompt (iOS/Android)
    User-->>WebView: Biometric confirmation

    WebView->>API: POST /sdk/{envId}/users/passkeys/register
    API-->>WebView: VerifyResponse (passkey registered)

    WebView-->>WS: Success
    WS-->>User: Show "Passkey Created" bottom sheet
```

### Complex — Multiple external systems (4-5 participants)

Best for flows that span multiple backends, SDKs, or auth providers.

```mermaid
sequenceDiagram
    actor User
    participant FE as Frontend (React Native)
    participant Auth0 as Auth0
    participant BE as Bitvavo Backend
    participant DY as Dynamic API

    Note over User,DY: Authentication
    FE->>BE: POST /defi-auth/access-token (userId)
    BE-->>FE: Bitvavo JWT
    FE->>DY: POST /externalAuth/signin (jwt)
    DY-->>FE: Dynamic JWT + User (wallets[])

    Note over User,DY: Wallet Creation
    User->>FE: Tap "Create Wallet"

    Note over FE,Auth0: Credential Verification
    FE->>Auth0: webAuth.authorize(deviceId)
    Auth0-->>User: Show login prompt (biometric/password)
    User-->>Auth0: Authenticate
    Auth0-->>FE: Auth0 credentials

    Note over FE,BE: Passphrase Resolution
    FE->>BE: GET /passphrase (guid)
    alt 404 — not found
        BE-->>FE: 404
        FE->>BE: POST /passphrase (guid)
        BE-->>FE: 201
        FE->>BE: GET /passphrase (guid)
    end
    BE-->>FE: { passphrase }

    Note over FE,DY: Embedded Wallet Creation
    loop For each enabled chain (EVM, SOL)
        FE->>DY: createWallet({ chain, password: passphrase })
        alt Failure (retry up to 2x)
            DY-->>FE: Error
            FE->>DY: createWallet (retry)
        end
        DY-->>FE: Wallet created
    end

    FE-->>User: Show success bottom sheet
```

## Choosing Between Simple and Complex

| Signal | Use Simple (3-4 participants) | Use Complex (4-5 participants) |
|--------|-------------------------------|--------------------------------|
| External systems | 1 SDK/API | 2+ SDKs/APIs |
| Auth involved | No separate auth step | Auth0, JWT exchange, etc. |
| Retry/branching | Minimal | Multiple conditional paths |
| Diagram length | ~15 lines | ~25 lines max |
