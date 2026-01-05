; Author: An anonymous fan of Dhuum
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

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'


Opt('MustDeclareVars', 1)

; ==== Constantes ====
Global Const $DeldrimorFarmInformations = 'Deldrimor title farm, bring solid heroes composition'
; Average duration ~ 45m
Global Const $DELDRIMOR_FARM_DURATION = 45 * 60 * 1000

;~ Main loop for the norn faction farm
Func DeldrimorTitleFarm($STATUS)
	If GetMapID() <> $ID_Umbral_Grotto Then
		Info('Moving to Rata Sum')
		DistrictTravel($ID_Umbral_Grotto, $DISTRICT_NAME)
		WaitMapLoading($ID_Umbral_Grotto, 10000, 2000)
	EndIf
	DeldrimorTitleSetup()

	AdlibRegister('TrackGroupStatus', 10000)
	Local $result = DeldrimorTitle()
	AdlibUnRegister('TrackGroupStatus')
	; Temporarily change a failure into a pause for debugging :
	;If $result == 1 Then $result = 2
	Return $result
EndFunc   ;==>DeldrimorTitleFarm

Func DeldrimorTitleSetup()
	SwitchMode($ID_HARD_MODE)
	SetTitleDwarven()
EndFunc   ;==>DeldrimorTitleSetup

Func DeldrimorTitle()

	Info("Taking Quest")
	GoNearestNPCToCoords(-23818, 13931)
	RandomSleep(750)
	Dialog(8618497)
	RandomSleep(750)
	GoNearestNPCToCoords(-23818, 13931)
	RandomSleep(750)
	Dialog(0x00000083)
	Dialog(0x00000084)
	RandomSleep(200)
	WaitMapLoading($ID_Secret_Lair_Of_The_Snowmen, 10000, 2000)

	GoNearestNPCToCoords(-14103, 15457)
	RandomSleep(1000)
	Dialog(0x00000084)
	RandomSleep(1000)

	If MoveAggroAndKill(-15988, 10018, 'Snowmen at begining') Then Return 1
	If MoveAggroAndKill(-17986, 6483, '') Then Return 1
	If MoveAggroAndKill(-17574, 2190, 'Snowmen') Then Return 1
	If MoveAggroAndKill(-15361, 2551, 'Cleaning way') Then Return 1
	If MoveAggroAndKill(-14596, 2612, 'Going to shrine') Then Return 1
	If MoveAggroAndKill(-14506, 3963, '') Then Return 1

	GoNearestNPCToCoords(-12512, 3919)
	RandomSleep(500)

	If MoveAggroAndKill(-14556, 4065, '') Then Return 1
	If MoveAggroAndKill(-14596, 2612, '') Then Return 1
	If MoveAggroAndKill(-14583, 1896, '') Then Return 1
	If MoveAggroAndKill(-14262, 974, '') Then Return 1
	If MoveAggroAndKill(-13759, -552, '') Then Return 1
	If MoveAggroAndKill(-13306, -1211, '') Then Return 1
	If MoveAggroAndKill(-12570, -2997, '') Then Return 1

	If MoveAggroAndKill(-13114, -6255, 'Snowman') Then Return 1
	If MoveAggroAndKill(-14367, -9244, 'Snowman') Then Return 1

	GoNearestNPCToCoords(-16025, -10702)
	RandomSleep(500)

	If MoveAggroAndKill(-15396, -10850, 'Ennemy near door') Then Return 1

	If MoveAggroAndKill(-13970, -9719) Then Return 1
	If MoveAggroAndKill(-13047, -10683) Then Return 1

	If MoveAggroAndKill(-10097, -11373, 'Angry Snowman') Then Return 1

	Moveto(-9852, -11078)
	RandomSleep(500)
	RandomSleep(2000)
	MoveTo(-9547, -10960)
	RandomSleep(500)
	Sleep(1000)

	MoveAggroAndKill(-11464, -11034)
	MoveAggroAndKill(-14162, -9527)
	MoveAggroAndKill(-15284, -10824)
	MoveAggroAndKill(-15454, -12245)
	ClearTarget()
	RandomSleep(500)
	TargetNearestItem()
	ActionInteract()
	RandomSleep(500)
	ActionInteract()
	Moveto(-15869, -12119)

	If MoveAggroAndKill(-17287, -13895, 'Snowman') Then Return 1
	If MoveAggroAndKill(-15483, -16565, 'Boss and others') Then Return 1
	If MoveAggroAndKill(-13362, -17430, '') Then Return 1

	If MoveAggroAndKill(-12974, -17414) Then Return 1
	PickUpItems()

	If MoveAggroAndKill(-11215, -18002) Then Return 1
	TargetNearestItem()
	RandomSleep(500)
	ActionInteract()

	MoveAggroAndKill(-11300, -18290)
	MoveAggroAndKill(-9618, -19271)
	MoveAggroAndKill(-7856, -19136)
	MoveAggroAndKill(-7560, -18592)

	Local $chestspawn = False
	Local $TimerGuynotThere = TimerInit()
	Do
		TargetNearestItem()
		Sleep(500)
		If DllStructGetData(GetCurrentTarget(), 'ID') <> 32 Then $chestspawn = True
		If TimerDiff($TimerGuynotThere) > 240000 Then
			CurrentAction("Apparently, Koris is stuck somewhere on the dungeon, go again")
			Sleep(2000)
			Return
		EndIf
	Until $chestspawn = True

	TargetNearestItem()
	ActionInteract()
	RandomSleep(2500)
	PickUpItems()

	Return $SUCCESS
EndFunc   ;==>DeldrimorTitle