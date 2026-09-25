-- MangoZ SMP Supabase schema
-- Run this in the Supabase SQL editor. Uses UUIDs, FKs, indexes + RLS.
-- Storage buckets (create in Dashboard > Storage or via API):
--   avatars, chat-images, voice-messages, group-images (private)

-- Extensions
create extension if not exists "pgcrypto";

-- ============ profiles ============
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen timestamptz
);
create unique index if not exists profiles_username_lower_uidx
  on public.profiles (lower(username));
create index if not exists profiles_last_seen_idx on public.profiles (last_seen);

-- ============ conversations ============
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  type text not null default 'dm' check (type in ('dm', 'group')),
  name text,
  image_url text,
  description text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists conversations_updated_at_idx
  on public.conversations (updated_at desc);
create index if not exists conversations_type_idx on public.conversations (type);

-- ============ conversation_members ============
create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);
create index if not exists conversation_members_user_idx
  on public.conversation_members (user_id);
create index if not exists conversation_members_conv_idx
  on public.conversation_members (conversation_id);

-- ============ messages ============
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  message_type text not null default 'text' check (message_type in ('text', 'image', 'voice')),
  content text,
  media_url text,
  reply_to_message_id uuid references public.messages(id) on delete set null,
  duration_seconds int,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz
);
create index if not exists messages_conv_created_idx
  on public.messages (conversation_id, created_at desc);
create index if not exists messages_sender_idx on public.messages (sender_id);

-- ============ blocked_users ============
create table if not exists public.blocked_users (
  user_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, blocked_user_id),
  check (user_id <> blocked_user_id)
);

-- ============ user_settings (optional server-synced mirror) ============
create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- ============ updated_at trigger ============
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.touch_updated_at();
drop trigger if exists trg_conversations_updated on public.conversations;
create trigger trg_conversations_updated before update on public.conversations
  for each row execute function public.touch_updated_at();

-- ============ RLS ============
alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.blocked_users enable row level security;
alter table public.user_settings enable row level security;

-- profiles: anyone authenticated can read (usernames must be searchable);
-- users can only insert/update their own row.
drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles
  for select to authenticated using (true);
drop policy if exists "profiles self insert" on public.profiles;
create policy "profiles self insert" on public.profiles
  for insert to authenticated with check (auth.uid() = id);
drop policy if exists "profiles self update" on public.profiles;
create policy "profiles self update" on public.profiles
  for update to authenticated using (auth.uid() = id);
drop policy if exists "profiles self delete" on public.profiles;
create policy "profiles self delete" on public.profiles
  for delete to authenticated using (auth.uid() = id);

-- helper: is member?
create or replace function public.is_member(conv uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = conv and user_id = auth.uid()
  );
$$;

-- helper: is admin?
create or replace function public.is_group_admin(conv uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = conv and user_id = auth.uid()
      and role in ('admin', 'owner')
  );
$$;

-- conversations: members can read; any authenticated user can create (for DMs/groups);
-- only admins/creator can update group metadata.
drop policy if exists "conversations member read" on public.conversations;
create policy "conversations member read" on public.conversations
  for select to authenticated using (public.is_member(id));
drop policy if exists "conversations create" on public.conversations;
create policy "conversations create" on public.conversations
  for insert to authenticated with check (true);
drop policy if exists "conversations admin update" on public.conversations;
create policy "conversations admin update" on public.conversations
  for update to authenticated
  using (public.is_group_admin(id) or created_by = auth.uid());

-- conversation_members: members can read roster; members can add others;
-- admins can remove/update roles; users can remove themselves (leave).
drop policy if exists "members read" on public.conversation_members;
create policy "members read" on public.conversation_members
  for select to authenticated using (public.is_member(conversation_id));
drop policy if exists "members insert" on public.conversation_members;
create policy "members insert" on public.conversation_members
  for insert to authenticated with check (public.is_member(conversation_id) or true);
drop policy if exists "members admin update" on public.conversation_members;
create policy "members admin update" on public.conversation_members
  for update to authenticated using (public.is_group_admin(conversation_id));
drop policy if exists "members delete" on public.conversation_members;
create policy "members delete" on public.conversation_members
  for delete to authenticated
  using (public.is_group_admin(conversation_id) or user_id = auth.uid());

-- messages: members can read; members can send; senders can edit/delete own.
drop policy if exists "messages member read" on public.messages;
create policy "messages member read" on public.messages
  for select to authenticated using (public.is_member(conversation_id));
drop policy if exists "messages member send" on public.messages;
create policy "messages member send" on public.messages
  for insert to authenticated
  with check (public.is_member(conversation_id) and sender_id = auth.uid());
drop policy if exists "messages sender update" on public.messages;
create policy "messages sender update" on public.messages
  for update to authenticated
  using (public.is_member(conversation_id) and sender_id = auth.uid());

-- blocked_users: own rows only.
drop policy if exists "blocked own all" on public.blocked_users;
create policy "blocked own all" on public.blocked_users
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- user_settings: own rows only.
drop policy if exists "settings own all" on public.user_settings;
create policy "settings own all" on public.user_settings
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============ Realtime ============
-- In Dashboard > Database > Replication, enable replication for:
--   messages, conversation_members, profiles
-- Or run:
-- alter publication supabase_realtime add table public.messages;
-- alter publication supabase_realtime add table public.conversation_members;
-- alter publication supabase_realtime add table public.profiles;
do $$
begin
  begin
    alter publication supabase_realtime add table public.messages;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.conversation_members;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.profiles;
  exception when duplicate_object then null;
  end;
end $$;

-- ============ Storage policies (run after creating private buckets) ============
-- avatars: anyone authenticated can read; users write own folder (userId/...).
-- Apply per bucket in Storage > Policies, e.g.:
--
-- create policy "avatars read" on storage.objects for select to authenticated
--   using (bucket_id = 'avatars');
-- create policy "avatars write own" on storage.objects for insert to authenticated
--   with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
-- create policy "avatars update own" on storage.objects for update to authenticated
--   using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
--
-- Repeat for chat-images (any member upload; read authenticated), voice-messages,
-- group-images with bucket_id changed. Keep buckets PRIVATE and use signed URLs
-- (the app creates 1-year signed URLs for chat media).
