Scriptname ADLHarness extends ObjectReference  
{When the item this script is attached to is unequipped, check if the dog has a lantern equipped and unequip it, returning it to the player.}

Armor Property equippedArmor Auto
{State itself as an object to be removed if equipped to the player.}

Armor Property ADLLantern Auto
{The armor piece for the dog lantern.}

Armor Property ADLDogBooks Auto
{The armor piece for displaying books on the dog.}

Armor Property ADLDogScrolls Auto
{The armor piece for displaying books on the dog.}

ObjectReference Property PlayerREF Auto
{The reference for the player.}


;On unequip of the harness, remove any equipped lantern from the dog.
Event OnUnequipped(Actor akActor)

	;Does the dog have a lantern equipped?
	If akActor.IsEquipped(ADLLantern)
		akActor.RemoveItem(ADLLantern, 1, true, PlayerREF)
	EndIf

	;Does the dog have books equipped?
	If akActor.IsEquipped(ADLDogBooks)
		akActor.RemoveItem(ADLDogBooks, 1, true, PlayerREF)
	EndIf

	;Does the dog have scrolls equipped?
	If akActor.IsEquipped(ADLDogScrolls)
		akActor.RemoveItem(ADLDogScrolls, 1, true, PlayerREF)
	EndIf

EndEvent


;Detects if the player is attempting to equip the item and unequip it immediately.
Event OnEquipped(Actor akActor)

	;Is the actor trying to equip this object the player?
	If akActor == PlayerRef
		PlayerREF.RemoveItem(equippedArmor, 1, true)
		PlayerREF.AddItem(equippedArmor, 1, true)
		Debug.Notification("No puedes equipar un " + equippedArmor.GetName() + ".")
	EndIf

EndEvent