Scriptname ADLCMCMController extends SKI_ConfigBase
{The controlling script for the mod configuration menu.}

;====================
;Import Functions
;====================

Import Game


;====================
;Import Scripts
;====================

ADLMainController Property mainFunctions Auto
{The script that triggers shared functions for dogs.}
ADLControllerDogs Property dogFunctions Auto
{The script that triggers various functions for dogs.}


;====================
;MCM Properties
;====================

;FEATURES
;Interface

Int iTutorials
Bool ValTutorials = True
Int iNotify
Bool ValNotify = False
Int iInventory
Bool ValInventory = False

;Management
Int iNames
Bool ValNames = False
Int iTeleport
Bool ValTeleport = False
Int iCrafting
Bool ValCrafting = True

;Behaviour
Int iRecall
Int indexRecall
String[] Property sRecall Auto
Int iCommands
Bool ValCommands = False
Int iAnimations
Bool ValAnimations = True
Int iStupid
Bool ValStupid = True

;Needs
Int iAffinity
Bool ValAffinity = True
Int iHappiness
Bool ValHappiness = False
Int iHunger
Bool ValHunger = False

;CONFIGURATION
;Management
Int iInventoryCap
Float fInventoryCap = 150.0
Int iCost
Float fCost = 500.0

;Behaviour
Int iWait
Float fWait = 72.0
Int iRunaway
Float fRunaway = 30.0

;Sandboxing
Int iInns
Bool ValInns = True
Int iStores
Bool ValStores = False
Int iHomes
Bool ValHomes = True
Int iTowns
Bool ValTowns = False

;Needs
Int iAffinityChance
Float fAffinityChance = 30.0
Int iHappinessRate
Float fHappinessRate = 10.0
Int iHungerRate
Float fHungerRate = 10.0
Int iCheckRate
Float fCheckrate = 2.0

;TRACKING
;Dog Select
Int iDogSelect
String[] Property sDogs Auto
;Skin Selection
Int iSkinDog
Int indexDogSkins = 0
Int indexHuskySkins = 0
Int indexDeathHoundSkins = 0
Int indexKelpieSkins = 0
String[] Property sDogSkins Auto
String[] Property sHuskySkins Auto
String[] Property sDeathHoundSkins Auto
String[] Property sKelpieSkins Auto
String[] currentSkins
FormList dogSkins
;Race Select
Int iRace
Int iIndexRaces
String[] Property sRaces Auto
;Tracking Toggle
Int iTracking
Bool[] Property ValTracking Auto
;Dog Stats
Int indexDogs
Int iDogStat01
Int iDogStat02
FLoat fDogHealth
Float fDogStamina
Float fHealth
Float fStamina

;GUIDE
Int gAdoption
Int gDiscovery
Int gBreeders
Int gAffinity
Int gMerchants
Int gInventory
Int gCrafting
Int gHomes
Int gPetting
Int gHappiness
Int gNeeds
Int gHunger
Int gCommands
Int gFetch
Int gNames
Int gTracking
Int gRecall
Int gAbandonment
Int gDiseases
Int gRunaways

;MAINTENANCE
Int iLogs
Bool ValLogs = False
Int iDebug
Bool ValDebug = False
Int iDismissDogs
Int iStop
Bool ValStop = False
String Property Version Auto Hidden
String Property modVersion Auto

;====================
;General Properties
;====================

FormList Property ADLFormCurrentDogs Auto
{The form list that holds all currently recruited dogs.}

ObjectReference Property PlayerREF Auto
{The reference for the player.}

Quest[] Property dogQuests Auto
{The array containing the quests controlling all functions of the mod.}

ReferenceAlias[] Property dogAliases Auto
{The array containing the reference alises for all recruited dogs.}

Sound[] Property menuSounds Auto
{The array of sounds for the menu selection.}

Spell[] Property dogSpells Auto
{The array that contains the spells for the mod provided via MCM.}


Event OnInit()

	Parent.OnInit()

EndEvent


