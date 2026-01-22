#CS ===========================================================================
#################################
#								#
#			Vaettir Bot			#
#								#
#################################
Author: gigi
Modified by: Pink Musen (v.01), Deroni93 (v.02-3), Dragonel (with help from moneyvsmoney), Night, Gahais
;
; Run this farm bot as Assassin or Mesmer or Monk or Elementalist
;
; Vaettir farms in Jaga Moraine based on below articles:
https://gwpvx.fandom.com/wiki/Build:A/Me_Vaettir_Farm
https://gwpvx.fandom.com/wiki/Build:Me/A_Vaettir_Farm
https://gwpvx.fandom.com/wiki/Build:Mo/A_55hp_Vaettir_Farmer
https://gwpvx.fandom.com/wiki/Build:E/Me_Obsidian_Flesh_Vaettir_Farmer
#CE ===========================================================================

#include-once
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $AME_KAPPA_FARMER_SKILLBAR = 'OwVU4lPL2hN8Id2BEBSANBLhbK'
Global Const $MEA_KAPPA_FARMER_SKILLBAR = 'OQdUAMhOsPP8Id2BEBSANBLhbK'
Global Const $MOA_KAPPA_FARMER_SKILLBAR = 'OwcT8Y/8ZqegHRnBXMgxtE3ReAA'
Global Const $EME_KAPPA_FARMER_SKILLBAR = 'OgVFwDKJL7Uk0n2wXlLoBgJwSwNF'
Global Const $R_KAPPA_HERO_SKILLBAR = 'OgASY5LPQHgLAAAAAAAAAAA'

Global Const $KAPPA_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- +4 Shadow Arts (+3 +1 headgear)' & @CRLF _
	& '- Armor with HP runes and 5 blessed/prodigy insignias (+50 armor when enchanted)' & @CRLF _
	& '- A shield with the inscription ''Like a rolling stone'' (+10 armor against earth damage) and +45 health while enchanted' & @CRLF _
	& '- In case of Monk 55hp, use grim cesta -50hp and armor with 5*-75hp runes' & @CRLF _
	& '- In case of Obsidian Flesh Elementalist, recommended to have armor full with geomancer runes' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- Cupcakes' & @CRLF _
	& 'Recommended to have maxed out Norn title. If not maxed out then this farm is good for raising Norn rank' & @CRLF _
	& 'Vaettir farm can be a good way to max out survivor title' & @CRLF _
	& 'You can run this farm as Assassin or Mesmer or Monk or Elementalist. Bot will set up build automatically for these professions' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:A/Me_Vaettir_Farm' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Me/A_Vaettir_Farm' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Mo/A_55hp_Vaettir_Farmer' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:E/Me_Obsidian_Flesh_Vaettir_Farmer'
; Average duration ~ 3m40 ~ First run is 6m30s with setup and run
Global Const $KAPPA_FARM_DURATION = 4 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($KAPPA_SHADOWFORM) is better than UseSkillEx(2))
Global Const $KAPPA_PROTECTIVE_SPIRIT	    = 1
Global Const $KAPPA_DEADLY_PARADOX			= 2
Global Const $KAPPA_SHADOWFORM				= 3
Global Const $KAPPA_EBON_BATTLE_STANDARD_OF_WISDOWN     = 4
Global Const $KAPPA_VIPERS_DEFENSE          = 5
Global Const $KAPPA_RADIATION_FIELD 		= 6
Global Const $KAPPA_DEATHS_CHARGE           = 7
Global Const $KAPPA_BALTHAZARS_SPIRIT	    = 8


Global Const $KAPPA_MESMER_VISIONS_OF_REGRET	= 4
Global Const $KAPPA_MESMER_SHATTER_HEX			= 5

Global Const $KAPPA_ELEMENTALIST_GLYPH_OF_SWIFTNESS	    = 1
Global Const $KAPPA_ELEMENTALIST_STONEFLESH_AURA		= 3
Global Const $KAPPA_ELEMENTALIST_MANTRA_OF_FROST		= 5

Global Const $KAPPA_HERO_MARGRID_THE_SLY         = 1
Global Const $KAPPA_HERO_EDGE_OF_EXTINCTION     = 1
Global Const $KAPPA_HERO_TOXICITY               = 2

