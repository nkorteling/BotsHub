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
; - noticed some scenarios where map is not cleared - check whether this can be fixed by adding a few additional locations

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $VQ_Arborstone_Farm_Informations = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot doesnt load hero builds - please use your own teambuild'
; Average duration ~ 40m
Global Const $VQ_ARBORSTONE_FARM_DURATION = 41 * 60 * 1000

Global $DonatePoints = False

;~ Main loop for the kurzick faction farm
Func VanquishArborstone($STATUS)
	ArborstoneSetup()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToArborstone()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VanquishArborstoneCycle()
	AdlibUnRegister('TrackPartyStatus')

	; Temporarily change a failure into a pause for debugging :
	;If $result == $FAIL Then $result = $PAUSE
	TravelToOutpost($ID_Altrumm_Ruins, $DISTRICT_NAME)
	Return $result
EndFunc


;~ Setup for kurzick farm
Func ArborstoneSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Altrumm_Ruins, $DISTRICT_NAME)
	; Assuming that team has been set up correctly manually
	If GetKurzickFaction() > (GetMaxKurzickFaction() - 25000) Then
		RandomSleep(200)
		GoNearestNPCToCoords(5390, 1524)

		If $DonatePoints Then
			Info('Donating Kurzick faction points')
			While GetKurzickFaction() >= 5000
				DonateFaction('kurzick')
				RandomSleep(500)
			WEnd
		Else
			Info('Converting Kurzick faction points into Amber Chunks')
			Dialog(0x83)
			RandomSleep(550)
			Local $temp = Floor(GetKurzickFaction() / 5000)
			Local $dialogID = 0x800001 + ($temp * 256)
			Dialog($dialogID)
			RandomSleep(550)
		EndIf
		RandomSleep(500)
	EndIf

	If GetGoldCharacter() < 100 AND GetGoldStorage() > 100 Then
		Info('Withdrawing gold for shrines benediction')
		RandomSleep(250)
		WithdrawGold(100)
		RandomSleep(250)
	EndIf

	SwitchMode($ID_HARD_MODE)
	Info('Preparations complete')
EndFunc


;~ Move out of outpost into Arborstone
Func GoToArborstone()
	If GetMapID() <> $ID_Altrumm_Ruins Then TravelToOutpost($ID_Altrumm_Ruins, $DISTRICT_NAME)
	While GetMapID() <> $ID_Arborstone
		Info('Moving to Arborstone')
		MoveTo(4869, 6477)
		MoveTo(5747, 6874)
		MoveTo(6500, 7500)
		RandomSleep(1000)
		WaitMapLoading($ID_Arborstone, 10000, 2000)
	WEnd
EndFunc

