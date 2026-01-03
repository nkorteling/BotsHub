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
Global $HOC_SF_Queue = False
Global $HOC_OF_Queue = False
Global $HOC_Kill_Queue = False
Global $HOC_IsBusy = False
Global $HOC_ObsidianTimer = 0
Global $HOC_StoneFleshTimer = 0
Global Const $EMoPlantFarmerSkillbar = 'OgcTcZ88Z6uE4Q4A3JN7AKukVEA'
Global Const $RPEdgeOfExtinction	= 1 = 'OgkiYxm8AdAum4bMAAAsj5xA'
Global Const $HOC_DPSupportHeroSkillbar = 'Ogmioys8QjvvAAAAAAAAAAAA'
Global Const $HOC_FarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 3 in Wilderness Survival' & @CRLF _
	& '- A shield with +10 armor against Piercing damage)' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- The farm is not efficient for survivor farming as being unlucky with Mental Block, getting hit with Wild Throw or a lucky Boss hit can end the run.'

Global Const $HOC_FARM_DURATION = 2.5 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($HOC_GlyphOfSwiftness) is better than UseSkillEx(1))
Global Const $HOC_GlyphOfSwiftness	= 1
Global Const $HOC_ObsidianFlesh			= 2
Global Const $HOC_ProtectiveSpirit	= 3
Global Const $HOC_StoneFleshAura		= 4
Global Const $HOC_RadiationField	= 5
Global Const $HOC_EbonBattleStandardOfHonor	= 6
Global Const $HOC_SliverArmor		= 7
Global Const $HOC_Balthazars_Spirit	= 8

; Hero Build 1
Global Const $Hero_HOC_MOX			= 1
Global Const $HOC_CauterySignet1		= 1
Global Const $HOC_MysticHealing1		= 2

; Hero Build 2
Global Const $Hero_HOC_Melonni		= 2
Global Const $HOC_CauterySignet2		= 1
Global Const $HOC_MysticHealing2		= 2

; Hero Build 3
Global Const $Hero_HOC_Kahmu			= 3
Global Const $HOC_CauterySignet3		= 1
Global Const $HOC_MysticHealing3		= 2

; Hero Build 4
Global Const $Hero_HOC_PyreFierceshot	= 4
Global Const $HOC_EdgeOfExtinction	= 1
Global Const $HOC_Toxicity			= 2
Global Const $HOC_EnduringHarmony	= 3
Global Const $HOC_MakeHaste			= 4
Global Const $HOC_FallBack			= 7
Global Const $HOC_Incoming			= 8

Global $HOC_FARM_SETUP = False

;~ Main method to farm HOC
Func HOC_Farm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $HOC_FARM_SETUP Then SetupHOC_Farm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	;~ GoToHoldingsOfChokin()
	;~ Local $result = HOC_FarmLoop()
	;~ ReturnBackToOutpost($ID_Mihanu_Township)
	;~ Return $result
	
	Global $captureCoords = False
	Global $StartKill = False
	Global $EndScipt = False
	Global $StartBuffs = False
	Local $Started = False
	
	HotKeySet("j", "HOC_CapturePosition")
	HotKeySet("b", "HOC_StartKill")
	HotKeySet("{ESC}", "HOC_ExitScript")
	
	Info('Coordinate Logger Active - Press J to log position, ESC to exit')
	
	GoToHoldingsOfChokin()
	MoveToHOCFarmStart()
	HOC_CastSpirits()
	HOC_Aggro()
	
	While True
		Sleep(100)
		If $captureCoords Then
			Local $me = GetMyAgent()
			Local $x = Round(DllStructGetData($me, 'X'))
			Local $y = Round(DllStructGetData($me, 'Y'))
			Info("Position: MoveTo(" & $x & ", " & $y & ")")
			$captureCoords = False
		EndIf
		If $StartKill Then
			HOC_KillEnemies()
			$StartKill = False
		EndIf
		If $EndScipt Then HOC_ExitScript()
	WEnd
	
	HotKeySet("j")
	Return $SUCCESS
	
