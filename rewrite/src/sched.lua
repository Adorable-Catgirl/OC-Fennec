--[[
	This is the low level threading API, not exposed to userland.
]]
threads = {}
local thdlist = setmetatable({}, {__mode="k"})
local sig_queue = rte.collections.queue()
local flags = constants.get("thread_flags")
local event = constants.get("event")

local t_insert = table.insert
local t_remove = table.remove
local c_status = coroutine.status
local c_create = coroutine.create
local c_yield = coroutine.yield
local c_resume = coroutine.resume
local c_running = coroutine.running

local sched_rules = {
	min_sleep = 0
}

local function get_next_pid()
	local npid = -1
	for i=1, #thdlist do
		if (thdlist[i].pid > npid) then
			npid = thdlist[i].pid
		end
	end
	return npid+1
end

function threads.add(name, func, env, cmdline, flags, priority, parent, args, evar)
	local pid = get_next_pid()
	thdlist[#thdlist+1] = {
		name = name,
		coro = c_create(func),
		env = env,
		args = args,
		flags = flags,
		cmdline = cmdline,
		priority = priority,
		parent = parent,
		args = args,
		evar = evar,
		pid = pid,
		deadline = computer.uptime(),
		sigbuf = rte.collections.queue()
	}
	thdlist[thdlist[#thdlist].coro] = hdlist[#thdlist]
	return pid
end

local function thd_add(name, func)
	threads.add(name, func, _G, "", flags.BIOS_THREAD, 0, -1, nil, {})
end

function threads.signal(type, ...)
	sig_queue:add({type = type, args = {...}})
end

local function thd_is_valid(thd)
	return (c_status(thd.coro) ~= "dead") and
		thd.flags & flag.fishsleep == 0 and
		(thd_is_valid(thd.parent) and thd.flags & flag.standalone)
end

function threads.thread_signal(id, type, ...)
	local thd = threads.info(id)
	if not thd_is_valid(thd) then return nil, "invalid thread" end
	thd.sigbuf:add({type = type, args = {...}})
end

function threads.info(id)
	local proc
	if (type(id) == "number") then
		for i=1, #thdlist do
			if thdlist[i].pid == id then
				proc = thdlist[i]
				break
			end
		end
	elseif (type(id) == "thread") then
		proc = thdlist[id]
	else
		return nil, "invalid identifier"
	end
	if not proc then return nil, "thread not found" end
	return proc
end

local function psig(time)
	local ps = {computer.pullSignal(time)}
	if (#ps > 0) then
		threads.signal(event.signal, unpack(ps))
	end
end

local function autosleep()
	local min_dl = math.huge
	local now = false
	for i=1, #thdlist do
		min_dl = ((min_dl > thdlist[i].deadline) and thdlist[i].deadline) or min_dl
		if (thdlist[i].sigbuf:has_next()) then
			now = true
		end
	end
	min_dl = computer.uptime()-min_dl
	min_dl = ((min_dl >= 0 and not now) and min_dl) or 0
	psig(min_dl)
end

local function signals_update()
	if (#sig_queue == 0) then return end
	local sig = sig_queue:next()
	for i=1, #thdlist do
		thdlist[i].sigbuf:add(sig)
	end
end

local function threads_run()
	signals_update()
	local runlist = {}
	-- Determine what threads need to be run and in what order.
	for i=1, #thdlist do
		if ((thdlist[i].deadline <= computer.uptime() or thdlist[i].sigbuf:has_next()) and thdlist[i].flags & (flags.fishsleep | flags.bigsleep) == 0) then
			runlist[#runlist+1] = {thdlist[i], thdlist[i].sigbuf:has_next() and thdlist[i].sigbuf:next()}
		elseif (thdlist[i].args) then
			runlist[#runlist+1] = {thdlist[i], thdlist[i].args}
		end
	end
	table.sort(runlist, function(a, b)
		if (a[1].priority == b[1].priority) then
			return a[1].deadline < b[1].deadline
		end
		return a[1].priority < b[1].priority
	end)
	for i=1, #runlist do
		local e, dl = c_resume(runlist[i][1], unpack(runlist[i][2]))
		if (not e) then
			if (runlist[i][1].parent and runlist[i][1].flags & flags.standalone == 0) then
				runlist[i][1].parent.sigbuf:add(event.childerr, runlist[i][1].pid, dl)
			else
				syslog(loglevel.error, dl)
				runlist[i][1].flags = runlist[i][1].flags | flags.fishsleep
			end
		end
		psig(0)
	end
	local proclist = {}
	for i=1, #thdlist do
		if thd_is_valid(thdlist[i]) then
			proclist[#proclist+1] = thdlist[i]
			proclist[thdlist[i].coro] = thdlist[i]
		end
	end
	thdlist = setmetatable(proclist, getmetatable(thdlist))
	autosleep()
	return true
end