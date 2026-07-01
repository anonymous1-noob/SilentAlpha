-- ============================================================
-- SilentAlpha Finance Seed — PART 1: Users & Categories
-- Run this FIRST in Supabase SQL Editor
-- Creates: 10 finance categories + 100 users
-- All user passwords: Market@2025
-- Then run seed_p2_posts.sql, then seed_p3_engagement.sql
-- ============================================================

-- ── PHASE 0: CLEAR ALL OLD DATA ──────────────────────────────
TRUNCATE TABLE
  hidden_posts, poll_votes, polls, post_ratings,
  saved_posts, comments, notifications,
  reports, blocks, follows, follow_requests, posts
  RESTART IDENTITY CASCADE;

-- Only delete seed profiles (keep real user accounts intact)
DELETE FROM public.profiles WHERE id IN (
  SELECT id FROM auth.users WHERE email LIKE '%@silentmarket.in'
);
DELETE FROM auth.users WHERE email LIKE '%@silentmarket.in';

-- ── PHASE 1: FINANCE CATEGORIES ──────────────────────────────
DELETE FROM public.categories;

INSERT INTO public.categories (name, emoji) VALUES
  ('NSE/BSE Market',     '📊'),
  ('IPO Watch',          '🔔'),
  ('Technical Analysis', '📉'),
  ('SME Stocks',         '🏭'),
  ('Small & Mid Cap',    '📈'),
  ('Large Cap',          '🏦'),
  ('Mutual Funds',       '💰'),
  ('Financial Advice',   '🧠'),
  ('Macro Economy',      '🌐'),
  ('General Finance',    '💬');

-- ── PHASE 2: SEED USER DEFINITIONS ───────────────────────────
-- tier: W=Wolf(10) Q=Quant(5) P=Pro(15) R=Regular(30)
--       N=Novice(25) X=Random(15)

CREATE TEMP TABLE IF NOT EXISTS seed_users_def (
  seq         serial,
  email       text,
  handle      text,
  bio         text,
  tagline     text,
  tier        char(1),
  primary_cat text
);
TRUNCATE seed_users_def;

INSERT INTO seed_users_def (email,handle,bio,tagline,tier,primary_cat) VALUES
-- WOLVES (10)
('raghavniftypro@silentmarket.in','RaghavNiftyPro',
 '15 yrs in equity markets. Ex-Motilal Oswal dealer. SEBI RIA. Nifty delivery + options. Views are personal.',
 'Nifty या मत, बस करोड़पति बनो 📊','W','NSE/BSE Market'),

('deepakalphacapital@silentmarket.in','DeepakAlphaCapital',
 'CFA Level 3. Fund manager at a Mumbai AIF. Macro-first, bottom-up when valuations scream. Past ≠ future.',
 'Alpha is earned, not bought 🎯','W','Large Cap'),

('priyamarketqueen@silentmarket.in','PriyaMarketQueen',
 'Nifty 50 investor since 2008. Survived 2008 crash + 2020 COVID lows. 18yr compounding track record.',
 'Buy fear, sell greed. Repeat. 🏦','W','NSE/BSE Market'),

('arjunquantcapital@silentmarket.in','ArjunQuantCapital',
 'IIT Bombay → quant desk ICICI Securities. Python algo trader. Options strategies, vol surfaces. Data > opinion.',
 'Delta-neutral since 2019 ⚡','W','Technical Analysis'),

('vikraminvestsmart@silentmarket.in','VikramInvestSmart',
 'SEBI-registered investment advisor. 3000+ clients. PMS license. Speciality: retirement planning for families.',
 'Your wealth, my mission 💼','W','Financial Advice'),

('kavitamarkets@silentmarket.in','KavitaMarkets',
 '14 yrs in MF distribution. Ex-HDFC AMC. AMFI certified. Direct plans only. Zero NFO hype, ever.',
 'SIP करो, टेंशन मत करो 💰','W','Mutual Funds'),

('nithinvaluehunter@silentmarket.in','NithinValueHunter',
 'Deep value investor. Graham school. Screens 400+ stocks/month. Bought Avanti Feeds at ₹80. Patience = profit.',
 'Price is what you pay, value is what you get','W','Small & Mid Cap'),

