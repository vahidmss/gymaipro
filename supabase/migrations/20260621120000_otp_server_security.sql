-- لاگ rate-limit OTP (فقط service_role از Edge Function)
create table if not exists public.otp_send_log (
  id bigserial primary key,
  phone_number text not null,
  ip_address text,
  created_at timestamptz not null default now()
);

create index if not exists idx_otp_send_log_phone_created
  on public.otp_send_log (phone_number, created_at desc);

create index if not exists idx_otp_send_log_ip_created
  on public.otp_send_log (ip_address, created_at desc);

create table if not exists public.otp_verify_log (
  id bigserial primary key,
  phone_number text not null,
  ip_address text,
  created_at timestamptz not null default now()
);

create index if not exists idx_otp_verify_log_phone_created
  on public.otp_verify_log (phone_number, created_at desc);

alter table public.otp_send_log enable row level security;
alter table public.otp_verify_log enable row level security;

-- جدول otp_codes (اگر از قبل نبود)
create table if not exists public.otp_codes (
  id bigserial primary key,
  phone_number text not null,
  code text not null,
  expires_at timestamptz not null,
  is_used boolean not null default false,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_otp_codes_phone_active
  on public.otp_codes (phone_number, is_used, expires_at desc);

alter table public.otp_codes enable row level security;

-- دسترسی مستقیم anon/authenticated به OTP بسته — فقط service_role از Edge Function
drop policy if exists "otp_codes_public_read" on public.otp_codes;
drop policy if exists "otp_codes_public_insert" on public.otp_codes;
drop policy if exists "otp_codes_public_update" on public.otp_codes;
