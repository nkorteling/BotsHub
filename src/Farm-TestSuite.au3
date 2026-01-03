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

	HotKeySet("j", "CapturePosition")
	
	Info('Coordinate Logger Active - Press J to log position, ESC to exit')
	
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
	WEnd
	
	HotKeySet("j")
	Return $SUCCESS
EndFunc

Func CapturePosition()
	$captureCoords = True
EndFunc
