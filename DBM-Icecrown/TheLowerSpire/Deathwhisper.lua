local mod	= DBM:NewMod("Deathwhisper", "DBM-Icecrown", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 1799 $"):sub(12, -3))
mod:SetCreatureID(36855)
mod:SetUsedIcons(5, 6, 7)
mod:RegisterCombat("yell", L.YellPull)

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_AURA_REMOVED",
	"SPELL_CAST_START",
	"CHAT_MSG_MONSTER_YELL"
)

local warnAddsSoon					= mod:NewAnnounce("WarnAddsSoon", 3)
local warnDominateMind				= mod:NewTargetAnnounce(71289, 3)
local warnDeathDecay				= mod:NewSpellAnnounce(72108, 2)
local warnReanimating				= mod:NewAnnounce("WarnReanimating", 3)
local warnDarkTransformation		= mod:NewSpellAnnounce(70900, 4)
local warnDarkEmpowerment			= mod:NewSpellAnnounce(70901, 4)
local warnPhase2					= mod:NewPhaseAnnounce(2, 3)	
local warnFrostbolt					= mod:NewCastAnnounce(72007, 2)
local warnTouchInsignificance		= mod:NewAnnounce("WarnTouchInsignificance", 3)


local specWarnCurseTorpor			= mod:NewSpecialWarning("SpecWarnCurseTorpor")
local specWarnDeathDecay			= mod:NewSpecialWarning("SpecWarnDeathDecay")
local specWarnTouchInsignificance	= mod:NewSpecialWarning("SpecWarnTouchInsignificance")

local timerAdds						= mod:NewTimer(60, "TimerAdds")
local timerDominateMind				= mod:NewBuffActiveTimer(20, 71289)
local timerDominateMindCD			= mod:NewCDTimer(40, 71289)
local timerTouchInsignificance		= mod:NewTargetTimer(30, 71204)

local enrageTimer					= mod:NewEnrageTimer(600)

mod:AddBoolOption("SetIconOnDominateMind", true)

local lastDD	= 0
local dominateMindTargets	= {}
local dominateMindIcon = 7

local function showDominateMindWarning()
	warnDominateMind:Show(table.concat(dominateMindTargets, "<, >"))
	timerDominateMind:Start()
	timerDominateMindCD:Start()
	table.wipe(dominateMindTargets)
	dominateMindIcon = 7
end

function mod:addsTimer()
	timerAdds:Cancel()
	warnAddsSoon:Cancel()
	timerAdds:Start()
	warnAddsSoon:Schedule(55)	-- 5 secs prewarning
	self:ScheduleMethod(60, "addsTimer")
end

function mod:OnCombatStart(delay)
	enrageTimer:Start(-delay)
	timerAdds:Start(7)
	warnAddsSoon:Schedule(4)	-- 3sec pre-warning on start
	self:ScheduleMethod(7, "addsTimer")
	timerDominateMindCD:Start(30)	-- Sometimes 1 fails at the start, then the next will be applied 70 secs after start ?? :S
	table.wipe(dominateMindTargets)
	dominateMindIcon = 7
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(71289) then
		dominateMindTargets[#dominateMindTargets + 1] = args.destName
		if self.Options.SetIconOnDominateMind then
			self:SetIcon(args.destName, dominateMindIcon, 20)
			dominateMindIcon = dominateMindIcon - 1
		end
		self:Unschedule(showDominateMindWarning)
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("normal25") or (mod:IsDifficulty("heroic25") and #dominateMindTargets >= 3) then
			showDominateMindWarning()
		else
			self:Schedule(0.3, showDominateMindWarning)
		end
	elseif args:IsSpellID(72108, 71001) then
		if args:IsPlayer() then
			specWarnDeathDecay:Show()
		end
		if (GetTime() - lastDD > 5) then
			warnDeathDecay:Show()
			lastDD = GetTime()
		end
	elseif args:IsSpellID(71237) and args:IsPlayer() then
		specWarnCurseTorpor:Show()
	elseif args:IsSpellID(71204) then
		warnTouchInsignificance:Show(args.spellName, args.destName, args.amount or 1)
		if args:IsPlayer() and (args.amount or 1) >= 3 then
			specWarnTouchInsignificance:Show()
		end
		timerTouchInsignificance:Start(args.destName)
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(70842) then
		warnPhase2:Show()
		timerAdds:Cancel()
		warnAddsSoon:Cancel()
		self:UnscheduleMethod("addsTimer")
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(72007) then
		warnFrostbolt:Show()
	elseif args:IsSpellID(70900) then
		warnDarkTransformation:Show()
	elseif args:IsSpellID(70901) then
		warnDarkEmpowerment:Show()
	end
end


function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellReanimatedFanatic or msg:find(L.YellReanimatedFanatic) then
		self:SendSync("ReanimatedFanatic")
	elseif msg == L.YellDeformedFanatic or msg:find(L.YellDeformedFanatic) then
		self:SendSync("DeformedFanatic")
	end
end

function mod:OnSync(msg, arg)
	if msg == "DeformedFanatic" then
		warnDeformedFanatic:Show()
	elseif msg == "ReanimatedFanatic" then
		warnReanimating:Show()
	end
end
