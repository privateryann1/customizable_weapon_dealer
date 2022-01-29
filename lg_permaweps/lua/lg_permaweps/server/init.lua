local path = "lg_permaweps/"
if LG_PERMAWEPS.Cfg.Debug then print("[LG PERMAWEPS] Loaded " .. path .. "server/init.lua") end
if not LG_PERMAWEPS.Cfg.Debug and LG_PERMAWEPS then return end -- Prevent auto refresh on the file

LG_PERMAWEPS.Weps = {}
--LG_PERMAWEPS.Data = {}

util.AddNetworkString("lg_permaweps.haswep")
local function sendWeps(ply)
    if not IsValid(ply) then return end
    net.Start("lg_permaweps.haswep")
        if file.Exists( "lg/permaweps/data/" .. ply:SteamID64() .. ".txt" , "DATA" ) then
            local str = string.Explode( "\n", file.Read("lg/permaweps/data/" .. ply:SteamID64() .. ".txt", "DATA") )
            net.WriteString( util.TableToJSON( str ) )
        end
    net.Send(ply)

    net.Start("lg_permaweps.sync")
        net.WriteString(util.TableToJSON(LG_PERMAWEPS.Weps))
    net.Send(ply)
end

net.Receive("lg_permaweps.haswep", function(len,ply)
    //print(ply)
    sendWeps(ply)
end)

local function addWep(data)
    table.insert(LG_PERMAWEPS.Weps, data)
    local name = string.Explode(" ", string.lower(data.name))
    if #name > 1 then
        name = name[1] .. "_" .. name[2]
    else
        name = name[1]
    end
    local str = util.TableToJSON(data)
    local path2 = "lg/permaweps/weps/" .. name .. ".txt"
    file.Write(path2, str)
end

local function modifyWep(id, data)
    local name
    for k,v in pairs(LG_PERMAWEPS.Weps) do
        if v.id == id then
            data = v
            name = string.Explode(" ", string.lower( v.name ))
            break
        end
    end
    if #name > 1 then
        name = name[1] .. "_" .. name[2]
    else
        name = name[1]
    end
    local str = util.TableToJSON(data)
    local path2 = "lg/permaweps/weps/" .. name .. ".txt"
    file.Write(path2, str)
end

local function deleteWep(id)
    local name
    for k,v in pairs(LG_PERMAWEPS.Weps) do
        if v.id == id then
            name = string.Explode(" ", string.lower( v.name ))
            LG_PERMAWEPS.Weps[k] = nil
            break
        end
    end
    if #name > 1 then
        name = name[1] .. "_" .. name[2]
    else
        name = name[1]
    end
    file.Delete( "lg/permaweps/weps/" .. name .. ".txt" )
end

/*

local tbl = LG_PERMAWEPS.Weps

if LG_PERMAWEPS.Cfg.Debug then
    addWep({
        id = #tbl + 1,
        name = "AK-47",
        ent = "weapon_ak472",
        model = "models/weapons/w_rif_ak47.mdl",
        price = 1000,
        discount = 0,
        vipdiscount = 0,
        added = false
    })

    addWep({
        id = #tbl + 1,
        name = "M4A1 Silenced",
        ent = "weapon_ak472",
        model = "models/weapons/w_rif_m4a1_silencer.mdl",
        price = 2000,
        discount = 0,
        vipdiscount = 0,
        added = false
    })

    addWep({
        id = #tbl + 1,
        name = "M249",
        ent = "weapon_ak472",
        model = "models/weapons/w_mach_m249para.mdl",
        price = 3000,
        discount = 0,
        vipdiscount = 0,
        added = false
    })

    addWep({
        id = #tbl + 1,
        name = "AUG",
        ent = "weapon_ak472",
        model = "models/weapons/w_rif_aug.mdl",
        price = 4000,
        discount = 0,
        vipdiscount = 0,
        added = false
    })

    addWep({
        id = #tbl + 1,
        name = "Desert Eagle",
        ent = "weapon_ak472",
        model = "models/weapons/w_pist_deagle.mdl",
        price = 5000,
        discount = 0,
        vipdiscount = 0,
        added = false
    })

    addWep({
        id = #tbl + 1,
        name = "Silenced SMG",
        ent = "weapon_ak472",
        model = "models/weapons/w_smg_tmp.mdl",
        price = 6000,
        discount = 0,
        vipdiscount = 0,
        added = false
    })

    addWep({
        id = #tbl + 1,
        name = "AWP",
        ent = "weapon_pumpshotgun2",
        model = "models/weapons/w_snip_awp.mdl",
        price = 7000,
        discount = 0,
        vipdiscount = 0,
        added = false
    })

    addWep({
        id = #tbl + 1,
        name = "SG550",
        ent = "weapon_ak472",
        model = "models/weapons/w_snip_sg550.mdl",
        price = 8000,
        discount = 0,
        vipdiscount = 0,
        added = false
    })
end
*/

