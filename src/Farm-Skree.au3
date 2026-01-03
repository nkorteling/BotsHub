#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $RASkreeFarmerSkillbar = 'OgcTcZ88Z6uE4Q4A3JN7AKukVEA'
Global Const $PRunnerSkreeHeroSkillbar = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Global Const $DPSupportHeroSkillbar = 'Ogmioys8QjvvAAAAAAAAAAAA'
Global Const $RWinnowingHeroSkillbar = 'OggjcNYMIPPH5JAAAAAAAAAAAA'
Global Const $REoEWinterHeroSkillbar = 'OgASYZMHQ/6AAAAAAAAA'
Global Const $NTaintedHeroSkillbar = 'OABCUsxUcwWIAAAAAAAAAAAA'
Global Const $SkreeFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 3 in Wilderness Survival' & @CRLF _
	& '- A shield with +10 armor against Piercing damage)' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- The farm is not efficient for survivor farming as being unlucky with Mental Block, getting hit with Wild Throw or a lucky Boss hit can end the run. Rarely a patrolling Skree will kill the spirits.'

Global Const $SKREE_FARM_DURATION = 2.5 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($SF_DwarvenStability) is better than UseSkillEx(1))
Global Const $SF_DwarvenStability	= 1
Global Const $SF_Escape				= 2
Global Const $SF_WhirlingDefense	= 3
Global Const $SF_DeathsCharge		= 4
Global Const $SF_FeignedNeutrality	= 5
Global Const $SF_ShroudOfDistress	= 6
Global Const $SF_MentalBlock		= 7
Global Const $SF_GreatDwarfArmor	= 8

; Hero Build 1
Global Const $Hero_SF_MOX			= 1
Global Const $SF_CauterySignet1		= 1
Global Const $SF_MysticHealing1		= 2

; Hero Build 2
Global Const $Hero_SF_Melonni		= 2
Global Const $SF_CauterySignet2		= 1
Global Const $SF_MysticHealing2		= 2

; Hero Build 3
Global Const $Hero_SF_Kahmu			= 3
Global Const $SF_CauterySignet3		= 1
Global Const $SF_MysticHealing3		= 2

; Hero Build 4
Global Const $Hero_SF_GeneralMorgahn	= 4
Global Const $SF_VocalWasSogolon	= 1
Global Const $SF_Incoming			= 2
Global Const $SF_FallBack			= 3
Global Const $SF_EnduringHarmony	= 4
Global Const $SF_MakeHaste			= 5
Global Const $SF_StandYourGround	= 6
Global Const $SF_CantTouchThis		= 7
Global Const $SF_BladeturnRefrain	= 8

; Hero Build 5
Global Const $Hero_SF_Livia			= 5
Global Const $SF_TaintedFlesh		= 1
Global Const $SF_Masochism			= 2

; Hero Build 6
Global Const $Hero_SF_AcolyteJin	= 6
Global Const $SF_Winnowing			= 1
Global Const $SF_Soothing			= 2

; Hero Build 7
Global Const $Hero_SF_PyreFierceshot	= 7
Global Const $SF_EdgeOfExtinction	= 1
Global Const $SF_Winter				= 2


Global $SF_FARM_SETUP = False

;~ Main method to farm Skree
Func SkreeFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $SF_FARM_SETUP Then SetupSkreeFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToForumHighlands()
	Local $result = SkreeFarmLoop()
	ReturnBackToOutpost($ID_Tihark_Orchard)
	Return $result
EndFunc


