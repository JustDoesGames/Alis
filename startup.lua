update = false
console = false
--[[

Simplistic t Program (STP)

--]]

local patchnotes = {
	"Removed logo for simplisity",
	"Console on boot off by default",
	"Fully reworked update system. (now goes through github & pastebin)",
	"Updating is now 2x faster and now uses the 'http' api instead of shell",
	"Label will no longer show 'Booting STP...'",
	"Turtle is not longer required to be fueled to start in menu",
	"Added patch notes",
	"I am fully aware of current issues and in the process of fixing them.",
}

local w,h = term.getSize()
clr, cp, sb, st = term.clear, term.setCursorPos, term.setBackgroundColor, term.setTextColor

local function drawLine() st(colors.gray) for i=1, w do write(string.char(127)) end st(colors.white)  end
local function drawLines() clr() cp(1,1) drawLine() cp(1,h) drawLine() cp(1,2) end

drawLines()
cp(w/2-string.len("STP")/2,2) print("STP")

if fs.exists("/disk") and not fs.exists("/disk/startup.lua") and shell.getRunningProgram() ~= "/disk/startup.lua" then
	print("Type 'install' to install disk installer to '/disk/startup.lua'")
	write(": ")
	if string.lower(read()) == "install" then
		if fs.exists("/disk") then
			if fs.exists("/disk/startup.lua") then fs.delete("/disk/startup.lua") end
			fs.copy(shell.getRunningProgram(), "/disk/startup.lua")
			print("Installed to 'disk/startup.lua'. Rebooting...")
			sleep(1) os.reboot()
		end
	end
end

local c = function(t) if console then print("[STP] "..t) sleep(.02) end end
local setLabel = function(name) return os.setComputerLabel(tostring(name)) end -- did it this way to convert to string because fuck lua
local prevLabel = os.getComputerLabel()

local status, color = "Idle", "e"

if not http then
	c("Http is disabled. Skipping Update...") sleep(1)
elseif not update then
	c("Updates disabled. Skipping...") sleep(1)
else
	write("[STP] Checking for updates")
	local h = http.get("https://raw.githubusercontent.com/JustDoesGames/STP/main/startup.lua")
	local update = false
	if h then update = h.readAll() h.close() end textutils.slowPrint("...")
	--local f = fs.open("out.lua", "w") f.write(update) f.close() -- For debug reasons.
	if update then
		local t = fs.open(shell.getRunningProgram(), "r") local current = t.readAll() t.close()
		if update ~= current then
			c("Update Found!")
			c("Update Process (0/2)")
			local f = fs.open(shell.getRunningProgram(), "w") f.write(update) f.close()
			c("Update Process (1/2)")
			if fs.exists("/disk/startup.lua") then
				print("Update disk? ('disk/startup.lua')")
				print("y - YES")
				print("n - NO")
				while true do
					_,a = os.pullEvent("key")
					if a == keys.y then
						if fs.exists("/disk/startup.lua") then fs.delete("/disk/startup.lua") end
						fs.copy(shell.getRunningProgram(), "/disk/startup.lua")
						c("Disk updated.") break
					elseif a == keys.n then break end
				end
			end
			c("Update Process (2/2)")
			c("Update Complete. Rebooting...") sleep(1) os.reboot()
		else
			c("You are Up-To-Date.")
		end
	else
		c("Failed to obtain update. Skipping Update...")
	end
end
c("Cleaning up files...")
if fs.exists("STP_tmp.lua") then fs.delete("STP_tmp.lua") end -- cleanup update files

if not turtle then
	setLabel(prevLabel)
	clr() cp(1,1)
	c("Unit is not a t.") return
end
local t = turtle

local getLevel = t.getFuelLevel
local blocks_total, gDistance = 0, 0

if not fs.exists("/startup.lua") and t then
	print("Install Simple t Program (STP)?")
	print("Type 'install' to install.")
	write(": ")
	if string.lower(read()) == "install" then
		print("Installing...")
		if fs.exists("/startup.lua") then fs.delete("/startup.lua") end
		fs.copy(shell.getRunningProgram(), "/startup.lua")
		print("Installed to 'startup.lua'. Rebooting...")
		sleep(1) os.reboot()
	end