EndFunc

Func HOC_CapturePosition()
	$captureCoords = True
EndFunc

Func HOC_StartKill()
	$StartKill = True
EndFunc

Func HOC_ExitScript()
	$EndScipt = True
	Info('Exiting script')
	Return $FAIL
	Exit
EndFunc


;~ Skree farm team setup
Func SetupTeamHOC_Farm()
	
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
	Info('Adding Pyre Fierceshot')
	AddHero($ID_Pyre_Fierceshot)
	Sleep(1000)
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf

	Info('Loading Character skillbar')
	LoadSkillTemplate($RAHOC_FarmerSkillbar)
	Info('Loading Hero skillbars')
	LoadSkillTemplate($HOC_DPSupportHeroSkillbar, 1)
	LoadSkillTemplate($HOC_DPSupportHeroSkillbar, 2)
	LoadSkillTemplate($HOC_DPSupportHeroSkillbar, 3)
	LoadSkillTemplate($RPEdgeOfExtinction, 4)

	Sleep(250)
	DisableAllHeroSkills(1)
	DisableAllHeroSkills(2)
	DisableAllHeroSkills(3)
	DisableAllHeroSkills(4)
	EnableHeroSkillSlot($ID_Pyre_Fierceshot, $HOC_FallBack)
	EnableHeroSkillSlot($ID_Pyre_Fierceshot, $HOC_Incoming)
	Sleep(500)
EndFunc

;~ Skree farm setup
Func SetupHOC_Farm()
	;~ Info('Setting up farm')

	;~ Local $mapID = GetMapID()
	
	;~ If $mapID <> $ID_Mihanu_Township Then
	;~ 	TravelToOutpost($ID_Mihanu_Township, $DISTRICT_NAME)
	;~ EndIf

	;~ SwitchMode($ID_HARD_MODE)
	
	;~ Local $setupTeam = MsgBox(4, "Setup Team", "Do you want to setup the team (add heroes and load builds)?")
	;~ If $setupTeam = 6 Then ; Yes
	;~ 	SetupTeamHOC_Farm()
	;~ EndIf

	;~ Local $setupTeam = MsgBox(4, "Rezone", "Do you need to rezone?")
	;~ If $setupTeam = 6 Then ; Yes
	;~ 	GoToHoldingsOfChokin()
	;~ 	MoveTo(17700, -16192)
	;~ 	RandomSleep(1000)
	;~ 	WaitMapLoading($ID_Mihanu_Township, 10000, 1000)
	;~ EndIf
	
	$HOC_FARM_SETUP = True
	Info('Preparations complete')

EndFunc


;~ Move out of outpost into Holdings of Chokhin
Func GoToHoldingsOfChokin()
	If GetMapID() <> $ID_Mihanu_Township Then TravelToOutpost($ID_Mihanu_Township, $DISTRICT_NAME)
	While GetMapID() <> $ID_Holdings_Of_Chokhin
		Info('Moving to Holdings of Chokhin')
		MoveTo(-235, 2909)
		MoveTo(-297, 3509)
		MoveTo(-384, 4800)
		RandomSleep(1000)
		WaitMapLoading($ID_Holdings_Of_Chokhin, 10000, 1000)
	WEnd
EndFunc

Func MoveToHOCFarmStart()
	UseSkillEx($HOC_Balthazars_Spirit)
	MoveTo(16481, -15271)
	HOC_GetPlantSunspearBlessing()
	MoveTo(16667, -12978)
	MoveTo(15787, -12283)
	MoveTo(11645, -11264)
	MoveTo(11499, -10759)
	MoveTo(13384, -8573)
EndFunc

