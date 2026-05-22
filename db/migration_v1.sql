-- ─────────────────────────────────────────────────────────────────────────────
-- SilentAlpha — Migration v1
-- Safe to run against a partially-initialised DB.
-- Adds missing tables, fixes RLS policies, creates views.
-- Run in: Supabase → SQL Editor → Run
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 0. Extensions ─────────────────────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── 1. Missing tables ─────────────────────────────────────────────────────────

-- profiles (referenced by posts.author_id FK)
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text not null unique,
  avatar_url   text,
  campus       text,
  bio          text,
  created_at   timestamptz default now()
);

-- follows
create table if not exists public.follows (
  follower_id  uuid references public.profiles(id) on delete cascade,
  following_id uuid references public.profiles(id) on delete cascade,
  created_at   timestamptz default now(),
  primary key (follower_id, following_id)
);

-- blocks
create table if not exists public.blocks (
  blocker_id uuid references public.profiles(id) on delete cascade,
  blocked_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (blocker_id, blocked_id)
);

-- notifications
create table if not exists public.notifications (
  id           uuid primary key default uuid_generate_v4(),
  recipient_id uuid references public.profiles(id) on delete cascade,
  actor_id     uuid references public.profiles(id) on delete cascade,
  type         text not null check (type in ('like','comment','follow','mention')),
  post_id      uuid,
  body         text,
  read         boolean default false,
  created_at   timestamptz default now()
);

-- ── 2. Add missing columns to existing tables (safe, skip if exists) ──────────

-- posts: ensure all expected columns exist
alter table public.posts add column if not exists hashtags    text[] default '{}';
alter table public.posts add column if not exists category_id uuid;
alter table public.posts add column if not exists campus      text;
alter table public.posts add column if not exists image_url   text;
alter table public.posts add column if not exists like_count  int default 0;
alter table public.posts add column if not exists comment_count int default 0;
alter table public.posts add column if not exists edited_at   timestamptz;

-- categories: ensure emoji column exists
alter table public.categories add column if not exists emoji      text;
alter table public.categories add column if not exists post_count int default 0;

-- reports: ensure all columns exist
alter table public.reports add column if not exists post_id    uuid;
alter table public.reports add column if not exists comment_id uuid;
alter table public.reports add column if not exists reason     text;
alter table public.reports add column if not exists status     text default 'pending';

-- ── 3. RLS — enable on all tables ─────────────────────────────────────────────
alter table public.profiles     enable row level security;
alter table public.categories   enable row level security;
alter table public.posts        enable row level security;
alter table public.post_likes   enable row level security;
alter table public.saved_posts  enable row level security;
alter table public.comments     enable row level security;
alter table public.follows      enable row level security;
alter table public.blocks       enable row level security;
alter table public.reports      enable row level security;
alter table public.notifications enable row level security;

-- ── 4. RLS Policies (drop + recreate so they are always correct) ──────────────

-- profiles
drop policy if exists "Public profiles are viewable" on public.profiles;
drop policy if exists "Users can update own profile"  on public.profiles;
drop policy if exists "Users can insert own profile"  on public.profiles;
create policy "Public profiles are viewable" on public.profiles for select using (true);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- categories
drop policy if exists "Categories are public" on public.categories;
create policy "Categories are public" on public.categories for select using (true);

-- posts
drop policy if exists "Posts are viewable by all"    on public.posts;
drop policy if exists "Authenticated users can post" on public.posts;
drop policy if exists "Authors can update posts"     on public.posts;
drop policy if exists "Authors can delete posts"     on public.posts;
create policy "Posts are viewable by all"    on public.posts for select using (true);
create policy "Authenticated users can post" on public.posts for insert with check (auth.uid() = author_id);
create policy "Authors can update posts"     on public.posts for update using (auth.uid() = author_id);
create policy "Authors can delete posts"     on public.posts for delete using (auth.uid() = author_id);

-- post_likes
drop policy if exists "Likes are viewable"         on public.post_likes;
drop policy if exists "Users can manage own likes" on public.post_likes;
create policy "Likes are viewable"         on public.post_likes for select using (true);
create policy "Users can manage own likes" on public.post_likes for all    using (auth.uid() = user_id);

-- saved_posts
drop policy if exists "Users can manage own saves" on public.saved_posts;
create policy "Users can manage own saves" on public.saved_posts for all using (auth.uid() = user_id);

-- comments
drop policy if exists "Comments are viewable"       on public.comments;
drop policy if exists "Authenticated users comment" on public.comments;
drop policy if exists "Authors can delete comments" on public.comments;
create policy "Comments are viewable"       on public.comments for select using (true);
create policy "Authenticated users comment" on public.comments for insert with check (auth.uid() = author_id);
create policy "Authors can delete comments" on public.comments for delete using (auth.uid() = author_id);