end

if shell.getRunningProgram() == "disk/startup.lua" then
	clr() cp(1,1)
	c("t plugged in. Unplug to use.") return
end
c("Loading Functions...")

local flashcolors = {"c", "8"}
local function doRefuel()
	t.select(1) -- ensure first slot is selected
	if getLevel() == 0 then -- checks the first time
		t.refuel(1) -- attempts to refuel
		if getLevel() == 0 then -- if fails
			local flashtrack = 1
			c("Need Fuel to proceed...") -- needs fuel
			while getLevel() == 0 do setLabel("§"..flashcolors[flashtrack].."REFUEL") flashtrack=flashtrack+1 if flashtrack > #flashcolors then flashtrack=1 end t.refuel(1) sleep(.5) end -- searches for fuel
		end
	end
end

local function setInfo(stat, col)
	status, color = stat or status, col or color
	setLabel("§f"..math.min(getLevel(), 9999).." | §"..color..status)
end

local function drawInfo()
	drawLines()
	print("Fuel: "..math.min(getLevel(), 9999).."  ")
	print("Distance: "..gDistance.."  ")
	print("Blocks Broken: "..blocks_total.."  ") setInfo()
end

local function digForward() while t.dig() do t.dig() blocks_total = blocks_total + 1 sleep(.25) end end
local function digUp() while t.digUp() do t.digUp() blocks_total = blocks_total + 1 sleep(.25) end end
local function digDown() while t.digDown() do t.digDown() blocks_total = blocks_total + 1 sleep(.25) end end

local function goUp() doRefuel() while not t.up() do t.digUp() sleep(.25) end end
local function goDown() doRefuel() while not t.down() do t.digDown() sleep(.25) end end
local function goForward() doRefuel() while not t.forward() do t.dig() sleep(.25) end gDistance = gDistance + 1 end

turnRight, turnLeft = t.turnRight, t.turnLeft

local function requestDistance(estMoves)
	
	local distance = nil
	local function doDisCalc(scale)
		return math.ceil((distance*estMoves)/scale)
	end
	clr() cp(1,1) drawLine() cp(1,h) drawLine() cp(1,2)
	write("Distance: ") distance = tonumber(read())
	if distance == nil or distance < 1 then c("Invalid input.") sleep(1) return false end

	drawLine()
	print("Current Fuel Level: "..getLevel())
	print("Estimated Fuel Usage: "..distance*estMoves)
	drawLine()
	print("(80) Coal/Charcoal - "..doDisCalc(80))
	print("(120) Blaze Rods - "..doDisCalc(120))
	print("(800) Coal/Charcoal Blocks - "..doDisCalc(800))
	drawLine()
	c("Press 'enter' to confirm...")
	_,b = os.pullEvent("key")
	if b ~= keys.enter then return false end
	return distance
end

local function doPatchNotes()
	clr() cp(1,1) print("Press 'enter' to continue") print("Patch Notes: ")
	for i=1, #patchnotes do
		sleep(.1) os.pullEvent("key") print(patchnotes[i])
	end
	drawLine()
	print("press any key to exit.") sleep(.5) os.pullEvent("key")
end

local function basicTunnel(distance)
	if not distance then return false end
	drawInfo()
	c("Tunneling for "..distance.." blocks...")
	setInfo(distance-1, "a")
	for i=1, distance do
		t.turnLeft()
		drawInfo() digForward()
		goUp()
		drawInfo() digForward()
		t.turnRight()
		t.turnRight()
		drawInfo() digForward()
		drawInfo() goDown()
		drawInfo() digForward()
		t.turnLeft()
		if i ~= distance then while t.detect() do drawInfo() t.dig() sleep(.5) end goForward() setInfo(distance-i-1, "a") end
	end
	setInfo("Idle", "e")
end

local function doTunnel()
	local dis = requestDistance(3)
	if dis then basicTunnel(dis) turnRight() turnRight() for i=1, dis-1 do goForward() end turnRight() turnRight() end
