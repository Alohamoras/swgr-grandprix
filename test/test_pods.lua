-- v0.40.0 (TASKS §1h P2-P3; docs/podracing-recon-2026-11-25.md): the PODRACER CUP. A tile after the Rally Cup; the
-- draw (4 of the 5 pod layouts, a condition each); not a planet cup; the launch through LaunchCustomRace on the bare
-- pod track with GMV_Race's grid at 8 and the pod racers as the opponents, you in your pilot's pod (Shade's when yours
-- has none), the track's cinematics off - all in the save first and all put back at the menu.
local M = require('mock')
local W = require('world')
local T = require('util')

T.boot({ version = 3, races = 0, cups = 0, class = 'riffraff', restores = {}, abilityRestores = {} }, { Progression = { On = false } })
W.cupEvents()
local K, cfg, PR = require('gp'), require('config'), require('prog')
local H = rawget(_G, 'GU_TEST_SCREENS')
local RACERS = '/Game/Griffin/Narrative/CharacterDefs/Racers/'

-- the game's pod things in the mock world: the pod tracks (Vehicle.Special.Plane, six cinematic chains), the pod
-- racers, the game mode GMV_Race (grid 5), the pod build, LaunchCustomRace on the front end
local CHAINS = { 'IntroCinematic', 'PreRaceCinematicChain', 'SideBettingCinematicChain', 'IgnitionCinematicChain',
  'EventCompleteCinematicChain', 'EventFailedCinematicChain' }
