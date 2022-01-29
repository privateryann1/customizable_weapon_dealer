include("shared.lua")
include("lg_permaweps/lg_permaweps_config.lua")

local weps_tbl = {}
local weps_temp = {}
local active_frames = {}
local owned_weps = {}

net.Receive("lg_permaweps.haswep", function(len,ply)
    table.Empty(owned_weps)
    table.Add(owned_weps, util.JSONToTable( net.ReadString() ) )
end)

net.Start("lg_permaweps.haswep")
net.SendToServer()

local function sync()
    net.Start("lg_permaweps.sync")
    net.SendToServer()

    net.Receive("lg_permaweps.sync", function(len,ply)
        weps_tbl = util.JSONToTable(net.ReadString())
    end)
end
sync()

local function closeActiveFrames() -- Delete any unused popups
    for k,v in pairs(active_frames) do
        if IsValid(v) then v:Remove() end
    end
end

local function addWep(data)
    net.Start("lg_permaweps.addwep")
        net.WriteString(util.TableToJSON(data))
    net.SendToServer()
    timer.Simple(0, function() sync() end)
end

local function modifyWep(id, data)
    net.Start("lg_permaweps.modifywep")
        net.WriteInt(id,8)
        net.WriteString(util.TableToJSON(data))
    net.SendToServer()
    timer.Simple(0, function() sync() end)
end

local function deleteWep(id)
    net.Start("lg_permaweps.delwep")
        net.WriteInt(id,8)
    net.SendToServer()
    timer.Simple(0, function() sync() end)
end

local function purchaseWep(id)
    net.Start("lg_permaweps.purchasewep")
        net.WriteInt(id, 8)
    net.SendToServer()
end

