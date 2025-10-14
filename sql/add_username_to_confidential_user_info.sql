-- Add username snapshot to confidential info for easier review

alter table if exists public.confidential_user_info
  add column if not exists username_snapshot text;

-- Optional: simple index for filtering by username if needed later
create index if not exists confidential_user_info_username_idx
  on public.confidential_user_info (username_snapshot);


