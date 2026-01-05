; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

; Possible improvements :

Opt('MustDeclareVars', 1)

; ==== Constantes ====
Global Const $MinotaurHornInformations = 'For best results, have :' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot doesnt load hero builds - please use your own teambuild'

;~ Main loop for the minotaur horn farm
Func MinotaurHornFarm($STATUS)
	If GetMapID() <> $ID_Augury_Rock Then
		Info('Moving to Outpost')
		DistrictTravel($ID_Augury_Rock, $DISTRICT_NAME)
	EndIf

	MinotaurHornFarmSetup()

	If $STATUS <> 'RUNNING' Then Return 2

	MoveTo(-17071, -1065)
	MoveTo(-18069, -1026)
	MoveTo(-18853, -444)
	MoveTo(-20100, -400)
	RndSleep(1000)
	WaitMapLoading($ID_Prophets_Path, 10000, 2000)
	;ResetFailuresCounter()
	;AdlibRegister('TrackGroupStatus', 10000)
	Local $result = FarmMinotaurHorns()
	;AdlibUnRegister('TrackGroupStatus')

	; Temporarily change a failure into a pause for debugging :
	;If $result == 1 Then $result = 2
	Return $result
EndFunc

;~ Setup for the farm
Func MinotaurHornFarmSetup()
	SwitchMode($ID_NORMAL_MODE)
EndFunc

;~ Vanquish the map
Func FarmMinotaurHorns()
	If MoveAggroAndKill(18870, -6, '1',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(18828, 2201, '2',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(17106, 1459, '3',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(14424, 134, '4',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(10852, 1967, '5',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(10704, 6422, '6',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(9081, 7155, '7',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(8755, 10512, '8',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(12348, 10156, '9',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(7001, 8789, '10',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(5155, 8838, '11',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	If MoveAggroAndKill(2616, 7615, '12',$RANGE_EARSHOT * 1.5,Null,True) Then Return 1
	Return 0
EndFunc   ;==>FarmMinotaurHorns