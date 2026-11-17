Scriptname ADLDogAlias extends ReferenceAlias  
{Controls all actions carried out on the animal alias reference.}

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
ADLControllerDogs Property dogFunctions Auto
{The script that triggers various functions for dogs.}


;====================
;Properties
;====================

Armor[] Property dogArmorSpecial Auto
{The array containing special armor pieces that can equipped to dogs.}
Armor Property currentSkin Auto Hidden
{The current skin for this dog alias.}

Float Property dogHunger = 100.0 Auto Hidden
{The float that represents the dog's current hunger level.}
Float Property dogHappiness = 100.0 Auto Hidden
{The float that represents the dog's current happiness.}

FormList Property ADLFormFeedExceptions Auto
{A list of items dogs won't want to eat.}
FormList Property ADLFormFeedFavourites Auto
{A list of items dogs won't want to eat.}
FormList Property ADLFormCurrentDogs Auto
{The form list that holds all currently recruited dogs.}
FormList Property ADLFormDogAddons Auto
{The form list that holds all addons for dogs.}

GlobalVariable Property ADLGlobalCurrentDogs Auto
{The global that determine show many dogs are currently following.}
GlobalVariable Property GameDaysPassed Auto
{The global that determines how many game days have passed.}

Int Property deathType = 1 Auto Hidden
{1 - Standard | 2 - Sadness | 3 - Hunger}

ObjectReference Property PlayerREF Auto
{The reference for the player.}

Sound Property ADLSoundDogEat Auto
{The sound for the dog eating.}


;Wehn the game detects a menu close, check if a menu has been registered for and call the relevant action.
Event OnMenuClose(String menuName)

	Actor dogRef = Self.GetActorRef()
	Int dogIdentifier = Self.GetID()
	String dogName = dogFunctions.dogNames[dogIdentifier]

	;When feeding your dog, display their updated hunger state if notifications are enabled.
	If menuName == "GiftMenu"
		logReport("ADL | Menú cerrado | Regalo")
		String dogHungerState = mainFunctions.hungerState(dogHunger as Int)
		mainFunctions.createNotification(dogName, " está " + dogHungerState)
	EndIf

EndEvent


;When a game time update is registered by this alias, check their current wait state and perform the relevant action.
Event OnUpdateGameTime()

	Actor dogRef = Self.GetActorRef()
	Int dogIdentifier = Self.GetID()
	Int leaveChance = RandomInt(0, 100)
	String dogName = dogFunctions.dogNames[dogIdentifier]

	Float waitState = dogRef.GetAV("WaitingForPlayer")
	Float happinessRate = mainFunctions.settingsGlobals[8].Value
	Float hungerRate = mainFunctions.settingsGlobals[9].Value

	Spell happinessBuff = mainFunctions.dogSpells[0]
	Spell happinessDebuff = mainFunctions.dogSpells[1]
	Spell hungerBuff = mainFunctions.dogSpells[2]
	Spell hungerDebuff = mainFunctions.dogSpells[3]

	;Is the dog waiting for the player?
	If waitState == 1 ; Waiting
		logReport("ADL | Actualización de alias del perro | Revisión de espera")
		dogFunctions.dogHome(Self.GetActorRef())
		tweakHappiness(30, true)
	EndIf


	;Check the dog's happiness and updates the value if the feature is enabled.
	If mainFunctions.featuresGlobals[10].Value == 1

		logReport("ADL | Actualización de alias del perro | Revisión de felicidad")

		;Is the dog actively following the player?
		If waitState <= 1

			Self.RegisterForSingleUpdateGameTime(mainFunctions.settingsGlobals[10].Value)
			dogHappiness -= happinessRate

			logReport("ADL | Felicidad del perro | " + dogHappiness as Int)

			;Has the dog died from lack of affection?
			If dogHappiness <=0
				dogRef.GetActorBase().SetEssential(false)
				deathType = 2
				If leaveChance <= mainFunctions.settingsGlobals[11].Value
					dogFunctions.dogDismiss(dogRef)
					Notification(dogName + " se ha escapado por sentirse abandonado.")
					Return
				Else
					dogRef.Kill(getPlayer())
					Return
				EndIf
			;Is the dog feeling forsaken?
			ElseIf dogHappiness < 25
				Notification(dogName + " se siente abandonado")
				dogRef.AddSpell(happinessDebuff)
				If dogRef.hasSpell(happinessBuff)
					dogRef.RemoveSpell(happinessBuff)
					dogRef.DispelSpell(happinessBuff)
				EndIf
			;Is the dog feeling negelected?
			ElseIf dogHappiness < 50
				If dogRef.HasSpell(happinessBuff)
					dogRef.RemoveSpell(happinessBuff)
					dogRef.DispelSpell(happinessBuff)
				EndIf
				Notification(dogName + " se siente descuidado.")
			EndIf

		EndIf
		
	EndIf


	;Checks the dog's hunger and updates the value if the feature is enabled.
	If mainFunctions.featuresGlobals[11].Value == 1

		logReport("ADL | Actualización de alias del perro | Revisión de hambre")

		;Is the dog actively following the player?
		If waitState <= 1

			Self.RegisterForSingleUpdateGameTime(mainFunctions.settingsGlobals[10].Value)
			dogHunger -= hungerRate

			logReport("ADL | Hambre del perro | " + dogHunger as Int)

			;Has the dog died of starvation?
			If dogHunger <=0
				dogRef.GetActorBase().SetEssential(false)
				deathType = 3
				If leaveChance <= mainFunctions.settingsGlobals[11].Value
					dogFunctions.dogDismiss(dogRef, true)
					Notification(dogName + " se ha escapado por falta de comida.")
					Return
				Else
					dogRef.Kill(getPlayer())
					Return
				EndIf
			;Is the dog starving?
			ElseIf dogHunger < 25
				Notification(dogName + " se está muriendo de hambre!")
				dogRef.AddSpell(hungerDebuff)
				If dogRef.hasSpell(hungerBuff)
					dogRef.RemoveSpell(hungerBuff)
					dogRef.DispelSpell(hungerBuff)
				EndIf
			;Is the dog hungry?
			ElseIf dogHunger < 50
				If dogRef.HasSpell(hungerBuff)
					dogRef.RemoveSpell(hungerBuff)
					dogRef.DispelSpell(hungerBuff)
				EndIf
				Notification(dogName + " tiene hambre.")
			EndIf

		EndIf

	EndIf
	
EndEvent


;When the dog is loaded back into the game, re-equip their stored skin.
Event OnLoad()

	Actor dogRef = self.getActorRef()
	Int dogIdentifier = self.getID()

	If currentSkin != None
		mainFunctions.removeSkin(dogRef)
		dogRef.EquipItem(currentSkin, False, True)
	EndIf

EndEvent


;If the dog is unloaded from the game whilst following, place them back at the player's location.
Event OnUnload()

	Actor dogRef = Self.GetActorRef()
	Actor thePlayer = getPlayer()
	Location playerLocation = thePlayer.GetCurrentLocation()
	Int spawnPos = Utility.RandomInt(-150 ,-100)

	logReport("ADL | Alias del perro descargado")
	Wait(2)

	;Is the Automatic Recall feature enabled?
	If mainFunctions.featuresGlobals[6].Value >= 2
		;
		If !dogRef.IsNearPlayer()
			;Is the dog following the player and not being moved to a restricted location?
			If dogRef.GetAV("WaitingForPlayer") == 0 && !mainFunctions.ADLFormRestrictedLocs.HasForm(playerLocation)
				logReport("ADL | Perro llamado de vuelta")
				dogRef.MoveTo(thePlayer, spawnPos * Math.Sin(thePlayer.GetAngleZ()), spawnPos * Math.Cos(thePlayer.GetAngleZ()))
			EndIf
		EndIf
	EndIf

EndEvent


;When an item is added, check the current wait state and perform the relevant function.
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)

	;Wait States: 0 = Following | 1 = Waiting | 2 = Home | 3 = Unused | 4 = Loot

	Actor thePlayer = getPlayer()
	Actor dogActor = Self.GetActorRef()
	ObjectReference dogRef = Self.GetRef()
	Int dogIdentifier = Self.GetID()
	Int dogAffinity = dogActor.GetRelationshipRank(thePlayer)
	Int affinityChance = RandomInt(0, 100)
	Int persuadeChance = RandomInt(0,100)
	String dogName = dogFunctions.dogNames[dogIdentifier]
	Float waitState = Self.GetActorRef().GetAV("WaitingForPlayer")

	logReport("ADL | " + dogName + " Objeto recibido: " + akBaseItem.getName())

	;Is the dog fetching an item for the player?
	If waitState >= 3 && waitState < 10

		logReport("ADL | " + dogName + " recibió " + akBaseItem.getName())
		dogRef.RemoveItem(akBaseItem, aiItemCount, false, dogFunctions.fetchContainers[dogIdentifier])

	;Is the dog receiving an item to eat?
	ElseIf UI.IsMenuOpen("GiftMenu")

		;Check if the dog has eaten recently, and either accept or reject the food.
		If dogHunger > 85
			MessageBox(dogName + " no tiene hambre.")
			dogRef.RemoveItem(akBaseItem, aiItemCount, true)
			PlayerREF.AddItem(akBaseItem, aiItemCount, true)
			Return
		EndIf

		foodCheck(akBaseItem, aiItemCount, dogRef, thePlayer, dogName)

	;Cover other checks and actions to be performed when the dog is receiving items.
	Else

		If dogActor.IsEquipped(ADLFormDogAddons)

			;Is the added item a book?
			If akBaseItem.getType() == 27 ;Books

				;If the dog has more than 4 scrolls on them, add the special scrolls armor piece.
				If dogRef.GetItemCount(akbaseItem) >  4
					dogActor.EquipItem(dogArmorSpecial[1])
				Else
					;Does the dog have the books armor piece equipped? If so remove it.
					If dogActor.isEquipped(dogArmorSpecial[1] as Armor)
						dogActor.RemoveItem(dogArmorSpecial[1], 1, true)
					EndIf
				EndIf

			;Is the added item a scroll?
			ElseIf akbaseItem.getType() == 23 ; Scrolls

				;If the dog has more than 4 scrolls on them, add the special scrolls armor piece.
				If dogRef.GetItemCount(akbaseItem) >  4
					dogActor.EquipItem(dogArmorSpecial[2])
				Else
					;Does the dog have the scrolls armor piece equipped? If so remove it.
					If dogActor.isEquipped(dogArmorSpecial[2] as Armor)
						dogActor.RemoveItem(dogArmorSpecial[2], 1, true)
					EndIf
				EndIf

			EndIf

		EndIf

	EndIf

EndEvent


Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)

	Actor dogActor = Self.GetActorRef()

	If akBaseItem.GetType() == 27 ; Books

		;Does the dog have scrolls equipped?
		If dogActor.IsEquipped(dogArmorSpecial[1])
			;Does the dog no longer have enough of the item?
			If dogActor.GetItemCount(akBaseItem) < 5
				dogActor.RemoveItem(dogArmorSpecial[1])
			EndIf
		EndIf

	ElseIf akBaseItem.getType() == 23 ; Scrolls

		;Does the dog have scrolls equipped?
		If dogActor.IsEquipped(dogArmorSpecial[2])
			;Does the dog no longer have enough of the item?
			If dogActor.GetItemCount(akBaseItem) < 5
				dogActor.RemoveItem(dogArmorSpecial[2])
			EndIf
		EndIf

	EndIf

EndEvent


;Detects when an object is equipped on the dog and performs a check if they should be wearing their lantern or not.
Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)

	Actor thePlayer = getPlayer()
	ObjectReference dogRef = Self.GetRef()
	Int dogIdentifier = Self.GetID()
	String dogName = dogFunctions.dogNames[dogIdentifier]

	;Check if the dog has been given a lantern and pass it back to the player if the dog doesn't have a harness.
	If akBaseObject == dogArmorSpecial[0]
		If !Self.getActorRef().IsEquipped(ADLFormDogAddons)
			dogRef.RemoveItem(dogArmorSpecial[0], 1, true, thePlayer)
			Notification(dogName + " necesita un arnés.")
		EndIf
	EndIf

EndEvent


;Controls checking for if the player is commiting a betrayal by harming the dog.
Event OnCombatStateChanged(Actor akTarget, Int aeCombatState)

	Actor dogRef = Self.GetActorRef()

	;Is the attack target the player?
	If (akTarget == getPlayer())
		logReport("ADL | Combate iniciado: jugador")
		dogFunctions.dogDismiss(dogRef)
	EndIf

EndEvent


;Detects when your dog is hit and performs the relevant action depending on the attacker.
Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)

	Actor dogRef = Self.GetActorRef()
	Int dogIdentifier = Self.GetID()
	String dogName = dogFunctions.dogNames[dogIdentifier]
	Int leaveChance = RandomInt(0, 100)
	Float dogHealth = dogRef.GetActorValuePercentage("Health")

	;If the aggressor is the player, check ownership and perform a runaway check.
	If akAggressor == GetPlayer() && (akSource as Spell).isHostile()
		logReport("ADL | Perro molestado por un golpe: jugador")
		If ADLFormCurrentDogs.hasForm(dogRef)
			;If the dog's health is dangerously low, force the dog to run away out of fear of death.
			If dogHealth > 0.35 && doghealth < 0.50
				If leaveChance <= mainFunctions.settingsGlobals[11].Value
					dogFunctions.dogDismiss(dogRef)
				EndIf
			EndIf
		Else
			dogRef.SetRelationshipRank(GetPlayer(), -3)
			Notification(dogName + " ahora está irritado")
		EndIf
	Endif		

