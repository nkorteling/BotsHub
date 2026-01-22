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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

; Possible improvements : rewrite it all

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $DASkaleFinFarmerSkillbar = 'OgejkmrMbSmXfbaXNXTQ3lEYsXA'
Global Const $SkaleFinFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Earth Prayers' & @CRLF _
	& '- 10 in Scythe Mastery' & @CRLF _
	& '- 10 in Mysticism' & @CRLF _
	& '- A scythe with +5 energy and +20% enchantment duration' & @CRLF _
	& '- A one handed weapon +5 energy and +20% enchantment duration' & @CRLF _
	& '- A shield' & @CRLF _
	& '- Windwalker or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 8m20
Global Const $SKALEFIN_FARM_DURATION = (8 * 60 + 20) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($SkaleFin_SandShards) is better than UseSkillEx(1))
Global Const $SkaleFin_SandShards			= 1
Global Const $SkaleFin_VowOfStrength		= 2
Global Const $SkaleFin_StaggeringForce		= 3
Global Const $SkaleFin_EremitesAttack		= 4
Global Const $SkaleFin_Dash					= 5
Global Const $SkaleFin_DwarvenStability		= 6
Global Const $SkaleFin_Conviction			= 7
Global Const $SkaleFin_MysticRegeneration	= 8

Global $SKALEFIN_FARM_SETUP = False
Global $SkaleFinWaitForSettle = True

;~ Main method to farm feathers
Func SkaleFinFarm()
	; Need to be done here in case bot comes back from inventory management
	If Not $SKALEFIN_FARM_SETUP Then SetupSkaleFinFarm()
	GoToFahranur()
	Local $result = SkaleFinFarmLoop()
	ReturnBackToOutpost($ID_Jokanur_Diggings)
	Return $result
EndFunc


;~ Drake Flesh farm setup
Func SetupSkaleFinFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Jokanur_Diggings, $DISTRICT_NAME)
	SwitchMode($ID_NORMAL_MODE)
	LeaveParty() ; solo farmer
	LoadSkillTemplate($DASkaleFinFarmerSkillbar)
	GoToFahranur()
	Info('Rezoning to Jokanur Diggings')
	MoveTo(20120, 10885)
	MoveTo(20450, 9041)
	RandomSleep(1000)
	WaitMapLoading($ID_Jokanur_Diggings, 10000, 2000)
	$SKALEFIN_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


;~ Move out of outpost into Fahranur Explorable
Func GoToFahranur()
	If GetMapID() <> $ID_Jokanur_Diggings Then TravelToOutpost($ID_Jokanur_Diggings, $DISTRICT_NAME)
	While GetMapID() <> $ID_FAHRANUR_THE_FIRST_CITY
		Info('Moving to Fahranur Explorable')
		MoveTo(-2376, -947)
		MoveTo(-2743, -989)
		RandomSleep(1000)
		WaitMapLoading($ID_FAHRANUR_THE_FIRST_CITY, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func SkaleFinFarmLoop()
	If GetMapID() <> $ID_FAHRANUR_THE_FIRST_CITY Then Return $FAIL
	Info('Starting Skale Fin farming loop')
	SkaleFinFarmMoveRun(17522, 11991, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(14610, 13432, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(11529, 13852, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(10767, 17429, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(9855, 18895, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(7534, 18408, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(5504, 17058, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(1221, 16584, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(966, 15887, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(833, 14083, $RANGE_AREA * 2)
	SkaleFinFarmMoveRun(2620, 14282, $RANGE_AREA * 2)
	Info('Finished Skale Fin farming loop')
	If IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc

;~ Move and ... run ? Who the fuck wrote this ?
Func SkaleFinFarmMoveRun($x, $y, $KillRange)
	If IsPlayerDead() Then Return False
	Local $me = GetMyAgent()

	Move($x, $y)
	While IsPlayerAlive() And GetDistanceToPoint($me, $x, $y) > 250
		If IsRecharged($SkaleFin_DwarvenStability) Then UseSkillEx($SkaleFin_DwarvenStability)
		If IsRecharged($SkaleFin_Dash) Then UseSkillEx($SkaleFin_Dash)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') < 0.5 And GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($SkaleFin_MysticRegeneration)
		If Not IsPlayerMoving() Then Move($x, $y)
		RandomSleep(250)
		$me = GetMyAgent()

		If CountFoesInRangeOfAgent($me, 1200) > 1 Then
			Sleep(2000)
			SkaleFinStartKilling($KillRange)
		EndIf
	WEnd
	Return True
EndFunc

Func PickupAllItemsExceptBoots($item)
	Local $name = DllStructGetData($item, 'ID')
	Info('Item Name: ' & $name)
	Return True
EndFunc

Func SkaleFinStartKilling($KillRange = 900)
	Local $me = GetMyAgent()
	Local $target

	Info('Starting to kill foes')

	If DllStructGetData($me, 'HealthPercent') < 0.50  Then UseSkillEx($SkaleFin_MysticRegeneration)
	
	Sleep(2000)

	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	If IsRecharged($SkaleFin_VowOfStrength) Then UseSkillEx($SkaleFin_VowOfStrength)
		Sleep(500)
	If GetEnergy() >= 10 Then
		$target = GetNearestEnemyToAgent($me)
		UseSkillEx($SkaleFin_StaggeringForce)
		Sleep(100)
		UseSkillEx($SkaleFin_EremitesAttack, $target)
		Sleep(500)
	EndIf

	While CountFoesInRangeOfAgent($me, $KillRange) > 0
		If IsPlayerDead() Then Return $FAIL
			;~ If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($SkaleFin_MysticRegeneration)
			;~ If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($SkaleFin_Conviction)
			If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 And CountFoesInRangeOfAgent($me, 300) > 1 Then UseSkillEx($SkaleFin_SandShards)
				If IsRecharged($SkaleFin_VowOfStrength) <= 0 Then UseSkillEx($SkaleFin_VowOfStrength)
	
		Sleep(250)
		$target = GetNearestEnemyToAgent($me)
		Attack($target)
		$me = GetMyAgent()
	WEnd
	RandomSleep(500)
	Info('Looting')
	PickUpItems()
	Sleep(GetPing())
EndFunc