end

local function doAdvTunnel()
	local dis = requestDistance(6)
	if dis then
		basicTunnel(dis) sleep(.5)
		t.turnLeft() t.turnLeft()
		goUp() goUp()
		basicTunnel(dis) sleep(.5)
		t.turnLeft() t.turnLeft()
		goDown() goDown()
	end
end

local function doStripTunnel()
	local dis = requestDistance(2)
	if dis then
		for i=1, dis do
			drawInfo() goForward() setInfo(dis-i, "a") digUp() if math.floor(i/5) == math.ceil(i/5) then t.turnRight() digForward() t.turnLeft() t.turnLeft() digForward() t.turnRight() end
		end
		goUp() t.turnRight() digForward() t.turnLeft() t.turnLeft() digForward() goDown() t.turnLeft()
		for i=1, dis do drawInfo() setInfo(dis-i, "a") goForward() end t.turnLeft() t.turnLeft() setInfo("Idle", "e")
	end
end

local function doExtendedStripTunnel()
	local dis = requestDistance(2)
	if dis then
		for i=1, dis do
			drawInfo() goForward() setInfo(dis-i, "a") digUp() digDown() if math.floor(i/5) == math.ceil(i/5) then t.turnRight() digForward() t.turnLeft() t.turnLeft() digForward() t.turnRight() end
		end
		t.turnRight() digForward() t.turnLeft() t.turnLeft() digForward()  t.turnRight() goDown()
		t.turnRight() digForward() t.turnLeft() t.turnLeft() digForward() goUp() t.turnLeft()
		for i=1, dis do drawInfo() setInfo(dis-i, "a") goForward() end t.turnLeft() t.turnLeft()
	end
end

local function doDoubleStripTunnel()
	local dis = requestDistance(0)
	if dis then
		for i=1, dis do
			 drawInfo() goForward() setInfo(dis-i, "a") digUp() digDown() if math.floor(i/5) == math.ceil(i/5) then t.turnRight() digForward() t.turnLeft() t.turnLeft() digForward() t.turnRight() end
		end
		t.turnLeft()  goForward() digUp()  goForward() t.turnRight()
		for i=1, dis do
			 drawInfo() goForward() setInfo(dis-i, "a") digUp() digDown() if math.floor(i/5) == math.ceil(i/5) then t.turnRight() digForward() t.turnLeft() t.turnLeft() digForward() t.turnRight() end
		end
		t.turnRight() t.turnRight()
	end
end

local function doBroken()
	print("BROKEN! PLEASE CONSULT OWNER.")
	sleep(3)
end

local function do3x1()
	local dis = requestDistance(2)
	if dis then
		for i=1, dis do
			digForward()  drawInfo() goForward() setInfo(dis-i, "a") t.turnLeft() digForward() t.turnRight() t.turnRight() digForward() t.turnLeft()
		end t.turnRight() t.turnRight()
		for i=1, dis do goForward() end
	end
end

local function doManualControl()
	drawLines()
	print("w/s - Go forward / back")
	print("up/down - Go up / down")
	print("a/d - Turn left / right")
	print("e - Dig")
	print("r/f - Dig up / down")
	print("q - exit")
	while true do
		cp(1,h-1) write("Fuel Level: "..getLevel())
		a,b = os.pullEvent("key")
		if b == keys.w then
			goForward()
		elseif b == keys.s then
			t.back()
		elseif b == keys.d then
			turnRight()
		elseif b == keys.a then
			turnLeft()
		elseif b == keys.up then
			goUp()
		elseif b == keys.down then
			goDown()
		elseif b == keys.e then
			digForward()
		elseif b == keys.r then
			digUp()
		elseif b == keys.f then
			digDown()
		elseif b == keys.q then
			break
		end
	end
end

local function doInfMine()
	drawLines()
	print("Infinite Mine")
	print("Press 'q' to exit.")
	local function mine()
		while true do
			digForward() sleep(.01)
		end
	end
	local function getKey()
		local b while b ~= keys.q do
			_,b = os.pullEvent("key")
		end
	end
	parallel.waitForAny(mine, getKey)
