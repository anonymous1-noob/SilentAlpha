-- ============================================================
-- SilentAlpha — Fix: Rebuild seed_tiers as permanent table
-- Run this AFTER seed_p1_users.sql, BEFORE seed_p2_posts.sql
-- (Only needed because temp tables don't persist across sessions)
-- ============================================================

DROP TABLE IF EXISTS public.seed_tiers;

CREATE TABLE public.seed_tiers (
  tier        char(1)  NOT NULL,
  user_id     uuid     NOT NULL,
  primary_cat text     NOT NULL,
  handle      text     NOT NULL
);

INSERT INTO public.seed_tiers (tier, user_id, primary_cat, handle)
SELECT
  CASE p.handle
    -- WOLVES (W)
    WHEN 'RaghavNiftyPro'       THEN 'W'
    WHEN 'DeepakAlphaCapital'   THEN 'W'
    WHEN 'PriyaMarketQueen'     THEN 'W'
    WHEN 'ArjunQuantCapital'    THEN 'W'
    WHEN 'VikramInvestSmart'    THEN 'W'
    WHEN 'KavitaMarkets'        THEN 'W'
    WHEN 'NithinValueHunter'    THEN 'W'
    WHEN 'RishiAlphaGen'        THEN 'W'
    WHEN 'AnanyaFinPro'         THEN 'W'
    WHEN 'SureshBullCapital'    THEN 'W'
    -- QUANTS (Q)
    WHEN 'KiranOptionsDesk'     THEN 'Q'
    WHEN 'RahulVolSmith'        THEN 'Q'
    WHEN 'MeeraAlgoTrade'       THEN 'Q'
    WHEN 'SaurabhQuantFX'       THEN 'Q'
    WHEN 'PoojaDataDriven'      THEN 'Q'
    -- PROS (P)
    WHEN 'NikhilValueSeeker'    THEN 'P'
    WHEN 'SnehaMFBhakt'         THEN 'P'
    WHEN 'RajSmallCapHunter'    THEN 'P'
    WHEN 'AdityaNSEWatcher'     THEN 'P'
    WHEN 'PujaDividendQueen'    THEN 'P'
    WHEN 'SameerIPOTracker'     THEN 'P'
    WHEN 'TanyaTechAnalyst'     THEN 'P'
    WHEN 'RaviMacroLens'        THEN 'P'
    WHEN 'AnkitSectorRotate'    THEN 'P'
    WHEN 'DivyaBluechip'        THEN 'P'
    WHEN 'MohitMidCapMaster'    THEN 'P'
    WHEN 'SunitaSIPQueen'       THEN 'P'
    WHEN 'GauravSMESpecialist'  THEN 'P'
    WHEN 'RekhaValuePlus'       THEN 'P'
    WHEN 'VijayChartsMaster'    THEN 'P'
    -- REGULARS (R)
    WHEN 'AmitRetailInvestor'   THEN 'R'
    WHEN 'PreetiNiftyWatch'     THEN 'R'
    WHEN 'KarthikStockLover'    THEN 'R'
    WHEN 'NehaTaxSaver'         THEN 'R'
    WHEN 'SumanSpotTrader'      THEN 'R'
    WHEN 'AlokBankingBull'      THEN 'R'
    WHEN 'ShilpaIPOAlerts'      THEN 'R'
    WHEN 'RohitSectorWatch'     THEN 'R'
    WHEN 'MadhaviPsycho'        THEN 'R'
    WHEN 'VikashSmallCap'       THEN 'R'
    WHEN 'RenukaELSS'           THEN 'R'
    WHEN 'TarunMacroWatcher'    THEN 'R'
    WHEN 'ShobhaFundamentals'   THEN 'R'
    WHEN 'PrashantSensex'       THEN 'R'
    WHEN 'AnjaneyaFNO'          THEN 'R'
    WHEN 'NilaTaxFree'          THEN 'R'
    WHEN 'RameshDiviInvestor'   THEN 'R'
    WHEN 'SujataNifty50'        THEN 'R'
    WHEN 'TamonashBanking'      THEN 'R'
    WHEN 'VarshaStartInvest'    THEN 'R'
    WHEN 'PawanKiranaPicks'     THEN 'R'
    WHEN 'TanviChartRead'       THEN 'R'
    WHEN 'ManoharRetireFund'    THEN 'R'
    WHEN 'DeepakCapMarket'      THEN 'R'
    WHEN 'RatikaMFTrack'        THEN 'R'
    WHEN 'SrinathGrowthSeek'    THEN 'R'
    WHEN 'LalithaTechFund'      THEN 'R'
    WHEN 'AshwinSensexBull'     THEN 'R'
    WHEN 'MeenalPharmaFocus'    THEN 'R'
    WHEN 'HemantCalledBet'      THEN 'R'
    -- NOVICE (N)
    WHEN 'NewbieRahulSIP'       THEN 'N'
    WHEN 'SIPSahibJi'           THEN 'N'
    WHEN 'FirstTimeInvestor'    THEN 'N'
    WHEN 'AparnaBeginner'       THEN 'N'
    WHEN 'TechieLearnsInvest'   THEN 'N'
    WHEN 'RiyaChartBeginner'    THEN 'N'
    WHEN 'ManishNiftyQue'       THEN 'N'
    WHEN 'SonaliMFFirst'        THEN 'N'
    WHEN 'BihariBeginner'       THEN 'N'
    WHEN 'LalitMadeMistakes'    THEN 'N'
    WHEN 'NoobyTrader99'        THEN 'N'
    WHEN 'ShaliniLearns'        THEN 'N'
    WHEN 'SachinMultibagger'    THEN 'N'
    WHEN 'FaizanAsksQ'          THEN 'N'
    WHEN 'SwatiPinkPortfolio'   THEN 'N'
    WHEN 'KrishnaPessimist'     THEN 'N'
    WHEN 'DivyankaFirstSIP'     THEN 'N'
    WHEN 'PreethiTrueBeliever'  THEN 'N'
    WHEN 'GovindaChoiceStock'   THEN 'N'
    WHEN 'TejaSIPPlanner'       THEN 'N'
    WHEN 'SantoshEarningLearn'  THEN 'N'
    WHEN 'BhumikaFOMO'          THEN 'N'
    WHEN 'KabirBullRun'         THEN 'N'
    WHEN 'AdityaRetailNewb'     THEN 'N'
    WHEN 'MeeraQuestioner'      THEN 'N'
    -- RANDOMS (X)
    WHEN 'WealthWatcher99'      THEN 'X'
    WHEN 'ChaiPeCharcha'        THEN 'X'
    WHEN 'LoudmouthTrader'      THEN 'X'
    WHEN 'FUDSpreader'          THEN 'X'
    WHEN 'TippingMaster'        THEN 'X'
    WHEN 'GetRichQuick99'       THEN 'X'
    WHEN 'ConfusedKaka'         THEN 'X'
    WHEN 'CryptoTurnedStock'    THEN 'X'
    WHEN 'ZeroStonks'           THEN 'X'
    WHEN 'RandomPosterGuy'      THEN 'X'
    WHEN 'AstroSensex'          THEN 'X'
    WHEN 'PaperTraderPro'       THEN 'X'
    WHEN 'NervousNellyInvest'   THEN 'X'
    WHEN 'InflationDenier'      THEN 'X'
    WHEN 'StockGossipGirl'      THEN 'X'
    ELSE 'X'
  END                            AS tier,

  p.id                           AS user_id,

  CASE p.handle
    WHEN 'RaghavNiftyPro'       THEN 'NSE/BSE Market'
    WHEN 'DeepakAlphaCapital'   THEN 'Large Cap'
    WHEN 'PriyaMarketQueen'     THEN 'NSE/BSE Market'
    WHEN 'ArjunQuantCapital'    THEN 'Technical Analysis'
    WHEN 'VikramInvestSmart'    THEN 'Financial Advice'
    WHEN 'KavitaMarkets'        THEN 'Mutual Funds'
    WHEN 'NithinValueHunter'    THEN 'Small & Mid Cap'
    WHEN 'RishiAlphaGen'        THEN 'SME Stocks'
    WHEN 'AnanyaFinPro'         THEN 'Macro Economy'
    WHEN 'SureshBullCapital'    THEN 'Technical Analysis'
    WHEN 'KiranOptionsDesk'     THEN 'Technical Analysis'
    WHEN 'RahulVolSmith'        THEN 'Technical Analysis'
    WHEN 'MeeraAlgoTrade'       THEN 'NSE/BSE Market'
    WHEN 'SaurabhQuantFX'       THEN 'Macro Economy'
    WHEN 'PoojaDataDriven'      THEN 'Small & Mid Cap'
    WHEN 'NikhilValueSeeker'    THEN 'Small & Mid Cap'
    WHEN 'SnehaMFBhakt'         THEN 'Mutual Funds'
    WHEN 'RajSmallCapHunter'    THEN 'Small & Mid Cap'
    WHEN 'AdityaNSEWatcher'     THEN 'NSE/BSE Market'
    WHEN 'PujaDividendQueen'    THEN 'Large Cap'
    WHEN 'SameerIPOTracker'     THEN 'IPO Watch'
    WHEN 'TanyaTechAnalyst'     THEN 'Technical Analysis'
    WHEN 'RaviMacroLens'        THEN 'Macro Economy'
    WHEN 'AnkitSectorRotate'    THEN 'NSE/BSE Market'
    WHEN 'DivyaBluechip'        THEN 'Large Cap'
    WHEN 'MohitMidCapMaster'    THEN 'Small & Mid Cap'
    WHEN 'SunitaSIPQueen'       THEN 'Mutual Funds'
    WHEN 'GauravSMESpecialist'  THEN 'SME Stocks'
    WHEN 'RekhaValuePlus'       THEN 'Large Cap'
    WHEN 'VijayChartsMaster'    THEN 'Technical Analysis'
    WHEN 'AmitRetailInvestor'   THEN 'NSE/BSE Market'
    WHEN 'PreetiNiftyWatch'     THEN 'Mutual Funds'
    WHEN 'KarthikStockLover'    THEN 'NSE/BSE Market'
    WHEN 'NehaTaxSaver'         THEN 'Financial Advice'
    WHEN 'SumanSpotTrader'      THEN 'Technical Analysis'
    WHEN 'AlokBankingBull'      THEN 'Large Cap'
    WHEN 'ShilpaIPOAlerts'      THEN 'IPO Watch'
    WHEN 'RohitSectorWatch'     THEN 'NSE/BSE Market'
    WHEN 'MadhaviPsycho'        THEN 'Financial Advice'
    WHEN 'VikashSmallCap'       THEN 'Small & Mid Cap'
    WHEN 'RenukaELSS'           THEN 'Financial Advice'
    WHEN 'TarunMacroWatcher'    THEN 'Macro Economy'
    WHEN 'ShobhaFundamentals'   THEN 'Large Cap'
    WHEN 'PrashantSensex'       THEN 'NSE/BSE Market'
    WHEN 'AnjaneyaFNO'          THEN 'Technical Analysis'
    WHEN 'NilaTaxFree'          THEN 'Financial Advice'
    WHEN 'RameshDiviInvestor'   THEN 'Large Cap'
    WHEN 'SujataNifty50'        THEN 'Mutual Funds'
    WHEN 'TamonashBanking'      THEN 'Large Cap'
    WHEN 'VarshaStartInvest'    THEN 'Mutual Funds'
    WHEN 'PawanKiranaPicks'     THEN 'Large Cap'
    WHEN 'TanviChartRead'       THEN 'Technical Analysis'
    WHEN 'ManoharRetireFund'    THEN 'Large Cap'
    WHEN 'DeepakCapMarket'      THEN 'Small & Mid Cap'
    WHEN 'RatikaMFTrack'        THEN 'Mutual Funds'
    WHEN 'SrinathGrowthSeek'    THEN 'Small & Mid Cap'
    WHEN 'LalithaTechFund'      THEN 'Large Cap'
    WHEN 'AshwinSensexBull'     THEN 'NSE/BSE Market'
    WHEN 'MeenalPharmaFocus'    THEN 'Large Cap'
    WHEN 'HemantCalledBet'      THEN 'NSE/BSE Market'
    WHEN 'NewbieRahulSIP'       THEN 'General Finance'
    WHEN 'SIPSahibJi'           THEN 'Mutual Funds'
    WHEN 'FirstTimeInvestor'    THEN 'General Finance'
    WHEN 'AparnaBeginner'       THEN 'Mutual Funds'
    WHEN 'TechieLearnsInvest'   THEN 'General Finance'
    WHEN 'RiyaChartBeginner'    THEN 'Technical Analysis'
    WHEN 'ManishNiftyQue'       THEN 'General Finance'
    WHEN 'SonaliMFFirst'        THEN 'Mutual Funds'
    WHEN 'BihariBeginner'       THEN 'General Finance'
    WHEN 'LalitMadeMistakes'    THEN 'General Finance'
    WHEN 'NoobyTrader99'        THEN 'NSE/BSE Market'
    WHEN 'ShaliniLearns'        THEN 'Mutual Funds'
    WHEN 'SachinMultibagger'    THEN 'Small & Mid Cap'
    WHEN 'FaizanAsksQ'          THEN 'General Finance'
    WHEN 'SwatiPinkPortfolio'   THEN 'General Finance'
    WHEN 'KrishnaPessimist'     THEN 'General Finance'
    WHEN 'DivyankaFirstSIP'     THEN 'Mutual Funds'
    WHEN 'PreethiTrueBeliever'  THEN 'IPO Watch'
    WHEN 'GovindaChoiceStock'   THEN 'Large Cap'
    WHEN 'TejaSIPPlanner'       THEN 'Mutual Funds'
    WHEN 'SantoshEarningLearn'  THEN 'Financial Advice'
    WHEN 'BhumikaFOMO'          THEN 'General Finance'
    WHEN 'KabirBullRun'         THEN 'NSE/BSE Market'
    WHEN 'AdityaRetailNewb'     THEN 'NSE/BSE Market'
    WHEN 'MeeraQuestioner'      THEN 'General Finance'
    WHEN 'GetRichQuick99'       THEN 'SME Stocks'
    WHEN 'RandomPosterGuy'      THEN 'NSE/BSE Market'
    WHEN 'PaperTraderPro'       THEN 'Technical Analysis'
    ELSE 'General Finance'
  END                            AS primary_cat,

  p.handle
FROM public.profiles p
WHERE p.handle IN (
  'RaghavNiftyPro','DeepakAlphaCapital','PriyaMarketQueen','ArjunQuantCapital',
  'VikramInvestSmart','KavitaMarkets','NithinValueHunter','RishiAlphaGen',
  'AnanyaFinPro','SureshBullCapital','KiranOptionsDesk','RahulVolSmith',
  'MeeraAlgoTrade','SaurabhQuantFX','PoojaDataDriven','NikhilValueSeeker',
  'SnehaMFBhakt','RajSmallCapHunter','AdityaNSEWatcher','PujaDividendQueen',
  'SameerIPOTracker','TanyaTechAnalyst','RaviMacroLens','AnkitSectorRotate',
  'DivyaBluechip','MohitMidCapMaster','SunitaSIPQueen','GauravSMESpecialist',
  'RekhaValuePlus','VijayChartsMaster','AmitRetailInvestor','PreetiNiftyWatch',
  'KarthikStockLover','NehaTaxSaver','SumanSpotTrader','AlokBankingBull',
  'ShilpaIPOAlerts','RohitSectorWatch','MadhaviPsycho','VikashSmallCap',
  'RenukaELSS','TarunMacroWatcher','ShobhaFundamentals','PrashantSensex',
  'AnjaneyaFNO','NilaTaxFree','RameshDiviInvestor','SujataNifty50',
  'TamonashBanking','VarshaStartInvest','PawanKiranaPicks','TanviChartRead',
  'ManoharRetireFund','DeepakCapMarket','RatikaMFTrack','SrinathGrowthSeek',
  'LalithaTechFund','AshwinSensexBull','MeenalPharmaFocus','HemantCalledBet',
  'NewbieRahulSIP','SIPSahibJi','FirstTimeInvestor','AparnaBeginner',
  'TechieLearnsInvest','RiyaChartBeginner','ManishNiftyQue','SonaliMFFirst',
  'BihariBeginner','LalitMadeMistakes','NoobyTrader99','ShaliniLearns',
  'SachinMultibagger','FaizanAsksQ','SwatiPinkPortfolio','KrishnaPessimist',
  'DivyankaFirstSIP','PreethiTrueBeliever','GovindaChoiceStock','TejaSIPPlanner',
  'SantoshEarningLearn','BhumikaFOMO','KabirBullRun','AdityaRetailNewb',
  'MeeraQuestioner','WealthWatcher99','ChaiPeCharcha','LoudmouthTrader',
  'FUDSpreader','TippingMaster','GetRichQuick99','ConfusedKaka',
  'CryptoTurnedStock','ZeroStonks','RandomPosterGuy','AstroSensex',
  'PaperTraderPro','NervousNellyInvest','InflationDenier','StockGossipGirl'
);

-- Sanity check
SELECT tier, count(*) AS users FROM public.seed_tiers GROUP BY tier ORDER BY tier;
