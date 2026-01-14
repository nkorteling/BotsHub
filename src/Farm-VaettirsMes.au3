#CS ===========================================================================
#################################
#								#
#			Vaettir Bot			#
#								#
#################################
Author: gigi
Modified by: Pink Musen (v.01), Deroni93 (v.02-3), Dragonel (with help from moneyvsmoney), Night, Gahais
#CE ===========================================================================

#include-once
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $MeAVaettirsFarmerSkillbar = 'OwVUI2h5lPP8Id2BkAiANBLhbKA'
Global Const $MeVaettirsFarmInformations = 'For best results, have :' & @CRLF _
	& '- +4 Shadow Arts' & @CRLF _
	& '- Blessed insignias'& @CRLF _
	& '- A shield with the inscription Like a rolling stone (+10 armor against earth damage)' & @CRLF _
	& '- A main hand with +20% enchantments duration' & @CRLF _
	& '- Cupcakes'
; Average duration ~ 3m40 ~ First run is 6m30s with setup and run
Global Const $MeVaettirsFarmDuration = 4 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($MeV_Skill_Shadow_Form) is better than UseSkillEx(2))
Global Const $MeV_Skill_Deadly_Paradox		= 1
Global Const $MeV_Skill_Shadow_Form			= 2
Global Const $MeV_Skill_Shroud_of_Distress	= 3
Global Const $MeV_Skill_Way_of_Perfection	= 4
Global Const $MeV_Skill_Heart_of_Shadow		= 5
Global Const $MeV_Skill_Channeling			= 6
Global Const $MeV_Skill_Arcane_Echo			= 7
Global Const $MeV_Skill_Wastrels_Demise		= 8

; ==== Global variables ====
Global $MeV_ChatStuckTimer = TimerInit()
Global $MeV_Deadlocked = False
Global $MeV_shadowFormTimer = TimerInit()
Global $MeV_shroudOfDistressTimer = TimerInit()
Global $MeV_channelingTimer = TimerInit()

;~ Main method to farm Vaettirs
Func MeV_VaettirsFarm($STATUS)
	While $MeV_Deadlocked Or GetMapID() <> $ID_Jaga_Moraine
		$MeV_Deadlocked = False
		MeV_RunToJagaMoraine()
	WEnd

	If $STATUS <> 'RUNNING' Then Return $PAUSE
	Return MeV_VaettirsFarmLoop()
EndFunc


;~ Zones to Longeye if we are not there, and travel to Jaga Moraine
Func MeV_RunToJagaMoraine()
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Longeyes_Ledge Then TravelToOutpost($ID_Longeyes_Ledge, $DISTRICT_NAME)
	SwitchMode($ID_HARD_MODE)
	SetDisplayedTitle($ID_Norn_Title)
	LeaveParty() ; solo farmer
	Info('Setting up build skillbar')
	LoadSkillTemplate($AMeVaettirsFarmerSkillbar)

	Info('Exiting Outpost')
	MoveTo(-26000, 16000)
	Move(-26472, 16217)
	RandomSleep(1000)
	WaitMapLoading($ID_Bjora_Marches)

	RandomSleep(500)
	UseConsumable($ID_Birthday_Cupcake)
	RandomSleep(500)

	Info('Running to Jaga Moraine')
	Local $MeV_pathToJaga[30][2] = [ _
		[15003.8,	-16598.1], _
		[15003.8,	-16598.1], _
		[12699.5,	-14589.8], _
		[11628,		-13867.9], _
		[10891.5,	-12989.5], _
		[10517.5,	-11229.5], _
		[10209.1,	-9973.1], _
		[9296.5,	-8811.5], _
		[7815.6,	-7967.1], _
		[6266.7,	-6328.5], _
		[4940,		-4655.4], _
		[3867.8,	-2397.6], _
		[2279.6,	-1331.9], _
		[7.2,		-1072.6], _
		[7.2,		-1072.6], _
		[-1752.7,	-1209], _
		[-3596.9,	-1671.8], _
		[-5386.6,	-1526.4], _
		[-6904.2,	-283.2], _
		[-7711.6,	364.9], _
		[-9537.8,	1265.4], _
		[-11141.2,	857.4], _
		[-12730.7,	371.5], _
		[-13379,	40.5], _
		[-14925.7,	1099.6], _
		[-16183.3,	2753], _
		[-17803.8,	4439.4], _
		[-18852.2,	5290.9], _
		[-19250,	5431], _
		[-19968,	5564] _
	]
	For $i = 0 To UBound($MeV_pathToJaga) - 1
		If MeV_MoveRunning($MeV_pathToJaga[$i][0], $MeV_pathToJaga[$i][1]) == $FAIL Then Return $FAIL
	Next
	Move(-20076, 5580, 30)
	WaitMapLoading($ID_Jaga_Moraine)
