--[[

ALIS
Creator: Kogarashi

]]--

-- VARIABLES / FUNC. --

local tmp = nil -- tmp value for use anywhere it is needed
local vars = { -- Local Vars
	version = "1.00", -- Current Version
	devmode = false, -- devmode disables updates for developing + enables other things
	d_resetconfig = true, -- reset config every reset
	d_usedebugmenu = true,
	update = true, -- choose to update Alis or not
	config_location = "/alis/config.lua" -- Config for storing other variables
}
local w,h = 39,13 -- Width and Height (39x13 for turtle reguardless of actual screen size mostly due to development of UI)

local t,tx,f,o,p,str,turt = term,textutils,fs,os,paintutils,string,turtle -- Basic Term-wide Shorthand
local clr, cp, st, sb, sl = t.clear, t.setCursorPos, t.setTextColor, t.setBackgroundColor, sleep -- Basic Screen-use Shorthand Items
local multiSet, writeChar = function(t,b)st(t)sb(b)end, function(c) write(str.char(c)) end
local fex = f.exists -- Basic Code-use Shorthand Items
local getFuelLevel = turt.getFuelLevel -- Basic Turtle-use Shorthand Items

local let = function(Orig, DV) if type(Orig) == "nil" then return DV end return Orig end
local checkVar = function(var, expected, eExpect) if type(var) ~= expected then return error("checkVar: expected "..(eExpect or expected)..", got "..type(var)) end return true end

local loadFile = function(location) checkVar(location, "string", "File location (string)") local f = fs.open(location, "r") tmp = tx.unserialize(f.readAll()) f.close() return tmp end
local saveFile = function(location, tbl) checkVar(tbl, "table") local f = fs.open(location, "w") f.write(tx.serialize(tbl)) f.close() end

local label = o.setComputerLabel
local labelFormat = "§f"..math.min(getFuelLevel(), 9999).." "..str.char(4).." "

local run, sel = true, 1 -- Run for loop and Sel for currently selected

local sVars = {}
if fs.exists(vars.config_location) and not vars.d_resetconfig then sVars = loadFile(vars.config_location) end

sVars.stats = let(sVars.stats, {})
sVars.stats.mined = let(sVars.stats.mined, {})

sVars.settings = let(sVars.settings, {})
sVars.settings.doAnimations = let(sVars.settings.doAnimations, true)
sVars.settings.doBootScreen = let(sVars.settings.doBootScreen, true)

saveFile(vars.config_location, sVars)

-- Boot --


if sVars.settings.doBootScreen then
	multiSet(colors.white, colors.black) clr()
    for i=1, 4 do
        cp(1,1)
        label(str.sub("ALIS", 1,i))
        write(str.sub("ALIS", 1,i)) sleep(.1)
    end print("")
end

if not http then -- No HTTP
	print("Http is disabled.") sleep(.5)
elseif not vars.update or vars.devmode then -- Update is disabled or devmode activated
	print("Updates disabled."..(vars.devmode and " (DEVMODE)")) sleep(.5)
else
    local h = http.get("https://raw.githubusercontent.com/JustDoesGames/ALIS/main/startup.lua") -- Update location
	local update = false if h then update = h.readAll() h.close() end -- If able to connect
	if update then -- If able to obtain
		local t = fs.open(shell.getRunningProgram(), "r") local current = t.readAll() t.close() -- Get current running program
		if update ~= current then -- Compairs the two
			print("Update Found!") sleep(.1)
            local f = fs.open(shell.getRunningProgram(), "w") f.write(update) f.close() -- Opens current file (usualy startup.lua)
			if fs.exists("/disk/startup.lua") then -- If disk, try to update disk as well
				print("Update disk? ('disk/startup.lua')")
				print("[Y] - YES")
				print("[N] - NO")
				while true do
					_,a = os.pullEvent("key")
					if a == keys.y then
						if fs.exists("/disk/startup.lua") then fs.delete("/disk/startup.lua") end -- Deletes current disk version
						fs.copy(shell.getRunningProgram(), "/disk/startup.lua") -- Simple copy to location
						print("Disk Updated.") sleep(1) break -- Display updated and exit
					elseif a == keys.n then break end -- Does not want update
				end
			end
			os.reboot() -- Fresh reboot
		end
	else
		print("Failed to obtain update.") sleep(.5)
	end
