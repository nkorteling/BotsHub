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
; Replacing shadow form by something to tank assassins and warriors instead might be better

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global $IsBusy = False
Global Const $PongmeiChestRunnerSkillbar = 'Ogojchpr6SAHFH3kdfjhOXxl3lA'
Global Const $PongmeiChestRunInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Mysticism' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 3 in Deadly Arts' & @CRLF _
	& '- A shield with +30 or +45 health under enchantment or stance' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Windwalker insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& 'Note: in HM, very frequent failures on Am Fah - I suggest cutting that part of the farm if you wish to run in HM'
; Average duration ~ 4m20s
Global Const $PONGMEI_FARM_DURATION = (4 * 60 + 20) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Pongmei_DwarvenStability) is better than UseSkillEx(1))
Global Const $Pongmei_Escape	= 1
Global Const $Pongmei_Lightning_Reflexes	= 2
Global Const $Pongmei_YouAreAllWeaklings		= 3
Global Const $Pongmei_GrenthsAura		= 4
Global Const $Pongmei_CripplingVictory		= 5
Global Const $Pongmei_ReapImpurities	= 6
Global Const $Pongmei_MentalBlock		= 7
Global Const $Pongmei_DwarvenStability		= 8

Global $PONGMEI_FARM_SETUP = False

;~ Main method to chest farm Pongmei
Func PongmeiChestFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	;~ If Not $PONGMEI_FARM_SETUP Then SetupPongmeiFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToPongmeiValley()
	Local $result = PongmeiFarmLoop($STATUS)
	ReturnBackToOutpost($ID_Maatu_Keep)
	Return $result
EndFunc


;~ Pongmei chest farm setup
Func SetupPongmeiFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Maatu_Keep, $DISTRICT_NAME)

	LoadSkillTemplate($PongmeiChestRunnerSkillbar)

	;~ SwitchToHardModeIfEnabled()
	$PONGMEI_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


;~ Move out of outpost into Pongmei Valley
Func GoToPongmeiValley()
	If GetMapID() <> $ID_Maatu_Keep Then TravelToOutpost($ID_Maatu_Keep, $DISTRICT_NAME)
	While GetMapID() <> $ID_Pongmei_Valley
		Info('Moving to Pongmei Valley')
		MoveTo(-13278, 11932)
		MoveTo(-13319, 11400)
		RandomSleep(1000)
		WaitMapLoading($ID_Pongmei_Valley, 1000, 1000)
	WEnd
EndFunc

Func Rezone_PongmeiValley()
	If GetMapID() <> $ID_Maatu_Keep Then TravelToOutpost($ID_Maatu_Keep, $DISTRICT_NAME)
	While GetMapID() <> $ID_Pongmei_Valley
		GoToPongmeiValley()
		MoveTo(-13277, 7857)
		MoveTo(-13401, 11000)
		WaitMapLoading($ID_Maatu_Keep, 1000, 1000)
	WEnd
EndFunc


;~ Pongmei Chest farm loop
Func PongmeiFarmLoop($STATUS)
	If GetMapID() <> $ID_Pongmei_Valley Then Return $FAIL
	Info('Starting Granite farm')
	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent(GetMyAgent())

	; Switch to weapon set 2 before starting the farm loop
	SwitchWeaponSet(2)
	MoveTo(-15974, 7859)
	AttackClosestEnemy()
	Sleep(100) ; Give time for the attack to register
	While GetAgentAction(GetMyID()) <> $ACTION_Attack
		Sleep(500)
	WEnd
	MoveTo(-14920, 7652)
	Sleep(2000)
	Pongmei_KillCycle()

	
EndFunc


;~ Method to check to which place you are the closest to
Func SkipToPreventBackTracking($X, $Y, $nextX, $nextY)
	Local $me = GetMyAgent()
	If GetDistanceToPoint($me, $X, $Y) < GetDistanceToPoint($me, $nextX, $nextY) Then
		Info('Skipping')
		Return True
	EndIf
	Return False
