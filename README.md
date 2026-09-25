# MangoZ SMP

Community hub for the MangoZ SMP Minecraft server: realtime chats (DMs + groups),
live server map, Java/Bedrock status, profiles, settings, and a secret Minesweeper game.

Built with Flutter + Supabase + `oreui_flutter` (Minecraft Ore UI aesthetic).

## Quick start

```bash
flutter pub get
dart analyze        # must report "No issues found!"
flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

> `flutter analyze` via the Flutter tool may crash on machines with a corrupted
> Flutter SDK cache (`ios_add2app` directory). `dart analyze` is the reliable
> equivalent and is clean on this project.

### Defaults (no flags needed to boot)

- Java: `mangozsmp.seedloaf.gg:56928`
- Bedrock: `mangozsmp.seedloaf.gg:54992`
- Map: `http://mangozsmp.seedloaf.gg:51260`

Without Supabase flags the app boots into a "Backend not configured" state
instead of crashing.

## Supabase setup

1. Create a project at supabase.com.
2. Run `supabase/schema.sql` in the SQL editor (tables, indexes, RLS, realtime).
3. Storage → create private buckets: `avatars`, `chat-images`,
   `voice-messages`, `group-images`, then apply the storage policies at the
   bottom of `schema.sql`.
4. Database → Replication → enable `messages`, `conversation_members`, `profiles`.
5. Auth → configure email provider / redirect URLs.

See `.env.example` for flags.

## Features

- Auth (email/password, reset), username onboarding (unique + validated),
  avatar upload (camera/gallery, Supabase Storage).
- WhatsApp-style DMs + groups, realtime via Supabase Realtime, text/image/voice,
  replies, soft-delete, unread counts, pagination, link previews (OpenGraph).
- Server page: Java + Bedrock status via `ServerStatusService`
  (mcsrvstat.us API + measured HTTP latency — no fake data, no raw sockets).
- Map page: fullscreen WebView, HTTP + HTTPS, reload/back/forward,
  open-in-browser, cleartext allowed on Android.
- Settings: account, chats, notifications, privacy (+blocked users),
  appearance (light/dark/system), server (hosts/ports/map URL/interval), app info.
- Easter egg: Settings → App → tap version 7× → MangoZ Minesweeper
  (easy/medium/hard/custom, flags, timer, best times).
- NOT end-to-end encrypted — stated honestly in Privacy settings.

## Project structure

See `lib/` — `config/`, `models/`, `services/`, `providers/` (Riverpod),
`screens/` (one file per page), `widgets/` (Ore-based), `theme/`.

## Notes

- `oreui_flutter` is consumed as the published `^0.0.2` package (same source as
  https://github.com/MCDFsteve/oreui_flutter). The git checkout's `pubspec.yaml`
  is UTF-16-encoded and unusable as a git dependency, so the hosted version is used.
- Android: `usesCleartextTraffic="true"` + INTERNET/RECORD_AUDIO/CAMERA permissions.
