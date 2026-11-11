-- Galactic Grand Prix: study mode (v0.16, test-only; TASKS.md B10, DESIGN.md §14). Batches of single races for AI
-- tuning, driven by the test-only TestAutopilot. Off unless a file study.lua sits in the mod folder (next to save.lua):
--   return {
--     { class = '150', cup = 'ando', race = 1, label = '150 p0.5 catch0.8',
--       ai = { pressure = 0.5, pacing = { MaxAiSlowdownScale = 1.0, MaxAiCatchupScale = 0.8 }, errors = 0.5 } },
--     ...
--   }
-- ai = a whole AI profile (config AI.Profiles[class] keys: pressure, ops, pacing, catchup, errors, perfectStart,
-- aggression, config) that REPLACES the class's for that race only (ai.lua; put back with the race like any profile).
-- At the main menu with no cup and nothing to put back, each job's race launches through race.lua R.launch (the
-- class's parts, your racer, abilities and tune-ups) - no cup run, no points. Progress: study_state.lua (the next job),
-- so a restart resumes. Results: one [study] log line per job and a row in study_results.csv.
-- Cost at the menu: an io.open every 5 s; no game lookups here (main.lua passes what it knows).
local C = require('core')
local K = require('gp')
local log = C.log

local ST = {}
ST.CHECK_MS = 5000   -- how often study.lua is looked for at the menu
ST.SETTLE_MS = 5000  -- the menu settled (back, put back done) this long before the next job
ST.CLOSE_MS = 1000   -- after closing our page for a job
ST.MAX_TRIES = 2     -- a job interrupted this often (the game closed or crashed in its race) is skipped
ST.POSITIONS = { 1, 2, 3, 6, 12 }

local s = { clock = 0, checkedAt = -1e9, jobs = nil, running = nil, readyAt = nil, holdUntil = -1e9, lastErr = nil, state = nil }
ST.s = s -- (tests)

local function file(name) return C.DIR .. '/' .. name end

-- study.lua -> the job list, or nil (absent / unreadable; an error is logged once per new message)
local function readJobs()
  local f = io.open(file('study.lua'), 'r')
  if not f then s.lastErr = nil; return nil end
  local src = f:read('a'); f:close()
  local chunk, err = load(src, '=study.lua', 't', {})
  local ok, t = false, err
  if chunk then ok, t = pcall(chunk) end
  if not (ok and type(t) == 'table') then
    local msg = tostring(ok and 'it does not return a list' or t)
    if msg ~= s.lastErr then s.lastErr = msg; log('[study] study.lua unreadable: ' .. msg) end
    return nil
  end
  s.lastErr = nil
  return t
end

local function readState()
  local f = io.open(file('study_state.lua'), 'r')
  if not f then return { next = 1 } end
  local src = f:read('a'); f:close()
  local chunk = load(src, '=study_state.lua', 't', {})
  local ok, t = false, nil
  if chunk then ok, t = pcall(chunk) end
  if ok and type(t) == 'table' then t.next = math.max(1, math.floor(tonumber(t.next) or 1)); return t end
  return { next = 1 }
end
local function writeState()
  local f = io.open(file('study_state.lua'), 'w')
  if not f then log('[study] could not write study_state.lua'); return end
  f:write('-- Galactic Grand Prix study mode: the next job of study.lua (delete this file to start the study over)\nreturn ',
    C.serialize(s.state), '\n')
  f:close()
end

---------------------------------------------------------------------------------------------------------------------
-- text