;~ Vanquish the Arborstone map
Func VanquishArborstoneCycle()
	If GetMapID() <> $ID_Arborstone Then Return $FAIL
	Info('Taking blessing')
	GoNearestNPCToCoords(10472, -19582)
	Dialog(0x81)
	Sleep(1000)
	Dialog(0x2)
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)
	Dialog(0x86)
	RandomSleep(1000)

    Local $foes[][] = [ _ 
        [8620, -16318, 'Warden Group 3', $AGGRO_RANGE], _
        [12995, -8929, 'Warden Group 5', $AGGRO_RANGE], _
		[10446, -14122, 'Warden Group 4', 2*$AGGRO_RANGE], _
        [13373, -3077, 'Dredge Group 1', $AGGRO_RANGE], _
        [9915, -3750, 'Dredge Group 2', 2*$AGGRO_RANGE], _
        [8452, -2049, 'Dredge Group 3', $AGGRO_RANGE], _
        [13373, -3077, ' ', $AGGRO_RANGE], _
        [7379, -2078, 'Stone Guardian Group 1', $AGGRO_RANGE], _
        [3940, -164, 'Stone Guardian Boss 1', $AGGRO_RANGE], _
        [2442, -146, 'Warden Group 6', $AGGRO_RANGE], _
        [6365, 1266, 'Dredge Group 4', $AGGRO_RANGE], _
        [7744, 302, 'Dredge Group 5', $AGGRO_RANGE], _
        [8481, 1552, 'Dredge Group 6', $AGGRO_RANGE], _
        [8203, 6123, ' ', $AGGRO_RANGE], _
        [9623, 6391, ' ', $AGGRO_RANGE], _
        [12261, 5101, 'Kirin Group 1', $AGGRO_RANGE], _
        [12828, 1523, 'Dredge Group 7', $AGGRO_RANGE], _
        [12261, 5101, ' ', $AGGRO_RANGE], _
        [10405, 9147, 'Kirin Group 2', $AGGRO_RANGE], _
        [6604, 7236, 'Kirin Group 3', $AGGRO_RANGE], _
        [6948, 11108, 'Dredge Group 8', $AGGRO_RANGE], _
        [10815, 13213, 'Kirin Group 4', $AGGRO_RANGE], _
        [11032, 10609, 'Kirin Group 5', $AGGRO_RANGE], _
        [10815, 13213, ' ', $AGGRO_RANGE], _
        [8360, 13196, ' ', $AGGRO_RANGE], _
        [5213, 13687, 'Kirin Group 6', $AGGRO_RANGE], _
        [1430, 12692, 'Kirin Group 7', $AGGRO_RANGE], _
        [-2829, 11229, 'Kirin Group 8', $AGGRO_RANGE], _
        [-4198, 13870, 'Kirin Group 9', $AGGRO_RANGE], _
        [-8380, 14652, 'Kirin Group 10', $AGGRO_RANGE], _ 
        [-8889, 11924, 'Kirin Group 11', $AGGRO_RANGE], _
        [-8380, 14652, ' ', $AGGRO_RANGE], _
        [-12571, 13772, 'Kirin Group 12', $AGGRO_RANGE], _
        [-8380, 14652, ' ', $AGGRO_RANGE], _
        [-4198, 13870, '', $AGGRO_RANGE], _
        [-2829, 11229, '', $AGGRO_RANGE], _
        [990, 8872, 'Kirin Group 13', $AGGRO_RANGE], _
        [1476, 4712, 'Dredge Group 9', $AGGRO_RANGE], _
        [990, 8872, ' ', $AGGRO_RANGE], _
        [-2075, 5304, 'Dredge Group 10', $AGGRO_RANGE], _ 
        [-4203, 5695, 'Dredge Group 11', $AGGRO_RANGE], _
        [-9480, 5435, ' ', $AGGRO_RANGE], _
        [-10543, 5253, 'Dredge Group 12', $AGGRO_RANGE], _
        [-12027, 3728, 'Dredge Group 13', $AGGRO_RANGE], _ 
        [-11068, -1159, 'Dredge Group 14', $AGGRO_RANGE], _ 
        [-11890, -3553, 'Dredge Group 15', $AGGRO_RANGE], _ 
        [-13091, -5250, 'Dredge Group 16', $AGGRO_RANGE], _ 
        [-11826, -5639, 'Dredge Group 17', $AGGRO_RANGE], _  
        [-12775, -7086, 'Dredge Group 18', $AGGRO_RANGE], _  
        [-11443, -9623, 'Dredge Group 19', $AGGRO_RANGE], _ 
        [-12515, -10285, 'Dredge Boss 1', $AGGRO_RANGE], _ 
        [-11140, -8201, 'Dredge Group 20', $AGGRO_RANGE], _ 
        [-11826, -5639, ' ', $AGGRO_RANGE], _ 
        [-13091, -5250, ' ', $AGGRO_RANGE], _ 
        [-11890, -3553, ' ', $AGGRO_RANGE], _ 
        [-8262, 1514, 'Dredge Group 21', $AGGRO_RANGE], _ 
        [-4675, -629, 'Warden Group 7', $AGGRO_RANGE], _  
        [-2825, 424, 'Warden Group 8', 2*$AGGRO_RANGE], _  ;STAIRS 1
        [-4675, -629, ' ', $AGGRO_RANGE], _ 
        [-5804, -2670, 'Warden Group 9', $AGGRO_RANGE], _  ;STAIRS 2
        [-3565, -3153, 'Warden Group 10', $AGGRO_RANGE], _ ;TOP OF THE STAIRS
        [-1621, -4536, ' ', $AGGRO_RANGE], _
        [324, -5919, ' ', $AGGRO_RANGE], _
        [1744, -4961, 'Warden Group 11', $AGGRO_RANGE], _
        [5914, -5488, 'Warden Group 12', $AGGRO_RANGE], _
        [7943, -9508, ' ', $AGGRO_RANGE], _
        [1991, -9675, 'Warden Group 13', $AGGRO_RANGE], _
        [2683, -9146, 'Warden Boss 1', $AGGRO_RANGE], _
        [3995, -8651, 'Warden Group 14', $AGGRO_RANGE], _
        [3825, -13184, ' ', $AGGRO_RANGE], _
        [-507, -10712, 'Warden Group 15', $AGGRO_RANGE], _
        [-226, -6873, 'Warden Group 16', $AGGRO_RANGE], _
        [324, -5919, ' ', $AGGRO_RANGE], _
        [-3565, -3153, ' ', $AGGRO_RANGE], _
        [-4932, -6954, 'Warden Group 17', $AGGRO_RANGE], _
        [-7485, -9562, 'Warden Group 18', $AGGRO_RANGE], _
        [-8453, -12216, 'Warden Group 19', $AGGRO_RANGE], _
        [-8946, -16725, 'Warden Group 20', $AGGRO_RANGE], _
        [-8453, -12216, ' ', $AGGRO_RANGE], _
        [-4117, -15221, 'Warden Group 21', $AGGRO_RANGE], _
        [-3700, -18096, 'Warden Group 22', $AGGRO_RANGE], _
        [143, -18680, ' ', $AGGRO_RANGE], _
        [3927, -18606, 'Warden Group 23', $AGGRO_RANGE], _
        [2077, -17170, 'Stone Guardian Boss 2', 2*$AGGRO_RANGE], _
        [1414, -16224, 'Stone Guardian Group 2', $AGGRO_RANGE], _
        [-644, -16326, 'Stone Guardian Boss 3', 2*$AGGRO_RANGE], _
        [-2578, -14306, 'Stone Guardian Group 3', $AGGRO_RANGE], _
        [-4281, -11670, ' Stone Guardian Boss 4', 2*$AGGRO_RANGE], _
        [-4281, -11670, 'Stone Guardian Group 4', $AGGRO_RANGE] _
    ]

	If MoveAggroAndKillGroups($foes, 1, UBound($foes)) == $FAIL Then Return $FAIL
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc