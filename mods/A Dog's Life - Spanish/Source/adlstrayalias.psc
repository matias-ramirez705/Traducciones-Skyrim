Scriptname ADLStrayAlias extends ReferenceAlias
{Performs various actions on the actor attached to the stray alias.}


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
{The script that triggers shared functions for dogs.}


;====================
;Properties
;====================

FormList Property ADLFormCurrentDogs Auto
{The form list that holds all currently recruited dogs.}
FormList Property ADLFormFeedExceptions Auto
{A list of items dogs won't want to eat.}
FormList Property ADLFormFeedFavourites Auto
{A list of items dogs won't want to eat.}

FavorDialogueScript Property DialogueFavorGeneric Auto
{The script for controlling persuation results.}

Sound Property ADLSoundDogEat Auto
{The sound for the dog eating.}
Sound Property ADLSoundDogGrowl Auto
{The sound of the dog growling.}


;When an item (food in this case) is added to a stray dog, perform an affinity check and increase or decrease it.
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)

	Actor dogActor = Self.GetActorRef()

	If !ADLFormCurrentDogs.hasForm(dogActor)

		Actor thePlayer = getPlayer()
		Int dogAffinity = dogActor.GetRelationshipRank(thePlayer)
		Int affinityChance = RandomInt(0, 100)
		ObjectReference dogRef = Self.GetRef()
		String dogName = Self.GetActorRef().GetActorBase().GetName()

		logReport("ADL | Callejero recibió " + akBaseItem.getName())
		foodCheck(akBaseItem, aiItemCount, dogRef, thePlayer, dogName)

		;Run an affinity chance check.
		If affinityChance <= mainFunctions.settingsGlobals[7].Value
			mainFunctions.displayTutorial(9)
			dogActor.SetRelationshipRank(thePlayer, dogAffinity + 1)
			Notification(dogName + " te está tomando cariño.")
		Else
			logReport("ADL | " + dogName + " rechazó la amistad")
		EndIf

		mainFunctions.createNotification(dogName + " es " + mainFunctions.affinityName(dogActor.GetRelationshipRank(thePlayer)), "")

	Else

		Self.Clear()

	EndIf

EndEvent


;=========================
;Main Functions
;=========================


;Performs the action of petting with an animation and affinity check.
Function petStray(Actor dogRef)

	Actor thePlayer = getPlayer()
	String dogName = dogRef.GetBaseObject().getName()
	Int dogAffinity = dogRef.GetRelationshipRank(thePlayer)
	Int affinityChance = RandomInt(0, 100)
	Int persuadeChance = RandomInt(0,100)

	mainFunctions.sendIdle(GetPlayer(), "IdleGreybeardWordTeach")

	;Does the dog have good affinity towards the player?
	If dogAffinity >= 0

		If affinityChance <= mainFunctions.settingsGlobals[7].Value

			mainFunctions.displayTutorial(9)
			dogRef.SetRelationshipRank(thePlayer, dogAffinity + 1)
			Notification(dogName + " te está tomando cariño.")
			
			;If pass a chance check, increase persuation for the player.
			If persuadeChance < 30
				DialogueFavorGeneric.Persuade(dogRef)
			EndIf

		EndIf

	Else

		;Performs an affinity check.
		If affinityChance <= mainFunctions.settingsGlobals[7].Value

			mainFunctions.displayTutorial(9)
			dogRef.SetRelationshipRank(thePlayer, dogAffinity + 1)
			Notification(dogName + " te está tomando cariño.")

			;If pass a chance check, increase persuation for the player.
			If persuadeChance < 30
				DialogueFavorGeneric.Persuade(dogRef)
			EndIf

		Else

			logReport("ADL | Perro rechazó la amistad")

			;Add Diseases?
			dogRef.SetRelationshipRank(thePlayer, dogAffinity - 1)
			Notification(dogName + " te teme.")
			mainFunctions.sendIdle(dogRef, "idlestop")
			Wait(0.05)
			mainFunctions.sendIdle(dogRef, "attackstart_attackright01")
			ADLSoundDogGrowl.Play(thePlayer)
			thePlayer.DamageActorValue("Health", 10.0)

		EndIf
	EndIf

	mainFunctions.createNotification(dogName + " es " + mainFunctions.affinityName(dogRef.GetRelationshipRank(thePlayer)), "")

EndFunction


Function feedStray(ObjectReference dogRef, Actor thePlayer, Int hungerIncrease)

	While IsInMenuMode()
		;;Wait
	EndWhile
	mainFunctions.sendIdle(thePlayer, "IdleGive")
	Wait(1.5)
	ADLSoundDogEat.Play(thePlayer)

	Self.RegisterForMenu("GiftMenu")

EndFunction


Function foodCheck(Form akBaseItem, Int aiItemCount, ObjectReference dogRef, Actor thePlayer, String dogName)

	;Is the item a restricted item?
	If ADLFormFeedExceptions.HasForm(akBaseItem)
		logReport("ADL | Perro rechazó la comida")
		dogRef.RemoveItem(akbaseItem, aiItemCount, true, thePlayer)
		Notification(dogName + " escupió " + akBaseItem.getName())
		Return
	ElseIf ADLFormFeedFavourites.HasForm(akBaseItem)
		logReport("ADL | Perro aceptó la comida | Mejora aplicada")
		feedStray(dogRef, thePlayer, 30)
		dogRef.RemoveItem(akbaseItem, aiItemCount, true)
	Else
		logReport("ADL | Comida favorita del perro | Mejora aplicada")
		feedStray(dogRef, thePlayer, 20)
		dogRef.RemoveItem(akbaseItem, aiItemCount, true)
	EndIf

EndFunction


;=========================
;Extension Functions
;=========================

Function logReport(String logText)

	mainFunctions.logReport(logText)

EndFunction