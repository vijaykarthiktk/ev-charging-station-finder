

# ChargeFind — EV Charging Station Finder & Slot Booking

Case Study - 44

Name - Vijaykarthik T K

Roll - 150096724008

Flutter app to find EV charging stations, check slot availability, book slots, and track spending. Postgres backend for stations/bookings/reviews; Hive for device-local prefs only.

## Features

- Station discovery: list, search, filter (charger type, connector, price, distance, open-now, availability), sort (nearest / price / availability / rating)
- Map view with station pins (`flutter_map` + `geolocator`)
- Station detail: slots, pricing, amenities, reviews/ratings
- Slot booking: date/time/charger pick → confirmation → active bookings → cancel
- Local reminder 30 min before booking (`flutter_local_notifications`, best-effort, never fails booking)
- Favorites, vehicle garage, spending summary, onboarding, profile, light/dark theme

## Tech stack

| Layer         | Choice                                             |
| ------------- | -------------------------------------------------- |
| UI            | Flutter, Material                                  |
| State         | `flutter_riverpod`                               |
| Backend       | Postgres (`postgres` package, PG16)              |
| Local prefs   | Hive (`favorites`, `vehicle`, `prefs` boxes) |
| Map/location  | `flutter_map`, `latlong2`, `geolocator`      |
| Notifications | `flutter_local_notifications` + `timezone`     |

Entry: `lib/main.dart` → inits Hive → `ReminderService.init()` → `ProviderScope(ChargeFindApp)` → `RootShell` (or `OnboardingScreen` on first run).

## Architecture

```
UI screens (lib/screens)
  → Riverpod providers (lib/providers: filter/search/composed list, bookings, reviews, favorites, vehicle, spending, location)
    → Repositories (lib/repositories: StationRepository / BookingRepository interfaces)
      → Postgres impls (stations, slots, bookings, reviews) | Hive impls (favorites, vehicle garage)
```

- `lib/providers/repository_providers.dart` wires `pgConnectionProvider` → repos → `ReminderService`.
- `filteredStationsProvider` = `stations + searchQuery + stationFilter + favorites + availability + reviewSummary`.
- `BookingController` validates via `StationRepository`, persists booking, fire-and-forget reminder.
- Navigation: no named routes. `RootShell` tab shell (`Home | Favorites | Bookings | Profile`, `IndexedStack`) + `Navigator.push` for detail / booking / filter.

## Project structure

```
lib/
  main.dart                    # bootstrap
  core/config/db_config.dart   # DB_HOST/PORT/NAME/USER/PASSWORD via --dart-define
  core/theme/app_theme.dart    # light/dark theme
  core/errors/ core/utils/     # AppException, formatters
  models/                      # charging_station, booking, charging_slot, review,
                               # vehicle_profile, charger_type, connector_type, availability_status
  repositories/                # *_repository.dart interfaces + postgres_*/hive impls
  providers/                   # station, station_filter, booking, review, favorites,
                               # vehicle, spending, location, onboarding, repository_providers
  services/reminder_service.dart
  screens/
    station_list/              # root_shell, station_list, map, filter, favorites,
                               # active_booking, onboarding, profile (+ legacy profile_page)
    station_detail/            # station_detail_screen
    slot_booking/              # slot_booking, booking_confirmation
  widgets/                     # station_card, booking_summary, charger_badge,
                               # availability_indicator, search_field, etc.
db/schema.sql                  # stations, bookings, reviews
db/seed.sql                    # seed stations
test/                          # unit + postgres_live_test (skips without DB)
```

## Database

Tables in `db/schema.sql`:

- `stations` — catalog: name, address, distance_km, lat/lng, price_per_kwh, charger_types[], connectors[], power_kw JSONB, total_slots, hours, amenities[], is_offline
- `bookings` — reservations: station_id FK, station_name, charger_type, date/start/end, price, energy_kwh, status (`confirmed|completed|cancelled`); partial index `bookings_station_window(station_id,start,end) WHERE confirmed` for overlap checks
- `reviews` — ratings: station_id FK, rating 1–5, comment, author; index on `(station_id, created_at)`

## Prerequisites

- Flutter SDK (Dart `^3.10.0`), `flutter doctor` clean
- Docker (Option A) **or** local Postgres 16 (Option B)

## Setup

**Option A — Docker (any machine):**

```sh
docker compose up -d   # creates DB + schema + seed stations
```

**Option B — Homebrew Postgres (this Mac):**

```sh
psql -d postgres -c "CREATE ROLE chargefind LOGIN PASSWORD 'chargefind';"
psql -d postgres -c "CREATE DATABASE chargefind OWNER chargefind;"
psql -d chargefind -c "GRANT CREATE ON SCHEMA public TO chargefind;"
psql -h 127.0.0.1 -U chargefind -d chargefind -f db/schema.sql
psql -h 127.0.0.1 -U chargefind -d chargefind -f db/seed.sql
```

Reset schema:

```sh
psql -h 127.0.0.1 -U chargefind -d chargefind -f db/schema.sql
```

## Run

Defaults (`127.0.0.1:5432/chargefind/chargefind/chargefind`, `SslMode.disable`) match both setups above:

```sh
flutter pub get
flutter run -d macos
```

Custom database:

```sh
flutter run -d macos --dart-define=DB_HOST=db.example.com \
  --dart-define=DB_PORT=5432 --dart-define=DB_NAME=chargefind \
  --dart-define=DB_USER=chargefind --dart-define=DB_PASSWORD=secret
```

`DbConfig.fromEnvironment()` reads `DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD` (`lib/core/config/db_config.dart`). Local/dev Postgres runs without TLS; for a managed instance with TLS switch `SslMode.disable` → `SslMode.require`.

## Test

```sh
flutter test
```

Covers filter, booking flow, reviews, vehicle garage, spending (`test/`). `test/postgres_live_test.dart` does a live Postgres roundtrip and skips cleanly when no DB is up.

## Notes / known issues

- `profile_page.dart` + `profile_screen.dart` are a duplicate legacy pair; keep one.
- Notifications are local-only; no push backend.
- Hive stores favorites/garage per device — no cross-device sync.
