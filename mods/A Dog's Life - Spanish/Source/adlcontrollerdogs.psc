Scriptname ADLControllerDogs extends Quest  
{Triggers various functions for dogs.}


;====================
;Import Functions
;====================

Import Debug
Import Game
Import Utility


;====================
;Import Scripts
;====================

ADLMainController Property mainFunctions Auto
{The script for all common functions used in the mod.}
FavorDialogueScript Property DialogueFavorGeneric Auto
{The script for controlling persuation results.}


;====================
;Properties
;====================

FormList Property ADLFormCurrentDogs Auto
{The form list that holds all currently recruited dogs.}
FormList Property ADLFormDogAddons Auto
{The form list that holds all addons for dogs.}

GlobalVariable Property ADLGlobalCurrentDogs Auto
{The global that determine show many dogs are currently following.}
GlobalVariable Property purchasePrice Auto
{The cost of purchasing a dog.}

ObjectReference[] Property homeReferences Auto
{The array containing all of the home marker references for recruited dogs.}
ObjectReference[] Property fetchContainers Auto
{The array containing all of the container references for items dogs have found.}
ObjectReference Property PlayerREF Auto
{The reference for the player.}

Quest Property ADLDogDialogue Auto
{The quest that holds dialogue and data for dogs.}

ReferenceAlias[] Property dogAliases Auto
{The array containing the reference alises for all recruited dogs.}
ReferenceAlias Property strayAlias Auto
{The alias that is filled to call functions on stray dogs whilst in diagloue.}
ReferenceAlias Property familyPet Auto
{The alias that is filled for the family pet in Hearthfire.}
ReferenceAlias Property lodDog Auto
{The reference alias for Meeko when he has joined Lod.}

String[] Property dogNames Auto
{The array containing the names of all recruited dogs.}


;====================
;Main Functions
;====================

;Removes the purchasePrice in septims from the player and requests that the purchased dog start following the player.
Function purchaseDog(Actor dogTrainer, Actor dogRef, Bool removeGold = True)

	logReport("ADL | Perro reclutado")

	If removeGold
		PlayerREF.RemoveItem(GetForm(0xf), purchasePrice.Value as Int)
	EndIf

	dogFollow(dogRef)

EndFunction


;Forces the dog to follow you, setting ownership and having them follow the player.
Function dogFollow(Actor dogRef)

	Actor thePlayer = GetPlayer()
	String baseName = dogRef.GetBaseObject().GetName()
	ReferenceAlias dogAlias

	Int iIndex = 0
	Int dogIdentifier

	;Check through the dog aliases and fill the first alias that is empty.
	While iIndex < dogAliases.Length && dogAlias == None
		If dogAliases[iIndex].GetRef() == None
			dogAliases[iIndex].ForceRefTo(dogRef)
			dogAlias = dogAliases[iIndex]
			dogIdentifier = iIndex
		EndIf
		iIndex+=1
	EndWhile

	displayTutorial(0)
	dogRef.SetActorOwner(GetPlayer().GetActorBase())
	dogRef.SetRelationshipRank(thePlayer, 3)
	dogRef.SetPlayerTeammate()
	dogRef.SetAV("WaitingForPlayer", 0)
	ADLFormCurrentDogs.AddForm(dogRef)
	dogNames[dogIdentifier] = baseName
	dogRef.AllowPCDialogue(true)
	ADLGlobalCurrentDogs.Mod(1)

	createNotification(baseName, "te está siguiendo.")
	logReport("ADL | Cantidad de perros = " + ADLGlobalCurrentDogs.Value)

	mainFunctions.sendIdle(GetPlayer(), "IdleComeThisWay")

	;If any of the Needs systems are active, reguest to register for a check on their status.
	If mainFunctions.featuresGlobals[10].Value == 1 || mainFunctions.featuresGlobals[11].Value == 1
		dogAlias.RegisterForSingleUpdateGameTime(mainFunctions.settingsGlobals[10].Value)
	EndIf

EndFunction


;Forces the dog to start following again after being told to wait.
Function dogReFollow(Actor dogRef)

	ReferenceAlias dogAlias = getDog(dogRef)
	Int dogIdentifier = dogAlias.GetID()
	String dogName = dogNames[dogIdentifier]

	dogRef.SetPlayerTeammate()
	dogRef.SetAv("WaitingForPlayer", 0)
	createNotification(dogName, "te está siguiendo.")
	
	mainFunctions.sendIdle(GetPlayer(), "IdleComeThisWay")

	;If any of the Needs systems are active, reguest to register for a check on their status.
	If mainFunctions.featuresGlobals[10].Value == 1 || mainFunctions.featuresGlobals[11].Value == 1
		dogAlias.RegisterForSingleUpdateGameTime(mainFunctions.settingsGlobals[10].Value)
	EndIf

EndFunction


