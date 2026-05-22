# SilentAlpha — User Guide

SilentAlpha is an anonymous-first finance social platform where investors, traders, and market enthusiasts share analysis, opinions, and trade ideas — openly or anonymously.

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [The Feed](#2-the-feed)
3. [Creating a Post](#3-creating-a-post)
4. [Rating Posts](#4-rating-posts)
5. [Comments and Votes](#5-comments-and-votes)
6. [Explore Page](#6-explore-page)
7. [Hashtags and Tickers](#7-hashtags-and-tickers)
8. [Polls](#8-polls)
9. [Post Images](#9-post-images)
10. [Notifications & Activity](#10-notifications--activity)
11. [Your Profile](#11-your-profile)
12. [Following Other Users](#12-following-other-users)
13. [Saving Posts](#13-saving-posts)
14. [Post Analytics](#14-post-analytics)
15. [Leaderboard](#15-leaderboard)
16. [Badge System](#16-badge-system)
17. [Reporting and Blocking](#17-reporting-and-blocking)
18. [Admin Features](#18-admin-features)

---

## 1. Getting Started

### Creating an Account

1. Open the app and tap **Create Account** on the login screen.
2. Enter your email, a password, and a unique **@handle**.
3. Tap **Sign Up**. You'll be logged in immediately and redirected to the Home feed.

### Logging In

- Enter your registered email and password, then tap **Sign In**.
- Use **Forgot Password?** if you need a reset link sent to your email.

---

## 2. The Feed

The Home screen shows a scrolling feed of posts ordered by **Edge Rank** (a relevance score combining ratings, comments, saves, and recency). Pinned posts always appear at the top.

### Feed Tabs

| Tab | Content |
|---|---|
| **All** | Every post on the platform, ranked by edge rank |
| **Following** | Only posts from people you follow |

Switch between tabs using the **All / Following** tab bar at the top of the feed.

### Category Filter

On the **All** tab, category chips appear below the tab bar. Tap a chip to filter to that category. Tap again to clear the filter.

### Realtime "New Posts" Banner

When new posts arrive while you're reading the feed, a green **"New posts — tap to refresh"** banner appears at the top. Tap it to scroll to the top and see the new content.

### Pull to Refresh

Pull down anywhere on the feed to manually refresh.

---

## 3. Creating a Post

Tap the **+** button in the centre of the bottom navigation bar to open the New Post screen.

### Post Options

| Option | Description |
|---|---|
| **Anonymous toggle** | Hide your identity — your @handle and avatar will not be shown to others |
| **Content** | Up to 500 characters. `#hashtags` and `$TICKERS` are auto-detected |
| **Add image** | Attach a photo from your gallery (max 10 MB) |
| **Add poll** | Attach a poll with 2–4 options and an optional deadline |

### Drafts

Your post text is **automatically saved as a draft** as you type. If you close the screen without publishing, your text is restored the next time you open New Post.

### Tickers

Type a `$` followed by a stock/crypto symbol (e.g., `$AAPL`, `$BTC`) to tag a ticker. Detected tickers are shown as green chips below the text box and create a browsable ticker feed.

### Hashtags

Type `#` followed by a word (e.g., `#earnings`) to tag a topic. Detected hashtags appear as purple chips.

### Polls

1. Tap **Add poll** to expand the poll creator.
2. Enter a question and at least 2 options (up to 4).
3. Optionally set a deadline date after which voting closes.
4. Publish your post — the poll is automatically attached.

---

## 4. Rating Posts

Each post has a **rating slider** below the content, ranging from **−5 to +5**.

- Slide right for a positive rating (bullish / good analysis).
- Slide left for a negative rating (bearish / poor analysis).
- The emoji to the left of the slider reflects your current position.
- The average rating and total vote count appear on the right.
- **Tap the same value again** to remove your rating.

Ratings directly affect a post's Edge Rank score.

---

## 5. Comments and Votes

Tap any post card to open its detail screen.

### Adding a Comment

Tap the **comment box** at the bottom of the detail screen, type your reply, and tap **Send**.

### Nested Replies

Tap **Reply** on a comment to start a threaded reply. Replies are indented under the parent comment.

### Voting on Comments

Each comment has **↑ upvote** and **↓ downvote** buttons. Tap the same button again to remove your vote. The net vote score is shown next to each comment.

---

## 6. Explore Page

The Explore screen has two tabs:

### Posts Tab

- **Search bar** — search post content with 2+ characters for live results.
- **Trending Topics** — trending #hashtags as tappable chips that open a filtered feed.
- **Trending Tickers** — trending $TICKERS as green chips that open a filtered ticker feed.
- **Top Posts** — top posts by edge rank when not searching.

### People Tab

- Type in the search bar to find users by @handle.
- Tap a result to visit their profile.

---

## 7. Hashtags and Tickers

### Hashtags

- Any `#word` in a post is auto-detected and stored.
- Tapping a `#hashtag` anywhere (post content, trending chips) opens a filtered feed of all posts with that hashtag.

### Tickers

- Any `$SYMBOL` (e.g., `$TSLA`) in a post is auto-detected and stored.
- Tapping a `$TICKER` chip on a post card opens a filtered feed of all posts mentioning that ticker.
- Trending tickers (posts from the last 7 days) appear in the **Explore → Trending Tickers** row.

---

## 8. Polls

### Voting

- If a post has a poll, it appears below the post content on the card.
- Before voting: tap an option to cast your vote.
- After voting: results appear as percentage bars. Your choice is highlighted with a checkmark.

### Results

- Vote counts and percentages update in real time after you vote.
- The total number of votes and deadline (if set) are shown at the bottom.

### Closed Polls

Once the deadline passes, voting is disabled and only results are shown.

---

## 9. Post Images

- Tap **Add image** in the New Post screen to attach a photo from your gallery.
- Images are uploaded to secure storage and displayed below the post content.
- Tap the **×** on the image preview to remove it before publishing.

---

## 10. Notifications & Activity

Tap the **Activity** (bell) icon in the bottom navigation bar to see your notifications.

### Notification Types

| Type | Trigger |
|---|---|
| Rating | Someone rated your post |
| Comment | Someone commented on your post |
| Follow | Someone followed you |
| Mention | Someone @mentioned you |

### Badge Counter

A red dot (with count) appears on the Activity icon when you have unread notifications. It clears when you open the Activity tab.

### Real-time Delivery

Notifications arrive in real time via Supabase Realtime — no refresh needed.

---

## 11. Your Profile

Tap the **Profile** icon (far right of the bottom navigation) to view your profile.

### What's Shown

- Your avatar, @handle, bio, and tagline
- Follower / Following counts
- Your badge and score
- Your posts and saved posts (in tabs)

### Editing Your Profile

Tap **Edit Profile** to update your:
- Display handle
- Bio and tagline
- Avatar (pick from gallery — uploaded automatically)

---

## 12. Following Other Users

Tap any @handle or avatar to open another user's profile, then tap **Follow**.

- Their posts appear in your **Following** feed tab.
- They receive a follow notification.
- Tap **Unfollow** on their profile to stop following them.

---

## 13. Saving Posts

Tap the **bookmark** icon at the bottom-right of any post card to save it. Tap again to unsave.

Saved posts are visible under the **Saved** tab on your profile page.

---

## 14. Post Analytics

Authors can view analytics for their own posts:

- **Long-press** any of your post cards to open the analytics sheet.
- Or tap the **bar chart** icon in the post footer, or select **Analytics** from the ⋮ menu.

### Metrics Shown

| Metric | Meaning |
|---|---|
| Avg Rating | Average of all ratings cast |
| Ratings | Number of unique raters |
| Comments | Total comment count |
| Saves | Number of users who saved the post |
| Rating Distribution | Bar chart of each rating value (−5 to +5) |

---

## 15. Leaderboard

Tap the **leaderboard icon** (bottom-left floating button on the Home screen) to see the top 50 users by score.

- Medal icons (🥇🥈🥉) for the top 3.
- Each row shows rank, avatar, @handle, badge, and score.
- **You** are highlighted in the list.
- Tap any row to visit that user's profile.

---

## 16. Badge System

Your score accumulates as others rate and engage with your posts. Badges are awarded automatically:

| Badge | Score Threshold |
|---|---|
| 📄 Paper Trader | Below 0 |
| 👀 Market Lurker | 0–20 |
| 🐂 Bull Rider | 21–75 |
| 🔍 Analyst | 76–200 |
| 💼 Portfolio Pro | 201–500 |
| ⚡ Quant | 501–1500 |
| 🐺 Wolf of the Street | 1501+ |

Your current badge is displayed on your profile and in the leaderboard.

---

## 17. Reporting and Blocking

### Reporting Content

Tap **⋮** on any post or comment you didn't author and select **Report**. Choose a reason and submit. Admins review all reports.

### Blocking Users

From another user's profile, tap **⋮ → Block**. Blocked users cannot interact with you.

---

## 18. Admin Features

Users with the **admin** role have additional capabilities:

| Feature | How to Access |
|---|---|
| Pin / Unpin posts | ⋮ menu → **Pin post** / **Unpin post** |
| Manage categories | Admin Panel → Categories |
| Manage users / roles | Admin Panel → Users |
| Moderation queue | Admin Panel → Reports |

Pinned posts always appear at the top of the **All** feed, above edge-rank ordering. They show a **📌 Pinned** banner.

Access the Admin Panel from your profile page (visible only to admins).