; ==== Global variables ====
Global $kappa_move_options = CloneDictMap($Default_MoveDefend_Options)
$kappa_move_options.Item('defendFunction')				= KappaStayAlive
$kappa_move_options.Item('moveTimeOut')					= 100 * 1000
$kappa_move_options.Item('randomFactor')					= 50
$kappa_move_options.Item('hosSkillSlot')					= $KAPPA_VIPERS_DEFENSE
$kappa_move_options.Item('deathChargeSkillSlot')			= 0
$kappa_move_options.Item('openChests')					= False

Global $kappa_move_options_elementalist = CloneDictMap($kappa_move_options)
$kappa_move_options_elementalist.Item('hosSkillSlot')	= 0

Global $kappa_farm_setup = False
Global $kappa_player_profession = $ID_MONK
Global $kappa_deadlocked = False
Global $kappa_shadowform_timer = TimerInit()
Global $KAPPA_shroud_of_distress_timer = TimerInit()
Global $KAPPA_channeling_timer = TimerInit()
Global $KAPPA_glyph_of_swiftness_timer = TimerInit()
Global $kappa_obsidian_flesh_timer = TimerInit()
Global $KAPPA_stoneflesh_aura_timer = TimerInit()
Global $KAPPA_mantra_of_earth_timer = TimerInit()
Global $KAPPA_protective_spirit_timer = TimerInit()
Global $KAPPA_INITIAL_AMOUNT = 0
Global $KAPPA_Farm_Location[2] = [17774, -10933]


;~ Main method to farm Vaettirs
Func KappaFarm()
	If Not $kappa_farm_setup And SetupKappaFarm() == $FAIL Then Return $PAUSE
    GoToMaishangHills()
    local $result = KappaFarmLoop()
    ReturnBackToOutpost($ID_GYALA_HATCHERY)
    Return $result
EndFunc


Func SetupKappaFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_GYALA_HATCHERY, $district_name) == $FAIL Then Return $FAIL
	If SetupPlayerKappaFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	SwitchMode($ID_HARD_MODE)
    AddHero($ID_MARGRID_THE_SLY)
	Sleep(1000 + GetPing())
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerKappaFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		;~ Case $ID_ASSASSIN
		;~ 	$kappa_player_profession = $ID_ASSASSIN
		;~ 	LoadSkillTemplate($AME_KAPPA_FARMER_SKILLBAR)
		;~ Case $ID_MESMER
		;~ 	$kappa_player_profession = $ID_MESMER
			;~ LoadSkillTemplate($MEA_KAPPA_FARMER_SKILLBAR)
		Case $ID_MONK
			$kappa_player_profession = $ID_MONK
			LoadSkillTemplate($MOA_KAPPA_FARMER_SKILLBAR)
		;~ Case $ID_ELEMENTALIST
		;~ 	$kappa_player_profession = $ID_ELEMENTALIST
		;~ 	LoadSkillTemplate($EME_KAPPA_FARMER_SKILLBAR)
		Case Else
			Warn('You need to run this farm bot as Assassin or Mesmer or Monk or Elementalist')
			Return $FAIL
	EndSwitch
    LoadSkillTemplate($R_KAPPA_HERO_SKILLBAR, $ID_MARGRID_THE_SLY)
    DisableAllHeroSkills($ID_MARGRID_THE_SLY)
	Sleep(250 + GetPing())
    $kappa_farm_setup = True
	Return $SUCCESS
EndFunc

;~ Move out of outpost into Maishang Hills
Func GoToMaishangHills()
	If GetMapID() <> $ID_GYALA_HATCHERY Then TravelToOutpost($ID_GYALA_HATCHERY, $DISTRICT_NAME)
	While GetMapID() <> $ID_MAISHANG_HILLS
		Info('Moving to Maishang Hills')
		MoveTo(1041, 23543)
		MoveTo(4117, 27000)
		RandomSleep(1000)
		WaitMapLoading($ID_MAISHANG_HILLS, 10000, 1000)
	WEnd
EndFunc


