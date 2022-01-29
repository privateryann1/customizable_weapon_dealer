AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("lg_permaweps.npcused")

function ENT:Initialize()
	self:SetModel(LG_PERMAWEPS.Cfg.Mdl)
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetNPCState(NPC_STATE_SCRIPT)
	self:SetSolid(SOLID_BBOX)
	self:CapabilitiesAdd(CAP_TURN_HEAD)
	self:SetUseType(SIMPLE_USE)
	self:DropToFloor()
	self:SetMaxYawSpeed(90)
end

function ENT:AcceptInput(name, activator, caller)
	if name == "Use" and caller:IsPlayer() then
		net.Start("lg_permaweps.npcused", caller)
			net.WriteEntity(self)
		net.Send(caller)
	end
end