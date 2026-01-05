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

Opt('MustDeclareVars', 1)

Global Const $WS_Timeout = 120000

; ==== Constants ====
Global Const $WS_Skillbar = 'OAejAqiMJSXT+glTfTRbVTrgUPA'
Global Const $WS_Hero_Skillbar = 'OQCiYyo8sj5xm4bMAAAAAAAA'
Global Const $WS_FarmInformations = 'For best results, have :'
; Average duration ~ 3m ~ First run is 3m20s with setup
Global Const $WINGSTORM_FARM_DURATION = (3 * 60 + 10) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($WS_DwarvenStability) is better than UseSkillEx(1))
Global Const $WS_SignetOfSpirits	= 1
Global Const $WS_Vampirism			= 2
Global Const $WS_BloodSong	        = 3
Global Const $WS_Pain		        = 4
Global Const $WS_Anguish	        = 5
Global Const $WS_PainfulBond	    = 6
Global Const $WS_ShadowSanctuary  	= 7
Global Const $WS_FeastOfSouls	    = 8

; Hero Build 4
Global Const $Hero_WS_GeneralMorgahn= 1
Global Const $WS_Incoming			= 1
Global Const $WS_FallBack			= 2
Global Const $WS_EnduringHarmony	= 3
Global Const $WS_MakeHaste			= 4

Global $WS_FARM_SETUP = False

;~ Main method to farm WingStorm
Func WingStormFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $WS_FARM_SETUP Then SetupWingStormFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	WS_GoToDrazachThicket()

	Local $result = WingStormFarmLoop()

	ReturnBackToOutpost($ID_The_Eternal_Grove)
	Return $result
EndFunc

Func SetupWingStormFarm()
    Info('Setting up Wingstorm farm')

    Local $setupTeam = MsgBox(4, "Setup Team", "Do you want to setup the team (add heroes and load builds)?")
	If $setupTeam = 6 Then ; Yes
		WS_SetupTeam()
	EndIf

	Local $setupTeam = MsgBox(4, "Rezone", "Do you need to rezone?")
	If $setupTeam = 6 Then ; Yes
		WS_DrazachRezone()
	EndIf

    $WS_FARM_SETUP = True
EndFunc


;~ WingStorm farm team setup
Func WS_SetupTeam()
	
	Info('Setting up team')
	Sleep(500)
	LeaveParty()
	RandomSleep(500)
	Info('Adding General Morgahn')
	AddHero($ID_General_Morgahn)
	Sleep(1000)
	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 2')
	EndIf

	Info('Loading Character skillbar')
	LoadSkillTemplate($WS_Skillbar)
	Info('Loading Hero skillbars')
	LoadSkillTemplate($WS_Hero_Skillbar, 1)

	Sleep(250)
	DisableAllHeroSkills(1)
    Sleep(500)
	EnableHeroSkillSlot($Hero_WS_GeneralMorgahn, $WS_FallBack)
	EnableHeroSkillSlot($Hero_WS_GeneralMorgahn, $WS_Incoming)
	Sleep(500)

EndFunc

Func WS_GoToDrazachThicket()
    Info('Traveling to Drazach Thicket')
    MoveTo(-6401, 14503)
    WaitMapLoading($ID_Drazach_Thicket, 10000, 1000)
EndFunc

Func WS_DrazachRezone()
    Info('Rezoning Drazach Thicket')
    MoveTo(-2120, 12600)
    WS_GoToDrazachThicket()
    MoveTo(-3004, -16256)
    WaitMapLoading($ID_The_Eternal_Grove, 10000, 1000)
EndFunc

Func WingStormFarmLoop()
    Info('Starting Wingstorm farm loop')
    Local $farmStartTime = TimerInit()

    Local $moveResult = MoveToArea()
    If $moveResult <> $SUCCESS Then
        Warn('Error moving to Wingstorm area, aborting farm loop')
        Return $FAIL
    EndIf

    Info('Wingstorm farm loop completed')
    Return $SUCCESS
EndFunc

