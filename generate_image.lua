local options = {
	norom = false,
	bz = 16
}

--[[----------------------------------------------------------------------------
	LZSS - encoder / decoder
	This is free and unencumbered software released into the public domain.
	Anyone is free to copy, modify, publish, use, compile, sell, or
	distribute this software, either in source code form or as a compiled
	binary, for any purpose, commercial or non-commercial, and by any
	means.
	In jurisdictions that recognize copyright laws, the author or authors
	of this software dedicate any and all copyright interest in the
	software to the public domain. We make this dedication for the benefit
	of the public at large and to the detriment of our heirs and
	successors. We intend this dedication to be an overt act of
	relinquishment in perpetuity of all present and future rights to this
	software under copyright law.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
	OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	OTHER DEALINGS IN THE SOFTWARE.
	For more information, please refer to <http://unlicense.org/>
--]]----------------------------------------------------------------------------
--------------------------------------------------------------------------------
local lzss = {}
local string, table = string, table

--------------------------------------------------------------------------------
local POS_BITS = 12
local LEN_BITS = 16 - POS_BITS
local POS_SIZE = 1 << POS_BITS
local LEN_SIZE = 1 << LEN_BITS
local LEN_MIN = 3

--------------------------------------------------------------------------------
function lzss.compress(input)
	local offset, output = 1, {}
	local window = ''

	local function search()
		for i = LEN_SIZE + LEN_MIN - 1, LEN_MIN, -1 do
			local str = string.sub(input, offset, offset + i - 1)
			local pos = string.find(window, str, 1, true)
			if pos then
				return pos, str
			end
		end
	end

	while offset <= #input do
		local flags, buffer = 0, {}

		for i = 0, 7 do
			if offset <= #input then
				local pos, str = search()
				if pos and #str >= LEN_MIN then
					local tmp = ((pos - 1) << LEN_BITS) | (#str - LEN_MIN)
					buffer[#buffer + 1] = string.pack('>I2', tmp)
				else
					flags = flags | (1 << i)
					str = string.sub(input, offset, offset)
					buffer[#buffer + 1] = str
				end
				window = string.sub(window .. str, -POS_SIZE)
				offset = offset + #str
			else
				break
			end
		end

		if #buffer > 0 then
			output[#output + 1] = string.char(flags)
			output[#output + 1] = table.concat(buffer)
		end
	end

	return table.concat(output)
end

--------------------------------------------------------------------------------
function lzss.decompress(input)
	local offset, output = 1, {}
	local window = ''

	while offset <= #input do
		local flags = string.byte(input, offset)
		offset = offset + 1

		for i = 1, 8 do
			local str = nil
			if (flags & 1) ~= 0 then
				if offset <= #input then
					str = string.sub(input, offset, offset)
					offset = offset + 1
				end
			else
				if offset + 1 <= #input then
					local tmp = string.unpack('>I2', input, offset)
					offset = offset + 2
					local pos = (tmp >> LEN_BITS) + 1
					local len = (tmp & (LEN_SIZE - 1)) + LEN_MIN
					str = string.sub(window, pos, pos + len - 1)
				end
			end
			flags = flags >> 1
			if str then
				output[#output + 1] = str
				window = string.sub(window .. str, -POS_SIZE)
			end
		end
	end

	return table.concat(output)
end


local function generate_rom()
	local rgen = io.popen("luacomp src/rom.lua", "r")
	local code = rgen:read("*a")
	rgen:close()
	local rom = load(code)()
	local dat = "f16k"
	local buffer = ""
	local function buffer_flush()
		local zdat = lzss.compress(buffer)
		dat = dat .. string.char(#zdat & 0xFF, #zdat >> 8) .. zdat
		buffer = ""
	end
	local function buffer_write(wdat)
		if (#dat+#buffer >= options.bz*1024) then
			local rz = (options.bz*1024)-#buffer
			buffer = buffer..wdat:sub(1, rz)
			buffer_flush()
			buffer_write(wdat:sub(rz+1))
		else
			buffer = buffer .. wdat
		end
	end
	for k, v in pairs(rom) do
		buffer_write(string.char(#k)..k..string.char(#v & 0xFF, #v >> 8)..(((k:sub(#k-4) == ".lua") and "x") or "-")..v)
	end
	buffer_flush()
	return dat
end

local rom = generate_rom()
io.stderr:write("ROM Size: "..(#rom).." bytes\n")

local function mkstr(d)
	local dat = "\""
	for i=1, #d do
		if (d:sub(i, i) == "\t") then
			dat = dat .. "\\t"
		elseif (d:sub(i,i) == "\\") then
			dat = dat .. ("\\\\")
		elseif (d:sub(i,i) == "\"") then
			dat = dat .. ("\\\"")
		elseif (d:sub(i,i) == "\n") then
			dat = dat .. ("\\n")
		elseif (d:sub(i,i) == "\r") then
			dat = dat .. ("\\r")
		else
			dat = dat .. (d:sub(i,i))
		end
	end
	dat = dat .. ("\"")
	return dat
end

local function generate_image()
	local rgen = io.popen("luacomp src/kernel/init.lua", "r")
	local code = rgen:read("*a")
	rgen:close()
	return code:gsub("{{romdata}}", mkstr(rom):gsub("%%", "%%%%"))
end

local idat = generate_image()
io.stderr:write("Image size: "..#idat.." bytes\n")

local f = io.open("fennec.lua", "w")
f:write(idat)
f:close()