;~ Get Sunspear blessing only if title is not maxed yet
Func HOC_GetPlantSunspearBlessing()
	Local $sunspearTitlePoints = GetSunspearTitle()
	If $sunspearTitlePoints < 160000 Then
		Info('Getting sunspear title blessing')
		GoNearestNPCToCoords(15848,-15299)
		RandomSleep(300)
		Dialog(0x83)
		RandomSleep(300)
		Dialog(0x85)
		RandomSleep(300)
	EndIf
EndFunc

Func HOC_CastSpirits()
	CommandAll(13384, -8573)
	Sleep(3000)
	UseHeroSkill($Hero_HOC_PyreFierceshot, $HOC_EdgeOfExtinction)
	Sleep(5000)
	UseHeroSkill($Hero_HOC_PyreFierceshot, $HOC_Toxicity)
	Sleep(4000)
	UseHeroSkill($Hero_HOC_PyreFierceshot, $HOC_EnduringHarmony, GetMyAgent())
	Sleep(1000)
	CommandAll(13815, -11995)
EndFunc

Func HOC_Aggro()
	MoveTo(12361, -7726)
	Register_HOC_HealAndCureCycle()
	UseSkillEx($HOC_GlyphOfSwiftness)
	UseSkillEx($HOC_ObsidianFlesh)
	UseSkillEx($HOC_ProtectiveSpirit)
	RandomSleep(100)
	UseSkillEx($HOC_StoneFleshAura)
	RandomSleep(100)
	Register_HOC_AggroCycle()
	MoveTo(11414, -5622)
	MoveTo(10445, -5646)
	MoveTo(10780, -8132)
	MoveTo(10908, -8196)
	MoveTo(11750, -9214)
	MoveTo(11690, -8669)
	HOC_KillEnemies()
EndFunc

;~ Farm loop
Func HOC_FarmLoop()
	If GetMapID() <> $ID_Holdings_Of_Chokhin Then Return $FAIL
	
	;~ Get blessing
	HOC_GetPlantSunspearBlessing()

	;~ Move to spirit Location
	MoveTo(-4603, 10089)
	MoveTo(-7070, 5623)
	MoveTo(-7654, 5308)
	CommandAll(-7654, 5308)
	Sleep(3000)

	;~ Farm Setup
	HOC_CastFullSpiritsAndBuffs()

	;~ Flag Heroes
	CommandAll(-2957, 7732)
	Register_HOC_HealAndCureCycle()

	;~ Move to farm start
	MoveTo(-7285, 5594)
	Register_HOC_AggroCycle()

	MoveAggroingHOC_Farm(-7199, 6626)
	;~ Aggro
	MoveAggroingHOC_Farm(-7957, 6899)
	MoveAggroingHOC_Farm(-8085, 7120)
	HOC_KillEnemies()
	MoveAggroingHOC_Farm(-9523, 7592)
	MoveAggroingHOC_Farm(-11912, 6684)
	MoveAggroingHOC_Farm(-11545, 4986)
	MoveAggroingHOC_Farm(-10976, 4645)
	MoveAggroingHOC_Farm(-9702, 5885)
	MoveAggroingHOC_Farm(-9044, 5442)

	Local $farmTimer = TimerInit()

	While IsPlayerAlive() And TimerDiff($farmTimer) < 3000
		Local $nearestEnemy = GetNearestEnemyToAgent(GetMyAgent())
		If $nearestEnemy <> 0 And GetDistance(GetMyAgent(), $nearestEnemy) <= ($RANGE_EARSHOT / 2) Then
			Move(DllStructGetData($nearestEnemy, 'X'), DllStructGetData($nearestEnemy, 'Y'), 0)
		EndIf
		RandomSleep(100)
	WEnd
	
	If IsPlayerDead() Then 
		Unregister_HOC_AllCycles()
		Return $FAIL
	EndIf

	Info('Looting')
	
	HOC_Loot()

	Return CheckHOC_FarmResult()
EndFunc