Event OnPageReset(String Page)

	If Page == ""
		LoadCustomContent("ADL/ADLSplash.dds")
	Else
		UnloadCustomContent()
	EndIf

	If Page == "Features"

		SetCursorFillMode(LEFT_TO_RIGHT)

		AddTextOption("<font color='#729ac0'>Interfaz</font>", "")
		AddTextOption("<font color='#729ac0'>Gestión</font>", "")

		iTutorials = AddToggleOption("Tutoriales", ValTutorials)
		iNames = AddToggleOption("Nombres", ValNames)
		iNotify = AddToggleOption("Notificaciones", ValNotify)
		iTeleport = AddToggleOption("Teletransporte", ValTeleport)
		iInventory = AddToggleOption("Inventario", ValInventory)
		iCrafting = AddToggleOption("Fabricación", ValCrafting)

		AddEmptyOption()
		AddEmptyOption()

		AddTextOption("<font color='#729ac0'>Comportamiento</font>", "")
		AddTextOption("<font color='#729ac0'>Necesidades</font>", "")

		iRecall = AddMenuOption("Llamado", sRecall[indexRecall])
		iAffinity = AddToggleOption("Afinidad", ValAffinity)
		iCommands = AddToggleOption("Órdenes", ValCommands)
		iHappiness = AddToggleOption("Felicidad", ValHappiness)
		iAnimations = AddToggleOption("Animaciones", ValAnimations)
		iHunger = AddToggleOption("Hambre", ValHunger)
		iStupid = AddToggleOption("Perro estúpido", ValStupid)

	ElseIf Page == "Configuration"

		Int BlankFlag = OPTION_FLAG_DISABLED

		SetCursorFillMode(LEFT_TO_RIGHT)

		AddTextOption("<font color='#729ac0'>Gestión</font>", "")
		AddTextOption("<font color='#729ac0'>Comportamiento</font>", "")

		iInventoryCap = AddSliderOption("Capacidad de inventario", fInventoryCap, "{0} lbs")
		iWait = AddSliderOption("Tiempo de espera", fWait, "{0} horas")
		iCost = AddSliderOption("Costo de compra", fCost, "{0} septims")
		iRunaway = AddSliderOption("Probabilidad de fuga", fRunaway, "{0}%")

		AddEmptyOption()
		AddEmptyOption()

		AddTextOption("<font color='#729ac0'>Deambular</font>", "")
		AddTextOption("<font color='#729ac0'>Necesidades</font>", "")

		iInns = AddToggleOption("Tabernas", ValInns)
		iAffinityChance = AddSliderOption("Probabilidad de afinidad", fAffinityChance, "{0}%")
		iStores = AddToggleOption("Tiendas", ValStores)
		If mainFunctions.featuresGlobals[10].Value == 1
			iHappinessRate = AddSliderOption("Ritmo de felicidad", fHappinessRate, "{0} puntos")
		Else
			AddTextOption("Ritmo de felicidad", "Felicidad desactivada", BlankFlag)
		EndIf
		iHomes = AddToggleOption("Hogar", ValHomes)
		If mainFunctions.featuresGlobals[11].Value == 1
			iHungerRate = AddSliderOption("Ritmo de hambre", fHungerRate, "{0} puntos")
		Else
			AddTextOption("Ritmo de hambre", "Hambre desactivada", BlankFlag)
		EndIf
		iTowns = AddToggleOption("Pueblos", ValTowns)
		If mainFunctions.featuresGlobals[10].Value == 1 || mainFunctions.featuresGlobals[11].Value == 1
			iCheckRate = AddSliderOption("Intervalo de revisión de necesidades", fCheckrate, "{0} Hours")
		Else
			AddTextOption("Intervalo de revisión de necesidades", "Necesidades desactivadas", BlankFlag)
		EndIf

	ElseIf Page == "Dogs" || Page == "Tracking"

		SetCursorFillMode(LEFT_TO_RIGHT)
		Int BlankFlag = OPTION_FLAG_DISABLED

		AddTextOption("<font color='#729ac0'>Selección de animal</font>", "")

		If ADLFormCurrentDogs.GetSize() == 0
			AddEmptyOption()
			AddTextOption("No hay perros que rastrear", "")
		Else

			;GATHER DOG INFO
			Actor dogRef = ADLFormCurrentDogs.GetAt(indexDogs) as Actor
			Int dogIdentifier = mainFunctions.getDog(dogRef).GetID()
			ADLDogAlias needsFunctions = mainFunctions.getAliasScript(dogRef) as ADLDogAlias
			String dogname = dogRef.GetBaseObject().GetName()
			String dogHome = dogFunctions.homeReferences[dogIdentifier].GetCurrentLocation().getName()
			String dogLocation = dogRef.GetCurrentLocation().GetName()

			AddTextOption("<font color='#729ac0'>Información</font>", "")

			iDogSelect = AddMenuOption("Perro", dogName)
			AddTextOption("Nivel actual", dogRef.GetLevel())

			Int dogRace = mainFunctions.fetchRace(dogRef)
			iIndexRaces = dogRace
			iRace = AddMenuOption("Raza", sRaces[dogRace])

			;Display Dog State
			If !dogName == ""
				DisplayState(dogRef, dogName, dogLocation, dogHome)
			Else
				AddEmptyOption()
			EndIf

			;Display Dog Race
			If dogRef.GetRace() == mainFunctions.dogRaces[0] ; Standard Dog
				Int dogSkin = mainFunctions.getSkin(dogRef)
				indexDogSkins = dogSkin
				iSkinDog = AddMenuOption("Color", sDogSkins[dogSkin])
				currentSkins = sDogSkins
				dogSkins = mainFunctions.dogSkins[0]
			ElseIf dogRef.GetRace() == mainFunctions.dogRaces[1] || dogRef.GetRace() == mainFunctions.dogRaces[2] ; Husky Dog
				Int dogSkin = mainFunctions.getSkin(dogRef)
				indexHuskySkins = dogSkin
				iSkinDog = AddMenuOption("Color", sHuskySkins[dogSkin])
				currentSkins = sHuskySkins
				dogSkins = mainFunctions.dogSkins[1]
			ElseIf dogRef.GetRace() == mainFunctions.dogRaces[3] ; Death Hound
				Int dogSkin = mainFunctions.getSkin(dogRef)
				indexDeathHoundSkins = dogSkin
				iSkinDog = AddMenuOption("Color", sDeathHoundSkins[dogSkin])
				currentSkins = sDeathHoundSkins
				dogSkins = mainFunctions.dogSkins[2]
			ElseIf dogRef.GetRace() == mainFunctions.dogRaces[4] ; Kelpie
				Int dogSkin = mainFunctions.getSkin(dogRef)
				indexKelpieSkins = dogSkin
				iSkinDog = AddMenuOption("Color", sKelpieSkins[dogSkin])
				currentSkins = sKelpieSkins
				dogSkins = mainFunctions.dogSkins[3]
			Else
				AddTextOption("Color", "Sin colores alternativos", BlankFlag)
			EndIf

			iTracking = AddToggleOption("Rastreo activo", ValTracking[dogIdentifier])

			AddEmptyOption()
			AddEmptyOption()

			If !dogName == ""
				AddTextOption("<font color='#729ac0'>Atributos</font>", "")
				AddEmptyOption()
				fDogHealth = dogRef.GetBaseActorValue("Health")
				iDogStat01 = AddInputOption("Health", fDogHealth as Int + "<font color='#D1BD3B'> (" + dogRef.GetActorValue("Health") as Int + ")</font>")
				fDogStamina = dogRef.GetBaseActorValue("Stamina")
				iDogStat02 = AddInputOption("Stamina", fDogStamina as Int + "<font color='#D1BD3B'> (" + dogRef.GetActorValue("Stamina") as Int + ")</font>")
			EndIf

			AddEmptyOption()
			AddEmptyOption()

			AddTextOption("<font color='#729ac0'>Necesidades</font>", "")
			AddEmptyOption()

			If mainFunctions.featuresGlobals[10].Value == 1

				String HappinessState

				If dogRef.HasMagicEffect(mainFunctions.dogEffects[2])
					HappinessState = "<font color='#68d13b'>Mejora de Querido</font>"
				ElseIf dogRef.HasMagicEffect(mainFunctions.dogEffects[3])
					HappinessState = "<font color='#d13b3b'>Penalización de Descuidado</font>"
				Else
					HappinessState = "Sin mejoras activas"
				EndIf

				AddTextOption("Felicidad", mainFunctions.happinessState(needsFunctions.dogHappiness as Int))
				AddTextOption("Mejoras de felicidad", HappinessState)

			Else
				AddTextOption("Felicidad", "Felicidad desactivada", BlankFlag)
				AddTextOption("Mejoras de felicidad", "Felicidad desactivada", BlankFlag)
			EndIf

			If mainFunctions.featuresGlobals[11].Value == 1

				String HungerState

				If dogRef.HasMagicEffect(mainFunctions.dogEffects[0])
					HungerState = "<font color='#68d13b'>Mejora de Bien Alimentado</font>"
				ElseIf dogRef.HasMagicEffect(mainFunctions.dogEffects[1])
					HungerState = "<font color='#d13b3b'>Penalización de Malnutrido</font>"
				Else
					HungerState = "Sin mejoras activas"
				EndIf

				AddTextOption("Hambre", mainFunctions.hungerState(needsFunctions.dogHunger as Int))
				AddTextOption("Mejoras de hambre", HungerState)

			Else
				AddTextOption("Hambre", "Hambre desactivada", BlankFlag)
				AddTextOption("Mejoras de hambre", "Hambre desactivada", BlankFlag)
			EndIf

		EndIf

	ElseIf Page == "Guide"

		SetCursorFillMode(LEFT_TO_RIGHT)

		AddTextOption("<font color='#729ac0'>Jugabilidad</font>", "")
		AddTextOption("<font color='#729ac0'>Interacciones</font>", "")
		gAdoption = AddTextOption("Adopción", "")
		gDiscovery = AddTextOption("Descubrimiento", "")
		gBreeders = AddTextOption("Criadores de perros", "")
		gAffinity = AddTextOption("Afinidad", "")
		gMerchants = AddTextOption("Comerciantes", "")
		gInventory = AddTextOption("Inventario", "")
		gCrafting = AddTextOption("Fabricación", "")
		gHomes = AddTextOption("Hogares", "")
		gPetting = AddTextOption("Acariciar", "")
		gHappiness = AddTextOption("Felicidad", "")
		gNeeds = AddTextOption("Necesidades", "")
		gHunger = AddTextOption("Hambre", "")
		gCommands = AddTextOption("Órdenes", "")
		gFetch = AddTextOption("Buscar", "")
		gNames = AddTextOption("Nombres", "")
		gTracking = AddTextOption("Tracking", "")
		gRecall = AddTextOption("Llamado", "")
		gAbandonment = AddTextOption("Abandono", "")
		gDiseases = AddTextOption("Enfermedades", "")
		gRunaways = AddTextOption("Fugas", "")
		
	ElseIf Page == "Maintenance"

		SetCursorFillMode(LEFT_TO_RIGHT)
		Int BlankFlag = OPTION_FLAG_DISABLED

		AddTextOption("<font color='#729ac0'>Órdenes grupales</font>", "")
		AddTextOption("<font color='#729ac0'>Solución de problemas</font>", "")

		If ADLFormCurrentDogs.GetSize() > 0
			iDismissDogs = AddTextOption("Despedir perros", "")
		Else
			AddTextOption("Despedir perros", "", BlankFlag)
		EndIf

		iLogs = AddToggleOption("Registros de Papyrus", ValLogs)
		AddEmptyOption()
		iDebug = AddToggleOption("Notificaciones de depuración", ValDebug)
		AddEmptyOption()
		AddEmptyOption()

		AddTextOption("<font color='#729ac0'>Desinstalación</font>", "")
		AddTextOption("<font color='#729ac0'>Detalles del mod</font>", "")
		If !ValStop
			iStop = AddTextOption("<font color='#d6a738'>Detener mod</font>", "EN MARCHA")
		Else
			iStop = AddTextOption("Iniciar mod", "DETENIDO")
		EndIf
		AddTextOption("Versión del mod", modVersion)
		AddTextOption("Sitio web", "www.darkfox127.co.uk")

	EndIf