Func MoveToArea()
    Info('Moving to Wingstorm area')
    MoveTo(-3904, -16110)
    MoveTo(-8503, -15141)
    MoveTo(-8551, -13780)
    MoveTo(-7602, -12960)
    MoveTo(-6880, -12576)
    Sleep (1000)

    UseHeroSkill($Hero_WS_GeneralMorgahn, $WS_EnduringHarmony, GetMyAgent())
    Sleep(1000)
    UseHeroSkill($Hero_WS_GeneralMorgahn, $WS_MakeHaste, GetMyAgent())
    CommandAll(-5359, -16369)

    MoveTo(-5852, -12506)
    MoveTo(-4858, -11407)
    MoveTo(-5034, -10906)
    MoveTo(-5341, -8943)
    MoveTo(-5480, -7935)
    MoveTo(-5341, -8943)
    Sleep(4000)

    Info('Arrived at Wingstorm area')

    ; Wait until player is at least 90% HP
    Local $lifeRatio = DllStructGetData(GetMyAgent(), 'HP')
    If $lifeRatio < 0.9 Then
		Sleep(4000)
    EndIf   

    UseSkillEx($WS_SignetOfSpirits)
    Sleep(1000)
    UseSkillEx($WS_Vampirism)
    Sleep(750)
    UseSkillEx($WS_BloodSong)
    Sleep(750)
    UseSkillEx($WS_Pain)
    Sleep(750)
    UseSkillEx($WS_Anguish)
    Sleep(750)

    CheckForFoes()
    
    Local $lifeRatio = DllStructGetData(GetMyAgent(), 'HP')
    If $lifeRatio < 0.9 Then
		Sleep(4000)
    EndIf
    
    Sleep(1000)
    
    CheckForFoes()

    Local $boss = GetNearestBossFoe()
    UseSkillEx($WS_PainfulBond, $boss)
    Sleep(1000)
    MoveTo(-5240, -8943)
    UseSkillEx($WS_ShadowSanctuary)
    
    Sleep(6000)

    If Not IsPlayerAlive() Then
        Warn('Player died during Wingstorm event')
        Return $FAIL
    EndIf

    UseSkillEx($WS_FeastOfSouls)
    UseSkillEx($WS_ShadowSanctuary)
    Sleep(5000)

    Info('Boss defeated, moving to loot area')
    

    ; Loot items in the area
    Local $item = GetNearestItemToAgent(GetMyAgent())
    If $item <> 0 Then
        MoveTo(DllStructGetData($item, 'X'), DllStructGetData($item, 'Y'))
        PickUpItems()
        Sleep(1000)
    EndIf

    If Not IsPlayerAlive() Then
        Warn('Player died during looting')
        Return $FAIL
    EndIf

    Return $SUCCESS

EndFunc

Func CheckForFoes()
    If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA) > 0 Then
        Info('Foes already present in the area, skipping boss search')
        UseSkillEx($WS_PainfulBond, GetNearestEnemyToAgent(GetMyAgent()))
        While CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA) > 0
            Sleep(2000) ; Wait for foes to be defeated
            If Not IsPlayerAlive() Then
                Warn('Player died during Wingstorm event')
            Return $FAIL
            EndIf
        WEnd
        Info('Foes defeated, proceeding to loot')
        PickUpItems()
        Sleep(1000)
        ; Wait until player is at least 90% HP
        Local $lifeRatio = DllStructGetData(GetMyAgent(), 'HP')
        If $lifeRatio < 0.9 Then
            Sleep(4000)
        EndIf   

        While Not IsRecharged($WS_Anguish)
            Sleep(500)
        WEnd

        UseSkillEx($WS_SignetOfSpirits)
        Sleep(1000)
        UseSkillEx($WS_Vampirism)
        Sleep(750)
        UseSkillEx($WS_BloodSong)
        Sleep(750)
        UseSkillEx($WS_Pain)
        Sleep(750)
        UseSkillEx($WS_Anguish)
        Sleep(750)
        UseSkillEx($WS_ShadowSanctuary)
    EndIf
EndFunc