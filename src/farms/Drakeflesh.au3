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

; Possible improvements : rewrite it all

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $DADrakefleshFarmerSkillbar = 'OgejkmrMbSmXfbaXNXTQ3lEYsXA'
Global Const $DrakefleshFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Earth Prayers' & @CRLF _
	& '- 10 in Scythe Mastery' & @CRLF _
	& '- 10 in Mysticism' & @CRLF _
	& '- A scythe with +5 energy and +20% enchantment duration' & @CRLF _
	& '- A one handed weapon +5 energy and +20% enchantment duration' & @CRLF _
	& '- A shield' & @CRLF _
	& '- Windwalker or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 8m20
Global Const $DRAKEFLESH_FARM_DURATION = (8 * 60 + 20) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Drakeflesh_SandShards) is better than UseSkillEx(1))
Global Const $Drakeflesh_SandShards			= 1
Global Const $Drakeflesh_VowOfStrength		= 2
Global Const $Drakeflesh_StaggeringForce	= 3
Global Const $Drakeflesh_EremitesAttack		= 4
Global Const $Drakeflesh_Dash				= 5
Global Const $Drakeflesh_DwarvenStability	= 6
Global Const $Drakeflesh_Conviction			= 7
Global Const $Drakeflesh_MysticRegeneration	= 8

Global $DRAKEFLESH_FARM_SETUP = False

;~ Main method to farm feathers
Func DrakefleshFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $DRAKEFLESH_FARM_SETUP Then SetupDrakefleshFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToMahnkelon()
	Local $result = DrakefleshFarmLoop()
	ReturnBackToOutpost($ID_Rilohn_Refuge)
	Return $result
EndFunc


;~ Drake Flesh farm setup
Func SetupDrakefleshFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Rilohn_Refuge, $DISTRICT_NAME)
	SwitchMode($ID_NORMAL_MODE)
	LeaveParty() ; solo farmer
	LoadSkillTemplate($DADrakefleshFarmerSkillbar)

	Info('Entering Jaya Bluffs')
	Local $me = GetMyAgent()

	If GetDistanceToPoint($me, 17300, 17300) > 5000 Then MoveTo(17000, 12400)
	If GetDistanceToPoint($me, 17300, 17300) > 4400 Then MoveTo(19000, 13450)
	If GetDistanceToPoint($me, 17300, 17300) > 1800 Then MoveTo(18750, 16000)

	GoToMahnkelon()
	Move(10500, -13100)
	Move(10970, -13360)
	RandomSleep(1000)
	WaitMapLoading($ID_Rilohn_Refuge, 10000, 2000)
	$DRAKEFLESH_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


;~ Move out of outpost into Jaya Bluffs
Func GoToMahnkelon()
	If GetMapID() <> $ID_Rilohn_Refuge Then TravelToOutpost($ID_Rilohn_Refuge, $DISTRICT_NAME)
	While GetMapID() <> $ID_Floodplains_of_Mahnkelon
		Info('Moving to Jaya Bluffs')
		MoveTo(17300, 17300)
		Move(16800, 17550)
		RandomSleep(1000)
		WaitMapLoading($ID_Floodplains_of_Mahnkelon, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func DrakefleshFarmLoop()
	If GetMapID() <> $ID_Floodplains_of_Mahnkelon Then Return $FAIL

	Info('Running to Sensali.')
	UseConsumable($ID_Birthday_Cupcake)
	MoveTo(-14645, 8198)
	MoveTo(-13616, 8409)
	MoveTo(-12010, 10584)
	MoveTo(-10646, 10847)
	Info('Farming Sensali.')
	DrakefleshMoveKill(-8828, 11882, True)

	If IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Move and ... run ? Who the fuck wrote this ?
Func DrakefleshMoveRun($x, $y, $timeOut = 2*60*1000)
	If IsPlayerDead() Then Return False
	Local $me = GetMyAgent()
	Local $deadlock = TimerInit()

	Move($x, $y)
	While IsPlayerAlive() And GetDistanceToPoint($me, $x, $y) > 250
		If TimerDiff($deadlock) > $timeOut Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While IsPlayerAlive() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
		EndIf
		If IsRecharged($Drakeflesh_DwarvenStability) Then UseSkillEx($Drakeflesh_DwarvenStability)
		If IsRecharged($Drakeflesh_Dash) Then UseSkillEx($Drakeflesh_Dash)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HP') < 0.95 And GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Drakeflesh_MysticRegeneration)
		If Not IsPlayerMoving() Then Move($x, $y)
		RandomSleep(250)
		$me = GetMyAgent()
	WEnd
	Return True
EndFunc


;~ Move and kill I suppose
Func DrakefleshMoveKill($x, $y, $DrakeFleshwaitForSettle = True, $timeout = 5*60*1000)
	If IsPlayerDead() Then Return $FAIL
	Local $Angle = 0
	Local $stuckCount = 0
	Local $Blocked = 0
	Local $deadlock = TimerInit()

	Move($x, $y)
	Local $me = GetMyAgent()
	; TODO: fix this mess
	While GetDistanceToPoint($me, $x, $y) > 250
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While IsPlayerAlive() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
			If IsPlayerDead() Then Return $FAIL
		EndIf
		If IsPlayerDead() Then Return $FAIL
		If IsRecharged($Drakeflesh_DwarvenStability) Then UseSkillEx($Drakeflesh_DwarvenStability)
		If IsRecharged($Drakeflesh_Dash) Then UseSkillEx($Drakeflesh_Dash)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HP') < 0.9 Then
			If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Drakeflesh_MysticRegeneration)
			If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Drakeflesh_Conviction)
		EndIf
		$me = GetMyAgent()
		If CountFoesInRangeOfAgent($me, 1200, IsSensali) > 1 Then
			Sleep(2000)
			DrakeFleshKill($DrakeFleshwaitForSettle)
		EndIf
		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$Blocked += 1
			If $Blocked <= 5 Then
				Move($x, $y)
			Else
				$me = GetMyAgent()
				$Angle += 40
				Move(DllStructGetData($me, 'X')+300*sin($Angle), DllStructGetData($me, 'Y') + 300*cos($Angle))
				Sleep(2000)
				Move($x, $y)
			EndIf
		EndIf
		$stuckCount += 1
		If $stuckCount > 25 Then
			$stuckCount = 0
			SendChat('stuck', '/')
			RandomSleep(50)
		EndIf
		RandomSleep(250)
		$me = GetMyAgent()
	WEnd
	Return $SUCCESS
