Scriptname ADLThrowBall extends activemagiceffect  
{Removes a ball from the player's inventory and launches it ahead of the player for the dog to chase.}

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

Float Property impulseValue = 30.0 Auto
{The force to apply to the ball.}

Faction Property ADLCurrentDogFaction Auto
{The faction for owned dogs.}

FormList Property ADLFormCurrentDogs Auto
{The form list that holds all currently recruited dogs.}

FormList Property ADLFormDogTypes Auto
{The form list that holds all the dogs that can be followers.}

MiscObject Property ADLDogBall Auto
{The misc object for the ball.}

Spell Property ADLSpellThrowBall Auto
{The spepl for throwing a ball.}

ObjectReference Property PlayerREF Auto
{The reference for the player.}


Event OnEffectStart(Actor Target, Actor Caster)

	If PlayerREF.IsInInterior()
		Notification("Las pelotas deben lanzarse en el exterior.")
		Return
	EndIf

	Actor nearestDog = FindClosestReferenceOfAnyTypeInList(ADLFormDogTypes, PlayerREF.GetPositionX(), PlayerREF.GetPositionY(), PlayerREF.GetPositionZ(), 4092) as Actor
	Actor ThePlayer = getPlayer()
	ADLDogAlias needsFunctions = mainFunctions.getAliasScript(nearestDog) as ADLDogAlias

	If nearestDog.IsInFaction(ADLCurrentDogFaction)

		If nearestDog.GetActorValue("WaitingForPlayer") == 0

			ForceThirdPerson()
			ThePlayer.RemoveSpell(ADLSpellThrowBall)
			ThePlayer.RemoveItem(ADLDogBall, 1, True)

			ObjectReference ball = caster.PlaceAtMe(ADLDogBall, 1)

			;Place a yarn ball in the player's hand and launch it.
			ball.MoveToNode(Caster as ObjectReference, "NPC R Hand [RHnd]")
			Wait(0.05)
			ball.ApplyHavokImpulse(Math.Sin(Caster.GetAngleZ()), Math.Cos(Caster.GetAngleZ()), Math.asin(Caster.GetAngleX()), impulseValue)
			ball.SetActorOwner(ThePlayer.GetActorBase())
			ThePlayer.UnequipSpell(ADLSpellThrowBall, 1)
			nearestDog.EvaluatePackage()

			;Wait and disable the ball. This forces the dog to notice an object that was not present during the AI package start.
			Utility.Wait(1)
			ball.delete()
			ball.PlaceAtMe(ADLDogBall)
			nearestDog.SetActorValue("WaitingForPlayer", 10)
			nearestDog.EvaluatePackage()

			;Call for a happiness check to increase happiness and display a notification.
			needsFunctions.tweakHappiness(20)

		Else
			
			Notification("No hay perros siguiéndote cerca.")

		EndIf

	Else
		
		Notification("No hay perros siguiéndote cerca.")

	EndIf

EndEvent