-- v0.12: the unlock pacing check (docs/PHILOSOPHY.md point 6: always one thing just out of reach, never a flood).
-- A fresh save is walked through the progression cup by cup (v0.26: the league ladder, bronzes and golds). At every
-- step, while anything is locked:
--   * at least one locked thing is one step away - racing only what is open now can open it - and the player can see
--     it: a LOCKED tile on HOME (a class) or on an open class's cups page (the Galactic Cup, the title race) whose
--     text says what opens it;
--   * no single cup result from here (a gold in any cup open now) unlocks more than two things at once.
local M = require('mock')
local W = require('world')
local T = require('util')
T.boot({ version = 3, races = 0, cups = 0, vehicle = 'car', restores = {}, abilityRestores = {} })
local K = require('gp')
local PR = require('prog')
local cfg = require('config')

local function descs()
  local all = {}
  for _, t in ipairs(W.tiles or {}) do
    local d = rawget(t, '__props').TxtDescription
    all[#all + 1] = d and rawget(d, '__props').__text or ''
  end
  return all
end
local function split(s) local o = {}; for x in (s .. '|'):gmatch('(.-)|') do o[#o + 1] = x end; return o end
-- the LOCKED tiles the player can see now, as openSet names -> their text: HOME's classes, each open class's cups page
local function lockedTiles()
  local seen = {}
  M.press('F6'); M.tick(6)
  local titles, badges, ds = split(T.titles()), split(T.locks()), descs()
  for i, c in ipairs(K.leagues()) do
    if titles[i] == c.name:upper() and badges[i] == 'LOCKED' then seen[c.name] = ds[i] end
  end
  for _, c in ipairs(K.leagues()) do
    if PR.classOpen(K.data, c.key) then
      T.clickTitle(c.name:upper()); M.tick(3)
      titles, badges, ds = split(T.titles()), split(T.locks()), descs()
      for i, title in ipairs(titles) do
        if badges[i] == 'LOCKED' then
          local name = title == 'TITLE RACE' and 'TITLE RACE' or title
          seen[name .. ' at ' .. c.name] = ds[i]
        end
      end
      M.press('BACKSPACE'); M.tick(3)
    end
  end
  M.press('F6'); M.tick(6) -- (the menu key toggles: closed again for the next look)
  return seen
end
-- every lockable thing, as openSet names
local ALL = {}
for _, c in ipairs(K.leagues()) do
  ALL[#ALL + 1] = c.name
  for _, cup in ipairs(K.cups()) do if cup.final then ALL[#ALL + 1] = cup.name .. ' at ' .. c.name end end
  if (cfg.Title or {}).On ~= false then ALL[#ALL + 1] = 'TITLE RACE at ' .. c.name end -- (v0.33: off)
end
local function copyBest(b) local o = {}; for k, v in pairs(b) do o[k] = {}; for k2, v2 in pairs(v) do o[k][k2] = v2 end end; return o end
-- the cups open now: { class, cup }
local function openCups(data)
  local out = {}
  for _, c in ipairs(K.leagues()) do
    for _, cup in ipairs(K.cups()) do if PR.cupOpen(data, c.key, cup.key) then out[#out + 1] = { c.key, cup.key } end end
  end
  return out
end
-- open after a gold in every cup open now (one step: only what is open now is raced)
local function oneStepSet(data)
  local d = { best = copyBest(data.best), titles = data.titles }
  for _, x in ipairs(openCups(data)) do d.best[x[1]] = d.best[x[1]] or {}; d.best[x[1]][x[2]] = 1 end
  return PR.openSet(d)
end

local problems, maxFlood, floodAt, steps = {}, 0, '', 0
local function checkState(label)
  local data = K.data
  local open = PR.openSet(data)
  local locked = {}
  for _, x in ipairs(ALL) do if not open[x] then locked[#locked + 1] = x end end
  if #locked == 0 then return end
  steps = steps + 1
  local next1, tiles = oneStepSet(data), lockedTiles()
  local goals = {}
  for _, x in ipairs(locked) do
    if next1[x] and tiles[x] and tiles[x]:find(' to unlock%.?$') then goals[#goals + 1] = x end
  end
  if #goals == 0 then problems[#problems + 1] = label .. ': no visible locked thing one step away' end
  -- every single cup result from here
  for _, x in ipairs(openCups(data)) do
    local d = { best = copyBest(data.best), titles = data.titles }
    d.best[x[1]] = d.best[x[1]] or {}
    d.best[x[1]][x[2]] = 1
    local nw = PR.newlyOpen(open, PR.openSet(d))
    if #nw > maxFlood then maxFlood, floodAt = #nw, ('%s, then %s %s: %s'):format(label, x[1], x[2], table.concat(nw, ', ')) end
    if #nw > 2 then problems[#problems + 1] = ('%s: a trophy in %s at %s opens %d things (%s)'):format(label, x[2], x[1], #nw, table.concat(nw, ', ')) end
  end
  return goals
end

local PLANETS = {}
for _, cup in ipairs(K.cups()) do if not cup.final then PLANETS[#PLANETS + 1] = cup.key end end
local function walk(name, classOrder, colour)
  K.reset()
  local g = checkState(name .. ' fresh save')
  T.check(g and #g > 0, name .. ': a fresh save shows a goal one step away (' .. table.concat(g or {}, ', ') .. ')')
  for _, cls in ipairs(classOrder) do
    for _, cup in ipairs(PLANETS) do
      K.data.best[cls] = K.data.best[cls] or {}
      K.data.best[cls][cup] = colour
      checkState(('%s %s %s'):format(name, cls, cup))
    end
    K.data.best[cls].galactic = colour
    checkState(('%s %s galactic'):format(name, cls))
  end
  local open = PR.openSet(K.data)
  local all = true
  for _, x in ipairs(ALL) do if not open[x] then all = false end end
  T.check(all, name .. ': everything open at the end of the walk')
end
walk('bronzes', { 'riffraff', 'challenger', 'ace' }, 3)
walk('golds', { 'riffraff', 'challenger', 'ace' }, 1)
T.check(#problems == 0, ('every step (%d) shows a visible goal one step away and no cup opens more than two things%s'):format(steps,
  #problems > 0 and (': ' .. table.concat(problems, '; ')) or ''))
T.check(maxFlood == 2, 'the most one cup opens is two things (' .. floodAt .. ')')
T.finish()