EndFunc


;~ Kill foes
Func DrakeFleshKill($DrakeFleshwaitForSettle = True)
	If IsPlayerDead() Then Return $FAIL

	Local $deadlock, $timeout = 2*60*1000

	Local $stuckCount = 0
	SendChat('stuck', '/')
	RandomSleep(50)
	If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Drakeflesh_SandShards)
	If $DrakeFleshwaitForSettle Then
		If Not DrakeFleshWaitForSettle() Then Return $FAIL
	EndIf
	SendChat('stuck', '/')
	RandomSleep(50)
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeWeaponSet(1)
	If IsRecharged($Drakeflesh_VowOfStrength) Then UseSkillEx($Drakeflesh_VowOfStrength)
	If GetEnergy() >= 10 Then
		UseSkillEx($Drakeflesh_StaggeringForce)
		UseSkillEx($Drakeflesh_EremitesAttack, $target)
	EndIf
	ChangeWeaponSet(1)

	$deadlock = TimerInit()

	While CountFoesInRangeOfAgent(GetMyAgent(), 900, IsSensali) > 0
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While IsPlayerAlive() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
			If IsPlayerDead() Then Return $FAIL
		EndIf
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestEnemyToAgent(GetMyAgent())
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Drakeflesh_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Drakeflesh_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 And CountFoesInRangeOfAgent(GetMyAgent(), 300) > 1 Then UseSkillEx($Drakeflesh_SandShards)
		If IsRecharged($Drakeflesh_VowOfStrength) <= 0 Then UseSkillEx($Drakeflesh_VowOfStrength)
		$stuckCount += 1
		If $stuckCount > 100 Then
			$stuckCount = 0
			SendChat('stuck', '/')
			RandomSleep(50)
		EndIf

		Sleep(250)
		Attack($target)
	WEnd
	RandomSleep(500)
	Info('Looting')
	PickUpItems()
	FindAndOpenChests()
	ChangeWeaponSet(2)
	Return $SUCCESS
EndFunc


;~ Wait for foes to settle, I guess ?
Func DrakeFleshWaitForSettle($Timeout = 10000)
	Local $me = GetMyAgent()
	Local $target
	Local $deadlock = TimerInit()
	While IsPlayerAlive() And CountFoesInRangeOfAgent(-2,900) == 0 And (TimerDiff($deadlock) < 5000)
		If IsPlayerDead() Then Return False
		If DllStructGetData($me, 'HP') < 0.7 Then Return True
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Drakeflesh_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Drakeflesh_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Drakeflesh_SandShards)
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords(3, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd

	If CountFoesInRangeOfAgent($me, 900) == 0 Then Return False

	$deadlock = TimerInit()
	While (GetDistance($me, $target) > $RANGE_NEARBY) And (TimerDiff($deadlock) < $Timeout)
		If IsPlayerDead() Then Return False
		If DllStructGetData($me, 'HP') < 0.7 Then Return True
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Drakeflesh_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Drakeflesh_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Drakeflesh_SandShards)
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords(3, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd
	Return True
EndFunc