('rishialphagenesis@silentmarket.in','RishiAlphaGen',
 'SME IPO specialist. Tracked 50+ SMEs since 2018. Knows every promoter. GMP is my morning coffee. High risk.',
 'SME king of Dalal Street 🏭','W','SME Stocks'),

('ananyafinpro@silentmarket.in','AnanyaFinPro',
 'Macro economist turned investor. RBI, US Fed, DXY — connecting dots since 2012. MBA IIM-A. Views personal.',
 'Macro drives micro 🌐','W','Macro Economy'),

('sureshbullcapital@silentmarket.in','SureshBullCapital',
 'Full-time trader since 2012. Swing + positional. Nifty, Bank Nifty, F&O. 70%+ win rate in trending markets.',
 'Survive first, profit second 📈','W','Technical Analysis'),

-- QUANTS (5)
('kiranoptionsdesk@silentmarket.in','KiranOptionsDesk',
 'Options premium seller. Iron condors, strangles, calendars. Weekly expiry ninja. Risk-defined trades only.',
 'Theta is my salary 📉','Q','Technical Analysis'),

('rahulvolsmith@silentmarket.in','RahulVolSmith',
 'Vol trading, India VIX, PCR analysis. Self-taught quant. Runs a vol screener. Shares backtests publicly.',
 'VIX says everything 📊','Q','Technical Analysis'),

('meeraalgotrade@silentmarket.in','MeeraAlgoTrade',
 'Algo developer. Python + Zerodha Kite API. Market making, stat arb, mean reversion. 5-yr live track record.',
 'Code the market, beat the market 💻','Q','NSE/BSE Market'),

('saurabhquantfx@silentmarket.in','SaurabhQuantFX',
 'FX + rates quant. DXY, USD/INR, RBI OMOs. Macro models for equity. Ex-Goldman Sachs Mumbai.',
 'Rates before equities, always 🌐','Q','Macro Economy'),

('poojadatadriven@silentmarket.in','PoojaDataDriven',
 'Data scientist at a hedge fund. Factor models, smart beta, Fama-French India. Monthly factor return reports.',
 'Factor investing > stock picking 📊','Q','Small & Mid Cap'),

-- PROS (15)
('nikhilvalueseeker@silentmarket.in','NikhilValueSeeker',
 'DIY investor 8 yrs. Direct MF + select stocks. Concentrated portfolio. XIRR 19.4% since 2017.',
 'Quality + valuation = wealth','P','Small & Mid Cap'),

('snehamfbhakt@silentmarket.in','SnehaMFBhakt',
 'MF-only investor. 100% direct plans. Tracks 250+ funds monthly. Goal-based investing evangelist. No stock tips.',
 'Mutual funds sahi hai 💰','P','Mutual Funds'),

('rajsmallcaphunter@silentmarket.in','RajSmallCapHunter',
 'Small cap researcher. Factory visits, reads ARs cover-to-cover. Found 3 multibaggers in 5 yrs.',
 'Research before conviction 📈','P','Small & Mid Cap'),

('adityansewatcher@silentmarket.in','AdityaNSEWatcher',
 'NSE live watcher. Tracks FII/DII data daily. Breadth indicators, A-D ratio nerd. Swing trades on data.',
 'Data > noise, always 📊','P','NSE/BSE Market'),

('pujadividendqueen@silentmarket.in','PujaDividendQueen',
 'Dividend growth investor. ITC, Coal India, Power Grid. Building passive income. ₹15k/month dividend goal.',
 'Dividends sleep on your behalf 💵','P','Large Cap'),

('sameeripotracker@silentmarket.in','SameerIPOTracker',
 'IPO specialist. All mainboard + SME IPOs. GMP, allotment, listing analysis. 80%+ allotment rate.',
 'GMP nahi, fundamentals dekho 🔔','P','IPO Watch'),

('tanyatechanalyst@silentmarket.in','TanyaTechAnalyst',
 'Technical analyst 6 yrs. RSI, MACD, Bollinger, EMA. Swing trader in Nifty 50 stocks. 60%+ win rate.',
 'Charts don''t lie, traders do 📉','P','Technical Analysis'),