local function num(v) return ('%g'):format(v) end
-- the AI profile as compact text: 'catchup=1 errors=0.5 ops.AiMaxTimeAheadModifier=0.5/1 pacing.MaxAiSlowdownScale=1'
function ST.settingsText(t)
  local out = {}
  local function walk(v, prefix)
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
      local x = v[k]
      local name = prefix .. tostring(k)
      if type(x) == 'table' then
        if x[1] ~= nil then
          local p = {}
          for _, e in ipairs(x) do p[#p + 1] = type(e) == 'number' and num(e) or tostring(e) end
          out[#out + 1] = name .. '=' .. table.concat(p, '/')
        else walk(x, name .. '.') end
      else
        out[#out + 1] = name .. '=' .. (type(x) == 'number' and num(x) or tostring(x))
      end
    end
  end
  if type(t) == 'table' then walk(t, '') end
  return #out > 0 and table.concat(out, ' ') or '(class default)'
end

-- a race's numbers from the field (race.lua: name, you, pos, finished, time): the racers with a time in time order,
-- your place among them, the gap of each place in ST.POSITIONS to you (signed: negative = ahead of you), the AI's
-- spread (slowest AI - fastest AI)
function ST.numbers(field, pos)
  local timed = {}
  for _, f in ipairs(field or {}) do
    local t = tonumber(f.time)
    if f.finished and t and t > 0 then timed[#timed + 1] = { name = f.you and 'YOU' or f.name, you = f.you, t = t, pos = f.pos } end
  end
  table.sort(timed, function(a, b) if a.t ~= b.t then return a.t < b.t end; return (a.pos or 99) < (b.pos or 99) end)
  local n = { timed = timed, gaps = {} }
  for i, f in ipairs(timed) do if f.you then n.place, n.time = i, f.t end end
  n.pos = pos or n.place
  local lo, hi
  for _, f in ipairs(timed) do
    if not f.you then lo = lo and math.min(lo, f.t) or f.t; hi = hi and math.max(hi, f.t) or f.t end
  end
  n.spread = lo and (hi - lo) or nil
  if n.time then
    for _, p in ipairs(ST.POSITIONS) do
      local f = timed[p]
      if f then n.gaps[p] = { gap = f.t - n.time, name = f.name } end
    end
  end
  return n
end

-- 'you 1st 2:31.37, P2 +11.17 s (Malis Vazosk), P3 +13.0, P6 +20.2, P12 +44.1, AI spread 33.0 s'
-- (not 1st: P1 comes first, negative, with the winner's name)
function ST.resultText(n)
  local p = {}
  if n.time then
    p[1] = ('you %s %s'):format(C.ordinal(n.pos), K.fmtTime(n.time))
    local named = false
    for _, k in ipairs(ST.POSITIONS) do
      if k ~= n.place then
        local g = n.gaps[k]
        if not g then p[#p + 1] = ('P%d -'):format(k)
        elseif not named then named = true; p[#p + 1] = ('P%d %+.2f s (%s)'):format(k, g.gap, g.name)
        else p[#p + 1] = ('P%d %+.1f'):format(k, g.gap) end
      end
    end
  else
    p[1] = 'you DNF (no time)'
  end
  p[#p + 1] = n.spread and ('AI spread %.1f s'):format(n.spread) or 'AI spread -'
  return table.concat(p, ', ')
end

local function csvField(v)
  v = tostring(v == nil and '' or v)
  if v:find('[",\n]') then v = '"' .. v:gsub('"', '""') .. '"' end
  return v
end
ST.CSV_HEADER = 'job,label,class,event,your_pos,your_time,gap_p1,gap_p2,gap_p3,gap_p6,gap_p12,ai_spread,settings'
local function csvRow(i, job, ev, n)
  local function gap(k) local g = n.gaps[k]; return g and ('%.2f'):format(g.gap) or '' end
  local cls = K.class(job.class)
  local row = { i, job.label or '', cls and cls.name or job.class, ev.title, n.time and n.pos or 'DNF',
    n.time and ('%.2f'):format(n.time) or '', gap(1), gap(2), gap(3), gap(6), gap(12),
    n.spread and ('%.2f'):format(n.spread) or '', ST.settingsText(job.ai) }
  for k, v in ipairs(row) do row[k] = csvField(v) end
  return table.concat(row, ',')
end
local function appendCsv(line)
  local path = file('study_results.csv')
  local f = io.open(path, 'r')
  local fresh = true
  if f then fresh = (f:read(1) == nil); f:close() end
  f = io.open(path, 'a')
  if not f then log('[study] could not write study_results.csv'); return end
  if fresh then f:write(ST.CSV_HEADER, '\n') end
  f:write(line, '\n')
  f:close()
end

---------------------------------------------------------------------------------------------------------------------
-- the jobs

local function head(i, job)
  return ('[study] job %d/%d \'%s\''):format(i, #s.jobs, tostring(job.label or ('job ' .. i)))
end
-- the launchable event of a job, or nil + why
local function eventFor(i, job)
  if type(job) ~= 'table' then return nil, 'not a table' end
  local cls = K.class(tostring(job.class))
  if not cls then return nil, 'no class ' .. tostring(job.class) end
  local cup = K.cup(job.cup)
  if not cup then return nil, 'no cup ' .. tostring(job.cup) end
  local idx = math.floor(tonumber(job.race) or 1)
  local r = K.races(cup, cls.key)[idx]
  if not r then return nil, ('%s has no race %d at %s'):format(cup.name, idx, cls.name) end
  if job.ai ~= nil and type(job.ai) ~= 'table' then return nil, 'ai is not a table' end
  return { path = r.path, title = r.title, kind = r.kind, laps = r.laps, class = cls.key, study = i, studyCup = cup.key, studyRace = idx }
end

-- on to the next job; after a race the menu must settle again (a skipped job's next follows straight on: keep)
local function advance(i, keep)
  s.state = { next = i + 1 }
  writeState()
  s.running = nil
  if not keep then s.readyAt = nil end
end

function ST.on() return s.jobs ~= nil end
function ST.running() return s.running ~= nil end
-- v0.17: study.lua there with jobs still to run (main.lua: no boot into the GRAND PRIX tab - the study needs the plain
-- menu). Uses what ST.boot / ST.poll already read; no file access here.
function ST.pending()
  if not s.jobs then return false end
  local st = s.state or { next = 1 }
  return (tonumber(st.next) or 1) <= #s.jobs
end
-- a race result (or failure) that belongs to a study job
function ST.owns(out) return type(out) == 'table' and type(out.ev) == 'table' and out.ev.study ~= nil end

-- at load: study.lua there? (one io.open; nothing else happens without it)
function ST.boot()
  s.jobs = readJobs()
  s.checkedAt = s.clock
  if not s.jobs then return false end
  s.state = readState()
  local n = #s.jobs
  if s.state.next > n then s.state.done = true; log(('[study] study.lua: %d jobs, all done (delete study_state.lua to run them again)'):format(n))
  else log(('[study] study.lua: %d jobs, next job %d'):format(n, s.state.next)) end
  return true
end

-- every main-menu poll (dt ms; only while the menu is up and no race of ours runs). env = {
--   ready = function() -> true when a job may start (menu up, no race, no cup, nothing to put back, no result
--     screen waiting) - cheap flags only,
--   launch = function(job, ev) -> true | 'wait' (our page was closed first: try again shortly) | false, why }
function ST.poll(dt, env)
  s.clock = s.clock + (dt or 0)
  if s.running then return end
  if s.clock - s.checkedAt >= ST.CHECK_MS then
    s.checkedAt = s.clock
    local had = s.jobs ~= nil
    s.jobs = readJobs()
    if s.jobs and not had then
      s.state = readState()
      log(('[study] study.lua found: %d jobs, next job %d'):format(#s.jobs, s.state.next))
    end
  end
  if not s.jobs then s.readyAt = nil; return end
  s.state = s.state or readState()
  local i = s.state.next
  if i > #s.jobs then
    if not s.state.done then
      s.state.done = true
      writeState()
      log(('[study] all %d jobs done'):format(#s.jobs))
    end
    return
  end
  if not env.ready() then s.readyAt = nil; return end
  s.readyAt = s.readyAt or s.clock
  if s.clock - s.readyAt < ST.SETTLE_MS or s.clock < s.holdUntil then return end
  local job = s.jobs[i]
  local ev, why = eventFor(i, job)
  if not ev then log(('%s skipped: %s'):format(head(i, job or {}), why)); advance(i, true); return end
  -- a job whose race was interrupted (the game closed or crashed in it) runs again, at most MAX_TRIES times
  local tries = (s.state.started == i) and (tonumber(s.state.tries) or 0) or 0
  if tries >= ST.MAX_TRIES then
    log(('%s skipped: its race was interrupted %d times'):format(head(i, job), tries))
    advance(i, true)
    return
  end
  local cls = K.class(ev.class)
  log(('%s start: %s %s (%s race %d), AI %s%s'):format(head(i, job), ev.title, cls.name, ev.studyCup, ev.studyRace,
    ST.settingsText(job.ai), tries > 0 and (' - try %d (the last one was interrupted)'):format(tries + 1) or ''))
  local ok, res, why2 = pcall(env.launch, job, ev)
  if ok and res == 'wait' then s.holdUntil = s.clock + ST.CLOSE_MS; return end
  if ok and res == true then
    s.running = { i = i, job = job, ev = ev }
    s.state = { next = i, started = i, tries = tries + 1 }
    writeState()
    return
  end
  log(('%s launch failed, skipped: %s'):format(head(i, job), tostring(ok and (why2 or res) or res)))
  advance(i, true)
end

-- a study race is over (main.lua, from race.lua R.watch): the result line, the CSV row, the next job
function ST.onResult(out)
  local run = s.running
  if not (run and ST.owns(out) and out.ev.study == run.i) then return end
  local i, job, ev = run.i, run.job, run.ev
  advance(i) -- (first: whatever fails below, the study moves on)
  local cls = K.class(ev.class)
  local n = ST.numbers(out.field, out.pos)
  log(('%s %s %s: %s'):format(head(i, job), ev.title, cls and cls.name or ev.class, ST.resultText(n)))
  local ok, err = pcall(function() appendCsv(csvRow(i, job, ev, n)) end)
  if not ok then log('[study] csv row not written: ' .. tostring(err)) end
end
-- the race never loaded / was not offline (R.watch's { failed = ... })
function ST.onFailed(why)
  local run = s.running
  if not run then return end
  log(('%s failed (%s), skipped'):format(head(run.i, run.job), tostring(why)))
  advance(run.i)
end

return ST
