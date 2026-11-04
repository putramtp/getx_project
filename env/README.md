# Build-time API config

The app has no built-in API host. Every run and build passes one of these files:

```bash
flutter run --dart-define-from-file=env/dev.json
patrol test -t patrol_test/login_test.dart --device <id> --dart-define-from-file=env/dev.json
flutter build apk --release --dart-define-from-file=env/prod.json
```

Only the `*.example.json` files are committed; copy one to `<name>.json` and fill it in.

| Key | Meaning |
|---|---|
| `CENTRAL_API_URL` | **Workspace mode** — the central host's API (`https://app.<domain>/api`). Email sign-in, then each company's own host. |
| `API_BASE_URL` | **Direct mode** — one company's API, old `POST /login`. Used when `CENTRAL_API_URL` is not set. |
| `DEV_CONNECT_ADDRESS` | Debug builds only. Connect to this address (e.g. `127.0.0.1` with `adb reverse tcp:80 tcp:80`) while sending the real host as `Host`, so no tunnel is needed. |
| `API_TIMEOUT_SECONDS` | Request timeout (default 30). |

- `dev.example.json` — workspace mode (email sign-in) against the local backend over USB, no tunnel: run `adb reverse tcp:80 tcp:80` first.
- `direct.example.json` — one company host (e.g. an ngrok tunnel, or `http://mc.mastersystembackend.test/api` with `DEV_CONNECT_ADDRESS` over USB).
- `prod.example.json` — release: the central host only.

Local files used on the dev machine (gitignored): `dev.json` (direct, ngrok), `dev-usb.json` (direct, USB), `dev-workspace.json` (workspace, USB).

See `docs/superpowers/specs/2026-10-27-multi-tenant-production-design.md`.