;~ Check whether or not the farm was successful
Func CheckHOC_FarmResult()
	If IsPlayerDead() Then
		Info('Character died')
		Unregister_HOC_AllCycles()
		Return $FAIL
	EndIf
	Unregister_HOC_AllCycles()
	Return $SUCCESS
EndFunc

;~ Move to (X,Y) while staying alive and maintaining buffs during Skree farm
Func MoveAggroingHOC_Farm($x, $y)
	Move($x, $y, 0)

	Local $me = GetMyAgent()
	While IsPlayerAlive() And GetDistanceToPoint($me, $x, $y) > $RANGE_NEARBY
		If HOC_IsBodyBlocked() Then Return $FAIL
		RandomSleep(100)
		Move($x, $y)
		$me = GetMyAgent()
	WEnd
	Return $SUCCESS
EndFunc


;~ Check if bodyblock and if is move randomly until not bodyblocked anymore
Func HOC_IsBodyBlocked()
	Local $blocked = 0
	Local Const $PI = 3.14159
	Local $angle = 0

	Local $me = GetMyAgent()
	If DllStructGetData($me, 'HP') < 0.90 Then
		HOC_SendStuckCommand()
	EndIf

	While Not IsPlayerMoving()
		$blocked += 1
		Debug('Blocked: ' & $blocked)
		If $blocked > 1 Then
			$angle += $PI / 4
		EndIf

		If ($blocked > 4 Or DllStructGetData($me, 'HP') < 0.90) Then
			HOC_SendStuckCommand()
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
Func HOC_SendStuckCommand()
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

Func HOC_Loot()
	Local $lootTimer = TimerInit()
	While TimerDiff($lootTimer) < 30000  ; 30 second timeout
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
EndFunc

Func Register_HOC_HealAndCureCycle()
	AdlibRegister('HOC_HealAndCureCycle', 4500)
EndFunc

Func Unregister_HOC_HealAndCureCycle()
	AdlibUnRegister('HOC_HealAndCureCycle')
EndFunc

Func Register_HOC_AggroCycle()
	AdlibRegister('HOC_OsidianTimer', 1000)
	AdlibRegister('HOC_StoneFleshTimer', 1000)
EndFunc

Func Unregister_HOC_AggroCycle()
	AdlibUnRegister('HOC_OsidianTimer')
	AdlibUnRegister('HOC_StoneFleshTimer')
EndFunc

;~ Can be used in other farm bots - has no latency - can be used at most once every 1600ms
Func HOC_HealAndCureCycle()
	Local Static $adlibBusy = False
	Local Static $steady_Healing_Healer_Index = 0

	If $adlibBusy Then Return
	$adlibBusy = True
	
	Switch $steady_Healing_Healer_Index
		Case 0
			UseHeroSkill($Hero_HOC_Melonni, $HOC_MysticHealing2)
			UseHeroSkill($Hero_HOC_Kahmu, $HOC_MysticHealing3)
			UseHeroSkill($Hero_HOC_MOX, $HOC_CauterySignet1)

			Sleep(2000)
			$steady_Healing_Healer_Index = 1
		Case 1
			UseHeroSkill($Hero_HOC_MOX, $HOC_MysticHealing1)
			UseHeroSkill($Hero_HOC_Kahmu, $HOC_MysticHealing3)
			UseHeroSkill($Hero_HOC_Melonni, $HOC_CauterySignet2)	
			Sleep(2000)
			$steady_Healing_Healer_Index = 2
		Case 2
			UseHeroSkill($Hero_HOC_MOX, $HOC_MysticHealing1)
			UseHeroSkill($Hero_HOC_Melonni, $HOC_MysticHealing2)
			UseHeroSkill($Hero_HOC_Kahmu, $HOC_CauterySignet3)
			Sleep(2000)
			$steady_Healing_Healer_Index = 0

	EndSwitch
	$adlibBusy = False
EndFunc