;~ Farm loop
Func KappaFarmLoop()
	If $kappa_player_profession == $ID_ELEMENTALIST Then UseSkillEx($KAPPA_ELEMENTALIST_ELEMENTAL_LORD)
    If $kappa_player_profession == $ID_MONK Then UseSkillEx($KAPPA_BALTHAZARS_SPIRIT, GetMyAgent())
	Sleep(500 + GetPing())
	If Kappa_AggroAllMobs() == $FAIL Then Return $FAIL
	KappaKillSequence()
	Sleep(1000)

	If IsPlayerAlive() Then
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(KappaStayAlive)
			Sleep(GetPing())
		Next
	EndIf
    Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Self explanatory
Func Kappa_AggroAllMobs()

    KappaMoveDefending(16104, -9730)
    CommandAll(15481, -11029)
    KappaMoveDefending(19889, -12700)
    KappaSleepAndStayAlive(1000)
    $KAPPA_INITIAL_AMOUNT = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT*1.5)
    Info('Initial amount of Kappa aggroed: ' & $KAPPA_INITIAL_AMOUNT)
    KappaMoveDefending(18067, -9616)
    Info('Waiting for all Kappa to gather...')
    While CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT*1.5) <= $KAPPA_INITIAL_AMOUNT
        KappaSleepAndStayAlive(1000)
    WEnd
    Info('All Kappa gathered.')
    KappaMoveDefending(17500, -8751)
    KappaCastSpirits()
    KappaMoveDefending(18067, -9616)
    KappaSleepAndStayAlive(2000)
    KappaMoveDefending(19419, -11169)
    KappaSleepAndStayAlive(2000)
    ;~ KappaMoveDefending(18202, -12073)
    ;~ KappaSleepAndStayAlive(1000)
    KappaMoveDefending(17228, -10807)

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func KappaMoveDefending($destinationX, $destinationY)
	Local $result = Null
	Switch $kappa_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_MONK
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $kappa_move_options)
		Case $ID_ELEMENTALIST
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $kappa_move_options_elementalist)
	EndSwitch
	If $result == $STUCK Then
		; When playing as Elementalist or other professions that don't have death's charge or heart of shadow skills, then fight Vaettirs wherever player got surrounded and stuck
		KappaKillSequence()
		If IsPlayerDead() Then Return $FAIL
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(KappaStayAlive)
			Sleep(GetPing())
		Next
		Return $SUCCESS
	Else
		Return $result
	EndIf
EndFunc


;~ Wait while staying alive at the same time (like Sleep(..), but without the dying part)
Func KappaSleepAndStayAlive($waitingTime)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $waitingTime And IsPlayerAlive()
		RandomSleep(100)
		KappaStayAlive()
	WEnd
EndFunc


;~ Use whatever skills you need to keep yourself alive.
Func KappaStayAlive()
	Local $adjacentCount, $areaCount, $foesSpellRange = False, $foesNear = False
	Local $distance
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), 1400)
	For $foe In $foes
		$distance = GetDistance($me, $foe)
		If $distance < 1400 Then
			$foesNear = True
			If $distance < $RANGE_SPELLCAST Then
				$foesSpellRange = True
				If $distance < $RANGE_AREA Then
					$areaCount += 1
					If $distance < $RANGE_ADJACENT Then
						$adjacentCount += 1
					EndIf
				EndIf
			EndIf
		EndIf
	Next

	If $foesNear Then KappaCheckBuffs()
EndFunc


;~ Uses Shadow Form or other buffs like Obsidian Flesh or Protective Spirit if these are recharged
Func KappaCheckBuffs()
	Switch $kappa_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_MONK
			KappaCheckShadowForm()
		Case $ID_ELEMENTALIST
			Sleep(50)
	EndSwitch
EndFunc


;~ Uses Shadow Form if its recharged
Func KappaCheckShadowForm()
	; Caution, if playing monk 55hp then protective spirit has to be already on player when casting shadow form, otherwise damage reduction to 0 won't be applied due to specific guild wars mechanics
	; Furthermore, due to specific guild wars mechanics casting protective spirit multiple times can remove damage reduction to 0 so protective spirit has to casted only once just before Shadow Form, otherwise player will die very fast
	If (($kappa_player_profession == $ID_MONK Or $kappa_player_profession == $ID_ASSASSIN) And TimerDiff($kappa_shadowform_timer) > 19500 And GetEnergy() > 30) Then
		If $kappa_player_profession == $ID_MONK Then UseSkillEx($KAPPA_PROTECTIVE_SPIRIT)
		UseSkillEx($KAPPA_DEADLY_PARADOX)
		While IsPlayerAlive() And Not IsRecharged($KAPPA_SHADOWFORM)
			Sleep(50)
		WEnd
		UseSkillEx($KAPPA_SHADOWFORM)
		If $kappa_player_profession <> $ID_MONK Then
			While IsPlayerAlive() And Not IsRecharged($KAPPA_WAY_OF_PERFECTION)
				Sleep(50)
			WEnd
			UseSkillEx($KAPPA_WAY_OF_PERFECTION)
		EndIf
		$kappa_shadowform_timer = TimerInit()
	EndIf
