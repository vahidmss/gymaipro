-- Drop existing table and trigger if they exist
drop trigger if exists check_weight_record_frequency_trigger on weight_records;
drop table if exists public.weight_records;

-- Create weight_records table with proper constraints
create table public.weight_records (
  id uuid not null default gen_random_uuid(),
  profile_id uuid not null references auth.users(id) on delete cascade,
  weight numeric(5,2) not null check (weight > 0),
  recorded_at timestamp with time zone not null default timezone('utc'::text, now()),
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint weight_records_pkey primary key (id)
);

-- Enable RLS
alter table public.weight_records enable row level security;

-- Create policy for users to see their own records
create policy "Users can view their own weight records"
  on public.weight_records for select
  using (auth.uid() = profile_id);

-- Create policy for users to insert their own records
create policy "Users can insert their own weight records"
  on public.weight_records for insert
  with check (auth.uid() = profile_id);

-- Create or replace function for checking weight record frequency (7-day rule)
create or replace function check_weight_record_frequency()
returns trigger as $$
begin
  if exists (
    select 1 from weight_records
    where profile_id = new.profile_id
      and new.recorded_at - recorded_at < interval '7 days'
  ) then
    raise exception 'You can only add a weight record every 7 days';
  end if;
  return new;
end;
$$ language plpgsql;

-- Create trigger
create trigger check_weight_record_frequency_trigger
before insert on weight_records
for each row
execute function check_weight_record_frequency(); 