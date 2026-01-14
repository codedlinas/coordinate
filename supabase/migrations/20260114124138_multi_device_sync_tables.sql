-- =============================================================================
-- Multi-Device Sync Tables: deleted_visits (tombstones) + profiles
-- =============================================================================

-- Step 1: Create the deleted_visits table (tombstones for multi-device sync)
-- When a visit is deleted locally, we insert a tombstone here.
-- During sync, other devices check for tombstones and delete matching local visits.
-- This prevents "resurrection" of deleted visits across devices.

create table if not exists deleted_visits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  local_id text not null,
  deleted_at timestamptz not null default now(),
  unique(user_id, local_id)
);

-- Index for efficient sync queries
create index if not exists idx_deleted_visits_user_deleted on deleted_visits(user_id, deleted_at);

-- Enable RLS
alter table deleted_visits enable row level security;

-- RLS policy - users can only access their own tombstones
create policy "Users can CRUD their own tombstones"
  on deleted_visits for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- Step 2: Create the profiles table (synced user settings)
-- =============================================================================
-- Stores user preferences that sync across devices.
-- Uses the same id as auth.users for easy lookup.
-- updated_at is used for conflict resolution (latest wins).

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  -- Synced settings
  accuracy text default 'medium', -- low, medium, high
  tracking_interval_minutes int default 15,
  notifications_enabled boolean default true,
  country_change_notifications boolean default true,
  weekly_digest_notifications boolean default false,
  travel_reminders_enabled boolean default false,
  travel_reminder_hour int default 8,
  travel_reminder_minute int default 0,
  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index for sync queries
create index if not exists idx_profiles_updated on profiles(id, updated_at);

-- Enable RLS
alter table profiles enable row level security;

-- RLS policy - users can only access their own profile
create policy "Users can CRUD their own profile"
  on profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Trigger to auto-update updated_at on profile changes
-- (uses existing update_updated_at_column function from visits table migration)
create trigger update_profiles_updated_at
  before update on profiles
  for each row
  execute function update_updated_at_column();