util.AddNetworkString("lg_permaweps.purchasewep")
util.AddNetworkString("lg_permaweps.sync")
util.AddNetworkString("lg_permaweps.addwep")
util.AddNetworkString("lg_permaweps.modifywep")
util.AddNetworkString("lg_permaweps.delwep")

net.Receive("lg_permaweps.sync", function(len,ply)
    net.Start("lg_permaweps.sync")
        net.WriteString(util.TableToJSON(LG_PERMAWEPS.Weps))
    net.Send(ply)
end)

net.Receive("lg_permaweps.addwep", function(len,ply)
    addWep(util.JSONToTable(net.ReadString()))
end)

net.Receive("lg_permaweps.modifywep", function(len,ply)
    modifyWep(net.ReadInt(8), util.JSONToTable(net.ReadString()))
end)

net.Receive("lg_permaweps.delwep", function(len,ply)
    deleteWep(net.ReadInt(8))
end)

local meta = FindMetaTable("Player")

function meta:AddPermaWeapon(id)
    if not file.Exists( "lg/permaweps/data/" .. self:SteamID64() .. ".txt" , "DATA") then
        file.Write( "lg/permaweps/data/" .. self:SteamID64() .. ".txt" , tostring(id) )
    else
        file.Append( "lg/permaweps/data/" .. self:SteamID64() .. ".txt" , "\n" .. tostring(id) )
    end
    sendWeps(self)
end

net.Receive("lg_permaweps.purchasewep", function(len,ply)
    local id = net.ReadInt(8)
    ply:AddPermaWeapon(id)
    for k,v in pairs(LG_PERMAWEPS.Weps) do
        if v.id == id then
            ply:addMoney(-v.price)
            ply:Give( v.ent )
            break
        end
    end
end)

hook.Add("PlayerSpawn", "lg_permaweps_give_perma_weapon", function(ply)
    if file.Exists( "lg/permaweps/data/" .. ply:SteamID64() .. ".txt" , "DATA") then
        local str = string.Explode("\n", file.Read("lg/permaweps/data/" .. ply:SteamID64() .. ".txt", "DATA") )
        for k,v in pairs(str) do
            for key,val in pairs(LG_PERMAWEPS.Weps) do
                if val.id == tonumber(v) then
                    ply:Give( val.ent )
                    break
                end
            end
        end
    end
end)

hook.Add("PlayerInitialSpawn", "lg_send_weps_data", sendWeps)

hook.Add("InitPostEntity", "lg_permaweps_load", function()
    file.CreateDir("lg")
    file.CreateDir("lg/permaweps")
    file.CreateDir("lg/permaweps/weps")
    file.CreateDir("lg/permaweps/data")

    local weps = file.Find("lg/permaweps/weps/*.txt", "DATA")
    --local data = file.Find("lg/permaweps/data/*.txt", "DATA")

    if #weps >= 1 then
        for k,v in pairs(weps) do
            table.insert( LG_PERMAWEPS.Weps, util.JSONToTable( file.Read( "lg/permaweps/weps/" .. v, "DATA" ) ) )
        end
    end

    /*
    if #data >= 1 then
        for k,v in pairs(data) do
            -- data stuff here --
        end
    end
    */
end)