EndFunc


;~ Move to X, Y. This is to be used in the run from across Bjora Marches
Func MeV_MoveRunning($X, $Y)
	If IsPlayerDead() Then Return $FAIL

	Move($X, $Y)

	Local $target
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $X, $Y) > 250
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestEnemyToAgent($me)

		If GetDistance($me, $target) < 1300 And GetEnergy() > 20 Then MeV_TryUseShadowForm()

		$me = GetMyAgent()
		If DllStructGetData($me, 'HP') < 0.9 And GetEnergy() > 10 Then MeV_TryUseShroudOfDistress()
		If DllStructGetData($me, 'HP') < 0.5 And GetDistance($me, $target) < 500 And GetEnergy() > 5 And IsRecharged($MeV_Skill_Heart_of_Shadow) Then UseSkillEx($MeV_Skill_Heart_of_Shadow, $target)

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then Move($X, $Y)
		RandomSleep(500)
		$me = GetMyAgent()
	WEnd
	Return $SUCCESS
EndFunc


;~ Farm loop
Func MeV_VaettirsFarmLoop()
	RandomSleep(1000)
	MeV_GetVaettirsNornBlessing()
	MeV_AggroAllMobs()
	;KillMobs()
	MeV_VaettirsKillSequence()
	Sleep(1000)
	MeV_VaettirsStayAlive()

	Info('Looting')
	PickUpItems()

	Return MeV_RezoneToJagaMoraine()
EndFunc


;~ Get Norn blessing only if title is not maxed yet
Func MeV_GetVaettirsNornBlessing()
	Local $nornTitlePoints = GetNornTitle()
	If $nornTitlePoints < 160000 Then
		Info('Getting norn title blessing')
		GoNearestNPCToCoords(13400, -20800)
		RandomSleep(300)
		Dialog(0x84)
	EndIf
	RandomSleep(100)
	RandomSleep(100)
	RandomSleep(100)
	Sleep(100)
EndFunc


;~ Self explanatory
Func MeV_AggroAllMobs()
	Local $target
	Info('Aggroing left')
	MoveTo(13172, -22137)
	MeV_MoveAggroing(12496, -22600, 150)
	MeV_MoveAggroing(11375, -22761, 150)
	MeV_MoveAggroing(10925, -23466, 150)
	MeV_MoveAggroing(10917, -24311, 150)
	MeV_MoveAggroing(9910, -24599, 150)
	MeV_MoveAggroing(8995, -23177, 150)
	MeV_MoveAggroing(8307, -23187, 150)
	MeV_MoveAggroing(8213, -22829, 150)
	MeV_MoveAggroing(8307, -23187, 150)
	MeV_MoveAggroing(8213, -22829, 150)
	MeV_MoveAggroing(8740, -22475, 150)
	MeV_MoveAggroing(8880, -21384, 150)
	MeV_MoveAggroing(8684, -20833, 150)
	MeV_MoveAggroing(8982, -20576, 150)

	Info('Waiting for left ball')
	MeV_VaettirsSleepAndStayAlive(12000)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If GetDistance(GetMyAgent(), $target) < $RANGE_SPELLCAST Then
		UseSkillEx($MeV_Skill_Heart_of_Shadow, $target)
	Else
		UseSkillEx($MeV_Skill_Heart_of_Shadow, GetMyAgent())
	EndIf
	MeV_VaettirsSleepAndStayAlive(6000)

	Info('Aggroing right')
	MeV_MoveAggroing(10196, -20124, 150)
	MeV_MoveAggroing(9976, -18338, 150)
	MeV_MoveAggroing(11316, -18056, 150)
	MeV_MoveAggroing(10392, -17512, 150)
	MeV_MoveAggroing(10114, -16948, 150)
	MeV_MoveAggroing(10729, -16273, 150)
	MeV_MoveAggroing(10810, -15058, 150)
	MeV_MoveAggroing(11120, -15105, 150)
	MeV_MoveAggroing(11670, -15457, 150)
	MeV_MoveAggroing(12604, -15320, 150)
	MeV_MoveAggroing(12476, -16157)

	Info('Waiting for right ball')
	MeV_VaettirsSleepAndStayAlive(15000)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If GetDistance(GetMyAgent(), $target) < $RANGE_SPELLCAST Then
		UseSkillEx($MeV_Skill_Heart_of_Shadow, $target)
	Else
		UseSkillEx($MeV_Skill_Heart_of_Shadow, GetMyAgent())
	EndIf
	MeV_VaettirsSleepAndStayAlive(5000)

	MeV_MoveAggroing(12920, -17032, 30)
	MeV_MoveAggroing(12847, -17136, 30)
	MeV_MoveAggroing(12720, -17222, 30)
	;MeV_VaettirsSleepAndStayAlive(300)
	MeV_MoveAggroing(12617, -17273, 30)
	;MeV_VaettirsSleepAndStayAlive(300)
	MeV_MoveAggroing(12518, -17305, 20)
	;MeV_VaettirsSleepAndStayAlive(300)
	MeV_MoveAggroing(12445, -17327, 10)
