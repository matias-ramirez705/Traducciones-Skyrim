Scriptname ADLRecall extends activemagiceffect
{Recalls any distant dogs back to the player when the spell is cast.}


;====================
;Import Functions
;====================

Import Game
Import Debug


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

Sound Property ADLSoundWhistle Auto
{The sound played to recall over dogs.}


;On recall being called, fetch any following dogs and bring them back to the player's location.
Event OnEffectFinish(Actor akTarget, Actor akCaster)

	Actor thePlayer = GetPlayer()

	;Are there any dogs currently following?
	If ADLGlobalCurrentDogs.Value > 0

		Int iIndex = 0
		Int iNearby = 0

		While iIndex < ADLFormCurrentDogs.GetSize()

			Actor nextDog = ADLFormCurrentDogs.GetAt(iIndex) as Actor
			Int spawnPos = Utility.RandomInt(-900 ,-1000)

			;Is the alias filled?
			If nextDog != None

				Float waitState = nextDog.GetAV("WaitingForPlayer")

				;Is the dog following the player or waiting?
				If waitState != 2
					;Is the dog in range of the player?
					If !nextDog.IsNearPlayer()
						iNearby+=1
						nextDog.MoveTo(thePlayer, SpawnPos * Math.Sin(thePlayer.GetAngleZ()), SpawnPos * Math.Cos(thePlayer.GetAngleZ()))
					EndIf
				EndIf
			EndIf

			iIndex+=1

		EndWhile

		If iNearby == 0
			Notification("No hay perros perdidos.")
		Else
			mainFunctions.sendIdle(GetPlayer(), "IdleLookFar")
			ADLSoundWhistle.Play(thePlayer)
			mainFunctions.displayTutorial(6)
		EndIf

	EndIf

EndEvent