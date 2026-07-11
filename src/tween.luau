local ripple = require("../roblox_packages/ripple")
local cleanup = require("./cleanup")
local effect = require("./effect")
local source = require("./source")

local function tween<T>(src: () -> T, tweenOptions: ripple.TweenOptions)
	local tween = ripple.createTween(tweenOptions.position or src(), tweenOptions)
	local newValue = source(tween:getPosition())
	if not (tweenOptions and tweenOptions.start == false) then
		tween:start()
	end
	local disconnect = tween:onChange(newValue)

	cleanup(function()
		disconnect()
		tween:destroy()
	end)

	effect(function()
		tween:setGoal(src())
	end)
	return newValue, tween
end

return tween
