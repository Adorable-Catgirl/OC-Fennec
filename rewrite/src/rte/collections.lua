local collections = {
@[[	local lfs = require("lfs")
	for ent in lfs.dir("src/rte/collections") do
		if (ent:sub(#ent-3) == ".lua") then]]
	["@[{ent:sub(1, #ent-4)}]"] = (function()
--#include @[{"src/rte/collections/"..ent}]
	end)(),
@[[		end
	end]]
}