EndEvent


Event OnOptionInputAccept(Int aOption, String sString)

	Int ValueCheck = sString as Int

	If ValueCheck > 0 && ValueCheck <= 10000
		MenuSounds[2].Play(PlayerREF)
		SetSkill(aOption, sString)
	Else
		MenuSounds[1].Play(PlayerREF)
		ShowMessage("Introduce un valor entre 1 y 10000", false, "Volver")
	EndIf

EndEvent


Function SetSkill(Int aOption, String sString)

	Actor dogActor = dogAliases[indexDogs].GetActorRef()

	If aOption == iDogStat01
		fHealth = sString as Int
		SetInputOptionValue(aOption, sString as Int + "<font color='#D1BD3B'> (" + dogActor.GetActorValue("Health") as Int + ")</font>")
		dogActor.SetActorValue("Health", fHealth)
	ElseIf aOption == iDogStat02
		fStamina = sString as Int
		SetInputOptionValue(aOption, sString as Int + "<font color='#D1BD3B'> (" + dogActor.GetActorValue("Stamina") as Int + ")</font>")
		dogActor.SetActorValue("Stamina", fStamina)
	EndIf

EndFunction


Event OnOptionSelect(Int Option)

	Actor thePlayer = GetPlayer()

	menuSounds[0].Play(PlayerREF)

	If CurrentPage == "Features"

		If option == iTutorials
			ValTutorials = !ValTutorials
			SetToggleOptionValue(iTutorials, ValTutorials)
			ToggleButton(mainFunctions.featuresGlobals[0])
		ElseIf option == iNotify
			ValNotify = !ValNotify
			SetToggleOptionValue(iNotify, ValNotify)
			ToggleButton(mainFunctions.featuresGlobals[1])
		ElseIf option == iInventory
			ValInventory = !ValInventory
			SetToggleOptionValue(iInventory, ValInventory)
			ToggleButton(mainFunctions.featuresGlobals[2])
		ElseIf option == iNames
			ValNames = !ValNames
			SetToggleOptionValue(iNames, ValNames)
			ToggleButton(mainFunctions.featuresGlobals[4])
		ElseIf option == iTeleport
			ValTeleport = !ValTeleport
			SetToggleOptionValue(iTeleport, ValTeleport)
			ToggleButton(mainFunctions.featuresGlobals[5])

			If mainFunctions.featuresGlobals[5].Value == 1
				GetPlayer().AddSpell(dogSpells[4], False)
				MenuSounds[3].Play(PlayerREF)
			Else
				GetPlayer().RemoveSpell(dogSpells[4])
			EndIf

		ElseIf option == iCrafting
			ValCrafting = !ValCrafting
			SetToggleOptionValue(iCrafting, ValCrafting)
			ToggleButton(mainFunctions.featuresGlobals[12])
		ElseIf option == iCommands
			ValCommands = !ValCommands
			SetToggleOptionValue(iCommands, ValCommands)
			ToggleButton(mainFunctions.featuresGlobals[7])

		If mainFunctions.featuresGlobals[7].Value == 1
			Debug.Notification("Órdenes añadidas")
			thePlayer.AddSpell(dogSpells[0], False)
			thePlayer.AddSpell(dogSpells[1], False)
			thePlayer.AddSpell(dogSpells[2], False)
			MenuSounds[3].Play(PlayerREF)
		Else
			thePlayer.RemoveSpell(dogSpells[0])
			thePlayer.RemoveSpell(dogSpells[1])
			thePlayer.RemoveSpell(dogSpells[2])
		EndIf

		Elseif option == iAnimations
			ValAnimations = !ValAnimations
			SetToggleOptionValue(iAnimations, ValAnimations)
			ToggleButton(mainFunctions.featuresGlobals[8])
		Elseif option == iStupid
			ValStupid = !ValStupid
			SetToggleOptionValue(iStupid, ValStupid)
			ToggleButton(mainFunctions.featuresGlobals[13])
		ElseIf option == iAffinity
			ValAffinity = !ValAffinity
			SetToggleOptionValue(iAffinity, ValAffinity)
			ToggleButton(mainFunctions.featuresGlobals[9])
		ElseIf option == iHappiness
			ValHappiness = !ValHappiness
			SetToggleOptionValue(iHappiness, ValHappiness)
			ToggleButton(mainFunctions.featuresGlobals[10])
			mainFunctions.triggerNeeds()
		ElseIf option == iHunger
			ValHunger = !ValHunger
			SetToggleOptionValue(iHunger, ValHunger)
			ToggleButton(mainFunctions.featuresGlobals[11])
			mainFunctions.triggerNeeds()
		EndIf

	ElseIf CurrentPage == "Configuration"

		If option == iInns
			ValInns = !ValInns
			SetToggleOptionValue(iInns, ValInns)
			ToggleButton(mainFunctions.settingsGlobals[3])
		ElseIf option == iStores
			ValStores = !ValStores
			SetToggleOptionValue(iStores, ValStores)
			ToggleButton(mainFunctions.settingsGlobals[4])
		ElseIf option == iHomes
			ValHomes = !ValHomes
			SetToggleOptionValue(iHomes, ValHomes)
			ToggleButton(mainFunctions.settingsGlobals[5])
		ElseIf option == iTowns
			ValTowns = !ValTowns
			SetToggleOptionValue(iTowns, ValTowns)
			ToggleButton(mainFunctions.settingsGlobals[6])
		EndIf

	ElseIf CurrentPage == "Dogs" || CurrentPage == "Tracking"

		Actor dogRef = ADLFormCurrentDogs.GetAt(indexDogs) as Actor
		Int dogIdentifier = mainFunctions.getDog(dogRef).GetID()

		If option == iTracking
			ValTracking[dogIdentifier] = !ValTracking[dogIdentifier]
			SetToggleOptionValue(iTracking, ValTracking[dogIdentifier])
			TrackDogs(dogRef, ValTracking[dogIdentifier])
		EndIf

	ElseIf CurrentPage == "Guide"

		If option == gAdoption
			ShowMessage("Gánate la confianza de los perros callejeros acariciándolos y alimentándolos. Esto aumentará su Afinidad hacia ti y te permitirá adoptarlos como tuyos.", false, "Cerrar")
		ElseIf option == gDiscovery
			ShowMessage("Descubre nuevos perros callejeros por todo Skyrim y lleva la cuenta de los que encuentres en el menú de Seguimiento.", false, "Cerrar")
		ElseIf option == gBreeders
			ShowMessage("Compra perros nuevos a los criadores de perros y a otros comerciantes de Skyrim. Algunas ubicaciones incluyen Markarth, el Fuerte Guardia del Alba y Falkreath.", false, "Cerrar")
		ElseIf option == gAffinity
			ShowMessage("La Afinidad representa la disposición de un perro hacia ti. Cuanto más interactúes con él, más podrá aumentar o disminuir su afinidad, según las acciones que realices.", false, "Cerrar")
		ElseIf option == gMerchants
			ShowMessage("Los criadores de perros también venden una colección de objetos, como camas y arneses para perros, que aumentan las estadísticas de tu perro y decoran el hogar de tu mascota.", false, "Cerrar")
		ElseIf option == gInventory
			ShowMessage("Los perros solo tienen una cantidad limitada de almacenamiento. Puedes aumentarla comprando y fabricando arneses para ellos.", false, "Cerrar")
		ElseIf option == gCrafting
			ShowMessage("Fabrica objetos comunes para perros, como camas, arneses y otros artículos, en la forja y el bastidor de curtido.", false, "Cerrar")
		ElseIf option == gHomes
			ShowMessage("Asigna hogares a tus perros mediante el diálogo. Cuando los despidas o los dejes esperando demasiado tiempo, volverán a casa.", false, "Cerrar")
		ElseIf option == gPetting
			ShowMessage("Acaricia a los perros callejeros para intentar ganarte su confianza, pero ten cuidado: podrían atacarte.", false, "Cerrar")
		ElseIf option == gHappiness
			ShowMessage("La felicidad de tus perros disminuirá poco a poco a menos que les sigas mostrando cariño con caricias regulares, comida o jugando con ellos.", false, "Cerrar")
		ElseIf option == gNeeds
			ShowMessage("El sistema de Necesidades añade dificultad adicional al cuidado de un perro. Necesitarán comida y cariño para evitar que se escapen o incluso mueran.", false, "Cerrar")
		ElseIf option == gHunger
			ShowMessage("Tus perros pasarán hambre con el tiempo, por lo que tendrás que alimentarlos. No hacerlo puede provocar que tu perro se escape o muera de hambre.", false, "Cerrar")
		ElseIf option == gCommands
			ShowMessage("Utiliza las órdenes para dirigir a tus perros y que realicen acciones todos a la vez.", false, "Cerrar")
		ElseIf option == gFetch
			ShowMessage("Ordena a tus perros buscar objetos cercanos que quizás tú no habrías podido olfatear.", false, "Cerrar")
		ElseIf option == gNames
			ShowMessage("Al adoptar o comprar perros, puedes darles un nombre único. Algunos perros pueden venir ya con nombre.", false, "Cerrar")
		ElseIf option == gTracking
			ShowMessage("Rastrea a tus perros en la pestaña Misiones del menú para no perder nunca a tu peludo amigo.", false, "Cerrar")
		ElseIf option == gRecall
			ShowMessage("La habilidad de llamado permite obligar a los perros que te siguen a volver a tu ubicación actual. También puede realizarse automáticamente si los perros se pierden y quedan fuera de tu línea de visión.", false, "Cerrar")
		ElseIf option == gAbandonment
			ShowMessage("Abandona a tu perro mediante el diálogo y se irá corriendo, llegando incluso a atacarte antes de marcharse. Esto reducirá la Afinidad a su valor más bajo.", false, "Cerrar")
		ElseIf option == gDiseases
			ShowMessage("Los callejeros pueden transmitirte una enfermedad si te arañan.", false, "Cerrar")
		ElseIf option == gRunaways
			ShowMessage("Si los perros son maltratados o sufren inanición por falta de comida, es posible que se escapen. Esto reducirá la Afinidad a su valor más bajo.", false, "Cerrar")
		EndIf

	ElseIf CurrentPage == "Maintenance"

		If Option == iLogs
			ValLogs = !ValLogs
			SetToggleOptionValue(iLogs, ValLogs)
			ToggleButton(mainFunctions.settingsGlobals[12])
		ElseIf Option == iDebug
			ValDebug = !ValDebug
			SetToggleOptionValue(iDebug, ValDebug)
			ToggleButton(mainFunctions.settingsGlobals[13])
		ElseIf Option == iDismissDogs
			ShowMessage("Se están despidiendo a todos los perros. Sal del MCM, por favor.", "")
			Int iCount = ADLFormCurrentDogs.GetSize()
			While iCount > 0
				iCount-=1
				Actor nextDog = ADLFormCurrentDogs.GetAt(iCount) as Actor
				dogFunctions.dogDismiss(nextDog)
			EndWhile
		ElseIf Option == iStop
			ValStop = !ValStop
			If ValStop
				ShowMessage("El mod se está deteniendo, sal del MCM, por favor.", False)
				dogQuests[0].Stop()
			Else
				ShowMessage("El mod se está reiniciando, sal del MCM, por favor.", False)
				dogQuests[0].Start()
			EndIf
		EndIf

	EndIf

