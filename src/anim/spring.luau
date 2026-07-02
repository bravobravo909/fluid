const ripple = require("../../roblox_packages/ripple")
const cleanup = require("../cleanup")
const effect = require("../effect")
const source = require("../source")


local function spring<T>(src: () -> T, springOptions: ripple.SpringOptions)
    local spr = ripple.createSpring(springOptions.position or src(), springOptions)
    local newValue = source(spr:getPosition())
    if not (springOptions and springOptions.start == false) then
        spr:start()
    end
    local disconnect = spr:onChange(newValue)
    
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