;~ Skree farm team setup
Func SetupTeamSkreeFarm()
	
	Info('Setting up team')
	Sleep(500)
	LeaveParty()
	RandomSleep(500)
	Info('Adding MOX')
	AddHero($ID_MOX)
	Info('Adding Melonni')
	AddHero($ID_Melonni)
	Info('Adding Kahmu')
	AddHero($ID_Kahmu)
	Info('Adding General Morgahn')
	AddHero($ID_General_Morgahn)
	Info('Adding Livia')
	AddHero($ID_Livia)
	Info('Adding Acolyte Jin')
	AddHero($ID_Acolyte_Jin)
	Info('Adding Pyre Fierceshot')
	AddHero($ID_Pyre_Fierceshot)
	Sleep(1000)
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf

	Info('Loading Character skillbar')
	LoadSkillTemplate($RASkreeFarmerSkillbar)
	Info('Loading Hero skillbars')
	LoadSkillTemplate($DPSupportHeroSkillbar, 1)
	LoadSkillTemplate($DPSupportHeroSkillbar, 2)
	LoadSkillTemplate($DPSupportHeroSkillbar, 3)
	LoadSkillTemplate($PRunnerSkreeHeroSkillbar, 4)
	LoadSkillTemplate($NTaintedHeroSkillbar, 5)
	LoadSkillTemplate($RWinnowingHeroSkillbar, 6)
	LoadSkillTemplate($REoEWinterHeroSkillbar, 7)

	Sleep(250)
	DisableAllHeroSkills(1)
	DisableAllHeroSkills(2)
	DisableAllHeroSkills(3)
	DisableAllHeroSkills(4)
	DisableAllHeroSkills(5)
	DisableAllHeroSkills(6)
	DisableAllHeroSkills(7)
	EnableHeroSkillSlot($ID_General_Morgahn, $SF_FallBack)
	EnableHeroSkillSlot($ID_General_Morgahn, $SF_Incoming)
	EnableHeroSkillSlot($ID_General_Morgahn, $SF_VocalWasSogolon)
	Sleep(500)

EndFunc

;~ Skree farm setup
Func SetupSkreeFarm()
	Info('Setting up farm')

	Local $mapID = GetMapID()
	
	If $mapID <> $ID_Tihark_Orchard Then
		TravelToOutpost($ID_Tihark_Orchard, $DISTRICT_NAME)
	EndIf

	SwitchMode($ID_HARD_MODE)
	
	Local $setupTeam = MsgBox(4, "Setup Team", "Do you want to setup the team (add heroes and load builds)?")
	If $setupTeam = 6 Then ; Yes
		SetupTeamSkreeFarm()
	EndIf

	Local $setupTeam = MsgBox(4, "Rezone", "Do you need to rezone?")
	If $setupTeam = 6 Then ; Yes
		GoToForumHighlands()
		MoveTo(-2950, 14477)
		MoveTo(-1509, 14393)
		RandomSleep(1000)
		WaitMapLoading($ID_Tihark_Orchard, 10000, 1000)
	EndIf

	
	$SF_FARM_SETUP = True
	Info('Preparations complete')

EndFunc


;~ Move out of outpost into Forum Highlands
Func GoToForumHighlands()
	If GetMapID() <> $ID_Tihark_Orchard Then TravelToOutpost($ID_Tihark_Orchard, $DISTRICT_NAME)
	While GetMapID() <> $ID_Forum_Highlands
		Info('Moving to Forum Highlands')
		MoveTo(-1509, 14393)
		MoveTo(-2950, 14477)
		RandomSleep(1000)
		WaitMapLoading($ID_Forum_Highlands, 10000, 1000)
	WEnd
EndFunc

;~ Get Sunspear blessing only if title is not maxed yet
Func GetSkreeSunspearBlessing()
	Local $sunspearTitlePoints = GetSunspearTitle()
	If $sunspearTitlePoints < 160000 Then
		Info('Getting sunspear title blessing')
		GoNearestNPCToCoords(-3132, 15056)
		RandomSleep(300)
		Dialog(0x83)
		RandomSleep(300)
		Dialog(0x85)
		RandomSleep(300)
	EndIf
EndFunc