EndEvent


Event OnOptionSliderOpen(Int SliderOption)

	If SliderOption == iInventoryCap
		SetSliderDialogStartValue(fInventoryCap)
		SetSliderDialogDefaultValue(150.0)
		SetSliderDialogRange(50.0, 500.0)
		SetSliderDialogInterval(50.0)
	ElseIf SliderOption == iCost
		SetSliderDialogStartValue(fCost)
		SetSliderDialogDefaultValue(500.0)
		SetSliderDialogRange(100.0, 2000.0)
		SetSliderDialogInterval(50.0)
	ElseIf SliderOption == iWait
		SetSliderDialogStartValue(fWait)
		SetSliderDialogDefaultValue(72.0)
		SetSliderDialogRange(12.0, 168.0)
		SetSliderDialogInterval(12.0)
	ElseIf SliderOption == iRunaway
		SetSliderDialogStartValue(fRunaway)
		SetSliderDialogDefaultValue(30.0)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogInterval(10.0)
	ElseIf SliderOption == iAffinityChance
		SetSliderDialogStartValue(fAffinityChance)
		SetSliderDialogDefaultValue(30.0)
		SetSliderDialogRange(10.0, 100.0)
		SetSliderDialogInterval(10.0)
	ElseIf SliderOption == iHappinessRate
		SetSliderDialogStartValue(fHappinessRate)
		SetSliderDialogDefaultValue(10)
		SetSliderDialogRange(1, 20)
		SetSliderDialogInterval(1)
	ElseIf SliderOption == iHungerRate
		SetSliderDialogStartValue(fHungerRate)
		SetSliderDialogDefaultValue(10)
		SetSliderDialogRange(1, 20)
		SetSliderDialogInterval(1)
	ElseIf SliderOption == iCheckRate
		SetSliderDialogStartValue(fCheckRate)
		SetSliderDialogDefaultValue(4)
		SetSliderDialogRange(2, 24)
	EndIf

