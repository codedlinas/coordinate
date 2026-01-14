-- Tombstone cleanup function
-- Removes tombstones older than 90 days to prevent table bloat.
-- All devices should have synced within 90 days.

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

-- Usage: SELECT cleanup_old_tombstones();
-- Schedule via pg_cron or Supabase Edge Function for weekly cleanup