Func HOC_OsidianTimer()
	;~ If $HOC_ObsidianTimer = 0 Then $HOC_ObsidianTimer = TimerInit()
	;~ If Not IsPlayerAlive() Then
	;~ 	Unregister_HOC_AllCycles()
	;~ 	Return $FAIL
	;~ EndIf
	;~ If TimerDiff($HOC_ObsidianTimer) >= 9000 And not $HOC_IsBusy Then
	;~ 	$HOC_IsBusy = True
	;~ 	$HOC_ObsidianTimer = TimerInit()
	;~ 	UseSkillEx($HOC_GlyphOfSwiftness)
	;~ 	UseSkillEx($HOC_ObsidianFlesh)
	;~ 	$HOC_IsBusy = False
	;~ 	Sleep(100)
	;~ EndIf
	If $HOC_ObsidianTimer = 0 Then $HOC_ObsidianTimer = TimerInit()

	If IsRecharged($HOC_ObsidianFlesh) And Not $HOC_IsBusy Then
		$HOC_IsBusy = True
		UseSkillEx($HOC_GlyphOfSwiftness)
		UseSkillEx($HOC_ObsidianFlesh)
		$HOC_IsBusy = False
		$HOC_ObsidianTimer = TimerInit()
		Sleep(100)
		If $HOC_SF_Queue Then
			HOC_StoneFleshTimer()
			$HOC_SF_Queue = False
		EndIf
		If $HOC_Kill_Queue Then
			HOC_KillEnemies()
			$HOC_Kill_Queue = False
		EndIf
	ElseIf $HOC_IsBusy Then 
		$HOC_OF_Queue = True
	EndIf

EndFunc

Func HOC_StoneFleshTimer()
	;~ If $HOC_StoneFleshTimer = 0 Then $HOC_StoneFleshTimer = TimerInit()
	;~ If TimerDiff($HOC_StoneFleshTimer) >= 9000 And Not $HOC_IsBusy Then
	;~ 	$HOC_IsBusy = True
	;~ 	$HOC_StoneFleshTimer = TimerInit()
	;~ 	UseSkillEx($HOC_ProtectiveSpirit)
	;~ 	UseSkillEx($HOC_StoneFleshAura)
	;~ 	$HOC_IsBusy = False
	;~ 	Sleep(100)
	;~ EndIf
	If $HOC_StoneFleshTimer = 0 Then $HOC_StoneFleshTimer = TimerInit()

	If IsRecharged($HOC_StoneFleshAura) And Not $HOC_IsBusy Then
		$HOC_IsBusy = True
		UseSkillEx($HOC_ProtectiveSpirit)
		UseSkillEx($HOC_StoneFleshAura)
		$HOC_IsBusy = False
		$HOC_StoneFleshTimer = TimerInit()
		Sleep(100)
		If $HOC_OF_Queue Then
			HOC_ObsidianTimer()
			$HOC_OF_Queue = False
		EndIf
		If $HOC_Kill_Queue Then
			HOC_KillEnemies()
			$HOC_Kill_Queue = False
		EndIf
	ElseIf $HOC_IsBusy Then 
		$HOC_SF_Queue = True
	EndIf
EndFunc

Func HOC_KillEnemies()
	If Not $HOC_IsBusy Then
		Local $nearestEnemy = GetNearestEnemyToAgent(GetMyAgent())
		If $nearestEnemy <> 0 Then
			UseSkillEx($HOC_RadiationField, $nearestEnemy)
		Else
			UseSkillEx($HOC_RadiationField)
		EndIf
		Sleep(250)
		UseSkillEx($HOC_EbonBattleStandardOfHonor)
		Sleep(1000)
		UseSkillEx($HOC_SliverArmor)
		Sleep(250)
	ElseIf $HOC_IsBusy Then 
		$HOC_Kill_Queue = True
	EndIf
EndFunc

Func Unregister_HOC_AllCycles()
	Unregister_HOC_HealAndCureCycle()
	Unregister_HOC_AggroCycle()

EndFunc
