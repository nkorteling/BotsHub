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
Global Const $WS_Skillbar = 'OACjAqiMJSXT+glTfTRbVTMTUPA'
Global Const $WS_Hero_Skillbar = 'OQCiYyo8sj5xm4bMAAAAAAAA'
Global Const $WS_FarmInformations = 'For best results, have :'
	& '- The Missing Daughter quest not completed'
; Average duration ~ 3m ~ First run is 3m20s with setup
Global Const $WINGSTORM_FARM_DURATION = (3 * 60 + 10) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($WS_DwarvenStability) is better than UseSkillEx(1))
Global Const $WS_SignetOfSpirits	= 1
Global Const $WS_Vampirism			= 2
Global Const $WS_BloodSong	        = 3
Global Const $WS_Pain		        = 4
Global Const $WS_Anguish	        = 5
Global Const $WS_PainfulBond	    = 6
Global Const $WS_SpiritSiphon		= 7
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

	GoToDrazachThicket()
	Local $result = WingStormFarmLoop()
	ReturnBackToOutpost($ID_The_Eternal_Grove)
	Return $result
EndFunc


;~ WingStorm farm team setup
Func SetupTeamWingStormFarm()
	
	Info('Setting up team')
	Sleep(500)
	LeaveParty()
	RandomSleep(500)
	Info('Adding General Morgahn')
	AddHero($ID_General_Morgahn)
	Sleep(1000)
	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf

	Info('Loading Character skillbar')
	LoadSkillTemplate($WS_Skillbar)
	Info('Loading Hero skillbars')
	LoadSkillTemplate($WS_Hero_Skillbar, 1)


	Sleep(250)
	DisableAllHeroSkills(1)
	EnableHeroSkillSlot($ID_General_Morgahn, $WS_FallBack)
	EnableHeroSkillSlot($ID_General_Morgahn, $WS_Incoming)
	Sleep(500)

EndFunc

Func GoToDrazachThicket()
    Info('Traveling to Drazach Thicket')
    MoveTo(-2120, 12600)
    MoveTo(-6101, 14303)
    WaitMapLoading($ID_Drazach_Thicket, 10000, 1000)
EndFunc

Func DrazachRezone()
    Info('Rezoning Drazach Thicket')
    GoToDrazachThicket()
    MoveTo(-3403, -16256)
    WaitMapLoading($ID_The_Eternal_Grove, 10000, 1000)
EndFunc

Func MoveToArea()
    Local Const $WS_Run_Path = [ _
        [-3904, -16110], _
        [-8503, -15141], _
        [-8551, -13780], _
        [-7602, -12960], _
        [-6880, -12576], _
    ]
    Local Const $WS_Solo_Path = [ _
        [-5852, -12506], _
        [-4858, -11407], _
        [-5034, -10906], _
        [-5428, -8922], _
    ]

    Info('Moving to Wingstorm area')
    For $i = 0 To UBound($WS_Run_Path) - 1
        MoveTo($WS_Run_Path[$i][0], $WS_Run_Path[$i][1])
    Next

    UseHeroSkillSlot($ID_General_Morgahn, $WS_EnduringHarmony, GetMyAgent())
    Sleep(1000)
    UseHeroSkillSlot($ID_General_Morgahn, $WS_MakeHaste, GetMyAgent())
    CommandAll(-5359, -16369)

    For $i = 0 To UBound($WS_Solo_Path) - 1
        MoveTo($WS_Solo_Path[$i][0], $WS_Solo_Path[$i][1])
    Next

    Info('Waiting for keypress to restart...')
    While Not _IsPressed('j') ; 0D is the virtual-key code for Enter
        Sleep(100)
    WEnd
    Return $SUCCES

EndFunc