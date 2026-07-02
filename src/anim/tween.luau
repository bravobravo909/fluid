const ripple = require("../../roblox_packages/ripple")
const cleanup = require("../cleanup")
const effect = require("../effect")
const source = require("../source")


local function tween<T>(src: () -> T, tweenOptions: ripple.TweenOptions )
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