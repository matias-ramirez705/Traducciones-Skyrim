Scriptname ADLPlayerAlias extends ReferenceAlias

;====================
;Import Functions
;====================

Import Debug


;====================
;Import Scripts
;====================

ADLMainController Property mainFunctions Auto
{The script that triggers shared functions for dogs.}
ADLControllerDogs Property dogFunctions Auto
{The script that triggers various functions for dogs.}


;====================
;Properties
;====================

Container Property ADLFetchContainer Auto
{The base object for the fetch containers.}

FormList Property ADLFormCurrentDogs Auto
{The form list that holds all currently recruited dogs.}

GlobalVariable Property ADLGlobalCurrentDogs Auto
{The global that determine show many dogs are currently following.}


;When the player loads the game, apply various stored data to each dog.
Event OnPlayerLoadGame()

	;If the player has any active dogs, update their names.
	If ADLGlobalCurrentDogs.Value > 0

		Int listSize = ADLFormCurrentDogs.GetSize()
		Int iIndex = 0
		While iIndex < listSize

			Actor dogRef = ADLFormCurrentDogs.GetAt(iIndex) as Actor
			ReferenceAlias dogAlias = mainFunctions.getDog(dogRef)
			Int dogIdentifier = dogAlias.GetID()

			;If the alias is not empty, set the name.
			If dogAlias != None
				dogRef.GetBaseObject().SetName(dogFunctions.dogNames[dogIdentifier])
			EndIf

			iIndex+=1

		EndWhile

	EndIf

EndEvent


;When an item is added to the player, check its source and display the relevant notification.
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)

	;Is the container these items are coming from a favor or fetch container?
	If akSourceContainer.GetBaseObject() == ADLFetchContainer || akSourceContainer.GetBaseObject() == ADLFetchContainer

		;Does the added item count exceed 1?
		If aiItemCount > 1
			Notification(akBaseItem.GetName() + " (" + aiItemCount + ")" + " añadido")
		Else
			Notification(akBaseItem.GetName() + " añadido")
		EndIf

	EndIf

EndEvent