EndEvent


Event OnOptionSliderAccept(Int aOption, Float aValue)

	menuSounds[0].Play(PlayerREF)

	If aOption == iInventoryCap
		fInventoryCap = aValue
		SetSliderOptionValue(aOption, aValue, "{0} lbs")
		mainFunctions.settingsGlobals[1].Value = (aValue as Int)
	ElseIf aOption == iCost
		fCost = aValue
		SetSliderOptionValue(aOption, aValue, "{0} septims")
		mainFunctions.settingsGlobals[2].Value = (aValue as Int)
		dogQuests[1].UpdateCurrentInstanceGlobal(mainFunctions.settingsGlobals[2])
	ElseIf aOption == iWait
		fWait = aValue
		SetSliderOptionValue(aOption, aValue, "{0} Hours")
		mainFunctions.settingsGlobals[0].Value = (aValue as Int)
	ElseIf aOption == iRunaway
		fRunaway = aValue
		SetSliderOptionValue(aOption, aValue, "{0}%")
		mainFunctions.settingsGlobals[11].Value = (aValue as Int)
	ElseIf aOption == iAffinityChance
		fAffinityChance = aValue
		SetSliderOptionValue(aOption, aValue, "{0}%")
		mainFunctions.settingsGlobals[7].Value = (aValue as Int)
	ElseIf aOption == iHappinessRate
		fHappinessRate = aValue
		SetSliderOptionValue(aOption, aValue, "{0}%")
		mainFunctions.settingsGlobals[8].Value = (aValue as Int)
	ElseIf aOption == iHungerRate
		fHungerRate = aValue
		SetSliderOptionValue(aOption, aValue, "{0}%")
		mainFunctions.settingsGlobals[9].Value = (aValue as Int)
	ElseIf aOption == iCheckRate
		fCheckrate = aValue
		SetSliderOptionValue(aOption, aValue, "{0} Hours")
		mainFunctions.settingsGlobals[10].Value = (aValue as Int)
	EndIf