local function isWepsValid(data)
    for k,v in pairs(data) do
        for i, wep in pairs(v) do
            if ( isstring(wep) && #wep < 1 ) then return false end
        end
    end
    return true
end

local function delInvalid(data)
    for k,v in pairs(data) do
        if ( isstring(v) && #v < 1 ) then
            deleteWep(v.id)
            break
        elseif ( !IsValid(v) ) then
            deleteWep(v.id)
            break
        end
    end
end

function ENT:Draw()
    self:DrawModel()
    entpos = self:GetPos()
    local Pos = self:GetPos() + self:GetUp() * 80
    Pos = Pos + self:GetUp() * math.abs(math.sin(CurTime()) * 1)
    local Ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)  
    if LocalPlayer():GetPos():Distance( self:GetPos() ) > 300 then return end
    cam.Start3D2D(Pos, Ang, 0.1)
    	draw.SimpleTextOutlined("Permanent Weapons", "lg_arial.50", -5, 39, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, LG_PERMAWEPS.GetCol("black", 255))
    cam.End3D2D()
end

local round = 6

net.Receive("lg_permaweps.npcused", function(len,ply)
    local visible = true
    if !table.IsEmpty(weps_tbl) then
        for k,v in pairs(weps_tbl) do
            v.added = false
        end
    end
    sync()
    local frame = vgui.Create("DFrame")
    table.insert(active_frames, frame)
    frame:SetSize(ScrW() * 0.665, ScrH() * 0.72)
    frame:SetPos(-frame:GetWide() - 1, ScrH() / 2 - frame:GetTall() / 2)
    frame:MoveTo(ScrW() / 2 - frame:GetWide() / 2, ScrH() / 2 - frame:GetTall() / 2, 1, 0, -1)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame.Paint = function(self,w,h)
        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_bg", 255))
        draw.RoundedBoxEx(round,0,0,w,frame:GetTall() * 0.035,LG_PERMAWEPS.GetCol("menu_header", 255),true,true,false,false)

        draw.SimpleText("Permanent Weapons Shop", "lg_arial.20", frame:GetWide() * 0.01,frame:GetTall() * 0.035 / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
    end

    if !isWepsValid(weps_tbl) && !table.IsEmpty(weps_tbl) then
        delInvalid(weps_tbl)
        frame:Close()
        LocalPlayer():ChatPrint("Invalid weapon(s) found. They have been removed.")
    end

    /*
    local settings = vgui.Create("DButton", frame)
    settings:SetSize(frame:GetWide() * 0.06, frame:GetTall() * 0.035)
    settings:SetPos(frame:GetWide() * 0.905)
    settings:SetText("")
    settings.Paint = function(self,w,h)
        draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("settings", 255), false,false,false,false)
        draw.SimpleText("Settings", "lg_arial.20", settings:GetWide() / 2, settings:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
    end
    */

    local admin

    if LocalPlayer():IsSuperAdmin() then
        admin = vgui.Create("DButton", frame)
        admin:SetSize(frame:GetWide() * 0.055, frame:GetTall() * 0.035)
        admin:SetPos(frame:GetWide() * 0.91)
        admin:SetText("")
        admin.Paint = function(self,w,h)
            draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("admin", 255), false,false,false,false)
            draw.SimpleText("Admin", "lg_arial.20", admin:GetWide() / 2, admin:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
        end
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(frame:GetWide() * 0.04, frame:GetTall() * 0.035)
    close:SetPos(frame:GetWide() * 0.9622)
    close:SetText("")
    close.Paint = function(self,w,h)
        draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("close_button", 255), false,true,false,false)
        draw.SimpleText("X", "lg_arial.20", close:GetWide() / 2, close:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
    end
    close.DoClick = function()
        frame:Remove()
        closeActiveFrames()
    end

    local function toggleVisible()
        if visible then
            frame:SetVisible(false)
            visible = false
        else
            frame:SetVisible(true)
            visible = true
        end
    end


    function populateShop()
        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(ScrW() * 0.00520833333, ScrW() * 0.00520833333, ScrW() * 0.00520833333, ScrW() * 0.00520833333)
        local sbar = scroll:GetVBar()
        function sbar:Paint() end
        function sbar.btnUp:Paint() end
        function sbar.btnDown:Paint() end
        function sbar.btnGrip:Paint() end
        local grid = scroll:Add("DGrid")
        grid:Dock(TOP)
        grid:SetCols(4)
        grid:SetColWide(ScrW() * 0.164)
        grid:SetRowHeight(ScrH() * 0.289956)
        for k,v in pairs(weps_tbl) do
            local but = vgui.Create("DButton")
            but:SetText("")
            but:SetSize(ScrW() * 0.1586,ScrH() * 0.281956)
            but.Paint = function(self,w,h)
                draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
            end
            local model = vgui.Create("DModelPanel", but)
            model:SetSize(but:GetWide() * 1.5, but:GetTall())
            model:SetModel(v.model)
            model:SetCamPos(Vector(20, 50, 15))
            model:SetLookAt(Vector(-10, 5, 5))
            function model:LayoutEntity(ent) return end
            local canAfford
            if tonumber( LocalPlayer():getDarkRPVar("money") ) < tonumber( v.price ) then canAfford = false else canAfford = true end
            local overlay = vgui.Create("DPanel", but)
            overlay.active = false
            overlay:Dock(FILL)
            overlay:SetMouseInputEnabled(false)
            overlay.Paint = function(slf,w,h)
                if overlay.active then
                    draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("black", 100))
                    draw.SimpleTextOutlined(v.name, "lg_arial.20", but:GetWide() / 2, but:GetTall() / 2.1, LG_PERMAWEPS.GetCol("white", 255), 1, 1, 1, LG_PERMAWEPS.GetCol("black", 255))
                    if canAfford then
                        draw.SimpleTextOutlined(LG_PERMAWEPS.Cfg.Currency .. v.price, "lg_arial.25", but:GetWide() / 2, but:GetTall() / 1.8, LG_PERMAWEPS.GetCol("yesafford", 255), 1, 1, 1, LG_PERMAWEPS.GetCol("black", 255))
                    else
                        draw.SimpleTextOutlined(LG_PERMAWEPS.Cfg.Currency .. v.price, "lg_arial.25", but:GetWide() / 2, but:GetTall() / 1.8, LG_PERMAWEPS.GetCol("noafford", 255), 1, 1, 1, LG_PERMAWEPS.GetCol("black", 255))
                    end
                end
            end
            function model:Think()
                if self:IsHovered() and !overlayactive then
                    overlay.active = true
                else
                    overlay.active = false
                end
            end
            if !table.IsEmpty(owned_weps) and table.HasValue(owned_weps, tostring(v.id)) then
                local disabled = vgui.Create("DPanel", but)
                disabled:Dock(FILL)
                disabled:SetMouseInputEnabled(true)
                disabled.Paint = function(slf,w,h)
                    draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("black", 100))
                    draw.SimpleTextOutlined("Owned", "lg_arial.30", but:GetWide() / 2, but:GetTall() / 2, LG_PERMAWEPS.GetCol("noafford", 255), 1, 1, 1, LG_PERMAWEPS.GetCol("black", 255))
                end
            end
            model.DoClick = function()
                if !canAfford then
                    chat.AddText(Color(133,134,143) , "[",Color(80,200,121),"LG", Color(133,134,143), "] ", Color(255,255,255), "Permaweps: ", "You cannot afford that weapon.")
                    return
                end
                toggleVisible()
                local confirmation_text = "Please confirm that you're purchasing (" .. v.name .. ") for " .. LG_PERMAWEPS.Cfg.Currency .. v.price
                textSize = string.len(confirmation_text)
                local confirmation_frame = vgui.Create("DFrame")
                confirmation_frame:SetSize(ScrW() * 0.25 + textSize * ScrW() * 0.0009, ScrH() * 0.12)
                confirmation_frame:Center()
                confirmation_frame:MakePopup()
                confirmation_frame:SetDraggable(false)
                confirmation_frame:ShowCloseButton(false)
                confirmation_frame:SetTitle("")
                confirmation_frame.Paint = function(self,w,h)
                    draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_bg", 255))
                    draw.RoundedBoxEx(round,0,0,w,frame:GetTall() * 0.035,LG_PERMAWEPS.GetCol("menu_header", 255),true,true,false,false)
                    draw.SimpleText("Confirm Purchase", "lg_arial.20", frame:GetWide() * 0.01,frame:GetTall() * 0.035 / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                    draw.SimpleText(confirmation_text, "lg_arial.20", confirmation_frame:GetWide() / 2,confirmation_frame:GetTall() / 2 - confirmation_frame:GetTall() * 0.03, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end
                local confirmation_frame_close = vgui.Create("DButton", confirmation_frame)
                confirmation_frame_close:SetSize(confirmation_frame:GetWide() * 0.1, frame:GetTall() * 0.035)
                confirmation_frame_close:SetPos(confirmation_frame:GetWide() * 0.903)
                confirmation_frame_close:SetText("")
                confirmation_frame_close.Paint = function(self,w,h)
                    draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("close_button", 255), false,true,false,false)
                    draw.SimpleText("X", "lg_arial.20", confirmation_frame_close:GetWide() / 2, confirmation_frame_close:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end
                confirmation_frame_close.DoClick = function()
                    confirmation_frame:Remove()
                    closeActiveFrames()
                end
                confirmation_frame_confirm = vgui.Create("DButton", confirmation_frame)
                confirmation_frame_confirm:SetSize(confirmation_frame:GetWide() / 2, confirmation_frame:GetTall() * 0.25)
                confirmation_frame_confirm:SetPos(0, confirmation_frame:GetTall() - confirmation_frame_confirm:GetTall())
                confirmation_frame_confirm:SetText("")
                confirmation_frame_confirm.Paint = function(self,w,h)
                    draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("confirm_confirm", 255), false, false, true, false)
                    draw.SimpleText("Confirm", "lg_arial.25", confirmation_frame_confirm:GetWide() / 2, confirmation_frame_confirm:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end
                confirmation_frame_confirm.DoClick = function()
                    purchaseWep(v.id)
                    confirmation_frame:Remove()
                    closeActiveFrames()
                end
                confirmation_frame_cancel = vgui.Create("DButton", confirmation_frame)
                confirmation_frame_cancel:SetSize(confirmation_frame:GetWide() / 1.99, confirmation_frame:GetTall() * 0.25)
                confirmation_frame_cancel:SetPos(confirmation_frame:GetWide() / 2, confirmation_frame:GetTall() - confirmation_frame_cancel:GetTall())
                confirmation_frame_cancel:SetText("")
                confirmation_frame_cancel.Paint = function(self,w,h)
                    draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("confirm_cancel", 255), false, false, false, true)
                    draw.SimpleText("Cancel", "lg_arial.25", confirmation_frame_cancel:GetWide() / 2, confirmation_frame_cancel:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end
                confirmation_frame_cancel.DoClick = function()
                    confirmation_frame:Remove()
                    toggleVisible()
                end
            end
            grid:AddItem(but)
        end
    end
    populateShop()


    /*
    settings.DoClick = function()
        toggleVisible()
        settings_frame = vgui.Create("DFrame")
        table.insert(active_frames, settings_frame)
        settings_frame:SetSize(ScrW() * 0.3, ScrH() * 0.6)
        settings_frame:Center()
        settings_frame:MakePopup()
        settings_frame:SetDraggable(false)
        settings_frame:ShowCloseButton(false)
        settings_frame:SetTitle("")
        settings_frame.Paint = function(self,w,h)
            draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_bg", 255))
            draw.RoundedBoxEx(round,0,0,w,frame:GetTall() * 0.035,LG_PERMAWEPS.GetCol("menu_header", 255),true,true,false,false)
            draw.SimpleText("Settings", "lg_arial.20", frame:GetWide() * 0.01,frame:GetTall() * 0.035 / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
        end

        local settings_close = vgui.Create("DButton", settings_frame)
        settings_close:SetSize(settings_frame:GetWide() * 0.08, frame:GetTall() * 0.035)
        settings_close:SetPos(settings_frame:GetWide() * 0.923)
        settings_close:SetText("")
        settings_close.Paint = function(self,w,h)
            draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("close_button", 255), false,true,false,false)
            draw.SimpleText("X", "lg_arial.20", settings_close:GetWide() / 2, settings_close:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
        end
        settings_close.DoClick = function()
            settings_frame:Remove()
            closeActiveFrames()
        end

        local back = vgui.Create("DButton", settings_frame)
        back:SetSize(settings_frame:GetWide() * 0.085, frame:GetTall() * 0.035)
        back:SetPos(settings_frame:GetWide() * 0.84)
        back:SetText("")
        back.Paint = function(self,w,h)
            draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("settings", 255), false,false,false,false)
            draw.SimpleText("Back", "lg_arial.20", back:GetWide() / 2, back:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
        end
        back.DoClick = function()
            toggleVisible()
            settings_frame:Remove()
        end
    end
    */

    if LocalPlayer():IsSuperAdmin() and IsValid(admin) and ispanel(admin) then
        admin.DoClick = function()
            toggleVisible()
            adminvisible = true
            admin_frame = vgui.Create("DFrame")
            table.insert(active_frames, admin_frame)
            admin_frame:SetSize(ScrW() * 0.3, ScrH() * 0.2)
            admin_frame:Center()
            admin_frame:MakePopup()
            admin_frame:SetDraggable(false)
            admin_frame:ShowCloseButton(false)
            admin_frame:SetTitle("")
            admin_frame.Paint = function(self,w,h)
                draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_bg", 255))
                draw.RoundedBoxEx(round,0,0,w,frame:GetTall() * 0.035,LG_PERMAWEPS.GetCol("menu_header", 255),true,true,false,false)
                draw.SimpleText("Administration Panel", "lg_arial.20", frame:GetWide() * 0.01,frame:GetTall() * 0.035 / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)

                draw.SimpleText("Create and modify the weapons in the shop", "lg_arial.18", frame:GetWide() * 0.03, admin_frame:GetTall() * 0.34, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                draw.SimpleText("Add or remove weapons from players", "lg_arial.18", frame:GetWide() * 0.03, admin_frame:GetTall() * 0.77, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
            end

            local weps = vgui.Create("DButton", admin_frame)
            weps:SetSize(admin_frame:GetWide() * 0.225, admin_frame:GetTall() * 0.275)
            weps:SetPos(admin_frame:GetWide() * 0.7, admin_frame:GetTall() * 0.2)
            weps:SetText("")
            weps.Paint = function(self,w,h)
                draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                draw.SimpleText("View Weapons", "lg_arial.20", weps:GetWide() / 2,weps:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
            end

            local plys = vgui.Create("DButton", admin_frame)
            plys:SetSize(admin_frame:GetWide() * 0.225, admin_frame:GetTall() * 0.275)
            plys:SetPos(admin_frame:GetWide() * 0.7, admin_frame:GetTall() * 0.65)
            plys:SetText("")
            plys.Paint = function(self,w,h)
                draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                draw.SimpleText("View Players", "lg_arial.20", plys:GetWide() / 2,plys:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
            end

            local admin_close = vgui.Create("DButton", admin_frame)
            admin_close:SetSize(admin_frame:GetWide() * 0.08, frame:GetTall() * 0.035)
            admin_close:SetPos(admin_frame:GetWide() * 0.923)
            admin_close:SetText("")
            admin_close.Paint = function(self,w,h)
                draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("close_button", 255), false,true,false,false)
                draw.SimpleText("X", "lg_arial.20", admin_close:GetWide() / 2, admin_close:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
            end
            admin_close.DoClick = function()
                admin_frame:Remove()
                closeActiveFrames()
            end

            local shop = vgui.Create("DButton", admin_frame)
            shop:SetSize(admin_frame:GetWide() * 0.085, frame:GetTall() * 0.035)
            shop:SetPos(admin_frame:GetWide() * 0.84)
            shop:SetText("")
            shop.Paint = function(self,w,h)
                draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("settings", 255), false,false,false,false)
                draw.SimpleText("Back", "lg_arial.20", shop:GetWide() / 2, shop:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
            end
            shop.DoClick = function()
                toggleVisible()
                admin_frame:Remove()
            end

            local function toggleAdminVisible()
                if adminvisible then
                    admin_frame:SetVisible(false)
                    adminvisible = false
                else
                    admin_frame:SetVisible(true)
                    adminvisible = true
                end
            end

            weps.DoClick = function()
                toggleAdminVisible()
                weps_visible = true
                weps_frame = vgui.Create("DFrame")
                table.insert(active_frames, weps_frame)
                weps_frame:SetSize(ScrW() * 0.3, ScrH() * 0.6)
                weps_frame:Center()
                weps_frame:MakePopup()
                weps_frame:SetDraggable(false)
                weps_frame:ShowCloseButton(false)
                weps_frame:SetTitle("")
                weps_frame.Paint = function(self,w,h)
                    draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_bg", 255))
                    draw.RoundedBoxEx(round,0,0,w,frame:GetTall() * 0.035,LG_PERMAWEPS.GetCol("menu_header", 255),true,true,false,false)
                    draw.SimpleText("Weapons Configuration", "lg_arial.20", frame:GetWide() * 0.01,frame:GetTall() * 0.035 / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                end

                local weps_close = vgui.Create("DButton", weps_frame)
                weps_close:SetSize(weps_frame:GetWide() * 0.08, frame:GetTall() * 0.035)
                weps_close:SetPos(weps_frame:GetWide() * 0.923)
                weps_close:SetText("")
                weps_close.Paint = function(self,w,h)
                    draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("close_button", 255), false,true,false,false)
                    draw.SimpleText("X", "lg_arial.20", weps_close:GetWide() / 2, weps_close:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end
                weps_close.DoClick = function()
                    weps_frame:Remove()
                    closeActiveFrames()
                end

                local weps_back = vgui.Create("DButton", weps_frame)
                weps_back:SetSize(weps_frame:GetWide() * 0.085, frame:GetTall() * 0.035)
                weps_back:SetPos(weps_frame:GetWide() * 0.84)
                weps_back:SetText("")
                weps_back.Paint = function(self,w,h)
                    draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("settings", 255), false,false,false,false)
                    draw.SimpleText("Back", "lg_arial.20", weps_back:GetWide() / 2, weps_back:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end
                weps_back.DoClick = function()
                    toggleAdminVisible()
                    weps_frame:Remove()
                    if !table.IsEmpty(weps_tbl) then
                        for k,v in pairs(weps_tbl) do
                            v.added = false
                        end
                    end
                end

                local scroll = vgui.Create("DScrollPanel", weps_frame)
                scroll:Dock(FILL)
                scroll:DockMargin(weps_frame:GetWide() * 0.01736, weps_frame:GetWide() * 0.11, weps_frame:GetWide() * 0.0173565, weps_frame:GetWide() * 0.015)
                scroll.Paint = function(self,w,h)
                    --draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255), true,true,false,false)
                end

                local function populateWeps()
                    if !table.IsEmpty(weps_temp) then for k,v in pairs(weps_temp) do v:Remove(); weps_temp = {} end end -- Removes all previous weapon buttons to prevent duplicates
                    if !table.IsEmpty(weps_tbl) then
                        for k,v in pairs(weps_tbl) do
                            local but = scroll:Add("DButton")
                            table.insert(weps_temp, but)
                            but.data = v
                            but:SetText("")
                            but:Dock(TOP)
                            but:SetTall(ScrH() * 0.07)
                            but:DockMargin(0,0,0,5)
                            but.Paint = function(self,w,h)
                                draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                                draw.RoundedBoxEx(round,0,0,but:GetWide() * 0.17,h,LG_PERMAWEPS.GetCol("preview", 255), true,false,true,false)
                                draw.SimpleText(v.name, "lg_arial.22", but:GetWide() * 0.2, but:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                            end
                            local model = vgui.Create("DModelPanel", but)
                            model:SetSize(but:GetWide() * 1.5, but:GetTall())
                            model:SetModel(v.model)
                            model:SetCamPos(Vector(0, 40, 10))
                            model:SetLookAt(Vector(0, 0, 5))
                            function model:LayoutEntity(ent) return end

                            but.DoClick = function()
                                if weps_visible then
                                    weps_frame:SetVisible(false)
                                    weps_visible = false
                                else
                                    timer.Simple(0, function()
                                        weps_frame:SetVisible(true)
                                        weps_visible = true
                                    end)
                                end
                                lg_wepConfigurator(but.data)
                            end

                        end
                    end
                end
                populateWeps()

                local weps_new = vgui.Create("DButton", weps_frame)
                weps_new:SetSize(weps_frame:GetWide() * 0.2, weps_frame:GetTall() * 0.06)
                weps_new:SetPos(weps_frame:GetWide() * 0.025, weps_frame:GetTall() * 0.07)
                weps_new:SetText("")
                weps_new.Paint = function(self,w,h)
                    draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                    draw.SimpleText("New", "lg_arial.20", weps_new:GetWide() / 2, weps_new:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end

                local weps_search = vgui.Create("DTextEntry", weps_frame)
                weps_search:SetSize(weps_frame:GetWide() * 0.725, weps_frame:GetTall() * 0.06)
                weps_search:SetPos(weps_frame:GetWide() * 0.25, weps_frame:GetTall() * 0.07)
                weps_search:SetTextColor(Color(255,255,255))
                weps_search:SetEditable(true)
                weps_search.AllowInput = function()
                    return weps_search.allowed or false
                end
                function weps_search:OnChange()
                    if string.len(weps_search:GetValue()) > 30 then
                        weps_search.allowed = true
                        return
                    else
                        weps_search.allowed = false
                        weps_search.txt = weps_search:GetValue()
                    end
                end
                weps_search.Paint = function(self,w,h)
                    draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                    draw.SimpleText(weps_search.txt or "Search (Not working)", "lg_arial.20", weps_search:GetWide() / 2,weps_search:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end

                local function toggleWepsVisibility()
                    if weps_visible then
                        weps_frame:SetVisible(false)
                        weps_visible = false
                    else
                        populateWeps()
                        timer.Simple(0, function()
                            weps_frame:SetVisible(true)
                            weps_visible = true
                        end)
                    end
                end

                function lg_wepConfigurator(data)
                    local new_wep_frame = vgui.Create("DFrame")
                    table.insert(active_frames, new_wep_frame)
                    new_wep_frame:SetSize(ScrW() * 0.3, ScrH() * 0.25)
                    new_wep_frame:Center()
                    new_wep_frame:MakePopup()
                    new_wep_frame:SetDraggable(false)
                    new_wep_frame:ShowCloseButton(false)
                    new_wep_frame:SetTitle("")
                    new_wep_frame.Paint = function(self,w,h)
                        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_bg", 255))
                        draw.RoundedBoxEx(round,0,0,w,frame:GetTall() * 0.035,LG_PERMAWEPS.GetCol("menu_header", 255),true,true,false,false)
                        if data then
                            draw.SimpleText("Modify Weapon", "lg_arial.20", frame:GetWide() * 0.01,frame:GetTall() * 0.035 / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                        else
                            draw.SimpleText("New Weapon", "lg_arial.20", frame:GetWide() * 0.01,frame:GetTall() * 0.035 / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                        end
                        draw.SimpleText("Weapon Name", "lg_arial.20", ScrW() * 0.01, ScrH() * 0.054, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                        draw.SimpleText("Weapon Entity", "lg_arial.20", ScrW() * 0.01, ScrH() * 0.0935, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                        draw.SimpleText("Weapon Model", "lg_arial.20", ScrW() * 0.01, ScrH() * 0.133, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                        draw.SimpleText("Weapon Price", "lg_arial.20", ScrW() * 0.01, ScrH() * 0.1725, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                        //draw.SimpleText("Discount", "lg_arial.20", ScrW() * 0.01, ScrH() * 0.212, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                       // draw.SimpleText("VIP Discount", "lg_arial.20", ScrW() * 0.01, ScrH() * 0.2515, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                    end

                    local new_wep_close = vgui.Create("DButton", new_wep_frame)
                    new_wep_close:SetSize(new_wep_frame:GetWide() * 0.08, frame:GetTall() * 0.035)
                    new_wep_close:SetPos(new_wep_frame:GetWide() * 0.923)
                    new_wep_close:SetText("")
                    new_wep_close.Paint = function(self,w,h)
                        draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("close_button", 255), false,true,false,false)
                        draw.SimpleText("X", "lg_arial.20", new_wep_close:GetWide() / 2, new_wep_close:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end
                    new_wep_close.DoClick = function()
                        new_wep_frame:Remove()
                        closeActiveFrames()
                    end

                    local new_wep_back = vgui.Create("DButton", new_wep_frame)
                    new_wep_back:SetSize(new_wep_frame:GetWide() * 0.085, frame:GetTall() * 0.035)
                    new_wep_back:SetPos(new_wep_frame:GetWide() * 0.84)
                    new_wep_back:SetText("")
                    new_wep_back.Paint = function(self,w,h)
                        draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("settings", 255), false,false,false,false)
                        draw.SimpleText("Back", "lg_arial.20", new_wep_back:GetWide() / 2, new_wep_back:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end
                    new_wep_back.DoClick = function()
                        toggleWepsVisibility()
                        new_wep_frame:Remove()
                        if !table.IsEmpty(weps_tbl) then
                            for k,v in pairs(weps_tbl) do
                                v.added = false
                            end
                        end
                    end

                    local new_wep_name = vgui.Create("DTextEntry", new_wep_frame)
                    new_wep_name:SetSize(ScrW() * 0.2, ScrH() * 0.03)
                    new_wep_name:SetPos(ScrW() * 0.09, ScrH() * 0.04)
                    new_wep_name:SetTextColor(Color(255,255,255))
                    new_wep_name:SetEditable(true)
                    if data then new_wep_name:SetValue(data.name); new_wep_name.txt = new_wep_name:GetValue() end
                    function new_wep_name:OnChange()
                        new_wep_name.txt = new_wep_name:GetValue()
                    end
                    new_wep_name.Paint = function(self,w,h)
                        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                        draw.SimpleText(new_wep_name.txt or "", "lg_arial.20", new_wep_name:GetWide() / 2,new_wep_name:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end

                    local new_wep_ent = vgui.Create("DTextEntry", new_wep_frame)
                    new_wep_ent:SetSize(ScrW() * 0.2, ScrH() * 0.03)
                    new_wep_ent:SetPos(ScrW() * 0.09, ScrH() * 0.08)
                    new_wep_ent:SetTextColor(Color(255,255,255))
                    new_wep_ent:SetEditable(true)
                    if data then new_wep_ent:SetValue(data.ent); new_wep_ent.txt = new_wep_ent:GetValue() end
                    function new_wep_ent:OnChange()
                        new_wep_ent.txt = new_wep_ent:GetValue()
                    end
                    new_wep_ent.Paint = function(self,w,h)
                        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                        draw.SimpleText(new_wep_ent.txt or "", "lg_arial.20", new_wep_ent:GetWide() / 2,new_wep_ent:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end

                    local new_wep_mdl = vgui.Create("DTextEntry", new_wep_frame)
                    new_wep_mdl:SetSize(ScrW() * 0.2, ScrH() * 0.03)
                    new_wep_mdl:SetPos(ScrW() * 0.09, ScrH() * 0.12)
                    new_wep_mdl:SetTextColor(Color(255,255,255))
                    new_wep_mdl:SetEditable(true)
                    if data then new_wep_mdl:SetValue(data.model); new_wep_mdl.txt = new_wep_mdl:GetValue() end
                    function new_wep_mdl:OnChange()
                        new_wep_mdl.txt = new_wep_mdl:GetValue()
                    end
                    new_wep_mdl.Paint = function(self,w,h)
                        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                        draw.SimpleText(new_wep_mdl.txt or "", "lg_arial.20", new_wep_mdl:GetWide() / 2,new_wep_mdl:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end

                    local new_wep_price = vgui.Create("DTextEntry", new_wep_frame)
                    new_wep_price:SetSize(ScrW() * 0.2, ScrH() * 0.03)
                    new_wep_price:SetPos(ScrW() * 0.09, ScrH() * 0.16)
                    new_wep_price:SetTextColor(Color(255,255,255))
                    new_wep_price:SetEditable(true)
                    if data then new_wep_price:SetValue(data.price); new_wep_price.txt = new_wep_price:GetValue() end
                    function new_wep_price:OnChange()
                        new_wep_price.txt = new_wep_price:GetValue()
                    end
                    new_wep_price.Paint = function(self,w,h)
                        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                        draw.SimpleText(new_wep_price.txt or "", "lg_arial.20", new_wep_price:GetWide() / 2,new_wep_price:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end

                    --[[
                    local new_wep_discount = vgui.Create("DTextEntry", new_wep_frame)
                    new_wep_discount:SetSize(ScrW() * 0.2, ScrH() * 0.03)
                    new_wep_discount:SetPos(ScrW() * 0.09, ScrH() * 0.2)
                    new_wep_discount:SetTextColor(Color(255,255,255))
                    new_wep_discount:SetEditable(true)
                    if data then new_wep_discount:SetValue(data.discount); new_wep_discount.txt = new_wep_discount:GetValue() end
                    function new_wep_discount:OnChange()
                        new_wep_discount.txt = new_wep_discount:GetValue()
                    end
                    new_wep_discount.Paint = function(self,w,h)
                        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                        draw.SimpleText(new_wep_discount.txt or "", "lg_arial.20", new_wep_discount:GetWide() / 2,new_wep_discount:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end

                    local new_wep_vip_discount = vgui.Create("DTextEntry", new_wep_frame)
                    new_wep_vip_discount:SetSize(ScrW() * 0.2, ScrH() * 0.03)
                    new_wep_vip_discount:SetPos(ScrW() * 0.09, ScrH() * 0.24)
                    new_wep_vip_discount:SetTextColor(Color(255,255,255))
                    new_wep_vip_discount:SetEditable(true)
                    if data then new_wep_vip_discount:SetValue(data.vipdiscount); new_wep_vip_discount.txt = new_wep_vip_discount:GetValue() end
                    function new_wep_vip_discount:OnChange()
                        new_wep_vip_discount.txt = new_wep_vip_discount:GetValue()
                    end
                    new_wep_vip_discount.Paint = function(self,w,h)
                        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                        draw.SimpleText(new_wep_vip_discount.txt or "", "lg_arial.20", new_wep_vip_discount:GetWide() / 2,new_wep_vip_discount:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end
                    ]]

                    if data then
                        local del = vgui.Create("DButton", new_wep_frame)
                        del:SetSize(ScrW() * 0.095, ScrH() * 0.03)
                        del:SetPos(new_wep_frame:GetWide() * 0.65, ScrH() * 0.203)
                        del:SetText("")
                        del.Paint = function(self,w,h)
                            draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                            draw.SimpleText("Delete", "lg_arial.20", del:GetWide() / 2,del:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                        end
                        del.DoClick = function()
                            deleteWep(data.id)
                            timer.Simple(0, function()
                                new_wep_frame:Remove()
                                toggleWepsVisibility()
                            end)
                        end
                    end

                    local save = vgui.Create("DButton", new_wep_frame)
                    if data then
                        save:SetSize(ScrW() * 0.1, ScrH() * 0.03)
                    else
                        save:SetSize(ScrW() * 0.2, ScrH() * 0.03)
                    end
                    if data then
                        save:SetPos(new_wep_frame:GetWide() * 0.3, ScrH() * 0.203)
                    else
                        save:SetPos(new_wep_frame:GetWide() / 2 - save:GetWide() / 2, ScrH() * 0.203)
                    end
                    save:SetText("")
                    save.Paint = function(self,w,h)
                        draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_header", 255))
                        draw.SimpleText("Save", "lg_arial.20", save:GetWide() / 2,save:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                    end
                    save.DoClick = function()
                        if data then
                            modifyWep(data.id, {
                                id = data.id,
                                name = new_wep_name:GetValue() or "AK-47",
                                ent = new_wep_ent:GetValue() or "weapon_ak472",
                                model = new_wep_mdl:GetValue() or "models/weapons/w_rif_ak47.mdl",
                                price = new_wep_price:GetValue() or 1000,
                            })
                        else
                            addWep({
                                id = #weps_tbl + 1,
                                name = new_wep_name:GetValue() or "AK-47",
                                ent = new_wep_ent:GetValue() or "weapon_ak472",
                                model = new_wep_mdl:GetValue() or "models/weapons/w_rif_ak47.mdl",
                                price = new_wep_price:GetValue() or 1000,
                            })
                        end

                        timer.Simple(0, function()
                            new_wep_frame:Remove()
                            toggleWepsVisibility()
                        end)
                    end
                end

                weps_new.DoClick = function()
                    toggleWepsVisibility()
                    lg_wepConfigurator()
                end
            end

            plys.DoClick = function()
                toggleAdminVisible()
                plys_frame = vgui.Create("DFrame")
                table.insert(active_frames, plys_frame)
                plys_frame:SetSize(ScrW() * 0.3, ScrH() * 0.6)
                plys_frame:Center()
                plys_frame:MakePopup()
                plys_frame:SetDraggable(false)
                plys_frame:ShowCloseButton(false)
                plys_frame:SetTitle("")
                plys_frame.Paint = function(self,w,h)
                    draw.RoundedBox(round,0,0,w,h,LG_PERMAWEPS.GetCol("menu_bg", 255))
                    draw.RoundedBoxEx(round,0,0,w,frame:GetTall() * 0.035,LG_PERMAWEPS.GetCol("menu_header", 255),true,true,false,false)
                    draw.SimpleText("Players Configuration", "lg_arial.20", frame:GetWide() * 0.01,frame:GetTall() * 0.035 / 2, LG_PERMAWEPS.GetCol("white", 255), TEXT_ALIGN_LEFT, 1)
                end

                local plys_close = vgui.Create("DButton", plys_frame)
                plys_close:SetSize(plys_frame:GetWide() * 0.08, frame:GetTall() * 0.035)
                plys_close:SetPos(plys_frame:GetWide() * 0.923)
                plys_close:SetText("")
                plys_close.Paint = function(self,w,h)
                    draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("close_button", 255), false,true,false,false)
                    draw.SimpleText("X", "lg_arial.20", plys_close:GetWide() / 2, plys_close:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end
                plys_close.DoClick = function()
                    plys_frame:Remove()
                    closeActiveFrames()
                end

                local plys_back = vgui.Create("DButton", plys_frame)
                plys_back:SetSize(plys_frame:GetWide() * 0.085, frame:GetTall() * 0.035)
                plys_back:SetPos(plys_frame:GetWide() * 0.84)
                plys_back:SetText("")
                plys_back.Paint = function(self,w,h)
                    draw.RoundedBoxEx(round,0,0,w,h,LG_PERMAWEPS.GetCol("settings", 255), false,false,false,false)
                    draw.SimpleText("Back", "lg_arial.20", plys_back:GetWide() / 2, plys_back:GetTall() / 2, LG_PERMAWEPS.GetCol("white", 255), 1, 1)
                end
                plys_back.DoClick = function()
                    toggleAdminVisible()
                    plys_frame:Remove()
                end
            end
        end
    end
end)