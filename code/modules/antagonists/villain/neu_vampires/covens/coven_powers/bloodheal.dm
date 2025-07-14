#define HEAL_BASHING_LETHAL 30
#define HEAL_AGGRAVATED 6

/datum/coven/bloodheal
	name = "Bloodheal"
	desc = "Use the power of your Vitae to mend your flesh."
	icon_state = "bloodheal"
	power_type = /datum/coven_power/bloodheal
	max_level = 10

/datum/coven_power/bloodheal
	name = "Bloodheal power name"
	desc = "Bloodheal power description"

	level = 1
	check_flags = COVEN_CHECK_TORPORED
	vitae_cost = 50

	violates_masquerade = FALSE

	cooldown_length = 1 TURNS

	grouped_powers = list(
		/datum/coven_power/bloodheal/one,
		/datum/coven_power/bloodheal/two,
		/datum/coven_power/bloodheal/three,
		/datum/coven_power/bloodheal/four,
		/datum/coven_power/bloodheal/five,
		/datum/coven_power/bloodheal/six,
		/datum/coven_power/bloodheal/seven,
		/datum/coven_power/bloodheal/eight,
		/datum/coven_power/bloodheal/nine,
		/datum/coven_power/bloodheal/ten
	)

/datum/coven_power/bloodheal/activate()
	adjust_vitae_cost()

	. = ..()

	//normal bashing/lethal damage
	owner.heal_ordered_damage(HEAL_BASHING_LETHAL * vitae_cost, list(BRUTE, TOX, OXY, STAMINA))

	if(length(owner.get_wounds()))
		for (var/i in 1 to min(vitae_cost, length(owner.get_wounds())))
			var/datum/wound/wound = owner.get_wounds()[i]
			wound.heal_wound(10000)

	//aggravated damage
	owner.heal_ordered_damage(HEAL_AGGRAVATED * vitae_cost, list(BURN, CLONE))

	//brain damage and traumas healing
	var/obj/item/organ/brain/brain = owner.getorganslot(ORGAN_SLOT_BRAIN)
	if (brain)
		brain.applyOrganDamage(-HEAL_BASHING_LETHAL * vitae_cost)

	//miscellaneous organ damage healing
	var/obj/item/organ/eyes/eyes = owner.getorganslot(ORGAN_SLOT_EYES)
	if (eyes)
		eyes.applyOrganDamage(-HEAL_BASHING_LETHAL * vitae_cost)

		owner.adjust_blindness(-HEAL_AGGRAVATED * vitae_cost)
		owner.adjust_blurriness(-HEAL_AGGRAVATED * vitae_cost)

	//healing too quickly attracts attention
	if (violates_masquerade)
		owner.visible_message(
			span_warning("[owner]'s wounds heal with unnatural speed!"),
			span_warning("Your wounds visibly heal with unnatural speed!")
		)

	//update UI
	owner.update_damage_overlays()
	owner.update_health_hud()

/datum/coven_power/bloodheal/can_activate_untargeted(alert)
	adjust_vitae_cost()

	. = ..()

/datum/coven_power/bloodheal/proc/adjust_vitae_cost()
	vitae_cost = initial(vitae_cost)
	//tally up damage
	var/total_bashing_lethal_damage = owner.getBruteLoss() + owner.getToxLoss() + owner.getOxyLoss()
	var/total_aggravated_damage = owner.getCloneLoss() + owner.getFireLoss()

	//lower blood expenditure to what's necessary
	var/vitae_to_heal_bashing_lethal = ceil(total_bashing_lethal_damage / HEAL_BASHING_LETHAL)
	var/vitae_to_heal_aggravated = ceil(total_aggravated_damage / HEAL_AGGRAVATED)

	var/vitae_needed = max(vitae_to_heal_bashing_lethal, vitae_to_heal_aggravated)

	//vitae used to heal is the smaller of max vitae expenditure and what's needed to heal the damage
	vitae_cost = max(min(vitae_cost, vitae_needed), 1)

	//healing is a masquerade breach if it's done at level 3 and above
	if (vitae_cost > 2)
		violates_masquerade = TRUE
	else
		violates_masquerade = FALSE

//BLOODHEAL 1
/datum/coven_power/bloodheal/one
	name = "Minor Bloodheal"
	desc = "Slowly mend your undead flesh."

	level = 1
	vitae_cost = 50

	violates_masquerade = FALSE

//BLOODHEAL 2
/datum/coven_power/bloodheal/two
	name = "Bloodheal"
	desc = "Mend your undead flesh."

	level = 2
	vitae_cost = 100

	violates_masquerade = FALSE

//BLOODHEAL 3
/datum/coven_power/bloodheal/three
	name = "Quick Bloodheal"
	desc = "Mend your undead flesh with unnatural speed."

	level = 3
	vitae_cost = 150

	violates_masquerade = TRUE

//BLOODHEAL 4
/datum/coven_power/bloodheal/four
	name = "Major Bloodheal"
	desc = "Heal even the most grievous wounds in short order."

	level = 4
	vitae_cost = 200

	violates_masquerade = TRUE

//BLOODHEAL 5
/datum/coven_power/bloodheal/five
	name = "Greater Bloodheal"
	desc = "Regrow entire bodyparts without breaking a sweat."

	level = 5
	vitae_cost = 250

	violates_masquerade = TRUE

//BLOODHEAL 6
/datum/coven_power/bloodheal/six
	name = "Grand Bloodheal"
	desc = "Regrow entire bodyparts without breaking a sweat."

	level = 6
	vitae_cost = 300

	violates_masquerade = TRUE

//BLOODHEAL 7
/datum/coven_power/bloodheal/seven
	name = "Grand Bloodheal"
	desc = "Reconstitute your body from near nothing."

	level = 7
	vitae_cost = 350

	violates_masquerade = TRUE

//BLOODHEAL 8
/datum/coven_power/bloodheal/eight
	name = "Godlike Bloodheal"
	desc = "On the edge of Final Death, let your blood explode outwards and recreate you."

	level = 8
	vitae_cost = 400

	violates_masquerade = TRUE

//BLOODHEAL 9
/datum/coven_power/bloodheal/nine
	name = "Surpassing Bloodheal"
	desc = "Even as a titanic beast, you could restore your physical form in short order."

	level = 9
	vitae_cost = 450

	violates_masquerade = TRUE

//BLOODHEAL 10
/datum/coven_power/bloodheal/ten
	name = "Ascended Bloodheal"
	desc = "So long as you have access to blood, you cannot die. Your curse will not allow it."

	level = 10
	vitae_cost = 500

	violates_masquerade = TRUE

#undef HEAL_BASHING_LETHAL
#undef HEAL_AGGRAVATED
