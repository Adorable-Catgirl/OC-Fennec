APP.namespace = "os.fennec.core.fsh"
local proc = require("proc")
local tty = require("tty")
local cfg = require("cfg").load("/home/"..os.getenv("USER").."/.fshrc")
local arc = require("arc")

local function parse_ps1(p)
	local s, e = 0, 0
	local psp = ""
	while s do
		local oe = e
		s, e = p:find("%$%(.+%)", oe)
		if s then
			local svar = p:sub(s+2, e-1)
			psp = psp .. p:sub(oe+1, s-1) .. (os.getenv(svar) or "nil")
		else
			psp = psp .. p:sub(oe+1)
		end
	end
	return psp
end

local function get_foxac(exec, argn)
	local a = arc.open(exec)
	if (not a:exists("fshac.lua")) then
		return nil
	end
	local res, err = pcall(load(a:get("fshac.lua")))
	return res[argn]()
end

local function get_ac(exec, argn)
	if (exec:sub(#exec-3) == ".fox") then
		local ac = get_foxac(exec, argn)
		if ac then return ac end
	end
	return io.list(os.getenv("CWD"))
end

-- Parse command to lua.
local function parse_cmd(c)
	local cmd
	local args = {}
	local tmp = ""
	for i=1, #c do
		
	end
