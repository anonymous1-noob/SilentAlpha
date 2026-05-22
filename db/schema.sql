-- ─────────────────────────────────────────────────────────────────────────────
-- SilentAlpha – Supabase Schema
-- Run this in the Supabase SQL Editor (Project Settings → SQL Editor)
-- ─────────────────────────────────────────────────────────────────────────────

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── Profiles ─────────────────────────────────────────────────────────────────
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text not null unique,
  avatar_url   text,
  campus       text,
  bio          text,
  created_at   timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "Public profiles are viewable"  on public.profiles for select using (true);
create policy "Users can update own profile"  on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile"  on public.profiles for insert with check (auth.uid() = id);

-- ── Categories ────────────────────────────────────────────────────────────────
create table public.categories (
  id         uuid primary key default uuid_generate_v4(),
  name       text not null unique,
  emoji      text,
  post_count int default 0
);
alter table public.categories enable row level security;
create policy "Categories are public" on public.categories for select using (true);

-- Seed categories
insert into public.categories (name, emoji) values
  ('General',      '💬'),
  ('Campus Life',  '🎓'),
  ('Academics',    '📚'),
  ('Sports',       '⚽'),
  ('Events',       '🎉'),
  ('Tech',         '💻'),
  ('Relationships','❤️'),
  ('Mental Health','🧠'),
  ('Jobs & Internships','💼'),
  ('Humor',        '😂');

-- ── Posts ─────────────────────────────────────────────────────────────────────
create table public.posts (
  id          uuid primary key default uuid_generate_v4(),
  author_id   uuid not null references public.profiles(id) on delete cascade,
  content     text not null check (char_length(content) <= 500),
  hashtags    text[] default '{}',
  category_id uuid references public.categories(id),
  campus      text,
  image_url   text,
  like_count  int default 0,
  comment_count int default 0,
  created_at  timestamptz default now(),
  edited_at   timestamptz
);
alter table public.posts enable row level security;
create policy "Posts are viewable by all"    on public.posts for select using (true);
create policy "Authenticated users can post" on public.posts for insert with check (auth.uid() = author_id);
create policy "Authors can update posts"     on public.posts for update using (auth.uid() = author_id);
create policy "Authors can delete posts"     on public.posts for delete using (auth.uid() = author_id);