EndEvent


Event OnOptionMenuOpen(Int aOption)

	If aOption == iRecall

		SetMenuDialogStartIndex(indexRecall)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(sRecall)

	ElseIf aOption == iDogSelect

		Int iCount = 0
		While iCount < ADLFormCurrentDogs.GetSize()+1
			sDogs[iCount] = (ADLFormCurrentDogs.GetAt(iCount) as Actor).GetBaseObject().GetName()
			iCount += 1
		EndWhile

		SetMenuDialogStartIndex(indexDogs)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(sDogs)

	ElseIf aOption == iSkinDog

		Actor dogRef = ADLFormCurrentDogs.GetAt(indexDogs) as Actor
		Int dogIdentifier = mainFunctions.getDog(dogRef).GetID()
		Int skinIdentifier = mainFunctions.getSkin(dogRef)

		SetMenuDialogStartIndex(skinIdentifier)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(currentSkins)

	ElseIf aOption == iRace

		Actor dogRef = ADLFormCurrentDogs.GetAt(indexDogs) as Actor
		Int dogIdentifier = mainFunctions.getDog(dogRef).GetID()
		Int raceIdentifier = mainFunctions.fetchRace(dogRef)

		SetMenuDialogStartIndex(raceIdentifier)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(sRaces)

	EndIf

EndEvent


Event OnOptionMenuAccept(Int aOption, Int aIndex)

	Actor ThePlayer = GetPlayer() as Actor

	menuSounds[0].Play(PlayerREF)

	If (aOption == iRecall)
		indexRecall = aIndex
		SetMenuOptionValue(aOption, sRecall[indexRecall])
		If indexRecall == 0 ; Disabled
			ThePlayer.RemoveSpell(dogSpells[3])
			mainFunctions.featuresGlobals[6].Value = 0
		ElseIf indexRecall == 1 ; Manual
			ThePlayer.AddSpell(dogSpells[3])
			mainFunctions.featuresGlobals[6].Value = 1
			menuSounds[3].Play(PlayerREF)
		ElseIf indexRecall == 2 ; Automatic
			ThePlayer.RemoveSpell(dogSpells[3])
			mainFunctions.featuresGlobals[6].Value = 2
		ElseIf indexRecall == 3 ; Hybrid
			ThePlayer.AddSpell(dogSpells[3])
			mainFunctions.featuresGlobals[6].Value = 3
			menuSounds[3].Play(PlayerREF)
		EndIf
	EndIf

	If (aOption == iDogSelect)
		indexDogs = aIndex
		SetMenuOptionValue(aOption, sDogs[indexDogs])
		ForcePageReset()
	EndIf

	If (aOption == iSkinDog)

		Actor dogRef = ADLFormCurrentDogs.GetAt(indexDogs) as Actor
		Int dogIdentifier = mainFunctions.getDog(dogRef).GetID()
		ADLDogAlias dogValues = mainFunctions.getAliasScript(dogRef) as ADLDogAlias

		indexDogSkins = aIndex
		SetMenuOptionValue(aOption, currentSkins[indexDogSkins])
		mainFunctions.removeSkin(dogRef)
		dogRef.EquipItem(dogSkins.GetAt(indexDogSkins), False, True)
		dogValues.currentSkin = (dogSkins.GetAt(indexDogSkins) as Armor)

	ElseIf (aOption == iRace)

		Actor dogRef = ADLFormCurrentDogs.GetAt(indexDogs) as Actor
		Int dogIdentifier = mainFunctions.getDog(dogRef).GetID()
		ADLDogAlias dogValues = mainFunctions.getAliasScript(dogRef) as ADLDogAlias

		iIndexRaces = aIndex
		SetMenuOptionValue(aOption, sRaces[iIndexRaces])
		mainFunctions.removeSkin(dogRef)
		dogValues.currentSkin = (mainFunctions.ADLFormDefaultSkins.GetAt(iIndexRaces) as Armor)
		dogRef.SetRace(mainFunctions.ADLFormRaces.GetAt(iIndexRaces) as Race)
		;dogRef.EquipItem(mainFunctions.ADLFormDefaultSkins.GetAt(iIndexRaces), false, true)
		ForcePageReset()

	EndIf

