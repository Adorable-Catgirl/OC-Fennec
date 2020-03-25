function DAEMON:star(args)

end

function DAEMON:stop()

end

function DAEMON:ipc(message)

end

function DAEMON:security_setup(secenv)
	secenv.request("knrl.io")
	secenv.request("knrl.net")
	secenv.request("knrl.ipc")
	secenv.request("knrl.security")
	secenv.make_perm("test.myperm")
end

function DAEMON:setup_library(lib)
	lib:require_perm("test.myperm")
	function lib.functions.my_function()
		
	end
end