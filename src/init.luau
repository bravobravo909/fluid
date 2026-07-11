assert(game, "when using vide outside of Roblox, require lib.luau instead")

local vide = require(script.lib)

export type Source<T> = vide.Source<T>
export type Read<T> = vide.Read<T>
export type Can<T> = T | () -> T
export type PropertiesFor<T> = vide.PropertiesFor<T>
export type Instances = vide.Instances

return vide