('ravimacrolens@silentmarket.in','RaviMacroLens',
 'Macro watcher. RBI, MPC, US CPI, FII flow data. Equity calls based on macro cycle. Contrarian nature.',
 'Ignore macro at your own risk 🌐','P','Macro Economy'),

('ankitsectorrotate@silentmarket.in','AnkitSectorRotate',
 'Sector rotation strategy. NIFTY IT, PHARMA, BANK, AUTO. Rotates on economic cycle. 3-yr track record.',
 'Rotate with the economy 🔄','P','NSE/BSE Market'),

('divyabluechip@silentmarket.in','DivyaBluechip',
 'Large cap only investor. Buy and hold 5+ yrs. ROE, FCF, management quality. No F&O, no SME, ever.',
 'Boring stocks, exciting returns 🏦','P','Large Cap'),

('mohitmidcapmaster@silentmarket.in','MohitMidCapMaster',
 'Mid cap specialist. ₹2000-20000 cr market cap sweet spot. Tracks 150 mid caps monthly. 3 baggers in 4 yrs.',
 'Mid cap: the Goldilocks zone 📈','P','Small & Mid Cap'),

('sunitasipqueen@silentmarket.in','SunitaSIPQueen',
 'SIP evangelist. 12-yr investor. XIRR 16.8%. Preaches step-up SIP to every young professional.',
 'Step-up SIP > lump sum always 💰','P','Mutual Funds'),

('gauravsmespecialist@silentmarket.in','GauravSMESpecialist',
 'SME IPO researcher. Applies 15-20 SMEs/month. Tracks operator activity, promoter pledging carefully.',
 'SME = high risk, high reward 🏭','P','SME Stocks'),

('rekhavalueplus@silentmarket.in','RekhaValuePlus',
 'Value + quality investor. Inspired by Buffett + Munger. Screens for moat, pricing power, clean B/S.',
 'Moat is everything 🏰','P','Large Cap'),

('vijaychartsmaster@silentmarket.in','VijayChartsMaster',
 'Price action trader. No indicators — price, volume, S/R only. Swing + intraday. 7 yr experience.',
 'Price action never lies 📉','P','Technical Analysis'),

-- REGULARS (30)
('amitretailinvestor@silentmarket.in','AmitRetailInvestor',
 'Naukri + investing. SIP ₹25k/month. Goal: ₹5cr by 45. Reads ValuePickr daily. 4 yrs in markets.',
 'Slow and steady wins 📈','R','NSE/BSE Market'),

('preetiniftywatch@silentmarket.in','PreetiNiftyWatch',
 'Homemaker-turned-investor. Started ₹5k SIP in 2020. Now managing own MF portfolio. Learning TA slowly.',
 'Every rupee counts 💪','R','Mutual Funds'),

('karthikstocklover@silentmarket.in','KarthikStockLover',
 'IT engineer by day, investor by night. Sector rotation learner. Index core + stock satellites.',
 'Engineering returns like code 💻','R','NSE/BSE Market'),

('nehataxsaver@silentmarket.in','NehaTaxSaver',
 'Maxes 80C every year via ELSS. Slowly getting into direct stocks. Moneycontrol reader daily.',
 'Save tax, build wealth 💼','R','Financial Advice'),

('sumanspottrader@silentmarket.in','SumanSpotTrader',
 'Swing trader, 3 yrs in markets. Nifty 50 stocks. Learning risk management the hard way.',
 'Learning never stops 📊','R','Technical Analysis'),

('alokbankingbull@silentmarket.in','AlokBankingBull',
 'Banking sector bull. HDFC Bank, ICICI, Kotak. Believes financials drive India growth story.',
 'India is a banking story 🏦','R','Large Cap'),

('shilpaipoalerts@silentmarket.in','ShilpaIPOAlerts',
 'IPO applicant for listing gains. Not a long-term holder. Applies at cutoff, sells on listing day.',
 'IPO listing = ATM 🔔','R','IPO Watch'),

('rohitsectorwatch@silentmarket.in','RohitSectorWatch',
 'Tracks monthly sector performance. Rotates based on momentum. Excel dashboard. 2 yr track record.',
 'Follow the momentum 📈','R','NSE/BSE Market'),

