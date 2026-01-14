-- =============================================================================
-- Coordinate App - Supabase Setup SQL
-- =============================================================================
-- Run this in your Supabase SQL Editor: https://supabase.com/dashboard/project/xulkcjygzuqfaotjckht/sql
-- =============================================================================

-- Step 1: Create the visits table
-- This matches the VisitSyncDto structure for seamless sync
create table if not exists visits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  local_id text not null,
  country_code text not null,
  country_name text not null,
  entry_time_utc timestamptz not null,
  exit_time_utc timestamptz,
  city text,
  region text,
  updated_at timestamptz not null default now(),
  device_id text,
  is_manual_edit boolean default false,
  unique(user_id, local_id)
);

-- Step 2: Create index for faster sync queries
create index if not exists idx_visits_user_updated on visits(user_id, updated_at);

-- Step 3: Enable Row Level Security (RLS)
alter table visits enable row level security;

-- Step 4: Create RLS policy - users can only access their own data
create policy "Users can CRUD their own visits"
  on visits for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Step 5: Create a function to auto-update updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Step 6: Create trigger to auto-update updated_at on row changes
create trigger update_visits_updated_at
  before update on visits
  for each row
  execute function update_updated_at_column();

-- =============================================================================
-- Step 7: Create the deleted_visits table (tombstones for multi-device sync)
-- =============================================================================
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
-- Step 8: Create the profiles table (synced user settings)
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
create trigger update_profiles_updated_at
  before update on profiles
  for each row
  execute function update_updated_at_column();

-- =============================================================================
-- Step 9: Create profile on user signup (optional - auto-create profile)
-- =============================================================================
-- This function automatically creates a profile when a new user signs up.
-- Uncomment if you want profiles to be auto-created.

-- create or replace function handle_new_user()
-- returns trigger as $$
-- begin
--   insert into profiles (id)
--   values (new.id)
--   on conflict (id) do nothing;
--   return new;
-- end;
-- $$ language plpgsql security definer;

-- create trigger on_auth_user_created
--   after insert on auth.users
--   for each row execute function handle_new_user();

-- =============================================================================
-- Step 10: Tombstone cleanup function (call periodically to prevent bloat)
-- =============================================================================
-- Tombstones older than 90 days can be safely deleted since all devices
-- should have synced by then. Run this via a scheduled Edge Function or cron.

create or replace function cleanup_old_tombstones()
returns integer as $$
declare
  deleted_count integer;
begin
  delete from deleted_visits 
  where deleted_at < now() - interval '90 days';
  
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$ language plpgsql security definer;

-- To run manually: SELECT cleanup_old_tombstones();
-- To schedule: Set up a pg_cron job or Supabase Edge Function

-- =============================================================================
-- MANUAL STEPS IN SUPABASE DASHBOARD:
-- =============================================================================
-- 1. Go to Authentication > Providers
-- 2. Enable "Email" provider (should be enabled by default)
-- 3. For Google OAuth:
--    - Go to Google Cloud Console and create OAuth credentials
--    - Add the Client ID and Secret in Supabase
-- 4. Note your project URL and anon key from Settings > API
-- 5. (Optional) Set up pg_cron to run cleanup_old_tombstones() weekly
-- =============================================================================