end


-- BASE FUNCTIONS --

local function drawLine() st(colors.gray) for i=1, w do write(str.char(127)) end st(colors.white)  end -- Draws "#" across the width of the screen
local function drawLines() clr() cp(1,1) drawLine() cp(1,h) drawLine() cp(1,2) end -- Draws "#" across both top and bottom of screen

local flashcolors = {"c", "8"}
local function doRefuel()
	turt.select(1) -- ensure first slot is selected
	if getFuelLevel() == 0 then -- checks the first time
		turt.refuel(1) -- attempts to refuel
		if getFuelLevel() == 0 then -- if fails
			local flashtrack = 1
			print("Need Fuel to proceed...") -- needs fuel
			while getFuelLevel() == 0 do label("§"..flashcolors[flashtrack].."REFUEL") flashtrack=flashtrack+1 if flashtrack > #flashcolors then flashtrack=1 end turt.refuel(1) sleep(.5) end -- searches for fuel
		end
	end
end

-- MENU --

local baseMenu
local updateBaseMenu
updateBaseMenu = function()
	baseMenu = {
		{"Exit"}
	}
	if vars.d_usedebugmenu then
		baseMenu = {
			{"Menu 1 (Debug)", {
				{"Menu a - Display", {
					{"Hello World", function() drawLines() cp(1,2) tx.slowPrint("Hello World!") sleep(1) end},
					{"Toggle Animations", function() sVars.settings.doAnimations = not sVars.settings.doAnimations end},
					{"Test 3", {}}
				}},
				{"Menu b - Mine", {
					{"Test 1", {}},
					{"Test 2", {}},
					{"Test 3", {}}
				}},
				{"Menu c", {
					{"Test 1", {}},
					{"Test 2", {}},
					{"Test 3", {}}
				}},
				{"Menu d", {
					{"Test 1", {}},
					{"Test 2", {}},
					{"Test 3", {}}
				}},
				{"Menu e", {
					{"Test 1", {}},
					{"Test 2", {}},
					{"Test 3", {}}
				}},
				{"Menu f", {
					{"Test 1", {}},
					{"Test 2", {}},
					{"Test 3", {}}
				}},
			}},
			{"Exit"}
		}
	end