EndEvent


Event OnOptionDefault(Int Option)

	Actor thePlayer = GetPlayer()

	menuSounds[0].Play(PlayerREF)

	If currentPage == "Features"

		If option == iTutorials
			ValTutorials = True
			SetToggleOptionValue(iTutorials, ValTutorials)
			mainFunctions.featuresGlobals[0].Value = 1
		ElseIf option == iNotify
			ValNotify = False
			SetToggleOptionValue(iNotify, ValNotify)
			mainFunctions.featuresGlobals[1].Value = 0
		ElseIf option == iInventory
			ValInventory = False
			SetToggleOptionValue(iInventory, ValInventory)
			mainFunctions.featuresGlobals[2].Value = 0
		ElseIf option == iNames
			ValNames = False
			SetToggleOptionValue(iNames, ValNames)
			mainFunctions.featuresGlobals[4].Value = 0
		ElseIf option == iTeleport
			ValTeleport = False
			SetToggleOptionValue(iTeleport, ValTeleport)
			mainFunctions.featuresGlobals[5].Value = 0
			GetPlayer().RemoveSpell(dogSpells[4])
		ElseIf option == iCrafting
			ValCrafting = True
			SetToggleOptionValue(iCrafting, ValCrafting)
			mainFunctions.featuresGlobals[12].Value = 1
		ElseIf option == iCommands
			ValCommands = False
			SetToggleOptionValue(iCommands, ValCommands)
			mainFunctions.featuresGlobals[7].Value = 0
			thePlayer.RemoveSpell(dogSpells[0])
			thePlayer.RemoveSpell(dogSpells[1])
			thePlayer.RemoveSpell(dogSpells[2])
		ElseIf option == iAnimations
			ValAnimations = True
			SetToggleOptionValue(iAnimations, ValAnimations)
			mainFunctions.featuresGlobals[8].Value = 1
		ElseIf option == iStupid
			ValStupid = True
			SetToggleOptionValue(iStupid, ValStupid)
			mainFunctions.featuresGlobals[13].Value = 1
		ElseIf option == iAffinity
			ValAffinity = True
			SetToggleOptionValue(iAffinity, ValAffinity)
			mainFunctions.featuresGlobals[9].Value = 1
		ElseIf option == iHappiness
			ValHappiness = False
			SetToggleOptionValue(iHappiness, ValHappiness)
			mainFunctions.featuresGlobals[10].Value = 0
		ElseIf option == iHunger
			ValHunger = False
			SetToggleOptionValue(iHunger, ValHunger)
			mainFunctions.featuresGlobals[11].Value = 0
		EndIf

	ElseIf currentPage == "Configuration"

		If option == iInns
			ValInns = True
			SetToggleOptionValue(iInns, ValInns)
			mainFunctions.settingsGlobals[3].Value = 1
		ElseIf option == iStores
			ValStores = False
			SetToggleOptionValue(iStores, ValStores)
			mainFunctions.settingsGlobals[4].Value = 0
		ElseIf option == iHomes
			ValHomes = True
			SetToggleOptionValue(iHomes, ValHomes)
			mainFunctions.settingsGlobals[5].Value = 1
		ElseIf option == iTowns
			ValTowns = False
			SetToggleOptionValue(iTowns, ValTowns)
			mainFunctions.settingsGlobals[6].Value = 0
		EndIf

	ElseIf CurrentPage == "Dogs" || CurrentPage == "Tracking"

		Actor dogRef = ADLFormCurrentDogs.GetAt(indexDogs) as Actor
		Int dogIdentifier = mainFunctions.getDog(dogRef).GetID()

		If option == iTracking
			ValTracking[dogIdentifier] = False
			SetToggleOptionValue(iTracking, ValTracking[dogIdentifier])
			TrackDogs(dogRef, ValTracking[dogIdentifier])
		EndIf

	ElseIf CurrentPage == "Maintenance"

		If Option == iLogs
			ValLogs = False
			SetToggleOptionValue(iLogs, ValLogs)
			mainFunctions.settingsGlobals[12].Value = 0
		ElseIf Option == iDebug
			ValDebug = False
			SetToggleOptionValue(iDebug, ValDebug)
			mainFunctions.settingsGlobals[13].Value = 0
		EndIf

	EndIf

EndEvent