('madhavipsycho@silentmarket.in','MadhaviPsycho',
 'Behavioral finance enthusiast. Reads Kahneman. Investor psychology nerd. Mostly index funds.',
 'Mind over market 🧠','R','Financial Advice'),

('vikashsmallcap@silentmarket.in','VikashSmallCap',
 'Started with small caps. 60% mid/small index, 30% direct stocks. 1 lakh to 3 yr journey.',
 'Small cap dreams, big hopes 📈','R','Small & Mid Cap'),

('renukaelss@silentmarket.in','RenukaELSS',
 'ELSS first, then NPS. Tax-saving focused. Diversifying into large cap index. Retirement planning mode.',
 'Tax efficiency = more wealth 💰','R','Financial Advice'),

('tarunmacrowatcher@silentmarket.in','TarunMacroWatcher',
 'Follows global macro. US Fed, China GDP, oil prices. Thinks macro before picking sectors.',
 'Global macro, local returns 🌐','R','Macro Economy'),

('shobhafundamentals@silentmarket.in','ShobhaFundamentals',
 'Reads annual reports. Studies P/E, ROE, D/E. Holds 8 stocks concentrated. 3 yr track record.',
 'Fundamentals first, always 📚','R','Large Cap'),

('prashantsensex@silentmarket.in','PrashantSensex',
 'Sensex tracker. Index investing + occasional stock picks. Nifty BeES core. 5% satellite stocks.',
 'Sensex is India, India is Sensex 📊','R','NSE/BSE Market'),

('anjaneyafno@silentmarket.in','AnjaneyaFNO',
 'New to F&O. Mostly buys options. Learning from expensive mistakes. Sharing journey honestly.',
 'Options = education fees 📉','R','Technical Analysis'),

('nilataxfree@silentmarket.in','NilaTaxFree',
 'LTCG strategy. Holds >1 yr for tax efficiency. 6 stocks, 2 MFs. Simple portfolio philosophy.',
 '1 year = tax free gain 💼','R','Financial Advice'),

('rameshdiviinvestor@silentmarket.in','RameshDiviInvestor',
 'Dividend + growth hybrid. ITC, Power Grid + midcap growth stocks. Monthly dividend tracker.',
 'Dividends + growth = joy 💰','R','Large Cap'),

('sujatanifty50@silentmarket.in','SujataNifty50',
 'Pure index investor. Nifty 50 + Nifty Next 50. SIP monthly. Does not check portfolio daily.',
 'SIP + ignore = wealth 🧘','R','Mutual Funds'),

('tamonashbanking@silentmarket.in','TamonashBanking',
 'Tracks bank credit growth, NPA ratios, NIM spreads. Deep diver in financials. 5 yr banking bull.',
 'Banks make India run 🏦','R','Large Cap'),

('varshastartinvest@silentmarket.in','VarshaStartInvest',
 '20 yrs old, first job, first SIP. Learning basics. Follows MF analysts. Asks many questions.',
 'Newbie but eager! 🌱','R','Mutual Funds'),

('pawankiranapicks@silentmarket.in','PawanKiranaPicks',
 'Tracks FMCG + consumption. India consumption story is 20-yr tailwind. HUL, Marico, Pidilite fan.',
 'India eats, India invests 📈','R','Large Cap'),

('tanvichartread@silentmarket.in','TanviChartRead',
 'Learning TA since 3 months. EMA 20-50 crossovers, basic RSI. Making mistakes, learning fast.',
 'Charts are my new textbooks 📉','R','Technical Analysis'),

('manoharretire@silentmarket.in','ManoharRetireFund',
 'Pre-retirement investor. 10 yr horizon. Moving from equity-heavy to balanced. Large caps only.',
 'Safety over returns, 10 yrs to go 🏦','R','Large Cap'),

('deepakcapmarket@silentmarket.in','DeepakCapMarket',
 'Tracks market cap bands. Spreadsheet of large/mid/small allocation. Rebalances quarterly.',
 'Rebalance or regret 🔄','R','Small & Mid Cap'),

('ratikamftrack@silentmarket.in','RatikaMFTrack',
 'Tracks 50+ MF schemes monthly. Posts return comparisons. Helps friends choose funds. AMFI studying.',
 'MF gyaan for all 💰','R','Mutual Funds'),

