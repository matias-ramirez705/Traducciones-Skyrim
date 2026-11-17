Scriptname ADLCommands extends activemagiceffect  
{Triggers various bulk actions from the main dialogue script based on the requested actions.}


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

GlobalVariable Property ADLGlobalCurrentDogs Auto
{The global that determine show many dogs are currently following.}

Int Property commandType Auto
{Commands: 1 = Follow | 2 = Wait | 3 = Home | 4 = Taunt}

ObjectReference Property PlayerREF Auto
{The reference for the player.}

Topic Property dogfollowTopic Auto
{The topic to ask an actor the follow.}
Topic Property dogwaitTopic Auto
{The topic to ask an actor to wait.}
Topic Property doghomeTopic Auto
{The topic to ask an actor to go home.}


;When the effect is triggered, call for the defined command function.
Event OnEffectFinish(Actor akTarget, Actor akCaster)

	;Command Types 1  Follow | 2 = Wait | 3 = Home

	;If you have followers, perform the requested command
	If ADLFormCurrentDogs.GetSize() > 0
		mainFunctions.logReport("ADL - Orden solicitada: perro")
		triggerCommand(ADLFormCurrentDogs)
	EndIf

EndEvent


;Run through each alias in the stated list and call for the command to be run on them.
Function triggerCommand(FormList actorList)

	Int listSize = actorList.GetSize()
	Int iIndex = 0
	Int iNearby = 0
	
	While iIndex < listSize

		Actor nextDog = actorList.GetAt(iIndex) as Actor

		;Is the alias filled?
		If nextDog != None

			mainFunctions.logReport("Actor del comando: encontrado")
			Float waitState = nextDog.GetAV("WaitingForPlayer")

			;Is the follower following the player or waiting?
			If waitState < 3
				;Is the follower in range of the player?
				If nextDog.IsNearPlayer()
					iNearby+=1
					checkCommands(nextDog, waitState)
				EndIf
			EndIf
		EndIf

		iIndex+=1

	EndWhile

	If iNearby == 0
		failNotification()
	EndIf

EndFunction


;Call for the relevant command based on the defined command and follower type.
Function checkCommands(Actor nextDog, Float waitState)

	;Command Types: 1 = Follow | 2 = Wait | 3 = Home

	mainFunctions.displayTutorial(4)

	;Check against the requested command and trigger it.
	If commandType == 1
		If waitState == 1 || waitState == 2
			dialogueCommand(nextDog, waitState)
		EndIf
	ElseIf commandType == 2
		If waitState == 0
			dialogueCommand(nextDog, waitState)
		EndIf
	ElseIf commandType == 3
		If waitState == 0 || waitState == 1
			dialogueCommand(nextDog, waitState)
		EndIf
	EndIf

EndFunction


;Call the relevant controller function for the defined dog along with the releavtnd dialogue lines.
Function dialogueCommand(Actor dogRef, Float waitState)

	;Command Types: 1 = Follow | 2 = Wait | 3 = Home
	;Follower Types: 1 = Follower | 2 = Hireling | 3 = Animal

	If commandType == 1
		dogRef.Say(dogfollowTopic, None, True)
	ElseIf commandType == 2
		dogRef.Say(dogwaitTopic, None, True)
	ElseIf commandType == 3
		dogRef.Say(doghomeTopic, None, True)
	EndIf

EndFunction


;Return the relevant notification to display when a dog cannot be found.
String Function failNotification()

	If commandType == 1
		Return "No hay perros esperando cerca."
	ElseIf commandType == 2
		Return "No hay perros cerca."
	ElseIf commandType == 3
		Return "No hay perros esperando cerca."
	EndIf

EndFunction