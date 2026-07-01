# SilentAlpha Finance Seed Data Plan

## Overview

Three SQL files populate the app with realistic Indian stock market / finance community data.
Run them **in order** from the Supabase SQL Editor (Dashboard → SQL Editor → New Query).

| File | Purpose | Run order |
|------|---------|-----------|
| `db/seed_p1_users.sql` | Clear old data + 10 categories + 100 users | 1st |
| `db/seed_p2_posts.sql` | ~1200 posts with real finance content | 2nd |
| `db/seed_p3_engagement.sql` | Follows + ratings + comments + polls | 3rd |

All files must run in the **same Supabase session** (Parts 2 & 3 rely on the `seed_tiers` temp table created in Part 1).

**All user passwords:** `Market@2025`

---

## Categories (10)

| # | Name | Emoji |
|---|------|-------|
| 1 | NSE/BSE Market | 📊 |
| 2 | IPO Watch | 🔔 |
| 3 | Technical Analysis | 📉 |
| 4 | SME Stocks | 🏭 |
| 5 | Small & Mid Cap | 📈 |
| 6 | Large Cap | 🏦 |
| 7 | Mutual Funds | 💰 |
| 8 | Financial Advice | 🧠 |
| 9 | Macro Economy | 🌐 |
| 10 | General Finance | 💬 |

---

## User Tiers (100 users)

| Tier | Count | Badge | Description |
|------|-------|-------|-------------|
| W — Wolf | 10 | Wolf of the Street (≥1501) | Pro traders, ex-fund-managers, SEBI RIAs |
| Q — Quant | 5 | Quant (501–1500) | Data-driven analysts, options writers, algo traders |
| P — Pro | 15 | Portfolio Pro / Analyst (201–500) | Semi-pro retail investors |
| R — Regular | 30 | Bull Rider / Market Lurker (21–200) | Engaged retail investors |
| N — Novice | 25 | Market Lurker / Bull Rider (0–76) | Beginners, learning investors |
| X — Random | 15 | Paper Trader / Market Lurker (<21) | Casual users, some negative-score bad-advice givers |

---

## Posts (~1200)

### Volume per tier
| Tier | Posts per user | Total |
|------|---------------|-------|
| Wolf (10) | 30–40 | ~350 |
| Quant (5) | 22–28 | ~125 |
| Pro (15) | 12–18 | ~225 |
| Regular (30) | 7–12 | ~285 |
| Novice (25) | 4–8 | ~150 |
| Random (15) | 3–5 | ~60 |

### Quality gradient
- **High quality** (Wolf/Quant): Detailed analysis with real numbers, DCF, sector data, entry/target/SL setups
- **Medium quality** (Pro/Regular): Practical observations, partial analysis, reasonable takes
- **Low quality** (Novice/Random): Confused questions, tips without basis, emotional reactions

### Content by category
- **NSE/BSE Market**: Nifty/Sensex levels, FII/DII flow analysis, sector rotation, options chain, expiry data
- **IPO Watch**: DRHP analysis, GMP tracking, subscription figures, listing strategy
- **Technical Analysis**: RSI/MACD setups, entry-target-SL, VIX analysis, chart patterns
- **SME Stocks**: DRHP deep dives, operator risk warnings, listing gain strategy
- **Small & Mid Cap**: Fundamental analysis, DCF, quarterly results, valuation
- **Large Cap**: SOTP, quarterly results, dividend analysis, PE comparison
- **Mutual Funds**: Direct vs regular math, SIP step-up, category returns, NFO red flags
- **Financial Advice**: Emergency fund, asset allocation, 80C tax guide, retirement corpus math
- **Macro Economy**: RBI policy, US Fed impact, CPI data, India GDP, oil price effects
- **General Finance**: Portfolio milestones, money mindset, net worth milestones, FOMO posts

### Other post properties
- **Date range**: Past 365 days, random distribution
- **Anonymous posts**: ~10% of all posts have `is_anonymous = true`
- **Tickers**: Stock symbols embedded (e.g. `$RELIANCE`, `$TCS`, `$HDFCBANK`) — feeds TickerFeedScreen
- **Hashtags**: Finance hashtags per category — feeds trending hashtags feature
- **Chart images**: 8 Wolf posts get a `quickchart.io` image URL showing real rendered charts

### QuickChart.io posts (8 posts)
1. Nifty 50 — 13-month close price line chart
2. Sector YTD performance horizontal bar chart
3. SIP growth projection (₹5k/month at 12% CAGR)
4. MF category 5-year returns comparison
5. FII vs DII monthly net flows (dual bar)
6. Nifty 50 vs Gold vs FD — 10-year comparison
7. Small cap vs Mid cap vs Large cap 1Y/2Y/3Y returns
8. HDFC Bank 13-month price line chart

---

## Follows (~5,000–7,000 edges)

| Tier | Followers received | Users they follow |
|------|-------------------|------------------|
| Wolf | ~70 | ~8 (selective) |
| Quant | ~44 | ~14 |
| Pro | ~22 | ~20 |
| Regular | ~11 | ~30 |
| Novice | ~5 | ~40 |
| Random | ~2 | ~18 |

---

## Ratings → Leaderboard

`user_score = SUM(post_ratings.value)` across all ratings on user's posts.

| Tier | Raters/post | Avg value | Expected score |
|------|-------------|-----------|---------------|
| Wolf | 28 | +4.0 | 2,500–5,000 |
| Quant | 14 | +3.0 | 700–1,400 |
| Pro | 9 | +2.0 | 220–480 |
| Regular | 5 | +1.0 | 30–180 |
| Novice | 3 | ±0 | 0–60 |
| Random | 2 | −1.0 | −50 to +10 |

---

## Comments (~600)

- Wolf/Quant posts: 8–14 comments each (analytical, discussion-heavy)
- Pro/Regular posts: 2–5 comments (mix of analysis and casual)
- Novice/Random posts: 0–2 comments (casual, emoji, basic questions)

## Polls (12)

Sample polls assigned to top Wolf/Quant/Pro posts:
1. Which sector will outperform Nifty in next 6 months?
2. What is your current equity allocation?
3. Where will Nifty 50 be by December 2025?
4. Best performing MF category this year?
5. How do you react when portfolio falls 15%?
6. Which IPO strategy do you follow?
7. Active vs passive MF investing?
8. Biggest investment mistake?
9. Where to invest ₹1 lakh windfall today?
10. How often do you check your portfolio?
11. Nifty 50 PE above 22x — your view?
12. What is your primary investment goal?

Each poll gets 25–60 votes distributed randomly.

---

## Verification Checklist

1. Run Parts 1, 2, 3 in order — check the sanity query output after each
2. App → Leaderboard (FAB) → top 10 should all be Wolf/Quant tier with high scores
3. App → Feed → All → finance posts visible with category chips
4. App → Discovery → Trending hashtags → `#Nifty50`, `#MutualFunds`, etc.
5. App → Discovery → Trending tickers → `$RELIANCE`, `$TCS`, `$HDFCBANK`
6. Open a Wolf profile → check badge "Wolf of the Street", high post/follower count
7. Open a Random/X profile → check badge "Paper Trader", low/negative score
8. Tap a post with chart image → image loads from `quickchart.io`
9. Tap a poll post → vote options render correctly
10. Following feed → shows posts from people you followed