EndFunc


;~ Kill a mob group
Func MeV_VaettirsKillSequence()
	; Wait for shadow form to have been casted very recently
	While IsPlayerAlive() And TimerDiff($MeV_shadowFormTimer) > 5000
		If IsPlayerDead() Then Return
		Sleep(100)
		MeV_VaettirsStayAlive()
	WEnd

	Info('Killing')
	Local $deadlock = TimerInit()
	Local $target
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	If $foesCount > 0 Then
		; Echo the Wastrel's Demise
		UseSkillEx($MeV_Skill_Arcane_Echo)
		$target = MeV_GetWastrelsTarget()
		UseSkillEx($MeV_Skill_Wastrels_Demise, $target)
		While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < 60000
			; Use echoed wastrel if possible
			If IsRecharged($MeV_Skill_Arcane_Echo) And GetSkillbarSkillID($MeV_Skill_Arcane_Echo) == $ID_Wastrels_Demise Then
				$target = MeV_GetWastrelsTarget()
				If $target <> Null Then UseSkillEx($MeV_Skill_Arcane_Echo, $target)
			EndIf

			; Use wastrel if possible
			If IsRecharged($MeV_Skill_Wastrels_Demise) Then
				$target = MeV_GetWastrelsTarget()
				If $target <> Null Then UseSkillEx($MeV_Skill_Wastrels_Demise, $target)
			EndIf

			RandomSleep(100)
			MeV_VaettirsStayAlive()
			$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
		WEnd
	EndIf
EndFunc


;~ Exit Jaga Moraine to Bjora Marches and get back into Jaga Moraine
Func MeV_RezoneToJagaMoraine()
	Local $result = $SUCCESS
	If IsPlayerDead() Then $result = $FAIL

	Info('Zoning out and back in')
	MeV_MoveAggroing(12289, -17700)
	MeV_MoveAggroing(15318, -20351)

	Local $deadlockTimer = TimerInit()
	While IsPlayerDead()
		Info('Waiting for resurrection')
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$MeV_Deadlocked = True
			Return $FAIL
		EndIf
	WEnd
	MoveTo(15600, -20500)
	Move(15865, -20531)
	WaitMapLoading($ID_Bjora_Marches)
	MoveTo(-19968, 5564)
	Move(-20076, 5580, 30)
	WaitMapLoading($ID_Jaga_Moraine)

	Return $result
EndFunc


