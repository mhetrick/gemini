--gemini
--
--twin granulators
--watch them race
--
--ENC 1: select param
--ENC 2: modify L param
--ENC 3: modify R param
--
--KEY 1: hold to modify both 
--params with ENC 2
--KEY 2: start/stop
--KEY 3: reset granulators
--
--supports arc 4

engine.name = 'Gemini'

local voiceGate = 0
local dualMode = 0
local grainPositionL = 0
local grainPositionR = 0
local activeParam = 0

function init()
  
  local phase_poll = poll.set('phaseL', function(pos) grainPositionL = pos end)
  phase_poll.time = 0.05
  phase_poll:start()
  
  local phase_poll = poll.set('phaseR', function(pos) grainPositionR = pos end)
  phase_poll.time = 0.05
  phase_poll:start()
  
  params:add_file("sample", "Sample")
  params:set_action("sample", function(file) engine.read(file) end)
  
  params:add_taper("durationL", "Duration L", 0.1, 120, 20, 6, "s")
  params:set_action("durationL", function(value) engine.durationL(value) end)
  
  params:add_taper("durationR", "Duration R", 0.1, 120, 20, 6, "s")
  params:set_action("durationR", function(value) engine.durationR(value) end)
  
  params:add_taper("pitchL", "Pitch L", -48, 48, 0, 0, "st")
  params:set_action("pitchL", function(value) engine.pitchL(math.pow(0.5, -value / 12)) end)
  
  params:add_taper("pitchR", "Pitch R", -48, 48, 0, 0, "st")
  params:set_action("pitchR", function(value) engine.pitchR(math.pow(0.5, -value / 12)) end)
  
  params:add_taper("sizeL", "Size L", 1, 500, 100, 5, "ms")
  params:set_action("sizeL", function(value) engine.sizeL(value / 1000) end)
  
  params:add_taper("sizeR", "Size R", 1, 500, 100, 5, "ms")
  params:set_action("sizeR", function(value) engine.sizeR(value / 1000) end)
  
  params:add_taper("jitterL", "Jitter L", 0, 500, 0, 5, "ms")
  params:set_action("jitterL", function(value) engine.jitterL(value / 1000) end)
  
  params:add_taper("jitterR", "Jitter R", 0, 500, 0, 5, "ms")
  params:set_action("jitterR", function(value) engine.jitterR(value / 1000) end)

  params:add_taper("densityL", "Density L", 0, 512, 20, 6, "hz")
  params:set_action("densityL", function(value) engine.trigRateL(value) end)
  
  params:add_taper("densityR", "Density R", 0, 512, 20, 6, "hz")
  params:set_action("densityR", function(value) engine.trigRateR(value) end)
  
  params:bang()
  
  counter = metro.init(count, 0.01, -1)
  counter:start()
end

function count()
  redraw()
end


local function reset_voice()
  engine.seek(0)
end

local function start_voice()
  reset_voice()
  engine.gate(1)
  voiceGate = 1
end

local function stop_voice()
  voiceGate = 0
  engine.gate(0)
end


function enc(n, d)
  if n == 1 then
    activeParam = util.clamp(activeParam + d, 0, 4)
  elseif n == 2 then
    editLeft(d)
  elseif n == 3 then
    editRight(d)
  end
end

function key(n, z)
  if n == 1 then
    dualMode = z
  elseif n == 2 then
    if z == 1 then
      if voiceGate == 0 then start_voice() else stop_voice() end
    end
  elseif n == 3 then
    if z == 1 then 
      reset_voice() 
    end
  end
end


function editLeft(d)
  if activeParam == 0 then params:delta("durationL", d)
  elseif activeParam == 1 then params:delta("pitchL", d)
  elseif activeParam == 2 then params:delta("sizeL", d)
  elseif activeParam == 3 then params:delta("densityL", d)
  elseif activeParam == 4 then params:delta("jitterL", d)
  end
  
  if dualMode == 1 then editRight(d) end
end

function editRight(d)
  if activeParam == 0 then params:delta("durationR", d)
  elseif activeParam == 1 then params:delta("pitchR", d)
  elseif activeParam == 2 then params:delta("sizeR", d)
  elseif activeParam == 3 then params:delta("densityR", d)
  elseif activeParam == 4 then params:delta("jitterR", d)
  end
end


