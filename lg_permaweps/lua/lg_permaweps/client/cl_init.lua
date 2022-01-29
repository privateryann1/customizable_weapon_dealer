local path = "lg_permaweps/"
if LG_PERMAWEPS.Cfg.Debug then print("[LG PERMAWEPS] Loaded " .. path .. "client/cl_init.lua") end

LG_PERMAWEPS.Col = {}

function LG_PERMAWEPS.RegisterCol(name, r, g, b)
    LG_PERMAWEPS.Col[name] = {}
    for i = 1,255 do
        LG_PERMAWEPS.Col[name][i] = Color(r,g,b,i)
    end
end

function LG_PERMAWEPS.GetCol(name, alpha)
    return LG_PERMAWEPS.Col[name][alpha]
end

local scale = function(num, isY)
    return num * (isY and (ScrH() / 1080) or (ScrW() / 1920))
end

LG_PERMAWEPS.RegisterCol("menu_bg", 26,34,47)
LG_PERMAWEPS.RegisterCol("menu_header", 40,49,66)
LG_PERMAWEPS.RegisterCol("close_button", 166,57,60)
LG_PERMAWEPS.RegisterCol("settings", 55,119,183)
LG_PERMAWEPS.RegisterCol("admin", 220,116,45)
LG_PERMAWEPS.RegisterCol("preview", 32,40,53)

LG_PERMAWEPS.RegisterCol("white", 255,255,255)
LG_PERMAWEPS.RegisterCol("black", 0,0,0)

LG_PERMAWEPS.RegisterCol("yesafford", 26,161,37)
LG_PERMAWEPS.RegisterCol("noafford", 201,32,32)

LG_PERMAWEPS.RegisterCol("confirm_confirm", 58,158,60)
LG_PERMAWEPS.RegisterCol("confirm_cancel", 132,35,54)


function LG_PERMAWEPS.RegisterFont(font, name, weight)
    for i = 1,100 do
        surface.CreateFont(name .. "." .. i, {font = font, size = i, weight = weight or 500})
    end
end

LG_PERMAWEPS.RegisterFont("Arial", "lg_arial")
LG_PERMAWEPS.RegisterFont("Arial", "lg_arial_bold", 600)


hook.Add("OnScreenSizeChanged", "lg_permaweps_update_fonts", function()
    LG_PERMAWEPS.RegisterFont("Arial", "lg_arial")
    LG_PERMAWEPS.RegisterFont("Arial", "lg_arial_bold", 600)
end)