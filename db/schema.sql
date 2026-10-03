-- ChargeFind schema. Run: psql -h 127.0.0.1 -U chargefind -d chargefind -f db/schema.sql

CREATE TABLE IF NOT EXISTS stations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  distance_km DOUBLE PRECISION NOT NULL,
  latitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  price_per_kwh DOUBLE PRECISION NOT NULL,
  charger_types TEXT[] NOT NULL,
  connectors TEXT[] NOT NULL,
  power_kw JSONB NOT NULL DEFAULT '{}',
  total_slots INTEGER NOT NULL,
  operating_start_hour INTEGER NOT NULL,
  operating_end_hour INTEGER NOT NULL,
  amenities TEXT[] NOT NULL,
  is_offline BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS bookings (
  id TEXT PRIMARY KEY,
  station_id TEXT NOT NULL REFERENCES stations(id),
  station_name TEXT NOT NULL,
  charger_type TEXT NOT NULL,
  date DATE NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  price_per_kwh DOUBLE PRECISION NOT NULL,
  estimated_price DOUBLE PRECISION NOT NULL,
  energy_kwh DOUBLE PRECISION NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'confirmed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Live-availability lookups: confirmed bookings overlapping a window.
CREATE INDEX IF NOT EXISTS bookings_station_window
  ON bookings (station_id, start_time, end_time)
  WHERE status = 'confirmed';

CREATE TABLE IF NOT EXISTS reviews (
  id TEXT PRIMARY KEY,
  station_id TEXT NOT NULL REFERENCES stations(id),
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT NOT NULL DEFAULT '',
  author TEXT NOT NULL DEFAULT 'EV Driver',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS reviews_station_idx
  ON reviews (station_id, created_at DESC);