-- follows
drop policy if exists "Follows are public"           on public.follows;
drop policy if exists "Users can manage own follows" on public.follows;
create policy "Follows are public"           on public.follows for select using (true);
create policy "Users can manage own follows" on public.follows for all using (auth.uid() = follower_id);

-- blocks
drop policy if exists "Users manage own blocks" on public.blocks;
create policy "Users manage own blocks" on public.blocks for all using (auth.uid() = blocker_id);

-- reports
drop policy if exists "Users can submit reports" on public.reports;
drop policy if exists "Reporters can view own"   on public.reports;
create policy "Users can submit reports" on public.reports for insert with check (auth.uid() = reporter_id);
create policy "Reporters can view own"   on public.reports for select using (auth.uid() = reporter_id);

-- notifications
drop policy if exists "Users see own notifications" on public.notifications;
drop policy if exists "System can insert notifs"    on public.notifications;
drop policy if exists "Users can mark read"         on public.notifications;
create policy "Users see own notifications" on public.notifications for select using (auth.uid() = recipient_id);
create policy "System can insert notifs"    on public.notifications for insert with check (true);
create policy "Users can mark read"         on public.notifications for update using (auth.uid() = recipient_id);

-- ── 5. Triggers ───────────────────────────────────────────────────────────────

create or replace function update_post_like_count()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set like_count = coalesce(like_count,0) + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set like_count = greatest(coalesce(like_count,0) - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;
drop trigger if exists post_like_count_trigger on public.post_likes;
create trigger post_like_count_trigger
  after insert or delete on public.post_likes
  for each row execute function update_post_like_count();

create or replace function update_post_comment_count()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set comment_count = coalesce(comment_count,0) + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set comment_count = greatest(coalesce(comment_count,0) - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;
drop trigger if exists comment_count_trigger on public.comments;
create trigger comment_count_trigger
  after insert or delete on public.comments
  for each row execute function update_post_comment_count();

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, username, created_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    now()
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ── 6. Views ──────────────────────────────────────────────────────────────────

create or replace view public.posts_with_meta as
select
  p.*,
  coalesce(pr.username,   'anonymous') as author_username,
  pr.avatar_url                        as author_avatar_url,
  c.name                               as category_name,
  exists(
    select 1 from public.post_likes l
    where l.post_id = p.id and l.user_id = auth.uid()
  ) as is_liked,
  exists(
    select 1 from public.saved_posts s
    where s.post_id = p.id and s.user_id = auth.uid()
  ) as is_saved
from public.posts p
left join public.profiles pr on pr.id = p.author_id
left join public.categories c on c.id = p.category_id;

create or replace view public.comments_with_meta as
select
  cm.*,
  coalesce(pr.username, 'anonymous') as author_username,
  pr.avatar_url                      as author_avatar_url
from public.comments cm
left join public.profiles pr on pr.id = cm.author_id;

create or replace view public.trending_hashtags as
select unnest(hashtags) as hashtag, count(*) as count
from public.posts
where created_at > now() - interval '7 days'
  and array_length(hashtags, 1) > 0
group by hashtag
order by count desc;

create or replace view public.profile_stats as
select
  p.id,
  p.username,
  p.avatar_url,
  p.campus,
  p.bio,
  p.created_at,
  (select count(*) from public.follows f  where f.following_id = p.id) as follower_count,
  (select count(*) from public.follows f  where f.follower_id  = p.id) as following_count,
  (select count(*) from public.posts  pt  where pt.author_id   = p.id) as post_count,
  exists(
    select 1 from public.follows ff
    where ff.follower_id = auth.uid() and ff.following_id = p.id
  ) as is_following
from public.profiles p;

-- ── 7. Seed categories (insert only if the table is empty) ────────────────────
insert into public.categories (id, name, emoji, post_count)
select * from (values
  (uuid_generate_v4(), 'General',             '💬', 0),
  (uuid_generate_v4(), 'Campus Life',         '🎓', 0),
  (uuid_generate_v4(), 'Academics',           '📚', 0),
  (uuid_generate_v4(), 'Sports',              '⚽', 0),
  (uuid_generate_v4(), 'Events',              '🎉', 0),
  (uuid_generate_v4(), 'Tech',                '💻', 0),
  (uuid_generate_v4(), 'Relationships',       '❤️', 0),
  (uuid_generate_v4(), 'Mental Health',       '🧠', 0),
  (uuid_generate_v4(), 'Jobs & Internships',  '💼', 0),
  (uuid_generate_v4(), 'Humor',               '😂', 0)
) as t(id, name, emoji, post_count)
where not exists (select 1 from public.categories limit 1);