;~ Move to destX, destY, while staying alive vs vaettirs
Func MeV_MoveAggroing($X, $Y, $random = 150)
	If IsPlayerDead() Then Return $FAIL

	Local $blockedCount
	Local $heartOfShadowUsageCount
	Local $angle
	Local $stuckTimer = TimerInit()

	Move($X, $Y, $random)

	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	While GetDistanceToPoint($me, $X, $Y) > $random * 1.5
		If IsPlayerDead() Then Return False
		MeV_VaettirsStayAlive()
		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			If $heartOfShadowUsageCount > 6 Then
				While IsPlayerAlive()
					RandomSleep(1000)
				WEnd
				Return $FAIL
			EndIf

			$blockedCount += 1
			$me = GetMyAgent()
			If $blockedCount < 5 Then
				Move($X, $Y, $random)
			ElseIf $blockedCount < 10 Then
				$angle += 40
				Move(DllStructGetData($me, 'X') + 300 * sin($angle), DllStructGetData($me, 'Y') + 300 * cos($angle))
			ElseIf IsRecharged($MeV_Skill_Heart_of_Shadow) Then
				If $heartOfShadowUsageCount == 0 And GetDistance($me, $target) < $RANGE_SPELLCAST Then
					UseSkillEx($MeV_Skill_Heart_of_Shadow, $target)
				Else
					UseSkillEx($MeV_Skill_Heart_of_Shadow, $me)
				EndIf
				$blockedCount = 0
				$heartOfShadowUsageCount += 1
			EndIf
		Else
			If $blockedCount > 0 Then
				; use a timer to avoid spamming /stuck
				If TimerDiff($MeV_ChatStuckTimer) > 3000 Then
					SendChat('stuck', '/')
					$MeV_ChatStuckTimer = TimerInit()
				EndIf
				$blockedCount = 0
				$heartOfShadowUsageCount = 0
			EndIf

			; target is far, we probably got stuck
			If GetDistance($me, $target) > 1100 Then
				; dont spam
				If TimerDiff($MeV_ChatStuckTimer) > 3000 Then
					SendChat('stuck', '/')
					$MeV_ChatStuckTimer = TimerInit()
					RandomSleep(GetPing() + 20)
					; we werent stuck, but target broke aggro. select a new one
					If GetDistance($me, $target) > 1100 Then
						$target = GetNearestEnemyToAgent($me)
					EndIf
				EndIf
			EndIf
		EndIf
		RandomSleep(100)
		$me = GetMyAgent()
	WEnd
	Return $SUCCESS
EndFunc


;~ Wait while staying alive at the same time (like Sleep(..), but without the dying part)
Func MeV_VaettirsSleepAndStayAlive($waitingTime)
	If IsPlayerDead() Then Return
	Local $timer = TimerInit()
	While TimerDiff($timer) < $waitingTime
		RandomSleep(100)
		If IsPlayerDead() Then Return
		MeV_VaettirsStayAlive()
	WEnd
EndFunc


;~ Use whatever skills you need to keep yourself alive.
Func MeV_VaettirsStayAlive()
	Local $adjacentCount, $areaCount, $foesSpellRange = False, $foesNear = False
	Local $distance
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), 1200)
	For $foe In $foes
		$distance = GetDistance($me, $foe)
		If $distance < 1200 Then
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

	If $foesNear And GetEnergy() > 20 Then MeV_TryUseShadowForm()
	If ($adjacentCount > 20 Or DllStructGetData(GetMyAgent(), 'HP') < 0.6 Or ($foesSpellRange And DllStructGetData(GetEffect($ID_Shroud_of_Distress), 'SkillID') == 0)) And GetEnergy() > 10 Then
		MeV_TryUseShroudOfDistress()
	EndIf
	If $foesNear And GetEnergy() > 20 Then MeV_TryUseShadowForm()
	If $areaCount > 5 Then MeV_TryUseChanneling()
	If $foesNear And GetEnergy() > 20 Then MeV_TryUseShadowForm()
EndFunc


;~ Uses Shadow Form if its recharged
Func MeV_TryUseShadowForm()
	If TimerDiff($MeV_shadowFormTimer) > 18750 Then
		UseSkillEx($MeV_Skill_Deadly_Paradox)
		UseSkillEx($MeV_Skill_Shadow_Form)
		UseSkillEx($MeV_Skill_Way_of_Perfection)
		$MeV_shadowFormTimer = TimerInit()
	EndIf
EndFunc


;~ Uses Shroud of distress if its recharged
Func MeV_TryUseShroudOfDistress()
	If TimerDiff($MeV_shroudOfDistressTimer) > 50000 And TimerDiff($MeV_shadowFormTimer) < 18000 Then
		UseSkillEx($MeV_Skill_Shroud_of_Distress)
		$MeV_shroudOfDistressTimer = TimerInit()
	EndIf
EndFunc


;~ Uses Channeling if its recharged
Func MeV_TryUseChanneling()
	If TimerDiff($MeV_channelingTimer) > 25000 And TimerDiff($MeV_shadowFormTimer) < 19000 Then
		UseSkillEx($MeV_Skill_Channeling)
		$MeV_channelingTimer = TimerInit()
	EndIf
EndFunc


;~ Returns a good target for wastrels
Func MeV_GetWastrelsTarget()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	For $foe In $foes
		If GetHasHex($foe) Then ContinueLoop
		If Not GetIsEnchanted($foe) Then ContinueLoop
		Return $foe
	Next
	Return Null
EndFunc
