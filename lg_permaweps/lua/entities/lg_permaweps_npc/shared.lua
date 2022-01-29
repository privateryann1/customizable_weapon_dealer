AddCSLuaFile()

ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true

ENT.Category = "[LG]"
ENT.PrintName = "Perma Weapons NPC"
ENT.Author = "Private Ryan"

function ENT:SetAutomaticFrameAdvance(bUsingAnim)
	self.AutomaticFrameAdvance = bUsingAnim
end