;Forces the dog to wait at their current location.
Function dogWait(Actor dogRef)

	ReferenceAlias dogAlias = getDog(dogRef)
	Int dogIdentifier = dogAlias.GetID()
	String dogName = dogNames[dogIdentifier]

	displayTutorial(1)
	dogRef.SetAV("WaitingForPlayer", 1)
	dogAlias.RegisterForSingleUpdateGameTime(mainFunctions.settingsGlobals[0].Value)
	createNotification(dogName, "esperará aquí.")

	mainFunctions.sendIdle(GetPlayer(), "IdlePointClose")

EndFunction


;Forces the dog to be dismissed from the player's service entirely, having them return to their place of origin.
Function dogDismiss(Actor dogRef, Bool skipIdle = False, String messageText = "se va.")

	Actor thePlayer = getPlayer()
	ReferenceAlias dogAlias = getDog(dogRef)
	Int dogIdentifier = dogAlias.GetID()
	Int dogAffinity = dogRef.GetRelationshipRank(getPlayer())
	String dogName = dogNames[dogIdentifier]
	ADLDogAlias needsFunctions = mainFunctions.getAliasScript(dogRef) as ADLDogAlias

	If !skipIdle
		displayTutorial(3)
	EndIf

	dogRef.StopCombatAlarm()
	dogRef.SetPlayerTeammate(false, false)
	dogRef.SetAV("Aggression", 0)
	dogRef.SetAV("WaitingForPlayer", 0)
	dogRef.SetAV("Fame", 0)
	ADLFormCurrentDogs.RemoveAddedForm(dogRef)
	setTracking(ADLDogDialogue, dogIdentifier, false)
	ADLGlobalCurrentDogs.Mod(-1)

	;Checks if the dog has a unique name, displaying the relevant notification.
	If dogName == ""
		createNotification("", messageText)
	Else
		createNotification(dogName, messageText)
	EndIf

	logReport("ADL | Cantidad de perros = " + ADLGlobalCurrentDogs.Value)

	If !skipIdle
		mainFunctions.sendIdle(GetPlayer(), "IdlePointFar_02")
	EndIf

	;Set the values for happinness and hunger back to default values ready for if the dog is recruited again.
	needsFunctions.dogHappiness = 100
	needsFunctions.dogHunger = 100

	;Now the dog dislikes you, change the relationship to reflect it.
	dogRef.SetRelationshipRank(thePlayer, -4)

	;Remove the default skin stored value.
	needsFunctions.currentSkin = None

	dogAlias.Clear()

EndFunction


;Forces the dog to go home and displays the relevant on-screen notification depending on if they have a home assigned or not.
Function dogHome(Actor dogRef)

	ReferenceAlias dogAlias = getDog(dogRef)
	Int dogIdentifier = dogAlias.GetID()
	String dogName = dogNames[dogIdentifier]
	String homeName = homeReferences[dogIdentifier].GetCurrentLocation().GetName()

	dogRef.StopCombatAlarm()
	dogRef.SetPlayerTeammate(false)
	dogRef.SetAV("WaitingForPlayer", 2)

	;Determine where the dog's home marker is and display the correct notification for where the dog is returning to.
	If homeName == ""
		createNotification(dogName, "se dirige a casa.")
	ElseIf homeName == "Lugar para Perros"
		createNotification(dogName, "se quedará aquí por ahora.")
	Else
		createNotification(dogName, "vuelve a " + homeName)
	EndIf

	mainFunctions.sendIdle(GetPlayer(), "IdlePointFar_01")

EndFunction


;ALlows the player to pet the dog and updates their current happiness level if Happiness is enabled.
Function petDog(Actor dogRef)

	Actor thePlayer = getPlayer()
	ReferenceAlias dogAlias = getDog(dogRef)
	Int dogIdentifier = dogAlias.GetID()
	Int dogAffinity = dogRef.GetRelationshipRank(thePlayer)
	Int persuadeChance = RandomInt(0,100)
	String dogName = dogNames[dogIdentifier]
	ADLDogAlias needsFunctions = mainFunctions.getAliasScript(dogRef) as ADLDogAlias

	mainFunctions.sendIdle(GetPlayer(), "IdleGreybeardWordTeach")

	;Is Happiness enabled?
	If mainFunctions.featuresGlobals[10].Value == 1

		displayTutorial(10)
		needsFunctions.tweakHappiness(20)

		String dogHappinessState = mainFunctions.happinessState(needsFunctions.dogHappiness as Int)

		createNotification(dogName, " se siente " + dogHappinessState)

		;Add and remove the relevant buffs and debuffs.
		dogRef.AddSpell(mainFunctions.dogSpells[0])
		If dogRef.HasSpell(mainFunctions.dogSpells[1])
			dogRef.RemoveSpell(mainFunctions.dogSpells[1])
			dogRef.DispelSpell(mainFunctions.dogSpells[1])
		EndIf

	EndIf
	
EndFunction


