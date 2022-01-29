LG_PERMAWEPS = LG_PERMAWEPS or {}

local path = "lg_permaweps/"

if SERVER then
    AddCSLuaFile(path .. "lg_permaweps_config.lua")
    include(path .. "lg_permaweps_config.lua")
    include(path .. "server/init.lua")
else
    include(path .. "lg_permaweps_config.lua")
    include(path .. "client/cl_init.lua")

    LG_PERMAWEPS.RegisterFont("Arial", "lg_arial")
    LG_PERMAWEPS.RegisterFont("Arial", "lg_arial_bold", 600)
end