local tracks, seenT = {}, {}
for _, r in ipairs(cfg.Pools.pods) do
  local n = r.path:match('([^/]+)$')
  local full = r.path .. '.' .. n
  if not seenT[full] then
    seenT[full] = true
    local props = { VehicleTypeTag = { TagName = { ToString = function() return 'Vehicle.Special.Plane' end } } }
    for _, f in ipairs(CHAINS) do
      local cp = '/Game/Griffin/Cinematics/CINC_' .. f .. '_' .. n
      M.assets[cp .. '.CINC_' .. f .. '_' .. n] = M.new(cp .. '.CINC_' .. f .. '_' .. n, {}, 'CinematicChain')
      props[f] = M.assets[cp .. '.CINC_' .. f .. '_' .. n]
    end
    M.assets[full] = M.new(full, props, 'TrackDef')
    tracks[#tracks + 1] = full
  end
end
for _, n in ipairs({ 'Nesodon', 'Cabbage', 'Celery', 'Garlic', 'Onion', 'Pepper' }) do
  local full = RACERS .. 'DA_PlaneRacer_' .. n .. '.DA_PlaneRacer_' .. n
  M.assets[full] = M.new(full, { PreferredVehicleType = 1 }, 'RacerDef')
end
local GMV = '/Game/Griffin/Gameplay/Campaign/GameModes/GMV_Race'
M.assets[GMV .. '.GMV_Race'] = M.new(GMV .. '.GMV_Race', { GridMakeup = { Entries = M.tarr({ { EntryType = 4, NumEntrants = 5 } }) } }, 'GameModeVariantDef')
W.build(cfg.Pods.Build)
local custom = {}
rawget(W.fe, '__props').LaunchCustomRace = function(self, arch, mode, track, cond, build, dbg)
  custom[#custom + 1] = { arch = arch, mode = mode, track = track, cond = cond and cond.TagName, build = build }
end
local function gmvGrid() return rawget(M.assets[GMV .. '.GMV_Race'], '__props').GridMakeup.Entries[1].NumEntrants end
local function pref(k) return rawget(W.racerDef(k), '__props').PreferredVehicleType end

-- 1. v0.41 (TASKS §1h-L PL1-PL2): PODRACING is a league of its own - a poster on HOME after the car leagues, no
-- PODRACER CUP tile on the car leagues' cups pages; Pods.On = false hides the poster
M.press('F6'); M.tick(6)
T.check(T.titles():find('ACE|PODRACING', 1, true) ~= nil, 'HOME: the PODRACING poster after ACE (' .. T.titles() .. ')')
local function homeItem()
  for _, it in ipairs(H.SCREENS.home().items) do if it.title == 'PODRACING' then return it end end
end
T.check(homeItem() and #homeItem().pips == 2 and homeItem().info:find('LEARNER or PRO', 1, true), 'the poster: a medal per step, its rules line')
cfg.Pods.On = false
T.check(homeItem() == nil, 'Pods.On = false: no poster')
cfg.Pods.On = true
T.clickTitle('JUNKER'); M.tick(3)
T.check(not T.titles():find('PODRACER', 1, true), 'the car cups page: no PODRACER CUP tile (' .. T.titles() .. ')')
-- v0.42 (TASKS §1h-L PL2b): the poster opens the PODRACING page - LEARNER and PRO as league posters
H.S.screen = 'home'
cfg.StartScreen = true -- (the start screen: off in the older tests)
homeItem().act()
local pg = H.SCREENS[H.S.screen]()
local pt = {}
for i, it in ipairs(pg.items) do pt[i] = it.title end
T.check(H.S.screen == 'pods' and table.concat(pt, '|') == 'LEARNER|PRO' and pg.title == 'PODRACING', 'the poster -> the PODRACING page: LEARNER | PRO (' .. table.concat(pt, '|') .. ')')
T.check(pg.items[2].info:find('PRO.', 1, true) == 1 and pg.items[1].desc == 'The pace to learn the tracks', 'each step: its tagline and rules line')
-- PRO opens the cup's start screen at PRO
pg.items[2].act()
T.check(H.S.screen == 'garage' and H.S.start.cup == 'pods' and H.S.start.class == 'podspro' and #H.S.start.draw == 4 and K.data.podStep == 'podspro',
  'PRO -> the PODRACER CUP start screen at PRO, 4 races drawn, the step saved')
local gi = H.SCREENS.garage()
local vt, pil, kinds = nil, nil, {}
for _, it in ipairs(gi.items) do
  kinds[#kinds + 1] = tostring(it.kind or it.title)
  if it.kind == 'vehicle' then vt = it end
  if it.kind == 'racer' then pil = it end
end
T.check(table.concat(kinds, ',') == 'racer,vehicle,ability,ability,ability,ability,START', 'v0.43: the PRO start screen: PILOT, PODRACER, your four abilities, START - no tune-ups (' .. table.concat(kinds, ',') .. ')')
-- LEARNER: no abilities
H.S.start.class = 'pods'
local lk = {}
for _, it in ipairs(H.SCREENS.garage().items) do lk[#lk + 1] = tostring(it.kind or it.title) end
T.check(table.concat(lk, ',') == 'racer,vehicle,START', 'the LEARNER start screen: PILOT, PODRACER, START (' .. table.concat(lk, ',') .. ')')
H.S.start.class = 'podspro'
local AB0 = require('abil')
T.check(AB0.levelFor('podspro') == 3 and AB0.levelFor('pods') == 1, 'the ability level: PRO 3 (as ACE)')
T.check(gi.lines[1][1] == 'PODRACING PRO', 'the header: PODRACING PRO')
-- the PILOT tile: Shade (the car pilot here is Shade) flies the MythP3; no signature-kit words; Kestar's pod locked
T.check(pil.title == 'SHADE' and pil.info:find('Shade flies the MythP3.', 1, true) == 1 and not pil.info:find('signature', 1, true)
  and pil.info:find('Kestar Bool\'s Northropi opens once you beat him in a Galactic Cup final.', 1, true),
  'the PILOT tile: Shade flies the MythP3, Kestar\'s pod locked (' .. pil.info .. ')')
T.check(vt.title == 'MYTHP3' and vt.info:find('Shade\'s podracer', 1, true) == 1, 'the PODRACER tile: MYTHP3 (' .. vt.title .. ')')
local carRacer = K.data.racer
local seen = {}
for _ = 1, 5 do
  pil.act()
  for _, it in ipairs(H.SCREENS.garage().items) do if it.kind == 'racer' then pil = it end end
  seen[#seen + 1] = pil.title
end
T.check(table.concat(seen, ',') == 'GOLI & 02-R0,FOLA KANJEN,SEBULBA,SHADE,GOLI & 02-R0', 'Select cycles the pod pilots, Kestar skipped while locked (' .. table.concat(seen, ',') .. ')')
T.check(K.data.podRacer == 'Ghost' and K.data.racer == carRacer, 'the pod pilot saved apart (podRacer), your car pilot untouched')
local P0 = require('pods')
T.check(P0.chosen() == 'Ghost' and P0.racerKey('Rager') == 'DarkEnigma', 'the pod pilot raced: Goli; a pilot with no pod -> Shade')
-- B on the pods start screen (the garage's back is the cups page) lands on the PODRACING page; its B is HOME
H.S.screen = 'cups'
local sc = H.SCREENS.cups()
T.check(sc.key == 'pods' and H.S.screen == 'pods', 'the cups page of a pod step is the PODRACING page')
T.check(K.leagueName('podspro') == 'PODRACING PRO' and K.league('pods').pods == true, 'the step names: PODRACING PRO')
T.check(PR.nextUnlock(K.data, 'pods') == nil, 'a pod step opens nothing (no "Galactic Cup" goal)')
K.data.podRacer = nil
H.S.start = nil
H.S.screen = 'home'
cfg.StartScreen = false

-- 2. the draw: 4 races, 4 different layouts, each a pod race with a condition tag
local d = K.draw('pods', T.RND)
local bases, ok = {}, #d == 4
for _, r in ipairs(d) do
  if bases[r.path] or not r.pod or not r.condTag or not r.path:find('/Plane_Memory/TRAK_', 1, true) then ok = false end
  bases[r.path] = true
end
T.check(ok, 'the draw: 4 pod races on 4 different layouts, each with a condition tag')

-- 3. not a planet cup: the planet-cup count (the Galactic Cup's unlock) stays 5
local n, of = 0, 0
for _, c in ipairs(cfg.Cups) do if not c.final and not c.rally and not c.pods then of = of + 1 end end
T.check(of == 5 and select(2, K.golds('riffraff')) >= 5, 'five planet cups, the pods not among them')
T.check(K.planetOf(cfg.Pools.pods[1].path).name == 'Outer Rim' and K.planetOf(cfg.Pools.pods[3].path).name == 'Ando Prime',
  'the pod tracks\' planets: Mos Espa = Outer Rim, Mawhonic = Ando Prime')

-- 4. the launch: start the cup, race 1 through LaunchCustomRace
K.startCup('podspro', 'pods', 'car', nil, nil, d)
T.check(K.data.run.pods == true, 'the run is marked as the pods cup')
local ev = K.nextRace()
T.check(ev.pod and ev.condTag == d[1].condTag, 'the next race is a pod race with its condition')
local R = require('race')
local okL, msg = R.launch(ev, 'podspro', 'car', { 'bolt.concuss', 'shield.impact', 'surge.impact', 'mine.double' }, nil)
T.check(R.run and R.run.pe and #R.run.pe.paths == 4 and R.run.pe.paths[1]:find('Disruptor_ConcussV2', 1, true),
  'v0.43 PRO: your four picks queued for your pod at level 3 (' .. tostring(R.run and R.run.pe and R.run.pe.paths[1]) .. ')')
T.check(R.run.lo ~= nil and R.run.au ~= nil and T.logHas('[loadout] league podspro: AI racers get their four abilities at load'),
  'v0.43 PRO: the pod racers get kits (loadout) and fire them (aiuse)')
local LO0 = require('loadout')
local kit = table.concat(LO0.kitFor('Dud Bolt', 'podspro'), ',')
T.check(kit:find('Shockwave_Punch_Mk2', 1, true) and kit:find('Mine_Triple_AI', 1, true), 'Dud Bolt\'s kit at PRO (' .. kit .. ')')
T.check(okL, 'launched (' .. tostring(msg) .. ')')
local c = custom[1]
T.check(c and rawget(c.arch, '__name') == 'VA_Plane' and rawget(c.mode, '__name'):find('GMV_Race', 1, true)
  and rawget(c.track, '__name'):find(d[1].path:match('([^/]+)$'), 1, true) and tostring(c.cond) == d[1].condTag
  and rawget(c.build, '__name'):find('VBD_MP_PlaneTour', 1, true), 'LaunchCustomRace(plane, GMV_Race, the track, its condition, the pod build)')
local quick = 0
for _, call in ipairs(M.calls) do if call.name == 'LaunchQuickRace' then quick = quick + 1 end end
T.check(quick == 0, 'no LaunchQuickRace for a pod race')
T.check(gmvGrid() == 8, 'GMV_Race grid make-up 5 -> 8 (' .. tostring(gmvGrid()) .. ')')
local opp = W.charsText()
T.check(opp:find('Opp=PlaneRacer_Nesodon', 1, true) == nil and opp:find('Player=DarkEnigma', 1, true) ~= nil, 'you race as Shade (' .. opp .. ')')
local list = rawget(W.chars, '__props').Opponents
local got = {}
for i = 1, list:GetArrayNum() do got[i] = rawget(list[i], '__name'):match('(DA_%w+_%w+)%.') end
T.check(#got == 7 and got[1] == 'DA_PlaneRacer_Nesodon' and got[7] == 'DA_Racer_Antagonist', 'the opponents: the 6 pod racers and Kestar (' .. table.concat(got, ',') .. ')')
T.check(pref('DarkEnigma') == 1 and pref('Antagonist') == 1, 'Shade and Kestar race pods (PreferredVehicleType 1)')
local tr = M.assets[tracks[1]] and nil
local trk = c.track
local cleared = 0
for _, f in ipairs(CHAINS) do local v = rawget(trk, '__props')[f]; if not v or rawget(v, '__name') == nil or rawget(v, '__dead') then cleared = cleared + 1 end end
T.check(cleared == #CHAINS, 'the track\'s cinematic chains off (' .. cleared .. ')')
T.check(type(K.data.podRestore) == 'table' and #K.data.podRestore.chains == #CHAINS and #K.data.podRestore.pref == 2,
  'the save holds what to put back (6 chains, 2 pilots)')
T.check(T.logHas('[pods] ready: 6 cinematic chains off the track, pods for DarkEnigma, Antagonist, a grid of 8'), 'the [pods] line')

-- 5. the race and back to the menu: everything put back
W.race(7); M.tick(5)
W.finish(1, 150, 48); M.tick(25)
W.backToMenu(); M.tick(30)
T.check(gmvGrid() == 5, 'GMV_Race grid back to 5 (' .. tostring(gmvGrid()) .. ')')
T.check(pref('DarkEnigma') == 0 and pref('Antagonist') == 0, 'Shade and Kestar back in their cars')
local back = 0
for _, f in ipairs(CHAINS) do local v = rawget(trk, '__props')[f]; if v and rawget(v, '__name') and not rawget(v, '__dead') then back = back + 1 end end
T.check(back == #CHAINS, 'the track\'s chains back (' .. back .. ')')
T.check(K.data.podRestore == nil and W.charsText():find('Opp=Mercenary', 1, true) ~= nil, 'the save record gone, the opponents back (' .. W.charsText() .. ')')
T.check(T.logHas('[pods] put back'), 'the put-back line')

-- 6. a pilot with no pod (Biddy Blas) races as Shade
local RC = require('racer')
K.data.racer = 'Rager'
local P = require('pods')
T.check(P.racerKey('Rager') == 'DarkEnigma' and P.racerKey('Mentor') == 'Mentor', 'no pod of your own: Shade\'s; Sebulba keeps his')
local fp = P.fieldPaths('Antagonist')
T.check(#fp == 6 and not table.concat(fp, ','):find('Antagonist', 1, true), 'racing as Kestar: he is not also in the field')
-- v0.42: racing as Sebulba drops his pod-racer twin from the field (he was on the grid twice)
local fs = table.concat(P.fieldPaths('Mentor'), ',')
T.check(#P.fieldPaths('Mentor') == 6 and not fs:find('Nesodon', 1, true) and fs:find('Antagonist', 1, true), 'racing as Sebulba: his twin not in the field (' .. #P.fieldPaths('Mentor') .. ')')
-- Kestar beaten: his pod opens
K.data.boss = { beaten = true }
T.check(P.racerKey('Antagonist') == 'Antagonist' and P.cycle(1) ~= nil, 'Kestar beaten: he flies his Northropi')
K.data.boss = nil
T.check(P.racerKey('Antagonist') == 'DarkEnigma', 'Kestar not beaten: Shade')

-- v0.43.1 (P5): the cup result loads a planet's def by its codename when none is in memory (the owner's PODRACER cup:
-- "no PlanetDef for Outer Rim", Mos Espa drawn blank)
local PLA = '/Game/Griffin/Gameplay/Config/Planets/PLA_Beagle'
M.assets[PLA .. '.PLA_Beagle'] = M.new(PLA .. '.PLA_Beagle', { PlayerFacingName = FText('Outer Rim') }, 'PlanetDef')
local CE = require('cupend')
local bd = CE.defByCode(K.planetOf(cfg.Pools.pods[1].path))
T.check(bd and rawget(bd, '__name'):find('PLA_Beagle', 1, true) and T.logHas('PlanetDef PLA_Beagle loaded (the game calls it "Outer Rim")'),
  'the cup result: Mos Espa\'s planet def loaded by its codename (PLA_Beagle)')

-- 7. v0.41: the v0.40 results at the car leagues move to LEARNER (best finish, fastest time / lap per track), once
local P1, P2 = cfg.Pools.pods[1].path, cfg.Pools.pods[3].path
local old = { best = { riffraff = { pods = 3, jakku = 1 }, ace = { pods = 1 } }, perfect = { ace = { pods = true } },
  standings = { ace = { pods = { YOU = 60 } } },
  records = { riffraff = { [P1] = { time = 200, lap = 49 }, ['/x/EVT_A'] = { time = 1 } }, ace = { [P1] = { time = 190, lap = 50 }, [P2] = { time = 170 } } } }
K.movePods(old)
T.check(old.best.pods.pods == 1 and old.best.riffraff.pods == nil and old.best.ace.pods == nil and old.best.riffraff.jakku == 1,
  'moved: the best finish (gold), the car cups untouched')
T.check(old.perfect.pods.pods == true and old.standings.pods.pods.YOU == 60, 'moved: the perfect cup, the standings')
local r1 = old.records.pods[P1]
T.check(r1.time == 190 and r1.lap == 49 and old.records.pods[P2].time == 170 and old.records.riffraff['/x/EVT_A'] and old.records.ace[P1] == nil,
  'moved: the fastest time and lap per pod track; the car tracks stay')
old.best.ace.pods = 2
K.movePods(old)
T.check(old.best.ace.pods == 2 and old.podsMoved, 'only once (podsMoved)')
T.finish()