;Opens the trade menu with the dog and also displays optional notifications on screen for carry capacity.
Function dogTrade(Actor dogRef)

	ReferenceAlias dogAlias = getDog(dogRef)
	Int dogIdentifier = dogAlias.GetID()
	String dogname = dogRef.GetBaseObject().GetName()
	
	displayTutorial(5)

	dogRef.SetAV("CarryWeight", mainFunctions.settingsGlobals[1].Value)

	Wait(0.05)
	dogRef.OpenInventory(True)

	;If Notifications are enabled, display the dog's current carry weight when opening and closing the inventory menu.
	If mainFunctions.featuresGlobals[2].Value == 1
		
		Notification(dogName + " lleva " + dogRef.GetTotalItemWeight() as Int + " lbs" + " / " + dogRef.GetAV("CarryWeight") as Int + " lbs")
		While IsInMenuMode()
		;Do Nothing
		EndWhile
		Notification(dogName + " lleva " + dogRef.GetTotalItemWeight() as Int + " lbs" + " / " + dogRef.GetAV("CarryWeight") as Int + " lbs")

	EndIf

EndFunction


;Set's the dog's WaitingForPlayer actor value to force specific AI packages to trigger, allowing the dog to search out the requested item(s).
Function dogCommand(Actor dogRef, Int dogCommand)

	;COMMANDS: 3 = Ammo | 4 = Food or Potions | 5 = Ingredients | 6 = Keys | 7 = Lockpick | 8 = Weapon

	displayTutorial(7)
	dogRef.SetAV("WaitingForPlayer", dogCommand)

	mainFunctions.sendIdle(GetPlayer(), "IdlePointFar_01")

	dogRef.EvaluatePackage()

EndFunction


;Moves the dog's home marker to the current location or returns it to its origin.
Function dogNewHome(Actor dogRef)

	ReferenceAlias dogAlias = getDog(dogRef)
	Int dogIdentifier = dogAlias.GetID()
	String dogName = dogNames[dogIdentifier]
	ObjectReference homeMarker = homeReferences[dogIdentifier]

	displayTutorial(2)

	homeMarker.MoveTo(PlayerREF, 0, 0, 0)
	logReport("ADL | Marcador de hogar del perro movido")

	String homeName = homeMarker.GetCurrentLocation().GetName()

	;Display a notification stating the new home of your dog, checking if it has a name first.
	If homeName == ""
		Notification(dogName + " ha convertido este lugar en su nuevo hogar.")
	Else
		Notification(dogName + " ha hecho de " + homeName + " su nuevo hogar.")
	EndIf

	mainFunctions.sendIdle(GetPlayer(), "IdleGreybeardWordTeach")

	dogRef.EvaluatePackage()

EndFunction


;Sets the dog's new name by adding it to the string of dog names, displaying a notification on-screen if left unchanged.
Function dogName(Actor dogRef)

	displayTutorial(8)
	Wait(0.05)

	String baseName = dogRef.getBaseObject().getName()
	ReferenceAlias dogAlias = getDog(dogRef)
	Int dogIdentifier = dogAlias.getID()
	uiMenuBase nameMenu = uiExtensions.getMenu("UITextEntryMenu", true)

	nameMenu.openMenu(none, none)

	String newName = nameMenu.getResultString()

	;Changes the dog's name if text has been entered.
	If newName == ""
		createNotification(None, "Nombre sin cambios.")
	Else
		dogNames[dogIdentifier] = newName
		dogRef.getBaseObject().setName(newName)
		dogRef.SetAV("Fame", 1)
		mainFunctions.sendIdle(getPlayer(), "IdleGreybeardWordTeach")
	EndIf

EndFunction


;Checks items added to the dog's fetch container and feeds back the relevant notification on-screen.
Function dogitemsCheck(int dogIdentifier)

	String dogName = dogNames[dogIdentifier]
	ObjectReference dogContainer = fetchContainers[dogIdentifier]

	If fetchContainers[dogIdentifier].GetNumItems() <= 0
		Notification(dogName + " no encontró nada.")
	Else
		dogContainer.RemoveAllItems(PlayerREF, true, false)
	EndIf

EndFunction


Function meekoHandover(Actor meekoRef)

	dogDismiss(meekoRef, true, "se va para unirse a Lod.")
	lodDog.ForceRefTo(meekoRef as ObjectReference)

EndFunction


;Assigns the stray alias to allow for strays to react to scanarios.
Function assignAlias(Actor dogRef)

	strayAlias.ForceRefTo(dogRef)

EndFunction


;Assigns the family pet alias to allow children to react to a new pet.
Function assignFamilyPet(Actor dogRef)

	familyPet.ForceRefTo(dogRef)

EndFunction


;=========================
;Extension Functions
;=========================

Function displayTutorial(Int tutorialIndex)

	mainFunctions.displayTutorial(tutorialIndex)

EndFunction


Function logReport(String logText)

	mainFunctions.logReport(logText)

EndFunction


Function createNotification(String dogName, String messageSuffix)

	mainFunctions.createNotification(dogName, messageSuffix)

EndFunction


Function setTracking(Quest trackerQuest, Int dogIdentifier, Bool setActive = True)

	mainFunctions.setTracking(trackerQuest, dogIdentifier, setActive)


EndFunction


ReferenceAlias Function getDog(Actor dogRef)

	Return mainFunctions.getDog(dogRef)

EndFunction