EndFunc

Func Pongmei_KillCycle()
	Local $me = GetMyAgent()
	Local $foes = GetAgentsInRange($me, 1200, True) ; 1200 units is a typical aggro range, True = only foes
	Register_Pongmei_KillCycle()
	While UBound($foes) > 1
		Local $closestFoe = _GWA2_GetClosestAgent($me, $foes)
		If IsAgentInAttackRange($closestFoe) Then
			AttackAgent($closestFoe)
		Else
			MoveToAgent($closestFoe)
		EndIf
		$foes = GetAgentsInRange($me, 1200, True) ; Refresh foes list
	WEnd
	; Pickup items after killing all foes
	Unregister_Pongmei_KillCycle()
	PickUpItems()
	Return $SUCCESS
EndFunc

Func Register_Pongmei_EscapeCycle()
	AdlibRegister('Pongmei_EscapeCycle', 1000)
	AdlibRegister('Pongmei_DwarvenStability', 5000)	
EndFunc

Func Unregister_Pongmei_EscapeCycle()
	AdlibUnRegister('Pongmei_EscapeCycle')
	AdlibUnRegister('Pongmei_DwarvenStability')
EndFunc

Func Register_Pongmei_KillCycle()
	UseSkillEx($Pongmei_MentalBlock)
	UseSkillEx($Pongmei_Lightning_Reflexes)
	UseSkillEx($Pongmei_GrenthsAura)
	UseSkillEx($Pongmei_YouAreAllWeaklings)
	AdlibRegister('Pongmei_GrenthsAuraCycle', 11000)
	AdlibRegister('Pongmei_CripplingVictoryCycle', 2000)
	AdlibRegister('Pongmei_ReapImpuritiesCycle', 2000)
	AdlibRegister('Pongmei_YouAreAllWeaklingsCycle', 13000)
EndFunc

Func Unregister_Pongmei_KillCycle()
	AdlibUnRegister('Pongmei_GrenthsAuraCycle')
	AdlibUnRegister('Pongmei_CripplingVictoryCycle')
	AdlibUnRegister('Pongmei_ReapImpuritiesCycle')
	AdlibUnRegister('Pongmei_YouAreAllWeaklingsCycle')
EndFunc

Func Pongmei_GrenthsAuraCycle()
	If IsRecharged($Pongmei_GrenthsAura) And GetEnergy() > 13 Then
		While $IsBusy
			Sleep(100)
		WEnd
		$IsBusy = True
		UseSkillEx($Pongmei_GrenthsAura)
		$IsBusy = False
	EndIf
EndFunc

Func Pongmei_CripplingVictoryCycle()
	If IsRecharged($Pongmei_CripplingVictory) Then
		While $IsBusy
			Sleep(100)
		WEnd
			$IsBusy = True
			UseSkillEx($Pongmei_CripplingVictory)
			$IsBusy = False
	EndIf
EndFunc

Func Pongmei_ReapImpuritiesCycle()
	If IsRecharged($Pongmei_ReapImpurities) Then
		While $IsBusy
			Sleep(100)
		WEnd
			$IsBusy = True
			UseSkillEx($Pongmei_ReapImpurities)
			$IsBusy = False
	EndIf
EndFunc

Func Pongmei_YouAreAllWeaklingsCycle()
	If IsRecharged($Pongmei_YouAreAllWeaklings) Then
		UseSkillEx($Pongmei_YouAreAllWeaklings)
	EndIf
EndFunc

Func Pongmei_EscapeCycle()
	If IsRecharged($Pongmei_Escape) And IsRecharged($Pongmei_Lightning_Reflexes)Then
		UseSkillEx($Pongmei_Escape)
	EndIf
EndFunc

Func Pongmei_DwarvenStability()
	If IsRecharged($Pongmei_DwarvenStability) Then
		While $IsBusy
			Sleep(100)
		WEnd
			$IsBusy = True
			UseSkillEx($Pongmei_DwarvenStability)
			$IsBusy = False
	EndIf
EndFunc