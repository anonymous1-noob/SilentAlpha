-- ============================================================
-- SilentAlpha Finance Seed — PART 2: Posts (~1200 posts)
-- Run AFTER seed_p1_users.sql in the SAME Supabase session
-- (seed_tiers temp table must still exist from Part 1)
-- ============================================================

DO $POSTS$
DECLARE
  -- ── Category IDs ──────────────────────────────────────────
  cat_nse   uuid; cat_ipo   uuid; cat_ta    uuid; cat_sme   uuid;
  cat_smc   uuid; cat_lc    uuid; cat_mf    uuid; cat_fa    uuid;
  cat_macro uuid; cat_gen   uuid;

  -- ── Content arrays: HIGH quality (Wolves / Quants) ────────
  nse_hi text[] := ARRAY[
    'Nifty 50 weekly wrap: Index +1.84% closing at 24,683. FIIs net bought ₹4,218 cr in cash — first net-buy week in 6 weeks. DIIs added ₹2,891 cr. A-D ratio 1847:734. IT led +3.2%, FMCG lagged -0.8%. If Nifty holds 24,400 support, next target is 25,200. Key risk: US CPI Thursday could trigger vol spike. Staying long with trailing SL at 24,100. #Nifty50 #FIIData #MarketUpdate',
    'Bank Nifty hit fresh ATH at 52,890 today. Breaking down the contribution: HDFC Bank +38 pts, ICICI Bank +31 pts, Kotak +12 pts. PSU banks dragged: SBI -0.4%, Bank of Baroda -0.8%. Private vs PSU divergence is stark. This tells me the rally is quality-driven. Bank Nifty PE at 18.2x — not cheap but FY25E EPS growth of 18% for private banks justifies it. Long $HDFCBANK $ICICIBANK #BankNifty',
    'Monthly FII/DII flow update — Oct 2025: FIIs sold ₹94,017 cr in equity (largest monthly outflow since Mar 2020). Why? Dollar at DXY 106, US 10yr yield at 4.9%, EM-wide outflows. DIIs absorbed ₹79,412 cr. SIP inflows holding at ₹21,400 cr/month — the domestic backstop is real. Long-term India story intact. Short-term pain expected — use it to accumulate. #FIIData #DIIData #NSEIndia',
    'Nifty options chain for 28 Nov expiry: Max OI at 24,500 PE (1.2 cr contracts) 25,000 CE (98 lakh). PCR at 1.31 — mildly bullish. ATM straddle = ₹287. IV rank: 42nd percentile. Expected move: ₹±850. I''m running a 24,200P/25,200C short strangle for ₹156 premium. Theta working for me. If Nifty stays in range for 8 days, full profit. #Nifty50 #FNO #Options $NIFTY',
    'Sector rotation becoming very visible last 3 months: Nifty IT +18.4%, Pharma +12.3%, Auto -2.1%, Realty -8.7%. Early-cycle sectors leading while rate-sensitives lag — textbook late-tightening/early-easing signal. I''m rotating into IT + Pharma, reducing Real Estate exposure. Watch RBI''s Feb MPC for rate cut confirmation. #SectorRotation #Nifty50 #MarketUpdate',
    'Nifty 50 market breadth today — bullish signal: 2,103 advances vs 891 declines on BSE (A-D ratio 2.36). When >65% stocks participate in an upmove, the rally is broad-based and sustainable. Not a narrow speculative top. Institutional participation visible in mid and small caps too. Staying invested, no reason to book profits at these levels. #MarketBreadth #Sensex #Nifty50',
    'Pre-budget market setup 2025: Historically, markets are up 3.2% avg in the month before Union Budget (last 10 yrs). FII positioning is light (they sold ₹45k cr in Q3). Domestic MF cash is 6.2% of AUM — ready to deploy. My expectation: infra, defence, railways outperform in budget month. Adding SGB-related PSU names. $NTPC $IRFC $BEL #Budget2025 #NSEIndia',
    'Sensex crossed 80,000 milestone today. Took 5 months from 75k to 80k (Jan to Jun 2025). For context: 70k → 75k took 8 months, 75k → 80k took 5 months — acceleration phase. At 80k Sensex, India is the 4th largest equity market globally. PE at 23.8x FY25E — not cheap but India premium is justified given 7%+ GDP growth. Stay long, manage volatility. #Sensex80k #BSEIndia',
    'Post RBI MPC impact on markets: 50bps CRR cut injects ₹1.16 lakh cr liquidity — bullish for financials. Repo kept at 6.5% (expected). Das tone hawkish on inflation. Market reading: first cut Feb 2026. Rate-sensitives (banks, RE, NBFCs) rallied 2-3% on liquidity injection. I''m long HDFC Bank and SBI ahead of the eventual cut cycle. $HDFCBANK $SBIN #RBI #BankNifty',
    'Nifty 52-week ATH breakout analysis: After 4 months of consolidation between 23,800-24,800, Nifty broke out to 25,100 on volume 1.8x average. Classic base breakout. Measured move target: 26,200 (height of base added to breakout level). RSI at 64 — not overbought. MACD histogram expanding positive. This breakout has legs. Adding to equity allocation. #Nifty50 #Breakout #TechnicalAnalysis',
    'FY25 Q2 results season summary: Of 230 Nifty 500 companies reported — 58% beat estimates, 24% in-line, 18% missed. Earnings growth: IT +12%, BFSI +18%, Auto +8%, FMCG -3%, Metals -22%. IT and BFSI clearly driving the earnings recovery. The consensus FY25 Nifty EPS of ₹1,050 looks achievable. At 24,800 Nifty, that''s 23.6x FY25 PE — fairly valued for 15% EPS CAGR. #EarningsSeason #Nifty50'
  ];

  nse_med text[] := ARRAY[
    'Market closed at 24,215 today, down 34 pts. Lots of stock-specific action — Q2 results season in full swing. IT stocks strong: $TCS +2.1%, $INFY +1.8%. Autos weak ahead of monthly sales data. FII sold ₹1,240 cr. Waiting for clearer direction. #Nifty50 #MarketUpdate',
    'Noticed Nifty has found buyers every time it touches 24,000-24,100. Zone has held 4 times in last 3 months. Either institutions accumulating or retail buying dips. Either way, strong demand zone. I''m staying invested in my core positions. #Nifty50 #SupportLevel',
    'FII bought ₹2,847 cr today in cash equities. DII sold ₹892 cr (profit booking likely). Net positive flow. This is the third consecutive FII buying day. When FIIs buy continuously, rally usually has more legs. Watch for continuation tomorrow. #FIIData #NSEIndia',
    'Sensex up 450 pts today. Banking and IT led the rally. Mid-cap index +0.8%. Small-cap index +1.1%. Breadth positive — more advances than declines. Market feels healthy right now. Not chasing momentum but not selling either. $HDFCBANK $TCS #Sensex #MarketUpdate',
    'Nifty expiry week observation: Usually volatile in the first 3 days, then settles. Max pain for this expiry is at 24,500. Expect stock-specific moves. F&O data shows 24,000 PE has seen massive writing — strong floor. Don''t panic-sell into expiry volatility. #NiftyExpiry #FNO',
    'Weekly green: Nifty +1.2% this week. 4 out of 5 days were positive. IT sector outperformed. Auto lagged on weak volumes data. My portfolio up 1.8% — some small caps doing well. Happy with the week. #Nifty50 #WeeklyWrap',
    'Post-budget market reaction: Initial volatility as expected. Market settled once traders read the fine print — capex at ₹11.11 lakh cr, fiscal deficit 4.9% (in-line), no new tax surprises. Infrastructure names +3-5%. Consumption flat. Budget = market-neutral with infra positive bias. #Budget2025 #NSEIndia',
    'Mid-month market update: Nifty +2.3% MTD, Bank Nifty +3.1% MTD. Global markets supportive — S&P500 near ATH. INR stable at 83.8. No major negative triggers visible. Staying with existing positions. Next catalyst: US Fed meeting end of month. #NSEIndia #MarketUpdate'
  ];

  nse_low text[] := ARRAY[
    'Why is Nifty falling today? My portfolio is all red 😭 Should I sell or hold? This is very stressful! Is this the crash everyone was warning about? #Nifty50 #Help',
    'Market is going up!! 🚀 All my stocks are green today! Is it going to 30k? Should I buy more now? #BullMarket #Nifty50',
    'My SIP is down -8% right now. Should I stop SIP? My friend said market will fall more. What to do? #SIP #Confused',
    'Someone tell me is this a good time to buy Nifty 50 index fund? Market seems high? Or should I wait? #NiftyIndex #Beginner',
    'Nifty fell 500 points today — very scary 😱 This is why I was afraid of markets. Should I move everything to FD? #Nifty50'
  ];

  -- ── IPO Watch content ──────────────────────────────────────
  ipo_hi text[] := ARRAY[
    'Hyundai India IPO deep dive: Issue price ₹1,960, size ₹27,870 cr — largest Indian IPO ever. Valuation at ₹1.59 lakh cr = 26x FY24 PE. Maruti trades at 28x, Tata Motors at 8x. Revenue CAGR 3yr: 14%. EBITDA margin: 12.4% — decent for auto. Key risk: India revenue = 100% topline, no diversification. Parent global Hyundai at 5x EV/EBITDA. Pricing seems full. I''d skip, wait for secondary dip. $HYUNDAIINDIA #IPO2025 #MainboardIPO',
    'Bajaj Housing Finance IPO analysis: ₹6,560 cr issue at ₹70. At ₹70 = 3.2x book value. FY24 PAT: ₹1,731 cr, +38% YoY. NIM: 4.02% — excellent for HFC. Competition: HDFC merged entity, LIC Housing. QIB subscribed 209x. Overall 67x. GMP: +₹56 (80% premium). This is a quality HFC at a fair price. I''d apply and consider holding 6-12 months beyond listing. $BAJAJHFL #IPO #HousingFinance',
    'IPO calendar analysis for Q3 FY26: 14 mainboard IPOs lined up, combined issue size ₹58,000 cr. Quality is mixed — 4 profitability-negative cos, 3 PE-backed with aggressive pricing. My watchlist: Waaree Energies (solar EPC, profitable, import-sub theme), Swiggy (food-tech, loss-making but moat), Acme Solar (renewable, good track). Skip: overvalued consumer tech plays. #IPOWatch #IPOCalendar2025',
    'Waaree Energies IPO breakdown: ₹4,321 cr issue at ₹1,503. Solar module manufacturer — India''s largest by capacity (12 GW). FY24 revenue ₹11,397 cr (+69% YoY). PAT ₹1,274 cr (11.2% margin). PE at listing price: 47x FY24. Sounds expensive but PLI tailwind + China+1 opportunity + order book of 21 GW justifies premium. Applied at cutoff. Holding for 12-18 months. $WAAREE #IPO #SolarEnergy',
    'Listing day strategy for mainboard IPOs: My framework — If subscribed >30x: sell 50% on listing open, hold rest for 30 days. If subscribed 10-30x: hold full for 45 days unless listing pop >35%. If subscribed <10x: sell on listing day regardless. SME IPOs: sell 100% on listing open (operator-driven, no retail liquidity). This strategy has given me 31% avg annual return on IPO portfolio since 2021. #IPOStrategy #ListingDay'
  ];

  ipo_med text[] := ARRAY[
    'Applied in Swiggy IPO at cutoff price ₹390. GMP is ₹35 (9% premium). Subscribed 3.6x overall, 6.2x QIB. Not a great subscription — market cautious on loss-making tech. Applied for listing gains only, no long-term interest at this valuation. #SwiggyIPO #IPO2025',
    'IPO GMP tracker today: Hyundai +₹120 (6%), Waaree +₹780 (52%), NTPC Green +₹22 (5%), Afcons Infra -₹8 (below issue). Waaree looks the most exciting. Afcons disappointing despite strong track record. Will sell Afcons on listing. #IPO #GMP',
    'Upcoming IPOs this week: 1. Vishal Mega Mart — ₹8,000 cr, retailing. 2. One Mobikwik Systems — ₹572 cr, fintech. 3. Sai Life Sciences — ₹3,042 cr, CDMO pharma. Most interest in Sai Life Sciences — CDMO sector is hot. Applied in all three at cutoff. #UpcomingIPO #IPOWatch',
    'NTPC Green Energy IPO: ₹10,000 cr issue, green energy play. Issue price ₹108. At ₹108 = 14x P/BV — very expensive. Revenue is just starting. Loss-making still. But NTPC brand + government backing + green energy theme = emotional premiums. Applied 50% of usual allocation given high risk-reward uncertainty. #NTPCGreen #IPO',
    'Allotment status for Hyundai IPO: Got allotment of 1 lot (7 shares). At ₹1,960 = ₹13,720 invested. GMP suggests ₹2,100 listing = ₹1,050 profit per lot. Modest but better than FD. Will sell on listing. #HyundaiIPO #IPOAllotment',
    'Final subscription data for Waaree Energies IPO: 76.34x overall. QIB: 208x. NII: 62x. Retail: 8.8x. Strong institutional interest signals quality. Retail lightly subscribed (allocation strategy: retail gets higher allotment in low subscription). Should get 1-2 lots easily. #WaareeIPO #IPOSubscription'
  ];

  ipo_low text[] := ARRAY[
    'Applied in all IPOs this month. Grey market says 50% gain. Fingers crossed for allotment! 🤞 Anyone else applying? #IPO2025',
    'My friend says this IPO will give 300% returns. Applying with max lots. Hope for the best! Is this a good IPO? #IPO',
    'Why didn''t I get IPO allotment again? Applied 6 times this month, zero allotment. Is there any trick? #IPOAllotment',
    'Selling Swiggy IPO on listing day. Not going to hold loss-making companies. Fast money then move on! #SwiggyIPO',
    'What is GMP in IPO? My friend keeps saying GMP is 80%. How does this decide listing price? #IPO #Beginner'
  ];

  -- ── Technical Analysis content ─────────────────────────────
  ta_hi text[] := ARRAY[
    'TATAMOTORS technical setup: Weekly chart showing classic cup-and-handle completing above ₹940. Volume on breakout = 2.3x average (strong). RSI at 62 (not overbought), MACD crossover bullish on daily. Target: ₹1,060 (measured move = handle height). SL: ₹895 (below handle low). Risk:Reward = 1:2.8. Allocating 3% of portfolio. Stop will trail as price moves. Not investment advice. $TATAMOTORS #TechnicalAnalysis #CupAndHandle',
    'Bullish RSI divergence on ICICIBANK: Price made lower low at ₹1,010 while RSI made higher low at 38. This setup has played out 3 times in last 2 years — avg gain 14% each time in 6 weeks. Entry: ₹1,025. Target 1: ₹1,100, Target 2: ₹1,145. SL: ₹985. R:R = 1:3. Sharing for educational purposes. Volume confirmation needed on breakout above ₹1,050. $ICICIBANK #RSIDivergence #TechnicalAnalysis',
    'India VIX spike to 18.4 — highest in 6 months. Historically when India VIX > 17, Nifty finds floor within 5-7 trading days 8 out of 10 times. Fear is at an extreme. Options strangles become expensive — great for premium sellers. I''m selling a Bank Nifty 51,000P/54,000C strangle for ₹410 credit. Max profit: ₹41,000/lot. Breakeven: 50,590 & 54,410. 8 days to expiry. #VIX #Options #BankNifty',
    'Weekly sector momentum scan — Top RS (Relative Strength vs Nifty): Nifty IT +4.3%, Pharma +3.1%, Defence +2.8%. Bottom RS: Realty -3.2%, Metals -2.1%, Auto -1.4%. Momentum investing rule: buy strength, cut weakness. I''m rotating from auto/metal names into IT + Pharma. RS scan updated every Friday. #RelativeStrength #MomentumInvesting #TechnicalAnalysis',
    'RELIANCE swing trade setup: EMA 20 crossed above EMA 50 on daily chart (golden cross). This signal last worked in Dec 2023 — stock ran from ₹2,480 to ₹2,960 (+19%) in 3 months. Current price ₹2,840. If this repeats, target ₹3,380. SL: ₹2,720 (below EMA 50). But note: single EMA crossover is not enough. Confirming with rising volume and MACD histogram turning positive. $RELIANCE #TechnicalAnalysis #GoldenCross',
    'Bank Nifty price action at key juncture: 53,000 is a triple top on weekly chart (tested 3 times, failed). A sustained break above 53,000 with volume would be very bullish — next stop 56,000. A rejection here could take it back to 50,000-50,500. Option traders: strangle at 50,000P/56,000C is asymmetric — 3:1 payout if big move either way. Currently running this position. #BankNifty #PriceAction',
    'Bearish head-and-shoulders forming on ADANIPORTS: Left shoulder at ₹1,380 (Aug), Head at ₹1,470 (Oct), Right shoulder forming at ₹1,410 (Dec). Neckline: ₹1,340. If neckline breaks with volume, target = ₹1,210 (neckline - head height). RSI not confirming breakdown yet — wait for price confirmation. SL for shorts: ₹1,440 (above right shoulder). $ADANIPORTS #TechnicalAnalysis #HeadAndShoulders',
    'Nifty Pharma breakout watch: Index consolidating 21,400-22,000 for 6 weeks. This is classic flag pattern after 31% rally YTD. Breakout above 22,000 with volume targets 24,200 (measured move). Sector has tailwinds: US FDA approvals picking up, API export growth 18% YoY. Stocks I like on this breakout: Sun Pharma, Cipla, Divi''s. $SUNPHARMA $CIPLA $DIVISLAB #NiftyPharma #Breakout',
    'Options expiry P&L for Nov: Short strangles — profitable in 3 of 4 expiries. Total theta collected: ₹87,400. One loss in high-VIX week (-₹23,000 on the 51k/54k BN strangle that got busted). Net: +₹64,400 for the month. Win rate 75%, average loss 2.8x average win. Improving position sizing — reducing allocation on high-IV weeks. #Options #OptionSelling #FNO',
    'HDFC Bank technical analysis: After months of underperformance, HDFC Bank is forming a strong base at ₹1,720-1,750. Volume pattern shows accumulation (high volume on green days, low on red). RSI at 52 — neutral, room to move. Fundamental trigger needed: Q3 NIM stabilization expected. Technical + fundamental convergence is my trigger to add. Target: ₹1,980. SL: ₹1,690. $HDFCBANK #TechnicalAnalysis'
  ];

  ta_med text[] := ARRAY[
    'EMA crossover buy signal on $WIPRO: 20EMA crossed above 50EMA on daily. Volume: 1.4x avg. RSI 58. Not a strong signal but worth watching. Entry above ₹580, SL ₹558, target ₹630. Small position only — IT sector has broader support. #TechnicalAnalysis $WIPRO',
    'Support and resistance levels for Nifty this week: Support — 24,200 (strong, tested twice), 23,800 (major). Resistance — 24,800 (recent swing high), 25,100 (psychological). Trade plan: buy near 24,200 support with SL below 24,000, target 24,800. #Nifty50 #SupportResistance',
    'Learning Bollinger Bands: When price touches lower band + RSI < 30 + volume spike = potential reversal signal. Saw this on $BAJFINANCE today at ₹6,820. 3 of 3 conditions met. Small buy for swing. Risk = 2%. Not for everyone — study before trading. #TechnicalAnalysis #BollingerBands',
    'RSI above 70 on $MARUTI — technically overbought. But overbought can stay overbought in strong uptrends. In bull markets, RSI 70 = re-entry after pullback, not sell signal. Trailing SL is better than RSI-based exit in trending stocks. Lesson I learned the hard way. $MARUTI #RSI #TechnicalAnalysis',
    'Candle pattern I find reliable: Morning Doji Star on daily = reversal after downtrend. All 3 conditions: 1. Strong downtrend before. 2. Doji gap down. 3. Strong green candle next day closes above midpoint of first candle. $SBIN formed this pattern today. Small speculative buy. #CandlePattern #MorningDojiStar',
    'My screen for breakout stocks this week: 1. $POLYCAB — 52-week high breakout, strong volume. 2. $LTIM — bullish pennant, close to apex. 3. $CUMMINSIND — new all-time high. These are NOT buy recommendations. Do your own research before acting. #Breakout #StockScreen'
  ];

  ta_low text[] := ARRAY[
    'I bought $TCS when RSI was 80. Now it''s falling. Does RSI 80 always mean sell? I''m confused about overbought signals. #TechnicalAnalysis #Confused',
    'Someone explain MACD in simple language please. I see green and red lines crossing but don''t know what it means. #MACD #BeginnerTA',
    'Is EMA 20 or EMA 50 better for signals? My chart has too many lines. Can someone simplify? #EMA #TechnicalAnalysis',
    'I drew a trendline on Nifty and it looks like it''s going to 26,000. Am I doing this right? 🤔 #TrendLine #Nifty50',
    'Paper traded for 1 month using technical analysis. Made 18% in paper. Now scared to put real money. Any advice? #PaperTrading'
  ];

  -- ── SME Stocks content ─────────────────────────────────────
  sme_hi text[] := ARRAY[
    'SME IPO market reality check for Q3: 87 SME IPOs launched. 82 listed at premium. Average listing gain: 52%. But 6-month post-listing returns for the same batch: average -31%. The pop is operator-driven retail frenzy. Real money is lost by those who hold. My rule: sell 100% on listing open for SMEs. Never hold unless you''ve done 40+ hrs of fundamental research on the company. #SMEIPO #RealityCheck',
    'Analyzing Resourceful Automobile SME IPO: Revenue ₹180 cr, PAT ₹12 cr (6.7% margin). Debt: ₹85 cr. Promoter holding: 68% post-IPO. No promoter pledging (green flag). PE at issue price: 28x TTM — expensive for a commodity auto ancillary. Industry PE: 15-18x. But SMEs command premium due to low float. Subscribed 420x. GMP ₹62 on ₹117 issue. I''d apply for listing gains only, not value. #SMEIPORisks #DueDiligence',
    'How to screen SME IPOs (my framework): 1. Revenue >₹50 cr and growing >20% YoY. 2. PAT margin >8%. 3. Promoter holding >65% post-IPO. 4. No promoter pledging. 5. D/E < 1.5. 6. Independent directors >2. 7. DRHP filed at least 30 days before open. 8. No related party transactions >10% of revenue. If 6+ boxes checked, apply. Most SMEs fail on 3-4 criteria. Be selective. #SMEIPO #InvestmentFramework',
    'Operator risk in SME IPOs: How to spot it — 1. GMP shoots up 100%+ in 2 days before listing. 2. Allottee count unusually low. 3. Promoter not selling any stake (wants stock high for pledging later). 4. Subscription dominated by HNI (not QIB). 5. Company has vague future plans in DRHP. When you see 3+ of these, the listing pop is manufactured. Operators will dump on retail. Don''t be the exit liquidity. #SMEOperator #SMEIPO'
  ];

  sme_med text[] := ARRAY[
    'Applied in Arisinfra Solutions SME IPO. Price ₹382, subscription 113x so far. GMP ₹85. Construction materials B2B platform — interesting model but early stage. Revenue ₹1,240 cr but very thin margins. Risk: high. Applying only 2 lots. #SMEIPO',
    'SME IPO subscription update: Premier Energies Day 2 — 78.4x subscribed. QIB: 112x. NII: 91x. Retail: 14x. Strong institutional interest is a green flag. Solar EPC space with 3-yr revenue CAGR of 78%. Applying at cutoff. #PremierEnergies #SMEIPO',
    'My SME IPO portfolio last 6 months: Applied 18, allotted 11, sold on listing. Average listing gain: 43%. Two went below issue price on listing — lost ₹8,400. Net: +₹67,200 on ₹2.1 lakh deployed. XIRR: 64%. High effort, high return. Not for everyone. #SMEIPOPortfolio',
    'Warning on EMS Technologies SME IPO: Promoter pledged 40% of his shares 3 months before IPO. Company revenue fell 22% last year but DRHP shows Q1 recovery. Red flags everywhere. Skip this one regardless of GMP. #SMEIPOWarning #PromoterPledging'
  ];

  sme_low text[] := ARRAY[
    'My friend said this SME company will 10x. Should I apply? Price is ₹200, GMP is ₹400. #SMEIPO #Advice',
    'What is the difference between SME IPO and mainboard IPO? Why do SMEs give more returns? #SMEIPO #Beginner',
    'Applied in 5 SME IPOs this week. GMP looks great on all. Hope I get allotment! 🙏 #SME',
    'Lost money in SME IPO that crashed after listing. Now scared. Were there warning signs? #SMEIPOLoss'
  ];

  -- ── Small & Mid Cap content ────────────────────────────────
  smc_hi text[] := ARRAY[
    'APL Apollo Tubes deep value thesis: Market cap ₹35,000 cr, FY24 revenue ₹18,650 cr, EBITDA ₹1,474 cr (7.9% margin). Branded structural steel tubes — pricing power over unbranded peers. Volume CAGR 5yr: 18%. Distribution moat: 850+ dealers nationwide. Return ratios: ROE 25%, ROCE 22%. Management: Sanjay Gupta, promoter-driven, low salary draw. At 31x PE it looks full but 25%+ earnings growth makes PEG = 1.24. 3-yr price target: ₹1,400 (current ₹610). $APLAPOLLO #MidCap #ValueInvesting',
    'IRFC fundamental analysis: Quasi-sovereign NBFC lending exclusively to Indian Railways. Government of India guarantees their borrowings — essentially zero credit risk. Spread locked at 0.35-0.4% above borrowing cost. Boring but predictable. ₹68,000 cr loan book growing 15-18% YoY (as IR expands capex). FY25E PAT: ₹6,800 cr. At current price ₹182, PE = 18x, P/BV = 2.8x. Fair value: ₹155-170. Slightly overvalued but defensiveness justifies premium. $IRFC #SmallCap #DefensivePlay',
    'Polycab India — why I''m buying: India''s #1 cables & wires company (26% market share). Replacing Chinese imports in FMEG segment. New segment growth 32% YoY. Power sector capex of ₹4.75 lakh cr over 5 yrs benefits Polycab directly. FY25 revenue guidance ₹21,000 cr vs FY24 ₹18,600 cr (+13%). EBITDA margin expanding 150bps on premiumization. At 42x FY26E earnings — not cheap but quality franchise. Adding in SIP mode. $POLYCAB #MidCap',
    'Latent View Analytics — my mid-cap tech pick: Revenue $76M, growing 22% in constant currency. EBITDA margin 23% (best-in-class for India IT mid-cap). Debt-free, ₹1,200 cr cash on books. Moat: pure-play data analytics (not a generic IT services co). Client concentration risk: top 5 = 54% revenue. At 56x FY25E earnings, valuation is aggressive. But data analytics TAM is massive. I''ll add on any 15%+ correction. $LATENTVIEW #SmallCap #DataAnalytics',
    'Mid-cap vs large-cap risk-return: Data from last 15 years — Nifty Midcap 100 CAGR: 16.8% vs Nifty 50: 13.4%. But max drawdown: Midcap -59% (2008), Nifty -54%. Sharpe ratio: nearly equal. Conclusion: Mid-caps do outperform over 10+ yr horizon but require strong stomach. For 5-yr horizon or less, large caps are safer. For 10+ yrs, 60% mid + 40% large beats 100% large historically. #MidCap #AssetAllocation #LongTermInvesting',
    'Quarterly results analysis: $CROMPTON Q2 FY25 — Revenue ₹1,680 cr (+8% YoY). EBITDA ₹162 cr (9.6% margin, -110bps YoY). Consumer segment: fans weak (-4%). Pumps & lighting: +17%. B2B lighting: +23%. ECD segment hurting due to price cuts. Management expects margin recovery in H2 with operating leverage. At 38x PE, high expectations priced in. Hold for now — selling if FY25 earnings disappoint. $CROMPTON #MidCap #QuarterlyResults',
    'Trident Ltd fundamental review: Textiles + paper. Revenue ₹8,200 cr. EBITDA margin 14% (much better than peers). Net debt: ₹1,800 cr (manageable). Capex cycle ending — FCF should improve from FY26. Dividend yield: 2.4%. US textile exports recovering after supply chain issues. The stock has done nothing for 2 yrs — creates opportunity. 3-yr investment thesis, not a momentum trade. $TRIDENT #SmallCap #Textile'
  ];

  smc_med text[] := ARRAY[
    '$IRFC Q2 FY25 results: PAT ₹1,687 cr, +15% YoY. NIM stable 1.4%. Government lending = zero credit risk. Dividend yield 1.7%. Railway capex keeps growing. Downside risk if spread narrows. Holding position. #IRFC #SmallCap',
    'Watching $MAPMYINDIA closely. Digital maps + EV + autonomous driving intersection. Revenue growing 35% YoY. Loss-making still. If India EV adoption accelerates, this could be a huge compounder. Very early stage, very risky. Maximum 1% portfolio allocation for me. #MapMyIndia #Speculative',
    '$POLYCAB hit 52-week high today at ₹7,340. Strong results + sector tailwind. But at 40x PE, fresh entry risky. I''m holding my existing position but not adding at these levels. #Polycab #MidCap',
    'Mid-cap index down 4% this month while Nifty flat. This kind of divergence usually mean-reverts within 6-8 weeks. Mid-caps getting oversold on FII selling (they prefer large cap liquidity). Could be a buying opportunity for quality mid-caps. Watching $CROMPTON $APLAPOLLO. #MidCap',
    'Small cap SIP strategy: I put ₹5,000/month in Nifty Smallcap 250 Index Fund. Never pick individual small caps unless I have 40+ hrs to spend on research. Index gives diversification + rebalancing. Smallcap index CAGR: 21% over 10 yrs. #SmallCapSIP #IndexFund',
    'Found an interesting small-cap: Man Infraconstruction. ₹1,800 cr mktcap. Building contractor with ₹9,000 cr order book. Net cash company. Promoter buying shares in open market. These are the early signals I look for. Now going deeper into the AR. #SmallCap #ManInfra'
  ];

  smc_low text[] := ARRAY[
    'My friend told me to buy IRFC at ₹220. It''s now at ₹182. Should I average down or cut losses? I don''t know what to do. #IRFC #Advice',
    'Which is better — small cap MF or buying small cap stocks directly? #SmallCap #Beginner',
    'Bought a multibagger tip from Telegram. Stock is down 40% now. Is this normal for small caps? 😔 #TelegramTips #Lesson',
    'My small cap portfolio down 25%. But I''m hodling for multibagger. Patience right? 🙏 #SmallCap #Patience'
  ];

  -- ── Large Cap content ──────────────────────────────────────
  lc_hi text[] := ARRAY[
    'Reliance Industries sum-of-parts valuation: O2C business: ₹8.3L cr (8x EBITDA). Telecom (Jio): ₹9.1L cr (DCF, 15% CAGR). Retail: ₹4.8L cr (30x EBITDA). Digital+new businesses: ₹2.0L cr. Holding company discount -15%. Total SOTP: ₹24.2L cr. Current market cap: ₹19.8L cr → 22% discount to SOTP. This discount has historically closed as new businesses scale. Adding on dips. 3-yr target: ₹3,600 (from ₹2,840 now). $RELIANCE #LargeCap #SOTP',
    'TCS Q2 FY26 results: Revenue $7,505M (+5.4% YoY in USD). EBIT margin: 24.1% (-90bps QoQ — wage hike impact). Headcount: 6,13,974 (flat YoY). Deal wins: $8.6B TCV — strongest in 5 quarters. Near-term margin headwind is priced in. H2 should see reversal. Revenue growth re-acceleration to 12-15% from Q4 FY26 is my base case. FY27E EPS: ₹175. At 28x FY27E = target ₹4,900. Current ₹4,200 — 17% upside with quality franchise premium. $TCS #LargeCap #ITResults',
    'HDFC Bank thesis revisited post-merger: NIM at 3.47% (down from 3.65% pre-merger) due to HDFC Ltd''s higher-cost liabilities. But CASA ratio recovering to 38% from lows of 35%. Loan book growing 11% YoY. Credit cost at 0.42% — impeccable asset quality. Merger integration 80% complete per management. NIM should bottom out in H2 FY26. Buy now before NIM recovery is priced in. At 2.3x FY26E BV = ₹1,900 target. $HDFCBANK #LargeCap #Banking',
    'ITC sum-of-parts: Cigarettes: ₹2.5L cr (15x EBITDA). Hotels (post-demerger listing): ₹35,000 cr. Agribusiness: ₹28,000 cr. FMCG (other): ₹65,000 cr. Paperboards: ₹25,000 cr. Holdings in subsidiaries: ₹8,000 cr. Total SOTP: ₹3.56L cr. Market cap: ₹3.2L cr. 11% discount. Demerger of hotels business in FY26 is the unlock trigger. ITC FMCG profitability improving (reached ₹1,000 cr PAT). 3-yr target: ₹600 (from ₹467 now). $ITC #LargeCap #SOTP',
    'Dividend portfolio update: ITC ₹6.50/share (yield 1.4%), Power Grid ₹9/share (yield 3.1%), Coal India ₹28/share (yield 4.8%), ONGC ₹5.25/share (yield 2.9%), Infosys ₹21/share (yield 2.2%). Portfolio of 5 Nifty stocks giving avg 2.9% dividend yield. This is not just income — it''s a signal of financial health. Companies that consistently grow dividends have the best long-term returns. $ITC $POWERGRID $COALINDIA #DividendInvesting',
    'Why I''m buying Maruti Suzuki now: FY25E revenue ₹1,47,000 cr. SUV volume share rising from 14% to 27% in 3 yrs. EV pivot (18 EVs by 2030). Toyota synergy unlocks platform + powertrain benefits. At 26x FY26E EPS of ₹575 = CMP ₹14,950. 5-yr target: ₹25,000 assuming 15% earnings CAGR. India auto penetration 32 vehicles/1000 people vs 800+ in US — the runway is enormous. $MARUTI #LargeCap #AutoSector',
    'Infosys Q3 FY26 results: Revenue $4,703M (+7.6% YoY). EBIT margin: 21.3% (in-line). Full year guidance raised to 4.5-5% CC growth (from 3.75-4.5%). This is the first guidance upgrade in 5 quarters — very positive signal. Deal wins: $2.4B TCV. BFSI vertical recovery visible. I was adding Infy between ₹1,350-1,400. Current ₹1,740 = 23% up since entry. Holding for target ₹2,100. $INFY #LargeCap #IT'
  ];

  lc_med text[] := ARRAY[
    '$HDFCBANK facing NIM pressure. But 3-yr story is intact. Merger integration headwinds are temporary. Adding in parts on dips below ₹1,750. Quality franchise doesn''t stay cheap for long. #HDFCBank #LargeCap',
    '$TCS forming nice base at ₹4,050-4,200 zone. 3 months of sideways consolidation. Any positive news in IT sector could trigger breakout to ₹4,500. Watching closely. #TCS #LargeCap',
    'ITC Q3 results — cigarettes volume +4% YoY (better than expected given tax fears). FMCG other growing 8% but still low margins. Hotels PAT doubled. If hotels demerger happens in FY26, value unlocks. At ₹467, risk-reward looks good. $ITC #LargeCap',
    'Dividend portfolio milestone: crossed ₹15,000/month in dividend income! 4 years of building this portfolio. Power Grid, ITC, Coal India, ONGC, Infosys. Dividend growth + yield = beating FD comfortably. $POWERGRID $COALINDIA #DividendIncome',
    'Sun Pharma results strong: US revenue +23% YoY. Domestic formulations +10%. Specialty business growing. EBITDA margin at 27% — sector best. At 38x PE, valuation is premium but quality justifies. Holding full position. $SUNPHARMA #LargeCap #Pharma',
    '$WIPRO underperforming peers this year. Revenue growth laggard. New CEO has 3 strategies but execution is slow. I sold half my position and shifted to Infosys + HCL Tech. Better risk-reward in those two. $WIPRO #LargeCap #IT'
  ];

  lc_low text[] := ARRAY[
    'Should I buy HDFC Bank or ICICI Bank for long term? Both are good banks. Which one will perform better? Help! #Banking #Advice',
    'ITC always gives good dividends but stock not moving. Why does this happen? Any tips? #ITC #Dividend',
    'Bought TCS at ₹4,500. Now at ₹4,200. Should I average down? When will IT sector recover? #TCS #Advice',
    'Is Reliance Industries safe to invest for 10 years? My dad says yes. My friend says sell. Confused! $RELIANCE',
    'What is P/E ratio in simple terms? If P/E is 30 is that good or bad for a stock? #PERatio #Beginner'
  ];

  -- ── Mutual Funds content ───────────────────────────────────
  mf_hi text[] := ARRAY[
    'Direct vs Regular MF plans — 20 year simulation: ₹10,000/month SIP. Assumed 12% CAGR (Direct), 10.5% (Regular after 1.5% distributor commission). After 20 yrs: Direct = ₹93.9 lakhs, Regular = ₹73.7 lakhs. Difference = ₹20.2 lakhs — for doing nothing except switching. If you''re in regular plans, switch NOW via MFCentral or Zerodha Coin. The distributor earns ₹20 lakhs from your money. You deserve that money. #DirectPlan #MutualFunds',
    'Category-wise October MF flows: Active Large Cap outflow ₹-1,247 cr (7th consecutive month). Flexi Cap inflow ₹3,084 cr. Mid Cap ₹4,210 cr. Small Cap ₹3,720 cr. Index funds: ₹7,230 cr (+18% MoM). Clear trend: investors moving from active large cap → passive index + active mid/small. SEBI''s expense ratio cut is working. For large cap: just buy Nifty 50 index. Active large cap add zero value over 10 yrs. #MFFlows #MutualFunds #IndexFunds',
    'SIP step-up math: ₹10,000/month SIP at 12% CAGR for 20 yrs = ₹99.9 lakhs. Same SIP with 10% annual step-up = ₹2.67 crores. The step-up adds 2.7x more corpus! Most people do flat SIP for 20 yrs and wonder why returns disappoint. Step-up SIP is the single most powerful retirement planning tool. Set it up today on your MF app. #StepUpSIP #RetirementPlanning #Compounding',
    'My top 3 flexi cap funds for 5-yr SIP: 1. Parag Parikh Flexi Cap — 25% international + India quality focus. 5-yr CAGR: 23.8%. AM: Rajeev Thakkar. 2. Kotak Flexi Cap — consistent value bias. 5-yr CAGR: 20.2%. 3. HDFC Flexi Cap — Prashant Jain legacy + Gopal Agrawal continuation. All 3 have expense ratios <0.5% (direct). Diversify across 2, not all 3. #FlexiCapFund #MutualFunds',
    'NFO analysis: Should you invest in new fund offers? My answer: almost never. Reason 1 — No track record. Reason 2 — "Theme" NFOs (ESG, electric vehicles, etc.) launch at market peaks of that theme. Reason 3 — Existing diversified funds already hold whatever this NFO will buy. Exception: truly unique category (international fund of specific geography not covered). 95% of NFOs are marketing exercises. #NFO #MutualFunds',
    'Index fund selection guide: Nifty 50 — Nippon India Nifty 50 Bees (ETF, 0.04% expense). Nifty Next 50 — UTI Nifty Next 50 Index (0.13%). Nifty Midcap 150 — Motilal Oswal Midcap 150 (0.17%). Smallcap 250 — Nippon Nifty Smallcap 250 (0.31%). Global: Motilal Oswal NASDAQ 100 FoF (0.1%). My portfolio: 60% Nifty 50, 20% Nifty Next 50, 20% Smallcap 250. Rebalance annually. #IndexFund #PassiveInvesting',
    'Understanding MF taxation (FY26 rules): Equity funds held >1 yr: LTCG 12.5% above ₹1.25L/yr. Held <1 yr: STCG 20%. Debt MF: taxed at slab rate (no indexation after 2023 Budget). ELSS: 3-yr lock-in, LTCG applies, qualifies for 80C. For tax efficiency: hold equity MFs for minimum 1 year, harvest losses in Dec (offset gains), use ELSS for 80C. #MFTaxation #TaxPlanning #MutualFunds'
  ];

  mf_med text[] := ARRAY[
    'Monthly SIP review: My Nifty 50 Index SIP returned 14.2% CAGR over 7 years. Total invested: ₹8.4L. Current value: ₹19.8L. Compounding is real. Don''t stop SIP when markets fall — that''s where all the returns come from. #SIP #IndexFund #CompoundingMagic',
    'Comparing top mid cap funds 5-yr returns: Kotak Midcap 50 Fund: 22.4%, Motilal Oswal Midcap: 28.6%, HDFC Midcap Opportunities: 21.8%, Nippon India Growth: 23.1%. Motilal significantly outperforming. But concentrated portfolio risk. I stay diversified across 2 mid cap funds. #MidCapFund #MutualFunds',
    'Why ELSS over PPF for 80C: ELSS lock-in 3 yrs vs PPF 15 yrs. ELSS historical CAGR ~14% vs PPF 7.1%. ₹1.5L invested in ELSS for 10 yrs = ₹5.6L. Same in PPF = ₹2.7L. Difference: ₹2.9L. Yes, ELSS has market risk. But over 10 yrs equity beats debt comfortably. Go ELSS. #ELSS #PPF #80C',
    'Parag Parikh Flexi Cap Fund — why I love it: 25% international allocation (US tech, Europe value). India portfolio is quality-focused (no cyclicals, no commodity). Fund manager (Rajeev Thakkar) is one of the most rational in India. 10-yr CAGR: 20.6%. Low portfolio turnover. Benchmark: Nifty 500 TRI. I put 40% of my equity MF allocation here. #PPFAS #FlexiCap',
    'Monthly SIP: ₹5k or ₹10k? Whatever you can afford to do WITHOUT breaking in a correction. If ₹10k SIP makes you panic and stop when market falls 20%, better to do ₹7k and stay invested. Consistency > amount. SIP discipline is worth more than SIP size. #SIP #Discipline #MutualFunds',
    'International MF options for Indian investors: 1. Motilal Oswal NASDAQ 100 FoF. 2. Mirae Asset S&P 500 FoF. 3. PGIM India Global Equity Opp (multi-geography). Taxation changed — now at slab rate like debt funds. Still useful for diversification. Max 15-20% of portfolio. #InternationalFund #GlobalDiversification'
  ];

  mf_low text[] := ARRAY[
    'Which mutual fund is best for ₹5000/month SIP? I''m 25 yrs old and want to invest for 20 years. Please suggest! #MutualFunds #Beginner #SIP',
    'My SIP is -12% right now. Should I stop or continue? I started 8 months ago. Very confused and worried. #SIP #Help',
    'Is Nifty 50 index fund good or should I invest in active funds? My banker says active funds are better. Who to believe? #IndexFund #ActiveFund',
    'Can I have 10 SIPs in 10 different funds? Or should I keep it simple? #SIP #MutualFunds #TooMany',
    'Parag Parikh fund invest karoon ya Axis Bluechip? Dono mein bahut confusion hai. Koi guide karo please! #MutualFunds'
  ];

  -- ── Financial Advice content ───────────────────────────────
  fa_hi text[] := ARRAY[
    'Emergency fund: the most ignored financial rule. Standard advice = 6 months expenses. For self-employed/gig: 12 months. Where to keep it? NOT FD (TDS + premature penalty). Best: 1. Liquid MF (immediate redemption T+1, ~7% returns). 2. High-yield savings (AU Small Finance Bank 7.25%). 3. Sweep-in FD at HDFC/ICICI (auto-converts excess balance). NEVER in equity. This money should be boring. #EmergencyFund #PersonalFinance #FinancialAdvice',
    'Asset allocation by age — evidence-based framework: 20s-30s: 90% equity + 10% debt. 40s: 70% equity + 30% debt. 50s: 50% equity + 50% debt. 60+: 30% equity + 70% debt. Rule of thumb: (100-age)% in equity. Adjust -10% if you have dependents or unstable income. Rebalance annually in January. This simple rule has beaten 90% of complex strategies over 25 yrs. #AssetAllocation #FinancialPlanning',
    'Complete 80C tax-saving guide: EPF (from salary — auto). ELSS MF: ₹1.5L limit (best option — 3yr lock-in). PPF: 7.1% guaranteed, 15yr (for risk-averse). NPS additional ₹50k deduction under 80CCD(1B). 80D: Health insurance premium up to ₹25k (₹50k if parents senior citizen). Total possible deductions: ₹2.75L. At 30% tax bracket = ₹82,500 saved. DO NOT buy traditional LIC plans for 80C — they destroy wealth. #TaxSaving #80C #FinancialPlanning',
    '10 financial rules I wish I knew at 22: 1. Earn > spend, invest the rest. 2. 20% savings rate minimum. 3. Debt is expensive — avoid consumer debt. 4. SIP > timing the market. 5. Tax efficiency matters as much as returns. 6. Real estate is lifestyle not investment. 7. Emergency fund before anything else. 8. Term insurance + health insurance before investing. 9. Track net worth quarterly. 10. Automate savings — remove willpower from the equation. #FinancialRules #MoneyMindset',
    'Retirement corpus math: If you want ₹1 lakh/month in today''s money at retirement 30 yrs from now: Inflation-adjusted need: ₹4.32L/month (at 5% inflation). Annual need: ₹51.8L. Corpus required at 4% SWR: ₹12.95 crores. To reach ₹12.95 cr in 30 yrs at 12% CAGR: need SIP of ₹35,480/month starting today. Or if you wait 5 yrs: ₹65,000/month SIP. Start early. Every year delay = double the monthly requirement. #RetirementPlanning #SIP #FinancialAdvice',
    'Term insurance: buy now, thank yourself later. Rule: Coverage = 15-20x annual income. ₹1 crore cover at 28 yrs = ₹7,500-10,000/year premium. Same cover at 38 yrs = ₹15,000-20,000/year. Buying 10 yrs early saves ₹1.5L over policy term. Platforms: Policybazaar to compare, buy direct from insurer. Zero investment plans — pure term only. Never buy ULIP or LIC endowment calling it "insurance". #TermInsurance #LifeInsurance #FinancialAdvice',
    'Portfolio review checklist I run every January: 1. Asset allocation drift? Rebalance if >5% off target. 2. Any zombie funds (underperforming benchmark 3 consecutive yrs)? Exit. 3. ELSS investments for 80C done? 4. Emergency fund still 6 months? 5. Insurance covers updated for income growth? 6. Goal-wise corpus on track? If not, increase SIP. 7. Any windfall to deploy? 30% lump sum + rest in 6-month STP. #AnnualReview #FinancialPlanning'
  ];

  fa_med text[] := ARRAY[
    'Tax saving for salaried: Max 80C (₹1.5L) via EPF + ELSS. Then 80CCD(1B) NPS ₹50k. Then 80D health insurance ₹25k. That''s ₹2.25L deduction. At 30% bracket = ₹67,500 saved per year. ELSS is best 80C — equity returns + tax benefit. #TaxSaving #80C #FinancialAdvice',
    'Credit card rule I follow: Pay 100% balance every month. No EMI on credit cards (19-42% effective interest). Use cards only for rewards + insurance. If you can''t pay full balance, cut the card. Credit card debt is the fastest way to poverty. #CreditCard #PersonalFinance',
    'Goal-based investing in practice: Separate goals → separate investments. Emergency fund → liquid MF. Child education (10 yr) → flexi cap MF SIP. House down payment (3 yr) → hybrid fund + recurring deposit. Retirement (25 yr) → Nifty 50 index SIP + NPS. Don''t mix goals. Don''t invest education fund in small cap. Match risk to timeline. #GoalBasedInvesting',
    'Health insurance: Don''t rely only on employer group policy. Reasons: 1. You lose it when you leave job. 2. Coverage too low (usually ₹3-5L). 3. Doesn''t cover pre-existing conditions well. Personal floater: ₹10-15L cover, ₹6,000-12,000/yr premium at 30. Niva Bupa, Star Health, HDFC Ergo are reputable. #HealthInsurance #PersonalFinance',
    'SIP vs Lump Sum: Data from last 20 yrs shows SIP underperforms lump sum in a consistently rising market by ~2% CAGR. But SIP wins in volatile sideways markets and psychologically — most investors can''t do lump sum without panic-selling. Pick the strategy you can actually execute. #SIPvsLumpSum #BehavioralFinance',
    'Money management tip that changed my life: Pay yourself first. On every salary credit, auto-transfer 20-25% to investment account before spending anything. What''s left is for spending. This reverses the "invest what''s left" failure mode. #PayYourselfFirst #PersonalFinance'
  ];

  fa_low text[] := ARRAY[
    'Is LIC better than mutual funds? My parents say LIC is safe. My colleague says MF is better. Who is right? #LIC #MutualFunds #Confused',
    'How much emergency fund should I have? I earn ₹50,000/month. Currently no savings. Scared to start. #EmergencyFund #Beginner',
    'I''m 35 with no investments. Is it too late to start? Should I invest in stock market at this age? Help! #Investing #LateStart',
    'Credit card bill ₹85,000 outstanding. Minimum due ₹2,500. Should I pay minimum or full? What is interest charged? #CreditCard #Help',
    'What is the difference between term insurance and LIC endowment plan? Which is better for a 28 year old? #TermInsurance #LIC'
  ];

  -- ── Macro Economy content ──────────────────────────────────
  macro_hi text[] := ARRAY[
    'RBI MPC Oct 2025 outcome: Repo held at 6.5% (6th consecutive hold). CRR cut 50bps → 4% (injects ₹1.16L cr liquidity). GDP forecast revised down 7.2% from 7.4%. Inflation projection: 4.5% FY26. Das tone: "Premature cuts risky." Market pricing: first cut Feb 2026. Rate-sensitives (banks, RE, NBFCs) rally on liquidity. Positioning in quality private banks ahead of rate cut cycle. $HDFCBANK $ICICIBANK #RBI #MonetaryPolicy',
    'US Fed 50bps cut impact on India markets: DXY weakened to 101, EM currencies strengthening broadly. INR at 83.4/$. Historical pattern post-first Fed cut: Nifty averages +18% in next 6 months (2001, 2007, 2019 data). FII flows to EMs surge as dollar carry unwinds. We''re at the start of this cycle. Overweight equity vs global peers. India growth premium (7% GDP vs 1-2% developed world) makes it the preferred EM destination. #USFed #FIIFlows #MacroTrade',
    'India CPI Sept 2025: 5.49% (vs expected 5.1%). Food inflation 9.24% — vegetables drove it (tomatoes +220% MoM). Core inflation at 3.6% — well controlled. RBI will look through supply-side food inflation. Rate cut in Dec still possible, Feb 2026 more certain. Bond yields: 10yr at 6.82%, priced for 1 cut. Equity impact: neutral to mildly negative (food inflation = consumption squeeze). #CPI #Inflation #RBI #MacroEconomy',
    'India GDP for Q1 FY26: 6.7% YoY growth (Census revised). Manufacturing +5.8% (muted), Services +7.9% (strong), Agriculture +2.4% (monsoon-dependent). Real GDP still above global average but deceleration from 8.2% peak. Private capex pickup lagging government capex. The big catalyst for reacceleration: rate cuts + US growth recovery + China+1 manufacturing shift. India structural growth thesis very much intact. #GDPGrowth #MacroEconomy',
    'Global macro impact on Indian equities — connection map: 1. US yields rise → FII outflows → Nifty correction. 2. Dollar strengthens → INR weakens → import inflation → RBI tightens. 3. China slowdown → commodity prices fall → India input costs decline → margin expansion for manufacturing cos. 4. Oil falls → India''s current account improves → INR strengthens → lower inflation. Currently: oil falling + China weak = net positive for India. #GlobalMacro #MacroEconomy'
  ];

  macro_med text[] := ARRAY[
    'RBI kept repo at 6.5% as expected. Market happy — no bad surprises. Banking stocks up 1.5% on the news. Rate cut narrative building for Feb 2026. Positioning in HDFC Bank ahead of that. #RBI #RepoRate',
    'US CPI came in at 2.9% — above 2.7% estimate. Fed cut timeline pushed back by 1 month. Indian markets reacted with 200pt Nifty fall in early morning trade. Recovered by close. FII may sell tomorrow. Watching. #USCPI #FIIFlows',
    'Oil at $72/barrel today — 18-month low. Very positive for India. Oil import bill drops ₹4-5L cr annually for every $10 price fall. CAD improves. INR strengthens. Inflation cools. RBI can cut rates sooner. PAINT, AVIATION, LOGISTICS stocks should benefit. #OilPrice #MacroEconomy',
    'India''s forex reserves at $700 billion — all-time high! RBI building reserves to cushion against any FII outflow shock. This is the highest EM reserve buffer excluding China. The "India is resilient" story is backed by this number. #ForexReserves #RBI',
    'Union Budget 2025 key takeaways: 1. Capital expenditure: ₹11.11L cr (same as last year). 2. Fiscal deficit: 4.9% of GDP. 3. No income tax changes. 4. Infrastructure + defence + railways: big allocations. 5. MSME incentives: positive for small cap. Net market positive. Focus on quality infrastructure names. #Budget2025 #FiscalPolicy',
    'Monsoon 2025 update: 7% above LPA (Long Period Average) as of August. Well-distributed across regions. Agriculture sector should grow 3.5-4% this year. Rural consumption revival expected from Kharif harvest (Nov-Dec). FMCG + consumer durables rural-focused cos benefit. #Monsoon2025 #Agriculture'
  ];

  macro_low text[] := ARRAY[
    'What is RBI rate cut? How does it affect my stock market portfolio? Can someone explain simply? #RBI #Beginner',
    'I heard US Fed cutting rates is good for India. But why exactly? Don''t understand the connection. #USFed #Macro',
    'Market fell because of US data. Why does US news affect Indian stocks? We are a different country no? #GlobalMarkets #Confused',
    'What is fiscal deficit? Budget mein ye word baar baar aata hai. Simple explanation please! #Budget #FiscalDeficit'
  ];

  -- ── General Finance content ────────────────────────────────
  gen_hi text[] := ARRAY[
    'Crossed ₹1 crore net worth today at age 34! Journey: Started at 24 with ₹15k salary + ₹5k SIP. Increased SIP 10% every year. No job change hops — one company, 10 yrs of compounding. Key lessons: 1. SIP discipline > salary hike chasing. 2. Avoided EMIs except home loan. 3. Didn''t touch investments during COVID crash. 4. Switched to direct MFs 6 yrs ago. 5. Trusted compounding and left it alone. Still only 34. Time is the real wealth weapon. #NetWorth1Crore #CompoundingMagic',
    'The most underrated finance skill: Saying no. Saying no to: lifestyle inflation when salary rises, buying things on EMI, FOMO investments, timing market entries, relatives asking for money, "friends" with sure-shot stock tips. Every "no" to these is a "yes" to your financial independence. Easy to type, hard to do. #FinancialDiscipline #MoneyMindset',
    'India vs China retail investor comparison: Indian SIP monthly: ₹21,400 cr ($2.6B). Chinese mutual fund SIP monthly: $8.2B. But India GDP = 20% of China. India retail investor as % of population: 7.3%. China: 14%. India growth potential in retail investing is enormous. In 10 yrs, India retail investment culture could match developed world. The structural bull case. #IndiaGrowth #RetailInvesting'
  ];

  gen_med text[] := ARRAY[
    'My portfolio this year: +31.4% CAGR. Mix: 55% direct stocks (mid/small cap), 30% index MF, 15% NPS. Best performer: $POLYCAB +87%. Worst: $WIPRO -3%. Overall: outperforming benchmark. Not repeating this process as a target but as a report card. #PortfolioUpdate #InvestingJourney',
    'Just hit ₹50L in MF portfolio! Started 8 yrs ago with ₹8k/month SIP. Increased to ₹30k/month over time. Total invested: ₹26L. XIRR: 16.4%. Not genius — just showed up every month and didn''t panic. #SIPMilestone #CompoundingWorks',
    'Question for the community: Should I pay off home loan (8.5% interest) or invest in equity MF (expected 12% return)? I know the math says invest. But what about the psychological benefit of being debt-free? Genuinely torn. Thoughts? #HomeLoan #FinancialDecision',
    'Book recommendation: The Psychology of Money by Morgan Housel. Changed how I think about investing. Key insight: "Getting wealthy and staying wealthy require different skills." Getting wealthy = risk-taking. Staying wealthy = humility + paranoia. #BookRecommendation #PersonalFinance',
    'Tracking net worth since 3 years. Jan 2023: ₹8.2L. Jan 2024: ₹14.7L. Jan 2025: ₹24.8L. Jan 2026: ₹38.4L. It''s not linear — later years add more in absolute terms. This is compounding at work. Keep investing, track quarterly, celebrate progress. #NetWorthTracking',
    'Indians are underinsured. Stats: Average Indian health cover: ₹3.8L. Required minimum: ₹15L. Average term cover: ₹25L. Required minimum: ₹1 crore. Fix insurance first, then invest. Wrong order is a financial disaster. #InsuranceGap #PersonalFinance'
  ];

  gen_low text[] := ARRAY[
    'Market crashed today! Everyone said Sensex was going to 1 lakh. Now it''s falling. This is rigged!! #MarketCrash #Conspiracy',
    'My WhatsApp group says buy XYZ stock for 200% gain in 1 month. Anyone know this stock? Genuine or fake? #WhatsAppTips #StockTips',
    'Invested in crypto last year. Lost 70%. Now shifting to stocks. Is stock market also same as crypto? Very risky? #Crypto #StockMarket',
    'Rich dad poor dad book me likha hai stocks mein invest karo. To main karu? My family says bank FD best. #RichDadPoorDad #Confused',
    'Got Diwali bonus ₹50,000. Should I invest all in stocks or split? Which stocks? Help me please! #DiwaliBonus #WhereToInvest',
    'ASTROLOGY UPDATE: Jupiter entering Taurus on Friday = BULLISH for banking stocks per Vedic chart patterns. Accumulate HDFC Bank before Friday! 🪐 #AstroInvesting #JupiterTaurus',
    'I have been paper trading for 3 years. My paper portfolio is up 340%. But scared to put real money. Maybe 1 more year of paper trading first. #PaperTrading #Analysis',
    'Market is gambling. Banks give safe 7% interest. Why take risk in stocks? Sensible people keep money safe. FD zindabad! 🏦 #FDZindabad #MarketIsGambling',
    'Bought Adani stocks on news. They crashed 50%. Should I sue the company? This is cheating investors! #Adani #InvestorGrievance',
    'CRASH ALERT 🚨🚨🚨: Nifty 50 going to 10,000!! Sell everything NOW!! I predicted this 24 times already and trust me this time it''s real!! #NiftyCrash #SellEverything'
  ];

  -- ── Post generation loop ───────────────────────────────────
  v_user        record;
  v_post_count  int;
  v_cat         uuid;
  v_content     text;
  v_hashtags    text[];
  v_tickers     text[];
  v_is_anon     boolean;
  v_image_url   text;
  v_created_at  timestamptz;
  i             int;
  r_idx         int;

  -- Ticker pools per category
  nse_tickers   text[] := ARRAY['$NIFTY','$HDFCBANK','$ICICIBANK','$RELIANCE','$TCS','$INFY','$SBIN','$TATAMOTORS'];
  ta_tickers    text[] := ARRAY['$TATAMOTORS','$RELIANCE','$ICICIBANK','$HDFCBANK','$WIPRO','$BAJFINANCE','$ADANIPORTS','$MARUTI'];
  sme_tickers   text[] := ARRAY['$SMEINDEX'];
  smc_tickers   text[] := ARRAY['$IRFC','$POLYCAB','$LATENTVIEW','$APLAPOLLO','$CROMPTON','$TRIDENT','$MAPMYINDIA'];
  lc_tickers    text[] := ARRAY['$RELIANCE','$TCS','$HDFCBANK','$INFY','$ITC','$MARUTI','$SUNPHARMA','$WIPRO','$SBIN'];
  mf_tickers    text[] := ARRAY['$NIFTY'];
  ipo_tickers   text[] := ARRAY['$BAJAJHFL','$HYUNDAIINDIA','$WAAREE'];
  macro_tickers text[] := ARRAY['$NIFTY','$HDFCBANK','$SBIN'];

  -- Hashtag pools per category
  nse_tags    text[] := ARRAY['#Nifty50','#NSEIndia','#BSEIndia','#Sensex','#FIIData','#MarketUpdate','#StockMarket'];
  ipo_tags    text[] := ARRAY['#IPO','#IPOWatch','#IPO2025','#GMP','#ListingGains','#MainboardIPO'];
  ta_tags     text[] := ARRAY['#TechnicalAnalysis','#ChartAnalysis','#RSI','#MACD','#SwingTrade','#Breakout'];
  sme_tags    text[] := ARRAY['#SMEIPO','#SMEStocks','#SmallBusiness','#IPOGains'];
  smc_tags    text[] := ARRAY['#SmallCap','#MidCap','#ValueInvesting','#MultiBagger','#StockResearch'];
  lc_tags     text[] := ARRAY['#LargeCap','#Nifty50','#BlueChip','#LongTerm','#DividendStocks'];
  mf_tags     text[] := ARRAY['#MutualFunds','#SIP','#IndexFunds','#DirectPlan','#ELSS','#Compounding'];
  fa_tags     text[] := ARRAY['#FinancialAdvice','#PersonalFinance','#MoneyTips','#FinancialPlanning','#RetirementPlanning'];
  macro_tags  text[] := ARRAY['#MacroEconomy','#RBI','#FedRate','#Inflation','#GDP','#FIIFlows'];
  gen_tags    text[] := ARRAY['#Finance','#Investing','#MoneyMindset','#WealthBuilding','#FinanceTips'];

  -- Chart image URLs (quickchart.io — assigned to first 8 Wolf posts)
  chart_urls text[] := ARRAY[
    'https://quickchart.io/chart?bkg=white&c={type:%27line%27,data:{labels:[%27Jun%27,%27Jul%27,%27Aug%27,%27Sep%27,%27Oct%27,%27Nov%27,%27Dec%27,%27Jan%27,%27Feb%27,%27Mar%27,%27Apr%27,%27May%27,%27Jun%27],datasets:[{label:%27Nifty+50+Monthly+Close%27,data:[23500,24180,24650,25800,24100,23750,24500,23200,22480,23950,24700,25100,24683],fill:false,borderColor:%27rgb(75,192,192)%27,tension:0.3}]}}&width=700&height=380',
    'https://quickchart.io/chart?bkg=white&c={type:%27bar%27,data:{labels:[%27IT%27,%27Banking%27,%27Pharma%27,%27Auto%27,%27FMCG%27,%27Realty%27],datasets:[{label:%27YTD+2025+Return+(%25)%27,data:[18.4,12.1,14.3,-2.1,3.8,-8.7],backgroundColor:[%27rgb(75,192,192)%27,%27rgb(54,162,235)%27,%27rgb(255,205,86)%27,%27rgb(255,99,132)%27,%27rgb(153,102,255)%27,%27rgb(255,159,64)%27]}]}}&width=700&height=380',
    'https://quickchart.io/chart?bkg=white&c={type:%27line%27,data:{labels:[%27Yr+1%27,%27Yr+3%27,%27Yr+5%27,%27Yr+7%27,%27Yr+10%27,%27Yr+15%27,%27Yr+20%27],datasets:[{label:%27Rs+5000%2Fmo+SIP+%4012%25+CAGR+(Rs+Lakhs)%27,data:[0.62,2.34,4.08,7.15,11.5,25.0,49.9],fill:true,backgroundColor:%27rgba(75,192,192,0.2)%27,borderColor:%27rgb(75,192,192)%27}]}}&width=700&height=380',
    'https://quickchart.io/chart?bkg=white&c={type:%27bar%27,data:{labels:[%27Small+Cap%27,%27Mid+Cap%27,%27Flexi+Cap%27,%27Large+Cap%27,%27Hybrid%27,%27Debt%27],datasets:[{label:%275-yr+CAGR+(%25)%27,data:[24.8,22.3,18.9,16.4,14.2,7.8],backgroundColor:[%27rgb(255,99,132)%27,%27rgb(255,159,64)%27,%27rgb(255,205,86)%27,%27rgb(75,192,192)%27,%27rgb(54,162,235)%27,%27rgb(153,102,255)%27]}]}}&width=700&height=380',
    'https://quickchart.io/chart?bkg=white&c={type:%27bar%27,data:{labels:[%27Jul%27,%27Aug%27,%27Sep%27,%27Oct%27,%27Nov%27,%27Dec%27,%27Jan%27,%27Feb%27,%27Mar%27,%27Apr%27,%27May%27,%27Jun%27],datasets:[{label:%27FII+Net+(Rs+cr)%27,data:[-2340,1890,-8730,-15420,3210,-890,7840,12300,-4560,8920,6780,4218],backgroundColor:%27rgba(255,99,132,0.7)%27},{label:%27DII+Net+(Rs+cr)%27,data:[3210,2890,9100,14800,2100,1200,3400,2800,6700,4200,3100,2891],backgroundColor:%27rgba(75,192,192,0.7)%27}]}}&width=700&height=380',
    'https://quickchart.io/chart?bkg=white&c={type:%27line%27,data:{labels:[%272015%27,%272016%27,%272017%27,%272018%27,%272019%27,%272020%27,%272021%27,%272022%27,%272023%27,%272024%27,%272025%27],datasets:[{label:%27Nifty+50%27,data:[100,103,128,120,141,148,205,198,237,280,310],borderColor:%27rgb(75,192,192)%27,fill:false},{label:%27Gold%27,data:[100,109,116,123,140,164,175,183,200,220,248],borderColor:%27rgb(255,205,86)%27,fill:false},{label:%27FD+%407%25%27,data:[100,107,114,122,130,140,150,160,172,184,197],borderColor:%27rgb(153,102,255)%27,fill:false}]}}&width=700&height=380',
    'https://quickchart.io/chart?bkg=white&c={type:%27bar%27,data:{labels:[%271Y%27,%272Y%27,%273Y%27],datasets:[{label:%27Small+Cap%27,data:[38.2,24.8,32.1],backgroundColor:%27rgba(255,99,132,0.7)%27},{label:%27Mid+Cap%27,data:[28.7,19.4,24.8],backgroundColor:%27rgba(255,159,64,0.7)%27},{label:%27Large+Cap%27,data:[18.4,14.2,16.1],backgroundColor:%27rgba(75,192,192,0.7)%27}]}}&width=700&height=380',
    'https://quickchart.io/chart?bkg=white&c={type:%27line%27,data:{labels:[%27Jun%27,%27Jul%27,%27Aug%27,%27Sep%27,%27Oct%27,%27Nov%27,%27Dec%27,%27Jan%27,%27Feb%27,%27Mar%27,%27Apr%27,%27May%27,%27Jun%27],datasets:[{label:%27HDFC+Bank+(Rs)%27,data:[1580,1620,1690,1780,1650,1590,1700,1580,1520,1680,1730,1780,1850],borderColor:%27rgb(54,162,235)%27,fill:false,tension:0.3}]}}&width=700&height=380'
  ];

  chart_idx    int := 1;
  wolf_post_i  int := 0;  -- count Wolf posts to assign chart URLs