EndEvent



;Upon death, fully dismiss the dog.
Event OnDeath(Actor akKiller)

	Actor dogRef = Self.GetActorRef()
	Int dogIdentfier = Self.GetID()
	String dogName = dogFunctions.dogNames[dogIdentfier]

	;Has a name been entered?
	If dogName == ""
		Notification(dogRef.GetRace().GetName() + mainFunctions.deathState(deathType))
	Else
		Notification(dogName + mainFunctions.deathState(deathType))
	EndIf

	dogRef.SetPlayerTeammate(false, false)
	ADLFormCurrentDogs.RemoveAddedForm(dogRef)
	dogRef.SetAV("WaitingForPlayer", 0)
	mainFunctions.setTracking(dogFunctions, dogIdentfier, false)
	ADLGlobalCurrentDogs.Mod(-1)

	;Set the values for happinness and hunger back to default values ready for if the dog is reruited again.
	dogHappiness = 100
	dogHunger = 100

	Self.UnregisterForUpdate()
	Self.UnregisterForUpdateGameTime()
	Self.Clear()
	
EndEvent


;=========================
;Main Functions
;=========================

;Increases or decreases happiness based on the provided values.
Function tweakHappiness(Int happinessVal, Bool negetiveTweak = False)

	Int dogIdentfier = Self.GetID()
	String dogName = dogFunctions.dogNames[dogIdentfier]
	Float happinessRate = mainFunctions.settingsGlobals[8].Value

	mainFunctions.displayTutorial(10)

	;Check the dog's happiness and updates the value if the feature is enabled.
	If mainFunctions.featuresGlobals[10].Value == 1

		logReport("ADL | Ajuste de hambre del perro | " + happinessVal as Int)

		;Is there a negetive effect being applied instead to lower happiness?
		If negetiveTweak
			dogHappiness -= (doghappiness - happinessRate)
		Else
			dogHappiness += happinessVal
		EndIf

		If dogHappiness > 100
			dogHappiness = 100
		EndIf
		
	EndIf

