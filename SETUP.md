# SilentAlpha — Setup Guide

## 1. Prerequisites

- Flutter SDK ≥ 3.44
- A [Supabase](https://supabase.com) project (free tier works)

## 2. Supabase Database

1. Open your Supabase project → **SQL Editor**
2. Run migrations in order:
   - `db/schema.sql` — base tables, RLS policies, triggers, views
   - `db/migration_v7.sql` — edge_rank GREATEST guard (POWER crash fix)
   - `db/migration_v8.sql` — follow_requests table, profile_stats update, reserved handle
   - `db/migration_v9.sql` — raise post content limit from 500 to 2000 chars

## 3. Environment Variables

Edit `.env` at the project root:

```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Find these in Supabase → **Project Settings → API**.

## 4. Run the App

```bash
flutter pub get
flutter run
```

## 5. Feature Tour

| Screen | How to reach |
|--------|-------------|
| Login / Register | App launch |
| Feed (All / Following) | Home tab |
| Explore / Discover | Compass tab |
| Create post | `+` button in nav bar |
| Post detail + comments | Tap any post |
| Profile | Person tab or tap an avatar |
| Notifications + Follow Requests | Bell tab |
| Leaderboard | Home tab → leaderboard FAB |
| Moderation queue | Settings → Mod Queue (admin only) |

## 6. Feature Details

### Anonymous Posts
- Toggle "Post anonymously" when creating a post
- Anonymous posts show as `@anonymous` to all other users
- Only the post author can see their own handle on their anonymous posts
- The handle `anonymous` is reserved — no account may register it

### Follow System (Approval-Gated)
- Clicking **Follow** on a profile sends a follow **request**, not an instant follow
- The target user sees a notification in the Activity tab with **Accept / Decline** buttons
- Approving promotes the request to a real follow and notifies the requester
- Before approval is granted the feed's **Following** tab shows no posts from that user
- Clicking **Requested** cancels a pending request

### User Mentions in Comments
- Type `@handle` in any comment box to mention a user
- An autocomplete dropdown appears as you type; tap a name to complete it
- The mentioned user receives a notification in the Activity tab
- The handle `@anonymous` is exempt from mentions (not a real user)
- `@handles` render in accent color inside comment text

### Image Upload
- Maximum original file size: **5 MB**
- Images are automatically compressed to **< 100 KB** before upload
- Compression uses JPEG quality reduction + 800 × 800 maximum dimensions

### Post Redirect
- After publishing a post the app navigates back to the **Feed** (Home tab)

### Leaderboard
- Top 3 users display with 🥇🥈🥉 medals and a gradient glow card
- Their profiles show a top-rank banner with their position
- The leaderboard auto-refreshes once per day (stored in device preferences)
- Manual refresh available via the ↻ button

### Feed
- Category filter removed — feed shows all posts ranked by `edge_rank`
- Pull to refresh or tap the "New posts" banner for live updates

## 7. Architecture

```
lib/
├── auth/            Auth gate (session routing)
├── models/          Typed domain models
├── providers/       State management (Provider)
├── screens/         Route-level screens
│   ├── auth/
│   ├── feed/
│   ├── post/
│   ├── profile/
│   ├── discovery/
│   ├── leaderboard/
│   └── moderation/
├── services/        Supabase calls (supabase_service.dart)
├── utils/           Theme, avatar, hashtag, time helpers
└── widgets/         Reusable UI components
```

## 8. Supabase Views Used

| View | Purpose |
|------|---------|
| `posts_with_meta` | Feed with author info, edge_rank, is_saved |
| `following_posts_with_meta` | Posts from approved-followed users only |
| `comments_with_meta` | Comments with author info and vote data |
| `notifications_with_actor` | Notifications with actor profile |
| `trending_hashtags` | Top hashtags last 7 days |
| `profile_stats` | Follower/following/post counts, is_following, follow_request_pending |

## 9. Database Tables Added in v8

| Table | Purpose |
|-------|---------|
| `follow_requests` | Pending/accepted/rejected follow requests |
