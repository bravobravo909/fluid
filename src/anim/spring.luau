local cleanup = require("../reactive/cleanup")
local effect = require("../reactive/effect")
local ripple = require("../../roblox_packages/ripple")
local source = require("../reactive/source")
local types = require("../reactive/types")

local function spring<T>(src: () -> T, spring_options: ripple.SpringOptions<T>): (types.Source<T>, ripple.Spring<T>)
	local spr = ripple.createSpring(spring_options.position or src(), spring_options)
	local output = source(spr:getPosition())

	if spring_options.start ~= false then
		spr:start()
	end

	local disconnect = spr:onChange(output :: any)

	cleanup(function()
		disconnect()
		spr:destroy()
	end)

	effect(function()
		spr:setGoal(src())
	end)

	return output, spr
end

return spring