('srinathgrowthseek@silentmarket.in','SrinathGrowthSeek',
 'GARP investor. Screens 20%+ earnings growth + <30 PE. 3 yr track record in direct investing.',
 'GARP is the sweet spot 📈','R','Small & Mid Cap'),

('lalithatechfund@silentmarket.in','LalithaTechFund',
 'IT sector focused. TCS, Infosys, HCL Tech, Wipro. Indian IT is a 10-yr compounding machine.',
 'IT = India Tomorrow 💻','R','Large Cap'),

('ashwinsensexbull@silentmarket.in','AshwinSensexBull',
 'Sensex 80k believer. Buys every dip. No stop losses. Holds 5+ yrs. Index investing mainly.',
 'Dip = buy signal always 📊','R','NSE/BSE Market'),

('meenalpharma@silentmarket.in','MeenalPharmaFocus',
 'Pharma sector investor. Tracks USFDA filings. Sun Pharma, Cipla, Dr Reddys. 3 yr track.',
 'Pharma is defensive gold 💊','R','Large Cap'),

('hemantcalledbet@silentmarket.in','HemantCalledBet',
 'Tracking portfolio publicly. Started ₹2L in Jan 2024. Sharing monthly P&L — good and bad both.',
 'Transparent investor journey 📊','R','NSE/BSE Market'),

-- NOVICE (25)
('newbierahulsip@silentmarket.in','NewbieRahulSIP',
 'Started SIP last month. ₹2000/month in Nifty 50 index fund. 22 yrs old. Learning everything.',
 'Day 1 of wealth journey 🌱','N','General Finance'),

('sipsahibji@silentmarket.in','SIPSahibJi',
 'College final year. SIP ₹1000/month. Opened Zerodha. Confused about MF vs direct stocks.',
 'Starting small, dreaming big 💫','N','Mutual Funds'),

('firsttimeinvestor@silentmarket.in','FirstTimeInvestor',
 'Opened demat 3 months ago. Bought IRFC on a friend''s tip. Not sure why yet. Learning mode.',
 'Every expert was once a beginner 🌱','N','General Finance'),

('aparnabeginner@silentmarket.in','AparnaBeginner',
 'Homemaker, 35 yrs. Husband handles money but I want to learn. Started reading about MFs.',
 'Learning slowly but surely 📚','N','Mutual Funds'),

('techielearninvest@silentmarket.in','TechieLearnsInvest',
 'Software developer. High salary, zero savings. Woke up finally. Starting first SIP this week.',
 'Code I know, money I don''t 💻','N','General Finance'),

('riyachartbeginner@silentmarket.in','RiyaChartBeginner',
 'Bought Zerodha, downloaded Kite, stared at candles for 2 hours. Confused but very excited.',
 'Candles are confusing but cool 📉','N','Technical Analysis'),

('manishniftyque@silentmarket.in','ManishNiftyQue',
 'Questions about Nifty every day. PE ratio kya hota hai? Why is my SIP going down? Help me.',
 'So many questions! 🤔','N','General Finance'),

('sonalimffirst@silentmarket.in','SonaliMFFirst',
 'First direct MF via MFCentral. HDFC Mid Cap Opportunities. Just clicked confirm. Very nervous.',
 'MF first click done! 🎉','N','Mutual Funds'),

('biharibeginner@silentmarket.in','BihariBeginner',
 'Agriculture background. First in family to invest in markets. Learning English financial terms.',
 'New world, new learning 🌱','N','General Finance'),

('lalitmistakes@silentmarket.in','LalitMadeMistakes',
 'Lost ₹8k in F&O first month. Switched to MF. Expensive lesson. Sharing so you don''t repeat.',
 'Mistakes are the best teachers 😓','N','General Finance'),

('noobitrader99@silentmarket.in','NoobyTrader99',
 'Bought 10 different stocks in first week. Portfolio is a jungle. Learning to focus and simplify.',
 'Less is more 🌿','N','NSE/BSE Market'),

('shalinilearns@silentmarket.in','ShaliniLearns',
 'School teacher. Building corpus for daughter''s education. Starting ₹3k SIP. Simple approach.',
 'Simple investing for big goals 🎓','N','Mutual Funds'),