function printRound(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function redraw()
  -- do return end
  screen.clear()
  screen.level(15)

  rectHeight = 55
  rectWidth = 10

  screen.rect(1, 5, rectWidth, rectHeight)
  screen.stroke()
  
  screen.rect(128 - rectWidth, 5, rectWidth, rectHeight)
  screen.stroke()
  
  if voiceGate == 1 then
    screen.rect(1, 5, 10, rectHeight*grainPositionL)
    screen.fill()
    
    screen.rect(128 - rectWidth, 5, 10, rectHeight*grainPositionR)
    screen.fill()
  end
  
  pY = 15
  pSpacing = 10
  
  pOn = 15
  pOff = 8
  
  if activeParam == 0 then screen.level(pOn) else screen.level(pOff) end
  
  screen.move(22, pY)
  screen.text(printRound(params:get("durationL"), 1))
  screen.move(92, pY)
  screen.text(printRound(params:get("durationR"), 1))
  screen.move(45, pY)
  screen.text("Duration")
  
  pY = pY + pSpacing
  if activeParam == 1 then screen.level(pOn) else screen.level(pOff) end
  
  screen.move(22, pY)
  screen.text(printRound(params:get("pitchL"), 1))
  screen.move(92, pY)
  screen.text(printRound(params:get("pitchR"), 1))
  screen.move(52, pY)
  screen.text("Pitch")
  
  pY = pY + pSpacing
  if activeParam == 2 then screen.level(pOn) else screen.level(pOff) end
  
  screen.move(22, pY)
  screen.text(printRound(params:get("sizeL"), 1))
  screen.move(92, pY)
  screen.text(printRound(params:get("sizeR"), 1))
  screen.move(54, pY)
  screen.text("Size")
  
  pY = pY + pSpacing
  if activeParam == 3 then screen.level(pOn) else screen.level(pOff) end

  screen.move(22, pY)
  screen.text(printRound(params:get("densityL"), 1))
  screen.move(92, pY)
  screen.text(printRound(params:get("densityR"), 1))
  screen.move(48, pY)
  screen.text("Density")
  
  pY = pY + pSpacing
  if activeParam == 4 then screen.level(pOn) else screen.level(pOff) end
  
  screen.move(22, pY)
  screen.text(printRound(params:get("jitterL"), 1))
  screen.move(92, pY)
  screen.text(printRound(params:get("jitterR"), 1))
  screen.move(50, pY)
  screen.text("Jitter")

  screen.update()
end

a = arc.connect()

a.delta = function(n,d)
  if n == 1 then
    activeParam = util.clamp(activeParam + math.floor(d), 0, 4)
  elseif n == 2 then
    editLeft(d)
  elseif n == 3 then
    editRight(d)
  elseif n == 4 then
    editLeft(d)
    editRight(d)
  end
end

piSeg = 6.28/5

arc_redraw = function()
  a:all(0)
  
  a:segment(1, 0, piSeg * (activeParam+1), 3)
  
  if activeParam == 0 then
    local durationL = params:get("durationL") / 24
    a:segment(2, -2.5, -2.5 + durationL, 15)
    local durationR = params:get("durationR") / 24
    a:segment(3, -2.5, -2.5 + durationR, 15)
  elseif activeParam == 1 then
    local pitchL = params:get("pitchL") / 20
    if pitchL > 0 then
      a:segment(2,0.5,0.5+pitchL,15)
    else
      a:segment(2,pitchL-0.5,-0.5,15)
    end
    
    local pitchR = params:get("pitchR") / 20
    if pitchR > 0 then
      a:segment(3,0.5,0.5+pitchR,15)
    else
      a:segment(3,pitchR-0.5,-0.5,15)
    end
    
  elseif activeParam == 2 then
    local sizeL = params:get("sizeL") / 100
    a:segment(2, -2.5, -2.5 + sizeL, 15)
    local sizeR = params:get("sizeR") / 100
    a:segment(3, -2.5, -2.5 + sizeR, 15)
  elseif activeParam == 3 then
    local densityL = params:get("densityL") / 100
    a:segment(2, -2.5, -2.5 + densityL, 15)
    local densityR = params:get("densityR") / 100
    a:segment(3, -2.5, -2.5 + densityR, 15)
  elseif activeParam == 4 then
    local jitterL = params:get("jitterL") / 100
    a:segment(2, -2.5, -2.5 + jitterL, 15)
    local jitterR = params:get("jitterR") / 100
    a:segment(3, -2.5, -2.5 + jitterR, 15)
  end
  
  a:segment(4, 0, 6.28, 3)
  
  a:refresh()
end

re = metro.init()
re.time = 0.03
re.event = function()
  arc_redraw()
end
re:start()