EndFunction


;Increases or decreases hunger based on the provided values.
Function tweakHunger(Int hungerVal)

	Int dogIdentfier = Self.GetID()
	String dogName = dogFunctions.dogNames[dogIdentfier]

	mainFunctions.displayTutorial(11)

	;Check the dog's hunger and updates the value if the feature is enabled.
	If mainFunctions.featuresGlobals[11].Value == 1

		logReport("ADL | Ajuste de felicidad del perro | " + hungerVal as Int)

		dogHunger += hungerVal

		If dogHunger > 100
			dogHunger = 100
		EndIf

	EndIf

EndFunction


;When the dog is fed, check their hunger status and provide the relevant buffs and debuffs.
Function feedDog(ObjectReference dogRef, Actor thePlayer, Int hungerIncrease)

	Actor dogActor = dogRef as Actor

	Spell hungerBuff = mainFunctions.dogSpells[2]
	Spell hungerDebuff = mainFunctions.dogSpells[3]

	While IsInMenuMode()
		;;Wait
	EndWhile
	mainFunctions.sendIdle(thePlayer, "IdleGive")
	Wait(1.5)
	ADLSoundDogEat.Play(thePlayer)
	tweakHunger(hungerIncrease)

	;If the dog is well fed, apply the relevant buff.
	If dogHunger > 70
		dogActor.AddSpell(hungerBuff)
		If dogActor.hasSpell(hungerDebuff)
			dogActor.DispelSpell(hungerDebuff)
			dogActor.RemoveSpell(hungerDebuff)
		EndIf
	;if the dog is hungry, apply the relevant debuff.
	ElseIf dogHunger > 30
		If dogActor.hasSpell(hungerDebuff)
			dogActor.DispelSpell(hungerDebuff)
			dogActor.RemoveSpell(hungerDebuff)
		EndIf
	EndIf

	Self.RegisterForMenu("GiftMenu")

EndFunction


;Checks food being given the dog and either passes it back or consumes it, applying any relevant buffs.
Function foodCheck(Form akBaseItem, Int aiItemCount, ObjectReference dogRef, Actor thePlayer, String dogName)

	;Is the item a restricted item?
	If ADLFormFeedExceptions.HasForm(akBaseItem)
		logReport("ADL | Perro rechazó la comida")
		dogRef.RemoveItem(akbaseItem, aiItemCount, true, thePlayer)
		Notification(dogName + " escupió " + akBaseItem.getName())
		Return
	ElseIf ADLFormFeedFavourites.HasForm(akBaseItem)
		logReport("ADL | Perro aceptó la comida | Mejora aplicada")
		feedDog(dogRef, thePlayer, 30)
		dogRef.RemoveItem(akbaseItem, aiItemCount, true)
	Else
		logReport("ADL | Comida favorita del perro | Mejora aplicada")
		feedDog(dogRef, thePlayer, 20)
		dogRef.RemoveItem(akbaseItem, aiItemCount, true)
	EndIf

EndFunction


;=========================
;Extension Functions
;=========================

Function logReport(String logText)

	mainFunctions.logReport(logText)

EndFunction