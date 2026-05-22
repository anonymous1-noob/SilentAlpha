# SilentAlpha — Technical Workflow Document

This document describes the architecture, data models, key algorithms, and development workflows for the SilentAlpha application.

---

## Table of Contents

1. [Technology Stack](#1-technology-stack)
2. [Project Structure](#2-project-structure)
3. [Database Schema](#3-database-schema)
4. [Authentication Flow](#4-authentication-flow)
5. [State Management](#5-state-management)
6. [Feed & Edge Rank Algorithm](#6-feed--edge-rank-algorithm)
7. [Anonymous Identity System](#7-anonymous-identity-system)
8. [Rating System](#8-rating-system)
9. [Comment & Vote System](#9-comment--vote-system)
10. [Notification System](#10-notification-system)
11. [Realtime Architecture](#11-realtime-architecture)
12. [Ticker & Hashtag System](#12-ticker--hashtag-system)
13. [Poll System](#13-poll-system)
14. [Image Upload Flow](#14-image-upload-flow)
15. [Draft Post System](#15-draft-post-system)
16. [Post Analytics](#16-post-analytics)
17. [Leaderboard & Badge System](#17-leaderboard--badge-system)
18. [Admin Role & RLS Policies](#18-admin-role--rls-policies)
19. [Screen Navigation Map](#19-screen-navigation-map)
20. [Running the App Locally](#20-running-the-app-locally)
21. [Database Migrations](#21-database-migrations)
22. [Environment Configuration](#22-environment-configuration)

---

## 1. Technology Stack

| Layer | Technology |
|---|---|
| Mobile / Web framework | Flutter 3.41.9 / Dart 3.11.5 |
| Backend / Database | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| State management | Provider (`ChangeNotifier`) |
| Auth | Supabase Auth (email + password) |
| File storage | Supabase Storage (`avatars`, `post-images` buckets) |
| HTTP client | Supabase Dart SDK (`supabase_flutter`) |
| Animations | `animate_do`, `flutter_staggered_animations` |
| Image picking | `image_picker` |
| Local persistence | `shared_preferences` (drafts) |
| UUID generation | `uuid` |

---

## 2. Project Structure

```
lib/
├── auth/             Auth gate + sign-in/up screens
├── models/           Data models (Post, AppUser, Poll, Comment, etc.)
├── providers/        ChangeNotifier state (Auth, Feed, Comments, Categories, Notifications)
├── screens/
│   ├── admin/        Admin panel (users, categories, moderation)
│   ├── discovery/    Explore screen (posts + people tabs)
│   ├── feed/         Feed, hashtag feed, ticker feed
│   ├── leaderboard/  Leaderboard screen
│   ├── moderation/   Moderation queue
│   ├── notifications/ Notifications screen
│   ├── post/         Create, edit, detail, analytics
│   └── profile/      Profile + edit profile
├── services/         SupabaseService (all DB/storage calls)
├── utils/            AppTheme, AvatarUtils, HashtagUtils, TickerUtils, TimeUtils
└── widgets/
    ├── common/       Shared widgets (buttons, shimmer, report dialog)
    └── post/         PostCard, PollWidget

db/
├── migration_v1.sql … migration_v6.sql
docs/
├── USER_GUIDE.md
└── WORKFLOW.md
```

---

## 3. Database Schema

### Core Tables

| Table | Purpose |
|---|---|
| `profiles` | User handles, avatars, bios, roles |
| `posts` | Post content, hashtags, tickers[], is_pinned, is_anonymous, image_url |
| `post_ratings` | Rating value (−5…+5) per user per post (UNIQUE) |
| `saved_posts` | Bookmarked posts per user |
| `comments` | Threaded comments with parent_id |
| `comment_votes` | Up/down votes per user per comment |
| `follows` | follower_id → following_id |
| `blocks` | blocker_id → blocked_id |
| `notifications` | recipient_id, actor_id, type, post_id, body, read |
| `categories` | Category name + emoji |
| `polls` | Question, options[], deadline, linked to post |
| `poll_votes` | option_index per user per poll (UNIQUE) |
| `reports` | Content reports with status |

### Views

| View | Purpose |
|---|---|
| `posts_with_meta` | Posts + author info + rating stats + save count + poll JSONB + edge_rank |
| `following_posts_with_meta` | posts_with_meta filtered to auth.uid()'s followed users |
| `comments_with_meta` | Comments + author info + vote counts |
| `notifications_with_actor` | Notifications + actor handle/avatar |
| `profile_stats` | Profiles + follower/following/post counts + user_score |
| `trending_hashtags` | Hashtag frequency in last 7 days |
| `trending_tickers` | Ticker frequency in last 7 days |

### Functions

| Function | Signature | Purpose |
|---|---|---|
| `get_rating_distribution` | `(p_post_id uuid)` | Returns per-value vote counts for a post |

---

## 4. Authentication Flow

```
App start
  └─► AuthGate listens to Supabase.instance.client.auth.onAuthStateChange
        ├── session == null  →  LoginScreen
        └── session != null  →  HomeShell
```

- Sign-up also upserts a row in `profiles` (handle + id).
- The JWT token is managed by `supabase_flutter`; it auto-refreshes.
- `SupabaseService.currentUserId` returns `auth.currentUser?.id` synchronously.

---

## 5. State Management

| Provider | Manages |
|---|---|
| `AuthProvider` | Current `AppUser`, sign-in/out, profile load |
| `FeedProvider` | Post list, pagination, feed type (All/Following), realtime new-post flag, rating/save optimistic updates |
| `CommentsProvider` | Comment list for a single post, vote optimistic updates |
| `CategoriesProvider` | Category list, trending hashtags |
| `NotificationProvider` | Unread count, realtime notification channel |

All providers are registered in `MultiProvider` in `main.dart`. `FeedProvider` and `NotificationProvider` each hold a `RealtimeChannel` that is torn down on `dispose()` or sign-out.

---

## 6. Feed & Edge Rank Algorithm

Posts are scored server-side in the `posts_with_meta` view:

```sql
edge_rank =
  (avg_rating × ln(rating_count + 1)
   + ln(comment_count + 1)
   + ln(save_count + 1)
   + 1)
  / POWER((hours_since_posted + 2), 1.5)
```

- `avg_rating` can be negative, so it penalises poorly-rated posts.
- The denominator is a time-decay gravity factor (modelled after Hacker News).
- Ordering: `is_pinned DESC, edge_rank DESC` — pinned posts always top.

---

## 7. Anonymous Identity System

Anonymity is enforced at the **database view layer**, not the app layer:

```sql
CASE WHEN p.is_anonymous AND p.author_id != auth.uid()
     THEN NULL
     ELSE pr.handle
END AS author_handle
```

- Only the author themselves can see their own handle on an anonymous post.
- `author_id` is always returned (needed for ownership checks), but the app only exposes it internally.
- The Flutter `PostCard` shows "Anonymous" with a grey avatar when `author_handle` is null.

---

## 8. Rating System

- Table: `post_ratings(post_id, user_id, value)` with a UNIQUE constraint.
- Values: −5 to +5 integers (11-step slider in UI, divisions of 1).
- **Upsert** semantics: re-rating replaces the existing row.
- **Optimistic updates** in `FeedProvider.ratePost()` update the local post before the DB call, rolled back on error.
- A DB trigger (`notify_on_rating`) fires an insert into `notifications` on new/changed rating.

---

## 9. Comment & Vote System

- Comments support one level of threading via `parent_id`.
- Vote table: `comment_votes(comment_id, user_id, value)` UNIQUE.
- Values: +1 (upvote) or −1 (downvote).
- `comments_with_meta` view computes `vote_score`, `upvotes`, `downvotes`, and `user_vote` per row.
- `CommentsProvider.voteComment()` applies optimistic updates client-side.

---

## 10. Notification System

### DB Triggers (SECURITY DEFINER)

| Trigger | Event |
|---|---|
| `notify_on_rating` | After insert/update on `post_ratings` |
| `notify_on_comment` | After insert on `comments` |
| `notify_on_follow` | After insert on `follows` |

Each trigger inserts a row into `notifications(recipient_id, actor_id, type, post_id, body)`.

### Delivery

`NotificationProvider` subscribes to Postgres INSERT events on the `notifications` table filtered by `recipient_id = auth.uid()`. Each new row increments `_unreadCount` in real time.

Marking all read calls `SupabaseService.markNotificationsRead()` and resets `_unreadCount = 0`.

---

## 11. Realtime Architecture

### New Posts Banner (`FeedProvider`)

```dart
_realtimeChannel = client
    .channel('public:posts:new')
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'posts',
      callback: (_) { _hasNewPosts = true; notifyListeners(); },
    )
    .subscribe();
```

When `hasNewPosts` is true, `FeedScreen` shows a green banner. Tapping calls `dismissNewPosts()` which clears the flag and calls `refresh()`.

### Notification Counter (`NotificationProvider`)

Same pattern, filtered by `recipient_id`:

```dart
.channel('notifications:$userId')
.onPostgresChanges(
  event: PostgresChangeEvent.insert,
  table: 'notifications',
  filter: PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'recipient_id',
    value: userId,
  ),
  callback: (_) { _unreadCount++; notifyListeners(); },
)
```

Both channels are torn down on sign-out and re-established on sign-in.

---

## 12. Ticker & Hashtag System

### Detection Regex

```dart
// Tickers
RegExp(r'\$([A-Za-z][A-Za-z0-9]{0,7})')  // $AAPL, $BTC

// Hashtags
RegExp(r'#(\w+)')                          // #earnings
```

- Both utilities (`TickerUtils`, `HashtagUtils`) provide:
  - `extractNormalized(text)` → deduplicated list
  - `buildRichSpans(text, ...)` → tappable inline spans
- Tickers are stored in `posts.tickers text[]` column.
- Hashtags are stored in `posts.hashtags text[]` column.
- `getPosts()` supports `.contains('tickers', [ticker])` filtering.
- Trending views aggregate these arrays over the last 7 days.

### In-Post Display

`PostCard` renders ticker chips (`$TICKER` in green) separately from the content rich text. Tapping a chip navigates to `TickerFeedScreen`. Hashtags in the content text are rendered inline as tappable spans.

---

## 13. Poll System

### Tables

```
polls(id, post_id, question, options text[], deadline timestamptz)
poll_votes(id, poll_id, user_id, option_index, UNIQUE(poll_id, user_id))
```

### Embedding in Feed

The `posts_with_meta` view embeds polls as a JSONB subquery:

```sql
(SELECT jsonb_build_object(
  'id', pol.id, 'question', pol.question, 'options', pol.options,
  'deadline', pol.deadline,
  'total_votes', (SELECT COUNT(*) FROM poll_votes WHERE poll_id = pol.id),
  'user_vote', (SELECT option_index FROM poll_votes WHERE poll_id = pol.id AND user_id = auth.uid()),
  'results', (...)
) FROM polls pol WHERE pol.post_id = p.id LIMIT 1) AS poll
```

This avoids extra round-trips — the full poll state arrives with the post row.

### Voting Flow

1. `SupabaseService.votePoll(pollId, optionIndex)` — upsert on `poll_votes`.
2. `PollWidget` re-fetches the post from `posts_with_meta` to get updated counts.
3. Parent `PostCard` is updated via `onVoted` callback.

---

## 14. Image Upload Flow

### Avatar

```
User picks image (image_picker)
  └─► uploadAvatar('$userId/avatar.$ext', bytes, ext)
       └─► avatars bucket (public, upsert: true)
            └─► getAvatarPublicUrl(path) → stored in profiles.avatar_url
```

### Post Images

```
User picks image in CreatePostScreen
  └─► uploadPostImage('$userId/$timestamp.$ext', bytes, ext)
       └─► post-images bucket (public, 10 MB limit)
            └─► getPostImagePublicUrl(path) → passed to createPost as image_url
```

Both buckets have `upsert: true` so re-uploads replace the existing file.

---

## 15. Draft Post System

- `SharedPreferences` key: `'create_post_draft'`
- **Save**: triggered by `TextEditingController` listener on every keystroke.
- **Restore**: `_restoreDraft()` called in `initState()` — populates the text field if a draft exists.
- **Clear**: called on successful `_publish()` to prevent draft re-appearance.

---

## 16. Post Analytics

### Data Sources

| Metric | Source |
|---|---|
| avg_rating, rating_count, comment_count, save_count | `posts_with_meta` (already loaded with post) |
| Rating distribution | `get_rating_distribution(p_post_id)` RPC |

The `PostAnalyticsSheet` bottom sheet is triggered by:
1. Long-pressing your own `PostCard`.
2. Tapping the bar chart icon in the post footer (owner only).
3. ⋮ menu → **Analytics** (owner only).

### Rating Distribution RPC

```sql
CREATE OR REPLACE FUNCTION get_rating_distribution(p_post_id uuid)
RETURNS TABLE(rating_value int, vote_count bigint)
LANGUAGE sql SECURITY INVOKER STABLE AS $$
  SELECT value, COUNT(*) FROM post_ratings
  WHERE post_id = p_post_id GROUP BY value ORDER BY value DESC;
$$;
```

---

## 17. Leaderboard & Badge System

### Score Calculation

`profile_stats` view computes `user_score` from the `post_ratings` table:

```sql
user_score = SUM(avg_rating_per_post) weighted by engagement
```

(Exact formula in the `profile_stats` view definition in your Supabase schema.)

### Badge Tiers

Implemented in `UserBadge.fromScore(int score)` in `models.dart`:

| Score | Badge |
|---|---|
| < 0 | 📄 Paper Trader |
| 0–20 | 👀 Market Lurker |
| 21–75 | 🐂 Bull Rider |
| 76–200 | 🔍 Analyst |
| 201–500 | 💼 Portfolio Pro |
| 501–1500 | ⚡ Quant |
| 1500+ | 🐺 Wolf of the Street |

### Leaderboard Fetch

```dart
SupabaseService.getLeaderboard(limit: 50)
// → SELECT * FROM profile_stats ORDER BY user_score DESC LIMIT 50
```

---

## 18. Admin Role & RLS Policies

### Role Check Pattern

All admin-only operations are gated in RLS policies using:

```sql
EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
```

### Admin-Exclusive Actions

| Action | Policy table |
|---|---|
| Set `is_pinned` on posts | `posts` UPDATE policy |
| Delete any post | `posts` DELETE policy |
| Delete any comment | `comments` DELETE policy |
| Delete polls | `polls` DELETE policy |
| Update user roles | `profiles` UPDATE policy |
| Resolve reports | `reports` UPDATE policy |

### Flutter-Side Admin UI

The `AuthProvider` exposes `user.isAdmin` (derived from `profile.role == 'admin'`). The `PostCard` conditionally renders pin/unpin menu items and the `HomeShell` conditionally shows the admin panel link.

---

## 19. Screen Navigation Map

```
AuthGate
  ├── LoginScreen
  │     └── RegisterScreen
  └── HomeShell (IndexedStack)
        ├── [0] FeedScreen
        │     ├── All tab (category chips)
        │     └── Following tab
        │           └── PostCard → PostDetailScreen
        │                           ├── CommentsList
        │                           └── AddComment
        ├── [1] DiscoveryScreen
        │     ├── Posts tab → PostCard, HashtagFeedScreen, TickerFeedScreen
        │     └── People tab → ProfileScreen
        ├── [2] CreatePostScreen (fullscreenDialog)
        │     └── PollCreator (inline)
        ├── [3] NotificationsScreen
        └── [4] ProfileScreen
              ├── EditProfileScreen
              ├── PostCard → PostDetailScreen
              └── AdminScreen (admin only)
                    ├── UsersTab
                    ├── CategoriesTab
                    └── ModerationQueue

FAB (on Home tab): LeaderboardScreen
PostCard long-press: PostAnalyticsSheet (owner only)
TickerFeedScreen (via ticker chip taps)
HashtagFeedScreen (via hashtag taps)
```

---

## 20. Running the App Locally

```bash
# 1. Clone the repo
git clone <repo-url> && cd SilentAlpha

# 2. Install Flutter dependencies
flutter pub get

# 3. Create .env with Supabase credentials
cp .env.example .env
# Edit .env: SUPABASE_URL=... SUPABASE_ANON_KEY=...

# 4. Run on a device / emulator
flutter run

# 5. Run on Chrome (web)
flutter run -d chrome
```

---

## 21. Database Migrations

Migrations are in `db/migration_v*.sql`. Apply them in order via the Supabase SQL Editor or the CLI:

```bash
supabase db push   # if using local Supabase CLI
```

| Migration | Key Changes |
|---|---|
| v1 | Initial schema: profiles, posts, ratings |
| v2 | Comments, comment_votes, follows, saves |
| v3 | Notifications, blocks, reports |
| v4 | Categories, edge_rank view rebuild |
| v5 | Anon masking, notification triggers, avatars bucket, profile_stats |
| v6 | Tickers, is_pinned, polls, poll_votes, following_feed view, trending_tickers, post-images bucket, rating distribution RPC |

---

## 22. Environment Configuration

The app reads from a `.env` file at the project root (loaded by `flutter_dotenv`):

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

The `.env` file is excluded from version control via `.gitignore`. For CI/CD, inject these as build-time environment variables.