EndFunc

Func KappaCastSpirits()
    UseHeroSkill($KAPPA_HERO_MARGRID_THE_SLY, $KAPPA_HERO_EDGE_OF_EXTINCTION)
    UseHeroSkill($KAPPA_HERO_MARGRID_THE_SLY, $KAPPA_HERO_TOXICITY)
    KappaSleepAndStayAlive(500)
    CommandAll(9381, -7685)
EndFunc

;~ Kill a mob group
Func KappaKillSequence()
	; Wait for shadow form or other buffs to have been casted very recently
	While ($kappa_player_profession <> $ID_ELEMENTALIST And TimerDiff($kappa_shadowform_timer) > 5000)
        Sleep(100)
        KappaStayAlive()
        If IsPlayerDead() Then Return
	WEnd

	Info('Killing Kappa')
	Switch $kappa_player_profession
		;~ Case $ID_ELEMENTALIST
        ;~     KillKappaElementalist()
        ;~ Case $ID_MESMER
		;~ 	KillKappaMesmer()
		Case $ID_ASSASSIN, $ID_MONK
			KillKappaMonk()
	EndSwitch
EndFunc

Func MoveToMelee($targetFoe = Null)
    ;~ If IsRecharged($KAPPA_DEATHS_CHARGE) Then
    ;~     If $targetFoe = Null Then $targetFoe = TargetNearestEnemy() ; Assign only if not already passed
    ;~     UseSkillEx($KAPPA_DEATHS_CHARGE)
    ;~     Sleep(500)
    ;~ Else
    KappaMoveDefending($KAPPA_Farm_Location[0], $KAPPA_Farm_Location[1])
    ;~ EndIf
EndFunc

Func KillKappaMonk()
    Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) ; Use $RANGE_AREA for consistency
    Info('Starting to kill ' & $foesCount & ' Kappa')
    ;~ Local $targetFoe = TargetNearestEnemy()
    ;~ If $targetFoe = 0 Then
    ;~     Info('No valid target for Deaths Charge.')
    ;~ Else
    ;~     Info('Target for Deaths Charge: ' & $targetFoe)
    ;~ EndIf
    ;~ ChangeTarget($targetFoe)
    ;~ UseSkillEx($KAPPA_DEATHS_CHARGE)
    ;~ KappaSleepAndStayAlive(1000)
    MoveToMelee()
    Local $killTimer = TimerInit()
    While ($foesCount > 0 And IsPlayerAlive()) Or TimerDiff($killTimer) < 55000
        While timerDiff($kappa_shadowform_timer) > 14000
            KappaSleepAndStayAlive(100)
        WEnd
        If IsRecharged($KAPPA_EBON_BATTLE_STANDARD_OF_WISDOWN) Then
            UseSkillEx($KAPPA_EBON_BATTLE_STANDARD_OF_WISDOWN)
            KappaSleepAndStayAlive(500)
        EndIf
        If IsRecharged($KAPPA_RADIATION_FIELD) Then
            UseSkillEx($KAPPA_RADIATION_FIELD)
            KappaSleepAndStayAlive(500)
        EndIf
        If IsRecharged($KAPPA_VIPERS_DEFENSE) Then
            UseSkillEx($KAPPA_VIPERS_DEFENSE)
            KappaSleepAndStayAlive(500)
            MoveToMelee()
        EndIf

        ; Update foes count and log it
        $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
        Info('Remaining Kappa: ' & $foesCount)
        KappaSleepAndStayAlive(100)
    WEnd
    
    ; Check if the loop exited due to timeout
    If TimerDiff($killTimer) >= 55000 Then
        Warn('KillKappaMonk timed out. Exiting loop.')
    Else
        Info('Finished killing Kappa')
    EndIf
EndFunc