Event OnOptionHighlight(Int Option)

	If currentPage == "Features"

		If option == iTutorials
			SetInfoText("Muestra mensajes de tutorial con información adicional sobre las nuevas mecánicas de juego.")
		ElseIf option == iNotify
			SetInfoText("Muestra notificaciones al dar órdenes a tus perros.")
		ElseIf option == iInventory
			SetInfoText("Muestra la capacidad de inventario actual de tu perro mientras comercias con él.")
		ElseIf option == iNames
			SetInfoText("Renombra a tus perros hablando con ellos sobre su nombre. Los perros recién comprados o adoptados tendrán inicialmente esta opción independientemente de este ajuste.")
		ElseIf option == iTeleport
			SetInfoText("Usa el hechizo Teletransporta a Casa para enviar a los perros a casa en cualquier momento.")
		Elseif option == iCrafting
			SetInfoText("Aparecerán opciones de fabricación en las estaciones de trabajo para diversos objetos relacionados con los perros.")
		ElseIf option == iRecall
			SetInfoText("Los perros lejanos que queden fuera de tu vista volverán a ti automáticamente o mediante una nueva habilidad de voz.")
		ElseIf option == iCommands
			SetInfoText("Añade una colección de hechizos de órdenes activados por voz que te permiten dirigir a varios perros a la vez.")
		ElseIf option == iAnimations
			SetInfoText("Tanto el jugador como los perros realizarán animaciones breves en determinadas situaciones.")
		ElseIf option == iStupid
			SetInfoText("Cuando está activado, permite que se diga el diálogo de perro estúpido. Si lo desactivas, impedirás que los PNJ se metan con tu perro.")
		ElseIf option == iAffinity
			SetInfoText("La Afinidad representa la disposición de un perro hacia ti. Cuanto más interactúes con él, más podrá aumentar o disminuir su afinidad.")
		ElseIf option == iHappiness
			SetInfoText("La felicidad de tu perro disminuirá poco a poco a menos que le sigas mostrando cariño con caricias regulares, golosinas o jugando con él.")
		ElseIf option == iHunger
			SetInfoText("Tus perros pasarán hambre con el tiempo, por lo que tendrás que alimentarlos. No hacerlo puede provocar que tu perro se escape o muera de hambre.")
		EndIf

	ElseIf currentPage == "Configuration"

		If option == iInventoryCap
			SetInfoText("Establece el peso máximo que los perros pueden llevar en su inventario.")
		ElseIf option == iCost
			SetInfoText("Establece el costo de compra de los perros a los criadores.")
		ElseIf option == iWait
			SetInfoText("Establece cuánto tiempo esperarán los perros antes de volver a casa.")
		ElseIf option == iRunaway
			SetInfoText("La probabilidad de que tus perros se escapen si son maltratados. Esto incluye la inanición o el abuso físico.")
		ElseIf option == iInns
			SetInfoText("Permite que los perros descansen y deambulen por las tabernas mientras te siguen.")
		ElseIf option == iStores
			SetInfoText("Permite que los perros descansen y deambulen por las tiendas mientras te siguen.")
		ElseIf option == iHomes
			SetInfoText("Permite que los perros descansen y deambulen por casa mientras te siguen.")
		ElseIf option == iTowns
			SetInfoText("Permite que los perros descansen y deambulen por los pueblos mientras te siguen.")
		ElseIf option == iAffinityChance
			SetInfoText("La probabilidad de que los perros ganen o pierdan afinidad contigo al realizar diversas acciones.")
		ElseIf option == iHappinessRate
			SetInfoText("El ritmo al que baja la felicidad. El ritmo de felicidad va de 0 a 100. Al llegar a cero se producen fugas o muerte por tristeza.")
		ElseIf option == iHungerRate
			SetInfoText("El ritmo al que baja el hambre. El ritmo de hambre va de 0 a 100. Al llegar a cero se produce la muerte por inanición.")
		ElseIf option == iCheckRate
			SetInfoText("Cuánto tiempo, en horas de juego, transcurre antes de cada actualización de Necesidades para el Hambre y la Felicidad, reduciendo el ritmo en las cantidades especificadas.")
		EndIf

	ElseIf currentPage == "Dogs" || CurrentPage == "Tracking"

		If option == iTracking
			SetInfoText("Rastrea a tus perros en el mapa mediante una misión de la categoría Variados añadida a tu diario.")
		ElseIf iDogSelect
			SetInfoText("Selecciona el perro cuyo estado quieras ver y modificar.")
		ElseIf option == iSkinDog
			SetInfoText("Selecciona la piel que quieras aplicar a tu perro.")
		ElseIf option == iRace
			SetInfoText("Selecciona la raza a la que quieras cambiar a tu perro.")
		EndIf

	ElseIf CurrentPage == "Maintenance"

		If option == iDebug
			SetInfoText("Muestra notificaciones de depuración en pantalla cuando se realizan acciones clave.")
		Elseif option == iLogs
			SetInfoText("Imprime registros de depuración en los registros de Papyrus cuando se realizan acciones clave.")
		ElseIf Option == iStop && ValStop
			SetInfoText("Reinicia las misiones del mod para volver a ponerlo en marcha.")
		ElseIf Option == iStop
			SetInfoText("ADVERTENCIA: usa esta opción si planeas desinstalar el mod, para dar de baja las actualizaciones de los scripts.")
		EndIf

	EndIf

EndEvent


;====================
;Main Functions
;====================

Function DisplayState(Actor dogRef, String dogName, String dogLocation, String dogHome)

	Float dogValue = dogRef.GetActorValue("WaitingforPlayer")
	String dogState

	If dogValue == 0
		dogState = "Siguiéndote"
		AddTextOption("Following", "")
	ElseIf dogValue == 1
		dogState = "Esperando"
		AddTextOption("Esperando en " + dogLocation, "")
	ElseIf dogValue == 2
		dogState = "en casa"
		If dogHome == ""
			AddTextOption("Descansando en casa", "")
		Else
			AddTextOption("Descansando en " + dogHome, "")
		EndIf
	ElseIf dogValue >= 3
		dogState = "ocupado"
		AddTextOption("Haciendo un favor", "")
	EndIf

EndFunction


Function ToggleButton(GlobalVariable toggleGlobal)

	If ToggleGlobal.Value == 0
		ToggleGlobal.SetValue(1)
	Else
		ToggleGlobal.SetValue(0)
	EndIf

EndFunction


Function TrackDogs(Actor dogRef, Bool toggleInt)

	Int dogIdentifier = mainFunctions.getDog(dogRef).GetID()

	If toggleInt == False
		toggleInt = False
		dogQuests[0].SetObjectiveDisplayed(dogIdentifier, False)
	Else
		toggleInt = True
		dogQuests[0].SetObjectiveDisplayed(dogIdentifier)
	EndIf

EndFunction