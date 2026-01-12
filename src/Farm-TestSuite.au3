#CS ===========================================================================
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
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'
#include '../lib/Utils.au3'


;~ Main method to run the test suite
Func RunTestSuite($STATUS)
	Global $captureCoords = False
	Global $clearCoords = False
	Global $groupCount = 0

	HotKeySet("j", "CapturePosition")
	HotKeySet("o", "ClearPosition")
	
	Info('Coordinate Logger Active - Press J to log position, O to Clear Position, ESC to exit')
	
	While True
		Sleep(100)
		If $captureCoords Then
			Local $me = GetMyAgent()
			Local $x = Round(DllStructGetData($me, 'X'))
			Local $y = Round(DllStructGetData($me, 'Y'))
			Info("Position: MoveTo(" & $x & ", " & $y & ")")
			Info("Current Map ID: " & GetMapID())
			$captureCoords = False
		EndIf
		If $clearCoords Then
			$groupCount += 1

			Local $me = GetMyAgent()
			Local $closestEnemy = GetNearestEnemyToAgent($me)
			If IsDllStruct($closestEnemy) Then
				Local $modelID = DllStructGetData($closestEnemy, 'ModelID')
				Local $name = GetAgentName($closestEnemy)
			EndIf

			Local $groupName = $name & " Group " & $groupCount
			Local $x = DllStructGetData($me, 'X')
			Local $y = DllStructGetData($me, 'Y')
			Local $foes[1][4] = [[ $x, $y, $groupName, $AGGRO_RANGE ]]
			Info($name & " group cleared.")
			Info("MoveAggroAndKillGroups(" & $x & ", " & $y & ", " & $groupName & ", " & $AGGRO_RANGE & ")")
			MoveAggroAndKillGroups($foes, 1, UBound($foes))
			$clearCoords = False
		EndIf

	WEnd
	
	HotKeySet("j")
	HotKeySet("o")
	Return $SUCCESS
EndFunc

Func CapturePosition()
	$captureCoords = True
EndFunc

Func ClearPosition()
    $clearCoords = True
EndFunc