APP.namespace = "os.fennec.core.mkfox"

local io = security.request("os.fennec.core.io")
local lzss = require("lzss")
local arc = require("arc")
local foxspec = require("foxspec")

-- Calculate size.