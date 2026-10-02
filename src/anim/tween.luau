local cleanup = require("../reactive/cleanup")
local effect = require("../reactive/effect")
local ripple = require("../../roblox_packages/ripple")
local source = require("../reactive/source")
local types = require("../reactive/types")

local function tween<T>(src: () -> T, tween_options: ripple.TweenOptions<T>): (types.Source<T>, ripple.Tween<T>)
	local twn = ripple.createTween(tween_options.position or src(), tween_options)
	local output = source(twn:getPosition())

	if tween_options.start ~= false then
		twn:start()
	end

	local disconnect = twn:onChange(output :: any)

	cleanup(function()
		disconnect()
		twn:destroy()
	end)

	effect(function()
		twn:setGoal(src())
	end)

	return output, twn
end

return tween