end

local function doInfMineDown()
	drawLines()
	print("Infinite Mine - Dropping Down")
	print("Press 'q' to exit.")
	local function mine()
		while true do
			digForward() t.dropDown() sleep(.01)
		end
	end
	local function getKey()
		local b while b ~= keys.q do
			_,b = os.pullEvent("key")
		end
	end
	parallel.waitForAny(mine, getKey)
end

local function doInfRotateMine()
	drawLines()
	print("Infinite Rotate Mine")
	print("Press 'q' to exit.")
	local function mine()
		while true do
			digForward() sleep(.01) turnRight()
		end
	end
	local function getKey()
		local b while b ~= keys.q do
			_,b = os.pullEvent("key")
		end
	end
	parallel.waitForAny(mine, getKey)
end

local function doInfRotateMineDown()
	drawLines()
	print("Infinite Rotate Mine - Dropping Down")
	print("Press 'q' to exit.")
	local function mine()
		while true do
			digForward() t.dropDown() sleep(.01) turnRight()
		end
	end
	local function getKey()
		local b while b ~= keys.q do
			_,b = os.pullEvent("key")
		end
	end
	parallel.waitForAny(mine, getKey)
end

local function doInfAttack()
	drawLines()
	print("Infinite Attack")
	print("Press 'q' to exit.")
	local function mine()
		while true do
			t.attack() sleep(.01)
		end
	end
	local function getKey()
		local b while b ~= keys.q do
			_,b = os.pullEvent("key")
		end
	end
	parallel.waitForAny(mine, getKey)
end

local function doInfAttackDown()
	drawLines()
	print("Infinite Attack - Dropping Down")
	print("Press 'q' to exit.")
	local function mine()
		while true do
			t.attack() t.dropDown() sleep(.01)
		end
	end
	local function getKey()
		local b while b ~= keys.q do
			_,b = os.pullEvent("key")
		end
	end
	parallel.waitForAny(mine, getKey)
end

local function doInfRotateAttack()
	drawLines()
	print("Infinite Rotate Attack")
	print("Press 'q' to exit.")
	local function mine()
		while true do
			t.attack() sleep(.01) turnRight()
		end
	end
	local function getKey()
		local b while b ~= keys.q do
			_,b = os.pullEvent("key")
		end
	end
	parallel.waitForAny(mine, getKey)
end

local function doInfRotateAttackDown()
	drawLines()
	print("Infinite Rotate Attack - Dropping Down")
	print("Press 'q' to exit.")
	local function mine()
		while true do
			t.attack() t.dropDown() sleep(.01) turnRight()
		end
	end
	local function getKey()
		local b while b ~= keys.q do
			_,b = os.pullEvent("key")
		end
	end
	parallel.waitForAny(mine, getKey)
end

local function doSingleStaircaseUp()
	local dis = requestDistance(4)
	if dis then
		for i=1, dis do
			goForward()
			goUp() digUp()
		end turnRight() turnRight()
		for i=1, dis do
			goForward() goDown()
		end turnRight() turnRight()
	end
end

local function doTripleStaircaseUp()
	local dis = requestDistance(8)
	if dis then
		for i=1, dis do
			goForward()
			turnRight() digForward() turnLeft() turnLeft() digForward() turnRight()
			for i=1, 2 do
				goUp()
				turnRight() digForward() turnLeft() turnLeft() digForward() turnRight()
			end goDown()
		end turnRight() turnRight()
		for i=1, dis do
			goForward() goDown()
		end turnRight() turnRight()
	end
end

local function doRSC(cmd)
	st(colors.gray)
	clr() cp(1,1) print("Running Command: "..cmd) st(colors.white)
	shell.run(cmd)
	print("Press any key to continue...") os.pullEvent("key")
end

local run, sel = true, 1
local prevMenu = {}