('sachinmultibagger@silentmarket.in','SachinMultibagger',
 'Wants the next multibagger. Reads tips on X. Should read annual reports instead. Learning slowly.',
 'Next multibagger hunting 🔍','N','Small & Mid Cap'),

('faizanasksq@silentmarket.in','FaizanAsksQ',
 'Engineering student. Campus placement done. Starting salary. Researching where to invest first.',
 'Fresher investor incoming 🎓','N','General Finance'),

('swatipinkportfolio@silentmarket.in','SwatiPinkPortfolio',
 'Made pink Excel tracker for portfolio. 5 stocks, 2 MFs. Very proud of it. What is XIRR?',
 'Excel is my best friend 📊','N','General Finance'),

('krishnapessimist@silentmarket.in','KrishnaPessimist',
 'Market too high to invest. Waiting for big crash. Has been waiting since 2021. Cash sitting idle.',
 'Waiting for the perfect dip 😅','N','General Finance'),

('divyankafirstsip@silentmarket.in','DivyankaFirstSIP',
 'First SIP set up! ₹5000/month in Parag Parikh Flexi Cap. Very nervous about market crashing.',
 'First SIP anxiety is real! 😰','N','Mutual Funds'),

('preethitruebeliever@silentmarket.in','PreethiTrueBeliever',
 'Invested after watching Shark Tank India. Wants to find next Zepto. Mostly consumer brand IPOs.',
 'Shark Tank inspired me! 🦈','N','IPO Watch'),

('govindachoicestock@silentmarket.in','GovindaChoiceStock',
 'Buys stocks based on what products he uses. HUL, Pidilite, Asian Paints. Actually not bad.',
 'I invest in what I use 🛒','N','Large Cap'),

('tejasiplanner@silentmarket.in','TejaSIPPlanner',
 'Plans SIP in Excel, calculates future value, reads about it. Just started actually investing.',
 'Planner now becoming investor 📋','N','Mutual Funds'),

('santoshearninglearn@silentmarket.in','SantoshEarningLearn',
 'Daily wage worker saving ₹500/month for SIP. Inspiring. Believes in long-term compounding.',
 '₹500/month matters in 20 yrs 💪','N','Financial Advice'),

('bhumikafomo@silentmarket.in','BhumikaFOMO',
 'Bought stocks because friends were making money in 2024. FOMO investor. Learning risk management.',
 'FOMO brought me here 😬','N','General Finance'),

('kabirbullrun@silentmarket.in','KabirBullRun',
 'Thinks we are in permanent bull market. All-in equity. No emergency fund. Very high risk.',
 'Bull forever, no bears ever 🐂','N','NSE/BSE Market'),

('adityaretailnewb@silentmarket.in','AdityaRetailNewb',
 'Retail investor 2 months. Tracking blue chips. Moneycontrol app. Wants to understand P/E better.',
 'New to markets, here to learn 📱','N','NSE/BSE Market'),

('meeraquestioner@silentmarket.in','MeeraQuestioner',
 'Asks one finance question per day. Today: yield curve inversion. Tomorrow: PE expansion meaning.',
 'One question a day keeps ignorance away 🤔','N','General Finance'),

-- RANDOMS (15)
('wealthwatcher99@silentmarket.in','WealthWatcher99',
 'Shares forwarded WhatsApp market tips. Believes operator calls. Portfolio mostly red. Still hopeful.',
 'Tips chahiye tips do 📱','X','General Finance'),

('chaipecharcha@silentmarket.in','ChaiPeCharcha',
 'Finance talk over chai. Sometimes right, mostly wrong. Compares stock market to cricket. Passionate.',
 'Chai ke saath market ka mazaa ☕','X','General Finance'),

('loudmouthtrader@silentmarket.in','LoudmouthTrader',
 'Claims 500% returns, shows zero proof. Tips freely, zero accountability. FOMO content machine.',
 '500% return every year 🚀','X','General Finance'),

('fudspreadernow@silentmarket.in','FUDSpreader',
 'Market will crash 90% — says this every month. Wrong 36 months in a row. Permanent permabear.',
 'CRASH INCOMING!!!','X','General Finance'),

