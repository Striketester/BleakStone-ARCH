/datum/coven/demonic
	name = "Demonic"
	desc = "Get a help from the Hell creatures, resist THE FIRE, transform into an imp. Violates Masquerade."
	icon_state = "daimonion"
	clan_restricted = TRUE
	power_type = /datum/coven_power/demonic

/datum/coven_power/demonic
	name = "Daimonion power name"
	desc = "Daimonion power description"


//SENSE THE SIN
/datum/coven_power/demonic/sense_the_sin
	name = "Sense the Sin"
	desc = "Become supernaturally resistant to fire."

	level = 1

	cancelable = TRUE
	duration_length = 20 SECONDS
	cooldown_length = 10 SECONDS

/datum/coven_power/demonic/sense_the_sin/activate()
	. = ..()
	owner.physiology.burn_mod /= 100
	owner.color = "#884200"

/datum/coven_power/demonic/sense_the_sin/deactivate()
	. = ..()
	owner.color = initial(owner.color)
	owner.physiology.burn_mod *= 100

//FEAR OF THE VOID BELOW
/mob/living/carbon/human/proc/give_demon_flight()
	var/obj/item/organ/wings/old_wings = getorganslot(ORGAN_SLOT_WINGS)
	if(old_wings)
		return

	var/obj/item/organ/wings/flight/night_kin/demon_wings = new(get_turf(src))
	demon_wings.Insert(src)
	update_body()
	update_body_parts(TRUE)

/mob/living/carbon/human/proc/remove_demon_flight()
	var/obj/item/organ/wings/flight/night_kin/old_wings = getorganslot(ORGAN_SLOT_WINGS)
	if(!istype(old_wings))
		return
	old_wings.Remove(src)
	qdel(old_wings)
	update_body()
	update_body_parts(TRUE)

/datum/coven_power/demonic/fear_of_the_void_below
	name = "Fear of the Void Below"
	desc = "Sprout wings and become able to fly."

	level = 2
	check_flags = COVEN_CHECK_CONSCIOUS | COVEN_CHECK_CAPABLE | COVEN_CHECK_LYING | COVEN_CHECK_IMMOBILE

	violates_masquerade = TRUE

	cancelable = TRUE
	duration_length = 30 SECONDS
	cooldown_length = 20 SECONDS

/datum/coven_power/demonic/fear_of_the_void_below/activate()
	. = ..()
	owner.give_demon_flight()

/datum/coven_power/demonic/fear_of_the_void_below/deactivate()
	. = ..()
	owner.remove_demon_flight()

//CONFLAGRATION
/datum/coven_power/demonic/conflagration
	name = "Conflagration"
	desc = "Turn your hands into deadly claws."

	level = 3
	check_flags = COVEN_CHECK_CONSCIOUS | COVEN_CHECK_CAPABLE

	violates_masquerade = TRUE

	cancelable = TRUE
	duration_length = 30 SECONDS
	cooldown_length = 10 SECONDS

/datum/coven_power/demonic/conflagration/activate()
	. = ..()
	owner.drop_all_held_items()
	owner.put_in_r_hand(new /obj/item/weapon/arms/gangrel(owner))
	owner.put_in_l_hand(new /obj/item/weapon/arms/gangrel(owner))

/datum/coven_power/demonic/conflagration/deactivate()
	. = ..()
	for(var/obj/item/weapon/arms/gangrel/claws in owner)
		qdel(claws)

/datum/coven_power/demonic/conflagration/post_gain()
	. = ..()
	var/datum/action/cooldown/spell/projectile/fireball/baali/balefire = new(owner)
	balefire.Grant(owner)

/datum/action/cooldown/spell/projectile/fireball/baali
	name = "Infernal Fireball"
	desc = "This spell fires an explosive fireball at a target."
	school = "evocation"
	charge_time = 4 SECONDS
	invocation = "FR BRTH"
	invocation_type = "whisper"
	cooldown_time = 20 //10 deciseconds reduction per rank
	projectile_type = /obj/projectile/magic/aoe/fireball/rogue
	sound = 'sound/magic/fireball.ogg'

//PSYCHOMACHIA
/datum/coven_power/demonic/psychomachia
	name = "Psychomachia"
	desc = "Become a bat."

	level = 4
	check_flags = COVEN_CHECK_CONSCIOUS | COVEN_CHECK_CAPABLE | COVEN_CHECK_IMMOBILE | COVEN_CHECK_LYING

	violates_masquerade = TRUE

	duration_length = 30 SECONDS
	cooldown_length = 10 SECONDS
	grouped_powers = list(/datum/coven_power/demonic/condemnation)

	var/datum/action/cooldown/spell/undirected/shapeshift/bat/bat_shapeshift

/datum/coven_power/demonic/psychomachia/activate()
	. = ..()
	if(!bat_shapeshift)
		bat_shapeshift = new(owner)

	owner.drop_all_held_items()
	bat_shapeshift.do_shapeshift(owner)

/datum/coven_power/demonic/psychomachia/deactivate()
	. = ..()
	bat_shapeshift.restore_form(owner)
	owner.Stun(1.5 SECONDS)
	owner.do_jitter_animation(30)

//CONDEMNTATION
/datum/coven_power/demonic/condemnation
	name = "Condemnation"
	desc = "Become a bat."

	level = 5
	check_flags = COVEN_CHECK_CONSCIOUS | COVEN_CHECK_CAPABLE | COVEN_CHECK_IMMOBILE | COVEN_CHECK_LYING

	violates_masquerade = TRUE

	duration_length = 30 SECONDS
	cooldown_length = 10 SECONDS
	grouped_powers = list(/datum/coven_power/demonic/psychomachia)

	var/datum/action/cooldown/spell/undirected/shapeshift/bat/bat_shapeshift

/datum/coven_power/demonic/condemnation/activate()
	. = ..()
	if(!bat_shapeshift)
		bat_shapeshift = new(owner)

	owner.drop_all_held_items()
	bat_shapeshift.do_shapeshift(owner)

/datum/coven_power/demonic/condemnation/deactivate()
	. = ..()
	bat_shapeshift.restore_form(owner)
	owner.Stun(1.5 SECONDS)
	owner.do_jitter_animation(30)

/datum/coven_power/demonic/condemnation/post_gain()
	. = ..()
	var/datum/action/antifrenzy/antifrenzy_contract = new()
	antifrenzy_contract.Grant(owner)

/datum/action/antifrenzy
	name = "Resist Beast"
	desc = "Resist Frenzy and Rotshreck by signing a contract with Demons."
	button_icon_state = "resist"
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_LYING|AB_CHECK_CONSCIOUS
	var/used = FALSE

/datum/action/antifrenzy/Trigger(trigger_flags)
	var/mob/living/carbon/human/user = owner
	if(user.stat >= UNCONSCIOUS || user.IsSleeping() || user.IsUnconscious() || user.IsParalyzed() || user.IsKnockdown() || user.IsStun() || HAS_TRAIT(user, TRAIT_RESTRAINED) || !isturf(user.loc))
		return
	if(used)
		to_chat(owner, span_warning("You've already signed this contract!"))
		return
	used = TRUE
	user.antifrenzy = TRUE
	to_chat(owner, span_warning("You feel control over your Beast, but at what cost..."))
	qdel(src)
