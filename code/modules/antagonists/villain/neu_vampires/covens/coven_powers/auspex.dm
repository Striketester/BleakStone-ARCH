/datum/coven/auspex
	name = "Auspex"
	desc = "Allows to see entities, auras and their health through walls."
	icon_state = "auspex"
	power_type = /datum/coven_power/auspex

/datum/coven_power/auspex
	name = "Auspex power name"
	desc = "Auspex power description"


//HEIGHTENED SENSES
/datum/coven_power/auspex/heightened_senses
	name = "Heightened Senses"
	desc = "Enhances your senses far past human limitations."

	level = 1
	check_flags = COVEN_CHECK_CONSCIOUS
	vitae_cost = 0

	toggled = TRUE

/datum/coven_power/auspex/heightened_senses/activate()
	. = ..()

	ADD_TRAIT(owner, TRAIT_THERMAL_VISION, TRAIT_GENERIC)

	owner.update_sight()

/datum/coven_power/auspex/heightened_senses/deactivate()
	. = ..()

	REMOVE_TRAIT(owner, TRAIT_THERMAL_VISION, TRAIT_GENERIC)

	owner.update_sight()