BEGIN
  -- ── Fetch category IDs ──
  SELECT id INTO cat_nse   FROM categories WHERE name = 'NSE/BSE Market';
  SELECT id INTO cat_ipo   FROM categories WHERE name = 'IPO Watch';
  SELECT id INTO cat_ta    FROM categories WHERE name = 'Technical Analysis';
  SELECT id INTO cat_sme   FROM categories WHERE name = 'SME Stocks';
  SELECT id INTO cat_smc   FROM categories WHERE name = 'Small & Mid Cap';
  SELECT id INTO cat_lc    FROM categories WHERE name = 'Large Cap';
  SELECT id INTO cat_mf    FROM categories WHERE name = 'Mutual Funds';
  SELECT id INTO cat_fa    FROM categories WHERE name = 'Financial Advice';
  SELECT id INTO cat_macro FROM categories WHERE name = 'Macro Economy';
  SELECT id INTO cat_gen   FROM categories WHERE name = 'General Finance';

  -- ── Loop over every user ──
  FOR v_user IN
    SELECT tier, user_id, primary_cat, handle FROM seed_tiers ORDER BY random()
  LOOP
    -- Determine post count per tier
    v_post_count := CASE v_user.tier
      WHEN 'W' THEN 30 + floor(random()*10)::int
      WHEN 'Q' THEN 22 + floor(random()*6)::int
      WHEN 'P' THEN 12 + floor(random()*6)::int
      WHEN 'R' THEN  7 + floor(random()*6)::int
      WHEN 'N' THEN  4 + floor(random()*4)::int
      WHEN 'X' THEN  3 + floor(random()*3)::int
      ELSE 3
    END;

    FOR i IN 1..v_post_count LOOP
      v_image_url := NULL;

      -- 70% posts in primary category, 30% in random other categories
      IF random() < 0.70 THEN
        v_cat := CASE v_user.primary_cat
          WHEN 'NSE/BSE Market'     THEN cat_nse
          WHEN 'IPO Watch'          THEN cat_ipo
          WHEN 'Technical Analysis' THEN cat_ta
          WHEN 'SME Stocks'         THEN cat_sme
          WHEN 'Small & Mid Cap'    THEN cat_smc
          WHEN 'Large Cap'          THEN cat_lc
          WHEN 'Mutual Funds'       THEN cat_mf
          WHEN 'Financial Advice'   THEN cat_fa
          WHEN 'Macro Economy'      THEN cat_macro
          ELSE cat_gen
        END;
      ELSE
        -- Random other category
        v_cat := CASE floor(random()*10)::int
          WHEN 0 THEN cat_nse  WHEN 1 THEN cat_ipo  WHEN 2 THEN cat_ta
          WHEN 3 THEN cat_sme  WHEN 4 THEN cat_smc  WHEN 5 THEN cat_lc
          WHEN 6 THEN cat_mf   WHEN 7 THEN cat_fa   WHEN 8 THEN cat_macro
          ELSE cat_gen
        END;
      END IF;

      -- Pick content + hashtags + tickers based on tier quality + category
      IF v_cat = cat_nse THEN
        v_hashtags := nse_tags[1:3 + floor(random()*4)::int];
        v_tickers  := ARRAY[nse_tickers[1 + floor(random()*8)::int]];
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*11)::int;
          v_content := nse_hi[LEAST(r_idx, array_length(nse_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*8)::int;
          v_content := nse_med[LEAST(r_idx, array_length(nse_med,1))];
        ELSE
          r_idx := 1 + floor(random()*5)::int;
          v_content := nse_low[LEAST(r_idx, array_length(nse_low,1))];
        END IF;

      ELSIF v_cat = cat_ipo THEN
        v_hashtags := ipo_tags[1:2 + floor(random()*4)::int];
        v_tickers  := ARRAY[ipo_tickers[1 + floor(random()*3)::int]];
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*5)::int;
          v_content := ipo_hi[LEAST(r_idx, array_length(ipo_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*6)::int;
          v_content := ipo_med[LEAST(r_idx, array_length(ipo_med,1))];
        ELSE
          r_idx := 1 + floor(random()*5)::int;
          v_content := ipo_low[LEAST(r_idx, array_length(ipo_low,1))];
        END IF;

      ELSIF v_cat = cat_ta THEN
        v_hashtags := ta_tags[1:3 + floor(random()*3)::int];
        v_tickers  := ARRAY[ta_tickers[1 + floor(random()*8)::int]];
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*10)::int;
          v_content := ta_hi[LEAST(r_idx, array_length(ta_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*6)::int;
          v_content := ta_med[LEAST(r_idx, array_length(ta_med,1))];
        ELSE
          r_idx := 1 + floor(random()*5)::int;
          v_content := ta_low[LEAST(r_idx, array_length(ta_low,1))];
        END IF;

      ELSIF v_cat = cat_sme THEN
        v_hashtags := sme_tags[1:2 + floor(random()*2)::int];
        v_tickers  := '{}';
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*4)::int;
          v_content := sme_hi[LEAST(r_idx, array_length(sme_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*4)::int;
          v_content := sme_med[LEAST(r_idx, array_length(sme_med,1))];
        ELSE
          r_idx := 1 + floor(random()*4)::int;
          v_content := sme_low[LEAST(r_idx, array_length(sme_low,1))];
        END IF;

      ELSIF v_cat = cat_smc THEN
        v_hashtags := smc_tags[1:3 + floor(random()*2)::int];
        v_tickers  := ARRAY[smc_tickers[1 + floor(random()*7)::int]];
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*7)::int;
          v_content := smc_hi[LEAST(r_idx, array_length(smc_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*6)::int;
          v_content := smc_med[LEAST(r_idx, array_length(smc_med,1))];
        ELSE
          r_idx := 1 + floor(random()*4)::int;
          v_content := smc_low[LEAST(r_idx, array_length(smc_low,1))];
        END IF;

      ELSIF v_cat = cat_lc THEN
        v_hashtags := lc_tags[1:2 + floor(random()*3)::int];
        v_tickers  := ARRAY[lc_tickers[1 + floor(random()*9)::int]];
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*7)::int;
          v_content := lc_hi[LEAST(r_idx, array_length(lc_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*6)::int;
          v_content := lc_med[LEAST(r_idx, array_length(lc_med,1))];
        ELSE
          r_idx := 1 + floor(random()*5)::int;
          v_content := lc_low[LEAST(r_idx, array_length(lc_low,1))];
        END IF;

      ELSIF v_cat = cat_mf THEN
        v_hashtags := mf_tags[1:3 + floor(random()*3)::int];
        v_tickers  := '{}';
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*7)::int;
          v_content := mf_hi[LEAST(r_idx, array_length(mf_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*6)::int;
          v_content := mf_med[LEAST(r_idx, array_length(mf_med,1))];
        ELSE
          r_idx := 1 + floor(random()*5)::int;
          v_content := mf_low[LEAST(r_idx, array_length(mf_low,1))];
        END IF;

      ELSIF v_cat = cat_fa THEN
        v_hashtags := fa_tags[1:2 + floor(random()*3)::int];
        v_tickers  := '{}';
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*7)::int;
          v_content := fa_hi[LEAST(r_idx, array_length(fa_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*6)::int;
          v_content := fa_med[LEAST(r_idx, array_length(fa_med,1))];
        ELSE
          r_idx := 1 + floor(random()*5)::int;
          v_content := fa_low[LEAST(r_idx, array_length(fa_low,1))];
        END IF;

      ELSIF v_cat = cat_macro THEN
        v_hashtags := macro_tags[1:2 + floor(random()*4)::int];
        v_tickers  := ARRAY[macro_tickers[1 + floor(random()*3)::int]];
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*5)::int;
          v_content := macro_hi[LEAST(r_idx, array_length(macro_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*6)::int;
          v_content := macro_med[LEAST(r_idx, array_length(macro_med,1))];
        ELSE
          r_idx := 1 + floor(random()*4)::int;
          v_content := macro_low[LEAST(r_idx, array_length(macro_low,1))];
        END IF;

      ELSE  -- General Finance
        v_hashtags := gen_tags[1:2 + floor(random()*3)::int];
        v_tickers  := '{}';
        IF v_user.tier IN ('W','Q') THEN
          r_idx := 1 + floor(random()*3)::int;
          v_content := gen_hi[LEAST(r_idx, array_length(gen_hi,1))];
        ELSIF v_user.tier IN ('P','R') THEN
          r_idx := 1 + floor(random()*6)::int;
          v_content := gen_med[LEAST(r_idx, array_length(gen_med,1))];
        ELSE
          r_idx := 1 + floor(random()*10)::int;
          v_content := gen_low[LEAST(r_idx, array_length(gen_low,1))];
        END IF;
      END IF;

      -- ~10% of posts are anonymous
      v_is_anon := (random() < 0.10);

      -- Date: random within past 365 days
      v_created_at := now() - (random() * interval '365 days');

      -- Assign chart image to first 8 Wolf posts across first 8 wolves
      IF v_user.tier = 'W' AND i = 1 AND chart_idx <= 8 THEN
        v_image_url := chart_urls[chart_idx];
        chart_idx   := chart_idx + 1;
      END IF;

      INSERT INTO posts (
        author_id, content, hashtags, tickers, tags,
        category_id, image_url, is_anonymous, is_pinned, created_at
      ) VALUES (
        v_user.user_id, v_content, v_hashtags, v_tickers, '{}',
        v_cat, v_image_url, v_is_anon, false, v_created_at
      );

    END LOOP; -- posts per user
  END LOOP;   -- users

END $POSTS$;

-- Sanity check
SELECT count(*) AS total_posts FROM posts;
SELECT c.name, count(p.id) AS post_count
FROM posts p JOIN categories c ON c.id = p.category_id
GROUP BY c.name ORDER BY post_count DESC;
