Scriptname ADLMainController extends Quest
{Triggers shared functions for dogs.}

;====================
;Import Functions
;====================

Import Debug
Import Game


;====================
;Import Scripts
;====================

ADLControllerDogs Property dogFunctions Auto
{The script that triggers various functions for dogs.}


;====================
;Shared Properties
;====================

Bool itemDis = False
Bool[] Property tutorialBools Auto
{The array containing all bools that determine if the indexed tutorial has already been displayed.

Default = False}

Faction Property ADLCurrentDogFaction Auto
{The faction for owned dogs.}

FormList Property ADLFormRestrictedLocs Auto
{The form list containing all restricted locations.}
FormList[] Property dogSkins Auto
{The array of formlists for different dog skins.}
FormList Property ADLFormDefaultSkins Auto
{The formlist that contains the default skins for dog races.}
FormList Property ADLFormRaces Auto
{The form list that contains the races for all dogs.}

GlobalVariable[] Property featuresGlobals Auto
{The array containing all globals for tracking enabled features.}
GlobalVariable[] Property settingsGlobals Auto
{The array containering all globals for tracking stored settings.}

LeveledItem Property LItemMiscVendorMiscItems75 Auto
{The leveled list for misc items at general goods stores.}
LeveledItem Property LItemBlacksmithMinimum Auto
{The leveled list for blacksmith items at blacksmith merchants.}
LeveledItem Property ADLLeveledItemMerchantItems Auto
{The leveled list for all dog items to be distributed.}
LeveledItem Property ADLLeveledItemsArmors Auto
{The leveled list for all dog armours to be distributed.}


MagicEffect[] Property dogEffects Auto
{The array containing all magic effects dogs can have for MCM tracking. }

Message[] Property tutorialMessages Auto
{The array containing all tutorial messages displayed to the player.}

Race[] Property dogRaces Auto
{The array that contains all dog companion races.}

Spell[] Property dogSpells Auto
{The array containing all buffs and debuffs cast and dispelled from dogs.}


Event OnInit()

	If !itemDis

		itemDis = True
		LItemMiscVendorMiscItems75.AddForm(ADLLeveledItemMerchantItems, 1, 1)
		LItemBlacksmithMinimum.AddForm(ADLLeveledItemsArmors, 1, 3)

	EndIf

EndEvent

;=========================
;Utility Functions
;=========================

;Check if tutorials are enabled and displays the defined tutorial if it's not been displayed previously.
Function displayTutorial(Int tutorialIndex)

	If featuresGlobals[0].Value == 1
		If tutorialBools[tutorialIndex] == False
			tutorialMessages[tutorialIndex].Show()
			tutorialBools[tutorialIndex] = True
		EndIf
	EndIf

EndFunction


;Check if debug notification and trace logs are enabled then display and log the defined notification.
Function logReport(String logText)

	If settingsGlobals[12].Value == 1
		Trace(logText)
	EndIf

	If settingsGlobals[13].Value == 1
		Notification(logText)
	EndIf

EndFunction


;Check if notifications are enabled and display the follower's name along with the defined suffix as a notification.
Function createNotification(String dogName, String messageSuffix)

	If featuresGlobals[1].Value == 1
		If !dogName == ""
			Notification(dogName + " " + messageSuffix)
		Else
			Notification("Perro" + " " + messageSuffix)
		EndIf
	EndIf

EndFunction


;=========================
;Shared Functions
;=========================

;Check if tracking is enabled and display or hide the defined objective for tracking dogs on the map.
Function setTracking(Quest trackerQuest, Int dogIdentifier, Bool setActive = True)

	If setActive
		trackerQuest.SetObjectiveDisplayed(dogIdentifier)
	Else
		trackerQuest.SetObjectiveDisplayed(dogIdentifier, False)
	EndIf

EndFunction


;Checks if animations are enabled and triggers the requested idle  animation on either the player or dog.
Function sendIdle(Actor dogRef, String idleAnimation)

	;Are idles enabled?
	If featuresGlobals[8].Value == 1
		If GetCameraState() == 0
			ForceThirdPerson()
		EndIf
		SendAnimationEvent(dogRef, idleAnimation)
	EndIf

EndFunction


;=========================
;Fetch Data Functions
;=========================

;Cycles through each alias the defined actor is attached to and returns the reference alias for one that has the BFFAliasCheck script attached.
ReferenceAlias Function getDog(Actor dogRef)

	ADLCheckAlias aliasCheck
	ReferenceAlias dogAlias
	Int iIndex = 0

	While aliasCheck == None && iIndex < 20
		dogAlias = dogRef.GetNthReferenceAlias(iIndex)
		aliasCheck = dogAlias as ADLCheckAlias
		If aliasCheck == None
			iIndex += 1
		EndIf
	EndWhile

	Return dogAlias