('tippingmaster@silentmarket.in','TippingMaster',
 'Operator tips, circuit stocks, SMS tips daily. Probably multiple accounts. Track record: zero.',
 'Hot tips! DM me 🔥','X','General Finance'),

('getrichquick99@silentmarket.in','GetRichQuick99',
 'Penny stocks, circuit limiters, 10x in 10 days dream. Financial literacy = zero. High risk.',
 '10x guaranteed (disclaimer: not really) 💸','X','SME Stocks'),

('confusedkaka@silentmarket.in','ConfusedKaka',
 '62 yr old uncle. Son made him open Zerodha. Does not understand SIP. Random stock buying.',
 'Bete ne banaya demat 👴','X','General Finance'),

('cryptoturnedstock@silentmarket.in','CryptoTurnedStock',
 'Lost everything in crypto. Now trying stocks. Still thinks 100x is possible here. Unlearning.',
 'Crypto refugee in stock markets 🪙','X','General Finance'),

('zerostonks@silentmarket.in','ZeroStonks',
 'Posts memes about stocks. No analysis. Makes finance entertaining. Actually useful sometimes.',
 'Stonks go brrr 📈📉','X','General Finance'),

('randomposterguy@silentmarket.in','RandomPosterGuy',
 'Copy-pastes news headlines. No analysis attached. Pure fill content. Somehow has followers.',
 'News copypaste expert 📰','X','NSE/BSE Market'),

('astrosensex@silentmarket.in','AstroSensex',
 'Combines astrology with stock tips. Planetary movements + Nifty cycles. Has a following somehow.',
 'Jupiter enters Capricorn = buy HDFC 🪐','X','General Finance'),

('papertraderpro@silentmarket.in','PaperTraderPro',
 'Paper trading for 3 years. Refuses to invest real money. Every call is perfect in theory only.',
 'Perfect in theory, forever 📝','X','Technical Analysis'),

('nervousnelly@silentmarket.in','NervousNellyInvest',
 'Sells every time portfolio hits -5%. Panic-sold 4 times. Never rides the recovery. Classic mistake.',
 'Red screen = sell everything 😱','X','General Finance'),

('inflationdenier@silentmarket.in','InflationDenier',
 '"Bank FD is safest" person. Keeps everything in savings account. Inflation? Sounds made up.',
 'FD is safe! Markets are gambling! 🏦','X','General Finance'),

('stockgossipgirl@silentmarket.in','StockGossipGirl',
 'Market gossip account. Insider rumors, management drama, boardroom stories. Entertainment only.',
 'Dalal Street ka gossip 💬','X','General Finance');

-- ── SHARED TIER TABLE (permanent so it survives across sessions) ──
DROP TABLE IF EXISTS public.seed_tiers;
CREATE TABLE public.seed_tiers (
  tier        char(1),
  user_id     uuid,
  primary_cat text,
  handle      text
);

-- ── CREATE 100 USERS ──────────────────────────────────────────
DO $$
DECLARE
  u    record;
  _id  uuid;
  _pwd text;
BEGIN
  _pwd := crypt('Market@2025', gen_salt('bf', 10));

  FOR u IN SELECT * FROM seed_users_def ORDER BY seq LOOP
    _id := gen_random_uuid();

    INSERT INTO auth.users (
      id, instance_id, aud, role, email,
      encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data,
      is_super_admin, created_at, updated_at,
      confirmation_token, recovery_token
    ) VALUES (
      _id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      u.email, _pwd, now(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object('handle', u.handle),
      false,
      now() - (random() * interval '730 days'),
      now(),
      '', ''
    );

    -- Trigger creates profile; now set bio / tagline / role
    UPDATE public.profiles
       SET bio     = u.bio,
           tagline = u.tagline,
           role    = 'user'
     WHERE id = _id;

    INSERT INTO seed_tiers (tier, user_id, primary_cat, handle)
    VALUES (u.tier, _id, u.primary_cat, u.handle);
  END LOOP;
END $$;

-- Quick sanity check
SELECT tier, count(*) FROM seed_tiers GROUP BY tier ORDER BY tier;
SELECT count(*) AS total_users FROM profiles;