end
updateBaseMenu() -- Initial menu setup
local menuTree = {
	{title = "ALIS", m = baseMenu, sel = 1}
}
local getCurrentMenu = function() return menuTree[#menuTree] end

local function runMenu(menu)
	-- Local Functions --
	local menu = getCurrentMenu()
	local function resetScreen() p.drawFilledBox(5,3,w-5,9,colors.black) cp(w/2-(menu.title):len()/2,2) write(menu.title) sb(colors.black) end
	local drawScreen = function()
		for i=1, math.min(h-5, #menu.m) do
			if menu.m[i+(sel-1)] then
				if i+(sel-1) == sel then -- If selected
					p.drawLine(1,i+3,w,i+3,colors.gray) -- Highlight background
					st(colors.lightGray) cp(1,4) write(sel) st(colors.white) -- Display option # of left
					cp(w/2-str.len(menu.m[i+(sel-1)][1])/2, i+3) write(menu.m[i+(sel-1)][1]) sb(colors.black) -- Display option name
				else -- If not Selected
					st(colors.gray) cp(w/2-str.len(menu.m[i+(sel-1)][1])/2, i+3) -- Setup display color + coords
					write(menu.m[i+(sel-1)][1]) -- Display option name
				end
			end
		end st(colors.white)
	end

	local egg = 0
	-- Loop --
	drawLines()
	while true do
		
		-- Display Screen --
		resetScreen() cp(1,9)
		drawScreen()

		-- Key Input --
		_,b = o.pullEvent("key")

		if egg == 0 and b == keys.a then egg = 1 elseif egg == 1 and b == keys.l then egg = 2 elseif egg == 2 and b == keys.i then egg = 3 end
		if b == keys.w or b == keys.up then
			if sel == 1 then sel = #menu.m else sel = sel - 1 end -- Up
		elseif b == keys.s or b == keys.down then
			if b == keys.s and egg == 3 then
				error("EGG")
			else
				if sel == #menu.m then sel = 1 else sel = sel + 1 end -- Down
			end
		elseif b == keys.enter or b == keys.e then
			break -- Select option
		end
	end

	-- Blinking animation --
	if sVars.settings.doAnimations then
		st(colors.white)
		p.drawFilledBox(1,3,w,h-1,colors.black)
		for i=1, 2 do
			p.drawLine(1,4,w,4,colors.gray)
			cp(w/2-str.len(menu.m[sel][1])/2, 4)
			write(menu.m[sel][1]) sb(colors.black) sleep(.05)
			p.drawLine(1,4,w,4,colors.black) sleep(.05)
		end
		return sel
	end
	
	-- Return --
	return sel
end

local function execute()
	run, sel = true, 1 -- safe reset after install screen
	while run do
		local menu = getCurrentMenu() sel = menu.sel
		if #menu.m == 0 then
			menu.m[1] = {"Back"}
		else
			if menu.m[#menu] ~= {"Back"} and #menuTree ~= 1 then menu.m[#menu.m] = {"Back"} end -- Add "Back" option to menu
		end
		runMenu(menu.m) -- Run menu
		menuTree[#menuTree].sel = sel
		
		if type(menu.m[sel][2]) == "table" then -- MENU
			table.insert(menuTree, {title = menu.m[sel][1], m = menu.m[sel][2], sel = 1})
		elseif not menu.m[sel][2] then -- PREV / EXIT
			if #menuTree == 1 then run = false else table.remove(menuTree, #menuTree) end
		elseif type(menu.m[sel][2]) == "function" then -- EXECUTABLE
			menu.m[sel][2](dis)
		else
			error("what...")
		end
	end
end

-- INSTALLER --
--[[
if shell.getRunningProgram() ~= "/disk/startup.lua" or fs.exists("/disk") then
	local exit = false
	local install = function(grab, location)
		-- Display --
		drawLines() st(colors.white) cp((w/2)-3, 2) write("Install")
		local d_grab = str.sub(grab, grab:len()-34, grab:len())
		st(colors.gray) cp((w/2)-d_grab:len()/2,3) write(d_grab)
		
		-- Install --
		if fs.exists(location) then fs.delete(location) end
		local h = http.get(grab)
		if h then
			local r = h.readAll() h.close()
			local f = fs.open(location, "w") f.write(r) f.close()
		else
			return false
		end
		return true
	end
	
	-- Menu + Execute --
	local menu = {
		{"Alis - NO INSTALL", function() end},
		{"Alis - INSTALL", function() install("/startup.lua") end},
	}
	if vars.devmode then table.insert(menu, {"Dev-Alis - INSTALL", function() install("/startup.lua") end}) end
	if fs.exists("/disk") and not fs.exists("/disk/startup.lua") then table.insert(menu, {"Alis - DISK INSTALL", function() install("/disk/startup.lua") end}) if vars.devmode then table.insert(menu, {"Dev-Alis - DISK INSTALL", function() install("/disk/startup.lua") end}) end end
	table.insert(menu, {"Exit to Shell", function() exit = true end})
	runMenu(menu)
	menu[sel][2]()
	
	if exit then clr() cp(1,1) return end
end
]]
-- EXECUTE --

execute()
clr() cp(1,1)
