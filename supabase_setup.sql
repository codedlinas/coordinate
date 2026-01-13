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
-- MANUAL STEPS IN SUPABASE DASHBOARD:
-- =============================================================================
-- 1. Go to Authentication > Providers
-- 2. Enable "Email" provider (should be enabled by default)
-- 3. For Google OAuth:
--    - Go to Google Cloud Console and create OAuth credentials
--    - Add the Client ID and Secret in Supabase
-- 4. Note your project URL and anon key from Settings > API
-- =============================================================================