EndFunction


Int Function getSkin(Actor dogRef)

	Int iSkinIndex = 0

	If dogRef.GetRace() == dogRaces[0] ; Dog

		While !dogRef.IsEquipped(dogSkins[0].GetAt(iSkinIndex)) && iSkinIndex < (dogSkins[0].GetSize() - 1)
			iSkinIndex +=1
		EndWhile

		Return iSkinIndex

	ElseIf dogRef.GetRace() == dogRaces[1] || dogRef.GetRace() == dogRaces[2] ; Husky

		While !dogRef.IsEquipped(dogSkins[1].GetAt(iSkinIndex)) && iSkinIndex < (dogSkins[1].GetSize() - 1)
			iSkinIndex +=1
		EndWhile

		Return iSkinIndex

	ElseIf dogRef.GetRace() == dogRaces[3] ;Death Hound

		While !dogRef.IsEquipped(dogSkins[2].GetAt(iSkinIndex)) && iSkinIndex < (dogSkins[2].GetSize() - 1)
			iSkinIndex +=1
		EndWhile

		Return iSkinIndex

	ElseIf dogRef.GetRace() == dogRaces[4] ;Kelpie

		While !dogRef.IsEquipped(dogSkins[3].GetAt(iSkinIndex)) && iSkinIndex < (dogSkins[3].GetSize() - 1)
			iSkinIndex +=1
		EndWhile

		Return iSkinIndex
		
	EndIf

EndFunction


Function removeSkin(Actor dogRef)

	dogRef.RemoveItem(dogSkins[0], 1, true)
	dogRef.RemoveItem(dogSkins[1], 1, true)
	dogRef.RemoveItem(dogSkins[2], 1, true)
	dogRef.RemoveItem(dogSkins[3], 1, true)
	dogRef.RemoveItem(dogSkins[4], 1, true)

EndFunction


Function triggerNeeds()

	FormList currentDogs = dogFunctions.ADLFormCurrentDogs
	Int iIndex = 0

	While iIndex < currentDogs.getSize()

		Actor nextDog = currentDogs.getAt(iIndex) as Actor
		ReferenceAlias dogAlias = getDog(nextDog)

		dogAlias.RegisterForSingleUpdateGameTime(settingsGlobals[10].Value)

		iIndex +=1

	EndWhile

EndFunction


Int Function fetchRace(Actor dogRef)

	Int iRaceIndex = 0

	While dogRef.getRace() != (ADLFormRaces.GetAt(iRaceIndex) as Race) && iRaceIndex < (ADLFormRaces.GetSize() - 1)
		iRaceIndex +=1
	EndWhile

	Return iRaceIndex

EndFunction


ADLDogAlias Function getAliasScript(Actor dogRef)

	ADLDogAlias getAliasScript
	Int iDogIndex = 0
	
	While getAliasScript == None && dogRef
		getAliasScript = dogRef.GetNthReferenceAlias(iDogIndex) as ADLDogAlias
		If getAliasScript == None
			iDogIndex +=1
		EndIf
	EndWhile

	Return getAliasScript

EndFunction


String Function affinityName(Int Rank)

	;Fetches the current relationship of the dog with the player, returning a string.
	If Rank == 3
		return "Fiel"
	ElseIf Rank == 2
		return "Amistoso"
	ElseIf Rank == 1
		return "Sociable"
	ElseIf Rank == 0
		return "Neutral"
	ElseIf Rank == -1
		return "Cauteloso"
	ElseIf Rank == -2
		return "Antipático"
	ElseIf Rank == -3
		return "Irritado"
	ElseIf Rank == -4
		return "Muerto"
	EndIf

EndFunction


;Fetches the current happiness state of the dog and returns a string.
String Function happinessState(Int happinessVal)

	If happinessVal < 25
		return "Abandonado"
	ElseIf happinessVal < 50
		return "Descuidado"
	ElseIf happinessVal < 75
		return "Contento"
	Else
		return "Querido"
	EndIf

EndFunction


;Fetches the current hunger state of the dog and returns a string.
String Function hungerState(Int hungerVal)

	If hungerVal < 25
		return "Muriéndose de hambre"
	ElseIf hungerVal < 50
		return "Hambriento"
	ElseIf hungerVal < 75
		return "Un poco hambriento"
	Else
		return "Satisfecho"
	EndIf

EndFunction


;Fetches the current death type ad returns the correct string.
String Function deathState(Int deathType)

	If deathType == 1
		return " ha muerto."
	ElseIf deathType == 2
		return " ha muerto de un corazón roto."
	ElseIf deathType == 3
		return " ha muerto de inanición."
	EndIf

EndFunction