-- ── Post Likes ────────────────────────────────────────────────────────────────
create table public.post_likes (
  post_id    uuid references public.posts(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (post_id, user_id)
);
alter table public.post_likes enable row level security;
create policy "Likes are viewable"          on public.post_likes for select using (true);
create policy "Users can manage own likes"  on public.post_likes for all using (auth.uid() = user_id);

-- Auto-update like_count
create or replace function update_post_like_count()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set like_count = like_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set like_count = greatest(like_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;
create trigger post_like_count_trigger
  after insert or delete on public.post_likes
  for each row execute function update_post_like_count();

-- ── Saved Posts ───────────────────────────────────────────────────────────────
create table public.saved_posts (
  post_id    uuid references public.posts(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (post_id, user_id)
);
alter table public.saved_posts enable row level security;
create policy "Users can manage own saves" on public.saved_posts for all using (auth.uid() = user_id);

-- ── Comments ──────────────────────────────────────────────────────────────────
create table public.comments (
  id          uuid primary key default uuid_generate_v4(),
  post_id     uuid not null references public.posts(id) on delete cascade,
  author_id   uuid not null references public.profiles(id) on delete cascade,
  parent_id   uuid references public.comments(id) on delete cascade,
  content     text not null check (char_length(content) <= 1000),
  like_count  int default 0,
  created_at  timestamptz default now()
);
alter table public.comments enable row level security;
create policy "Comments are viewable"       on public.comments for select using (true);
create policy "Authenticated users comment" on public.comments for insert with check (auth.uid() = author_id);
create policy "Authors can delete comments" on public.comments for delete using (auth.uid() = author_id);

-- Auto-update post comment_count
create or replace function update_post_comment_count()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set comment_count = comment_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;
create trigger comment_count_trigger
  after insert or delete on public.comments
  for each row execute function update_post_comment_count();

-- ── Follows ───────────────────────────────────────────────────────────────────
create table public.follows (
  follower_id  uuid references public.profiles(id) on delete cascade,
  following_id uuid references public.profiles(id) on delete cascade,
  created_at   timestamptz default now(),
  primary key (follower_id, following_id)
);
alter table public.follows enable row level security;
create policy "Follows are public"          on public.follows for select using (true);
create policy "Users can manage own follows" on public.follows for all using (auth.uid() = follower_id);

-- ── Blocks ────────────────────────────────────────────────────────────────────
create table public.blocks (
  blocker_id uuid references public.profiles(id) on delete cascade,
  blocked_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (blocker_id, blocked_id)
);
alter table public.blocks enable row level security;
create policy "Users manage own blocks" on public.blocks for all using (auth.uid() = blocker_id);

-- ── Reports ───────────────────────────────────────────────────────────────────
create table public.reports (
  id          uuid primary key default uuid_generate_v4(),
  reporter_id uuid references public.profiles(id) on delete cascade,
  post_id     uuid references public.posts(id) on delete cascade,
  comment_id  uuid references public.comments(id) on delete cascade,
  reason      text not null,
  status      text default 'pending' check (status in ('pending','dismissed','actioned')),
  created_at  timestamptz default now()
);
alter table public.reports enable row level security;
create policy "Users can submit reports"   on public.reports for insert with check (auth.uid() = reporter_id);
create policy "Reporters can view own"     on public.reports for select using (auth.uid() = reporter_id);

-- ── Notifications ─────────────────────────────────────────────────────────────
create table public.notifications (
  id           uuid primary key default uuid_generate_v4(),
  recipient_id uuid references public.profiles(id) on delete cascade,
  actor_id     uuid references public.profiles(id) on delete cascade,
  type         text not null check (type in ('like','comment','follow','mention')),
  post_id      uuid references public.posts(id) on delete cascade,
  body         text,
  read         boolean default false,
  created_at   timestamptz default now()
);
alter table public.notifications enable row level security;
create policy "Users see own notifications" on public.notifications for select using (auth.uid() = recipient_id);
create policy "System can insert notifs"    on public.notifications for insert with check (true);
create policy "Users can mark read"         on public.notifications for update using (auth.uid() = recipient_id);

-- ── Views ─────────────────────────────────────────────────────────────────────

-- posts_with_meta: enriched post view for feed consumption
create or replace view public.posts_with_meta as
select
  p.*,
  pr.username   as author_username,
  pr.avatar_url as author_avatar_url,
  c.name        as category_name,
  exists(
    select 1 from public.post_likes l
    where l.post_id = p.id and l.user_id = auth.uid()
  ) as is_liked,
  exists(
    select 1 from public.saved_posts s
    where s.post_id = p.id and s.user_id = auth.uid()
  ) as is_saved
from public.posts p
join public.profiles pr on pr.id = p.author_id
left join public.categories c on c.id = p.category_id;

-- comments_with_meta: comments enriched with author info
create or replace view public.comments_with_meta as
select
  cm.*,
  pr.username   as author_username,
  pr.avatar_url as author_avatar_url,
  exists(
    select 1 from public.post_likes l
    where l.post_id = cm.post_id and l.user_id = auth.uid()
  ) as is_liked
from public.comments cm
join public.profiles pr on pr.id = cm.author_id;

-- notifications enriched with actor info
create or replace view public.notifications_with_actor as
select
  n.*,
  pr.username   as actor_username,
  pr.avatar_url as actor_avatar_url
from public.notifications n
join public.profiles pr on pr.id = n.actor_id;

-- trending hashtags (last 7 days)
create or replace view public.trending_hashtags as
select unnest(hashtags) as hashtag, count(*) as count
from public.posts
where created_at > now() - interval '7 days'
group by hashtag
order by count desc;

-- follower/following counts on profiles
create or replace view public.profile_stats as
select
  p.id,
  p.username,
  p.avatar_url,
  p.campus,
  p.bio,
  p.created_at,
  (select count(*) from public.follows f where f.following_id = p.id) as follower_count,
  (select count(*) from public.follows f where f.follower_id  = p.id) as following_count,
  (select count(*) from public.posts   pt where pt.author_id   = p.id) as post_count,
  exists(
    select 1 from public.follows ff
    where ff.follower_id = auth.uid() and ff.following_id = p.id
  ) as is_following
from public.profiles p;
