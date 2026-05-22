# SilentAlpha — Setup Guide

## 1. Prerequisites

- Flutter SDK ≥ 3.41
- A [Supabase](https://supabase.com) project (free tier works)

## 2. Supabase Database

1. Open your Supabase project → **SQL Editor**
2. Run the entire `db/schema.sql` file
   - Creates all tables, RLS policies, triggers, and views
   - Seeds 10 starter categories

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
| Campus onboarding | First login |
| Feed | Home tab |
| Explore / Discover | Compass tab |
| Create post | `+` button in nav bar |
| Post detail + comments | Tap any post |
| Profile | Person tab or tap an avatar |
| Notifications | Bell tab |
| Moderation queue | Settings → Mod Queue (admin only) |

## 6. Architecture

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
│   └── moderation/
├── services/        Supabase calls (supabase_service.dart)
├── utils/           Theme, avatar, hashtag, time helpers
└── widgets/         Reusable UI components
```

## 7. Supabase Views Used

| View | Purpose |
|------|---------|
| `posts_with_meta` | Feed with author info + is_liked/is_saved |
| `comments_with_meta` | Comments with author info |
| `notifications_with_actor` | Notifications with actor profile |
| `trending_hashtags` | Top hashtags last 7 days |
| `profile_stats` | Follower/following/post counts |