Func CastFullSpiritsAndBuffs()
	Sleep(1000)
	UseHeroSkill($Hero_SF_PyreFierceshot, $SF_EdgeOfExtinction)
	UseHeroSkill($Hero_SF_AcolyteJin, $SF_Winnowing)
	UseHeroSkill($Hero_SF_Livia, $SF_Masochism)
	UseHeroSkill($Hero_SF_GeneralMorgahn, $SF_VocalWasSogolon)
	Sleep(5000)
	UseHeroSkill($Hero_SF_PyreFierceshot, $SF_Winter)
	UseHeroSkill($Hero_SF_AcolyteJin, $SF_Soothing)
	Sleep(3000)
	UseHeroSkill($Hero_SF_GeneralMorgahn, $SF_EnduringHarmony, GetMyAgent())
	UseSkillEx($SF_ShroudOfDistress)
	Sleep(1000)
	UseHeroSkill($Hero_SF_Livia, $SF_TaintedFlesh, GetMyAgent())
	UseHeroSkill($Hero_SF_GeneralMorgahn, $SF_BladeturnRefrain, GetMyAgent())
	UseSkillEx($SF_DwarvenStability)
	Register_SF_BuffCycle()
	Sleep(1000)
	UseHeroSkill($Hero_SF_GeneralMorgahn, $SF_StandYourGround, GetMyAgent())
	UseHeroSkill($Hero_SF_GeneralMorgahn, $SF_CantTouchThis, GetMyAgent())
EndFunc


;~ Farm loop
Func SkreeFarmLoop()
	If GetMapID() <> $ID_Forum_Highlands Then Return $FAIL

	While IsPlayerAlive()	
		;~ Get blessing
		GetSkreeSunspearBlessing()

		;~ Move to spirit Location
		MoveTo(-4603, 10089)
		MoveTo(-7070, 5623)
		MoveTo(-7654, 5308)
		CommandAll(-7654, 5308)
		Sleep(4000)

		;~ Farm Setup
		CastFullSpiritsAndBuffs()
		;~ Check if enemies are in range before proceeding
		Local $enemiesInRange = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
		If $enemiesInRange > 0 Then
			Warn('Enemies detected in cast range during setup. Aborting farm.')
			Unregister_SF_HealAndCureCycle()
			Return $FAIL
		EndIf

		;~ Flag Heroes
		CommandAll(-2957, 7732)
		;~ Move to farm start
		Register_SF_HealAndCureCycle()
		MoveTo(-7285, 5594)
		;~ Register_SF_BuffCycle()
		Sleep(1000)
		MoveAggroingSkreeFarm(-7199, 6626)
		Register_SF_AggroCycle()
		;~ Aggro
		MoveAggroingSkreeFarm(-7957, 6899)
		UseSkillEx($SF_MentalBlock)
		MoveAggroingSkreeFarm(-8085, 7120)
		MoveAggroingSkreeFarm(-9523, 7592)
		MoveAggroingSkreeFarm(-11912, 6684)
		MoveAggroingSkreeFarm(-11545, 4986)
		MoveAggroingSkreeFarm(-10841, 4516)
		MoveAggroingSkreeFarm(-9975, 5229)
		MoveAggroingSkreeFarm(-9520, 5558)
		MoveAggroingSkreeFarm(-9044, 5442)

		;~ Find Target Foe
		Local $boss = GetNearestBossFoe()
		If $boss <> Null Then
			ChangeTarget($boss)
		Else
			Warn('No boss found in the area!')
		EndIf
		
		Register_SF_KillCycle()
		UseSkillEx($SF_WhirlingDefense)
		Sleep(2000)


		;~ Farm Start
		UseSkillEx($SF_DeathsCharge, $boss)

		Sleep(1000)

		Local $farmTimer = TimerInit()

		While IsPlayerAlive() And TimerDiff($farmTimer) < 3000
			Local $nearestEnemy = GetNearestEnemyToAgent(GetMyAgent())
			If $nearestEnemy <> 0 And GetDistance(GetMyAgent(), $nearestEnemy) <= ($RANGE_EARSHOT / 2) Then
				Move(DllStructGetData($nearestEnemy, 'X'), DllStructGetData($nearestEnemy, 'Y'), 0)
			EndIf
			RandomSleep(100)
		WEnd

		Info('Looting')
		
		; Move to distant items and pick them up
		Local $lootTimer = TimerInit()
		While TimerDiff($lootTimer) < 10000  ; 10 second timeout, Increase during event
			PickUpItems()
			
			Local $item = GetNearestItemToAgent(GetMyAgent())
			If $item = 0 Then ExitLoop
			
			Local $itemDistance = GetDistance(GetMyAgent(), $item)
			If $itemDistance > $RANGE_EARSHOT Then
				MoveTo(DllStructGetData($item, 'X'), DllStructGetData($item, 'Y'))
				RandomSleep(500)
			Else
				RandomSleep(1000)
			EndIf
		WEnd

		Return CheckSkreeFarmResult()
	WEnd
	Unregister_SF_AllCycles()
	Return $FAIL
