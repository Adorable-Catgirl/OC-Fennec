local consts = {}

@[[function flags(t)
	for i=1, #t do]]
	["@[{t[i]}]"] = @[{1 << (i-1)}],
	@[[end
end]]

@[[function enum(t)
	for i=1, #t do]]
	["@[{t[i]}]"] = @[{i-1}],
	@[[end
end]]

@[[local lfs = require("lfs")
for ent in lfs.dir("src/flags") do
	if (ent:sub(#ent-3) == ".lua") then]]
consts["@[{ent:sub(1, #ent-4)}]"] = {
	@[[loadfile("src/flags/"..ent, "t", _G)()]]
}
	@[[end]]
@[[end
flags = nil
enum = nil]]
local constants = {}

function constants.get(const)
	return consts[const]
end