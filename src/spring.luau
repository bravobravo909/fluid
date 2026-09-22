local ripple = require("../roblox_packages/ripple")
local cleanup = require("./cleanup")
local effect = require("./effect")
local source = require("./source")

local function spring<T>(src: () -> T, springOptions: ripple.SpringOptions<T>): (source.Source<T>, ripple.Spring<T>)
	local spr = ripple.createSpring(springOptions.position or src(), springOptions)
	local newValue = source(spr:getPosition())
	if not (springOptions and springOptions.start == false) then
		spr:start()
	end
	local disconnect = spr:onChange(newValue :: any)

	cleanup(function()
		disconnect()
		spr:destroy()
	end)

	effect(function()
		spr:setGoal(src())
	end)
	return newValue, spr
end

return spring