EndFunc

;~ Check whether or not the farm was successful
Func CheckSkreeFarmResult()
	If IsPlayerDead() Then
		Info('Character died')
		Unregister_SF_AllCycles()
		Return $FAIL
	EndIf
	Unregister_SF_AllCycles()
	Return $SUCCESS
EndFunc

;~ Move to (X,Y) while staying alive and maintaining buffs during Skree farm
Func MoveAggroingSkreeFarm($x, $y)
	Move($x, $y, 0)

	Local $me = GetMyAgent()
	While IsPlayerAlive() And GetDistanceToPoint($me, $x, $y) > $RANGE_NEARBY
		If SF_IsBodyBlocked() Then Return $FAIL
		RandomSleep(100)
		Move($x, $y)
		$me = GetMyAgent()
	WEnd
	Return $SUCCESS
EndFunc


;~ Check if bodyblock and if is move randomly until not bodyblocked anymore
Func SF_IsBodyBlocked()
	Local $blocked = 0
	Local Const $PI = 3.14159
	Local $angle = 0

	Local $me = GetMyAgent()
	If DllStructGetData($me, 'HP') < 0.90 Then
		SF_SendStuckCommand()
	EndIf

	While Not IsPlayerMoving()
		$blocked += 1
		Debug('Blocked: ' & $blocked)
		If $blocked > 1 Then
			$angle += $PI / 4
		EndIf

		If ($blocked > 4 Or DllStructGetData($me, 'HP') < 0.90) Then
			SF_SendStuckCommand()
		EndIf

		If $blocked > 7 Then
			Debug('Completely blocked')
			Return True
		EndIf
		Move(DllStructGetData($me, 'X') + 300 * sin($angle), DllStructGetData($me, 'Y') + 300 * cos($angle), 0)
		RandomSleep(250)
		$me = GetMyAgent()
	WEnd
	Return False
EndFunc


;~ Send /stuck - don't overuse
Func SF_SendStuckCommand()
	; use a timer to avoid spamming /stuck - /stuck is only useful when rubberbanding - there shouldn't be any enemy around the character then
	If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY) == 0 And TimerDiff($chatStuckTimer) > 10000 Then
		Warn('Sending /stuck')
		SendChat('stuck', '/')
		$chatStuckTimer = TimerInit()
		RandomSleep(GetPing() + 20)
		Return True
	EndIf
	Return False
EndFunc

Func Register_SF_HealAndCureCycle()
	AdlibRegister('SF_HealAndCureCycle', 4500)
EndFunc

Func Unregister_SF_HealAndCureCycle()
	AdlibUnRegister('SF_HealAndCureCycle')
EndFunc

Func Register_SF_BuffCycle()
	AdlibRegister('SF_FeignedNeutralityCycle', 5000)
	AdlibRegister('SF_ShroudOfDistressCycle', 10000)
	AdlibRegister('SF_DwarvenStabilityCycle', 2000)
	AdlibRegister('SF_GreatDwarfArmorCycle', 10000)
EndFunc

Func Unregister_SF_BuffCycle()
	AdlibUnRegister('SF_FeignedNeutralityCycle')
	AdlibUnRegister('SF_ShroudOfDistressCycle')
	AdlibUnRegister('SF_DwarvenStabilityCycle')
	AdlibUnRegister('SF_GreatDwarfArmorCycle')
EndFunc

Func Register_SF_AggroCycle()
	Unregister_SF_KillCycle()
	AdlibRegister('SF_EscapeCycle', 2000)
EndFunc

Func Unregister_SF_AggroCycle()
	AdlibUnRegister('SF_EscapeCycle')
EndFunc

Func Register_SF_KillCycle()
	Unregister_SF_AggroCycle()
	AdlibRegister('SF_WhirlingDefenseCycle', 45000)