local rawMenu = {
	{"Tunnel", {
		{"3x2 Tunnel - Single", doTunnel},
		{"3x4 Tunnel - Double", doAdvTunnel},
		{"3x1 Tunnel - Flat", do3x1},
	}},
	{"Strip Mine", {
		{"1x2 Strip Mine", doStripTunnel},
		{"1x3 Strip Mine", doExtendedStripTunnel},
		--{"Double Strip Mine", doBroken},
	}},
	{"Ininite", {
		{"Inf. Mine", doInfMine},
		{"Inf. Mine - Drop Down", doInfMineDown},
		{"Inf. Rotate Mine", doInfRotateMine},
		{"Inf. Rotate Mine - Drop Down", doInfRotateMineDown},
		{"Inf. Attack", doInfAttack},
		{"Inf. Attack - Drop Down", doInfAttackDown},
		{"Inf. Rotate Attack", doInfRotateAttack},
		{"Inf. Rotate Attack - Drop Down", doInfRotateAttackDown},
	}},
	{"Staircase", {
		{"Single Staircase - Up", doSingleStaircaseUp},
		{"Triple Staircase - Up", doTripleStaircaseUp},
	}},
	{"Turtle", {
		{"Unequip", {
			{"Left", function() doRSC("unequip left") end},
			{"Right", function() doRSC("unequip right") end},
		}},
		{"Equip", {
			{"Left", function() doRSC("equip 1 left") end},
			{"Right", function() doRSC("equip 1 right") end},
		}},
	}},
	{"Misc.", {
		{"Manual Control", doManualControl},
	}},
	{"Patch Notes", doPatchNotes},
	{"Exit"}
}

local function runMenu(menu)
	local function resetScreen() clr() cp(1,1) drawLine() cp(1,h) drawLine() cp(w/2-1,2) write("STP") sb(colors.black) end resetScreen()
	while true do
		
		blocks_total = 0
		resetScreen() cp(1,9)
		for i=1, math.min(h-5, #menu) do
			if menu[i+(sel-1)] then
				if i+(sel-1) == sel then
					paintutils.drawLine(1,i+3,w,i+3,colors.gray)
					st(colors.lightGray) cp(1,4) write(sel) st(colors.white)
					cp(w/2-string.len(menu[i+(sel-1)][1])/2, i+3) write(menu[i+(sel-1)][1]) sb(colors.black)
				else
					st(colors.gray) cp(w/2-string.len(menu[i+(sel-1)][1])/2, i+3)
					write(menu[i+(sel-1)][1])
				end
			end
		end st(colors.white)

		_,b = os.pullEvent("key")
		if b == keys.w or b == keys.up then
			if sel == 1 then sel = #menu else sel = sel - 1 end
		elseif b == keys.s or b == keys.down then
			if sel == #menu then sel = 1 else sel = sel + 1 end
		elseif b == keys.enter or b == keys.e then
			break
		end
	end
	st(colors.white)
	for i=1, 2 do
		resetScreen()
		paintutils.drawLine(1,4,w,4,colors.gray)
		cp(w/2-string.len(menu[sel][1])/2, 4)
		write(menu[sel][1]) sb(colors.black) sleep(.05)
		resetScreen() sleep(.05)
	end
	return sel
end

local function execute()
	local menu = rawMenu
	while run do
		
		if menu[#menu][1] ~= "Back" and #prevMenu ~= 0 then menu[#menu+1] = {"Back"} end
		runMenu(menu)
		
		if type(menu[sel][2]) == "table" then -- possible menu
			prevMenu[#prevMenu+1] = {menu = menu, sel = sel}
			menu = menu[sel][2] sel = 1
		elseif not menu[sel][2] then -- possible prev/exit
			if #prevMenu == 0 then run = false else menu, sel = prevMenu[#prevMenu].menu, prevMenu[#prevMenu].sel prevMenu[#prevMenu] = nil end
		elseif type(menu[sel][2]) == "function" then -- possible program
			blocks_total,gDistance=0,0 menu[sel][2](dis) setInfo("Idle", "e")
		end
	end
end

c("Executing STP...")
setInfo("Idle", "e")

execute()
clr() cp(1,1) print("STP Closed.") sleep(0.2)
