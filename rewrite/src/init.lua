local utils = krequire("utils")
local tsar = krequire("util_tsar")
local thd = krequire("thd")
--#include "src/constants.lua"
--#include "src/rte.lua"
-- Inject our custom scheduler
--#include "src/sched.lua"
thd.add = thd_add
thd.run = threads_run
do
	local thds = thd.get_threads()
	for i=1, #thds do
		local pid = get_next_pid()
		thdlist[#thdlist+1] = {
			name = thds[i][1],
			coro = thds[i][2],
			env = _G,
			args = nil,
			flags = consts.procflags.bios | consts.procflags.orphan | consts.procflags.system,
			cmdline = "",
			evar = {},
			priority = 0,
			parent = -1,
			args = nil,
			pid = pid,
			deadline = computer.uptime(),
			sigbuf = rte.collections.queue()
		}
		thdlist[thdlist[#thdlist].coro] = hdlist[#thdlist]
	end
end

return function()
	xpcall(function()

	end, function()

	end)
end