EndFunc

Func Unregister_SF_KillCycle()
	AdlibUnRegister('SF_WhirlingDefenseCycle')
EndFunc

;~ Can be used in other farm bots - has no latency - can be used at most once every 1600ms
Func SF_HealAndCureCycle()
	Local Static $adlibBusy = False
	Local Static $steady_Healing_Healer_Index = 0

	If $adlibBusy Then Return
	$adlibBusy = True
	
	Switch $steady_Healing_Healer_Index
		Case 0
			UseHeroSkill($Hero_SF_Melonni, $SF_MysticHealing2)
			UseHeroSkill($Hero_SF_Kahmu, $SF_MysticHealing3)
			UseHeroSkill($Hero_SF_MOX, $SF_CauterySignet1)

			Sleep(2000)
			$steady_Healing_Healer_Index = 1
		Case 1
			UseHeroSkill($Hero_SF_MOX, $SF_MysticHealing1)
			UseHeroSkill($Hero_SF_Kahmu, $SF_MysticHealing3)
			UseHeroSkill($Hero_SF_Melonni, $SF_CauterySignet2)	
			Sleep(2000)
			$steady_Healing_Healer_Index = 2
		Case 2
			UseHeroSkill($Hero_SF_MOX, $SF_MysticHealing1)
			UseHeroSkill($Hero_SF_Melonni, $SF_MysticHealing2)
			UseHeroSkill($Hero_SF_Kahmu, $SF_CauterySignet3)
			Sleep(2000)
			$steady_Healing_Healer_Index = 0

	EndSwitch
	$adlibBusy = False
EndFunc

Func SF_EscapeCycle()
	If IsRecharged($SF_Escape) Then
		UseSkillEx($SF_Escape)
	EndIf
EndFunc

Func SF_FeignedNeutralityCycle()
    Local Static $fnTimer = 0
    If $fnTimer = 0 Then $fnTimer = TimerInit()
    If TimerDiff($fnTimer) >= 25000 Then
        If IsRecharged($SF_FeignedNeutrality) Then
            UseSkillEx($SF_FeignedNeutrality)
			;~ Sleep(250)
            $fnTimer = TimerInit()
        EndIf
    EndIf
EndFunc

Func SF_ShroudOfDistressCycle()
    Local Static $sodTimer = 0
    If $sodTimer = 0 Then $sodTimer = TimerInit()
    If TimerDiff($sodTimer) >= 50000 Then
        If IsRecharged($SF_ShroudOfDistress) Then
            UseSkillEx($SF_ShroudOfDistress)
			;~ Sleep(1000)
            $sodTimer = TimerInit()
        EndIf
    EndIf
EndFunc

Func SF_DwarvenStabilityCycle()
    Local Static $dsTimer = 0
    If $dsTimer = 0 Then $dsTimer = TimerInit()
    If TimerDiff($dsTimer) >= 30000 Then
        If IsRecharged($SF_DwarvenStability) Then
            UseSkillEx($SF_DwarvenStability)
			;~ Sleep(250)
            $dsTimer = TimerInit()
        EndIf
    EndIf
EndFunc

Func SF_GreatDwarfArmorCycle()
    Local Static $gdaTimer = 0
    If $gdaTimer = 0 Then 
		$gdaTimer = TimerInit()
		UseSkillEx($SF_GreatDwarfArmor)
	EndIf
    If TimerDiff($gdaTimer) >= 40000 Then
        If IsRecharged($SF_GreatDwarfArmor) Then
            UseSkillEx($SF_GreatDwarfArmor)
			;~ Sleep(1000)
            $gdaTimer = TimerInit()
        EndIf
    EndIf
EndFunc

Func SF_WhirlingDefenseCycle()
	Info('Using Whirling Defense')
	UseSkillEx($SF_WhirlingDefense)
	Unregister_SF_KillCycle()
	Register_SF_AggroCycle()
EndFunc

Func Unregister_SF_AllCycles()
	Unregister_SF_BuffCycle()
	Unregister_SF_AggroCycle()
	Unregister_SF_KillCycle()
	Unregister_SF_HealAndCureCycle()
EndFunc