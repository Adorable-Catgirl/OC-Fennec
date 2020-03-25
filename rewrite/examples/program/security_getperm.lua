-- Only required in in raw lua form.
function APP:security_setup(secenv)
	secenv.request("knrl.io")
	secenv.request("knrl.net")
	secenv.request("knrl.ipc")
end

function APP:main(args)

end