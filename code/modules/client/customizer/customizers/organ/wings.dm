/obj/item/organ/wings
	name = "wings"
	desc = "A pair of wings. Those may or may not allow you to fly... or at the very least flap."
	visible_organ = TRUE
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_WINGS
	///What species get flights thanks to those wings. Important for moth wings
	var/list/flight_for_species
	///Whether a wing can be opened by the *wing emote. The sprite use a "_open" suffix, before their layer
	var/can_open
	///Whether an openable wing is currently opened
	var/is_open
	///Whether the owner of wings has flight thanks to the wings
	var/granted_flight

/obj/item/organ/wings/flight
	actions_types = list(/datum/action/item_action/organ_action/use/flight)

/datum/customizer/organ/wings
	name = "Wings"
	abstract_type = /datum/customizer/organ/wings

/datum/customizer_choice/organ/wings
	name = "Wings"
	organ_type = /obj/item/organ/wings
	organ_slot = ORGAN_SLOT_WINGS
	abstract_type = /datum/customizer_choice/organ/wings

/obj/item/organ/wings/anthro
	name = "wild-kin wings"

/obj/item/organ/wings/flight/night_kin
	name = "Vampire Wings"
	accessory_type = /datum/sprite_accessory/wings/large/gargoyle

/datum/customizer/organ/wings/harpy
	customizer_choices = list(/datum/customizer_choice/organ/wings/harpy)
	allows_disabling = FALSE

/datum/customizer_choice/organ/wings/harpy
	name = "Wings"
	organ_type = /obj/item/organ/wings/flight
	allows_accessory_color_customization = FALSE
	sprite_accessories = list(
		/datum/sprite_accessory/wings/large/harpyswept,
	)

/obj/effect/flyer_shadow
	name = ""
	desc = "A shadow cast from something flying above."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shadow"
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	alpha = 180
	var/datum/weakref/flying_ref

/obj/effect/flyer_shadow/Initialize(mapload, flying_mob)
	. = ..()
	if(flying_mob)
		flying_ref = WEAKREF(flying_mob)
	transform = matrix() * 0.75 // Make the shadow slightly smaller
	add_filter("shadow_blur", 1, gauss_blur_filter(1))

/obj/effect/flyer_shadow/Destroy()
	flying_ref = null
	return ..()

/obj/effect/flyer_shadow/attackby(obj/item/I, mob/user, params)
	var/mob/living/flying_mob = flying_ref.resolve()
	if(QDELETED(flying_mob))
		return

	if(flying_mob.z == user.z || !I.is_pointy_weapon())
		return

	user.visible_message(
		span_warning("[user] prepares to thrust [I] upward at [flying_mob]!"),
		span_warning("You prepare to thrust [I] upward at [flying_mob]!")
	)

	if(do_after(user, 3 SECONDS, src))
		I = user.get_active_held_item()
		if(!I?.is_pointy_weapon() || !flying_mob)
			return

		var/attack_damage = I.force

		user.visible_message(
			span_warning("[user] thrusts [I] upward, striking [flying_mob]!"),
			span_warning("You thrust [I] upward, striking [flying_mob]!")
		)

		flying_mob.apply_damage(attack_damage, BRUTE)

		if(prob(attack_damage * 1.5 && (flying_mob.movement_type & FLYING)))
			to_chat(flying_mob, span_userdanger("The attack knocks you out of the air!"))
			flying_mob.Knockdown(3 SECONDS)
		return TRUE

/obj/item/proc/is_pointy_weapon()
	return (reach >= 2) && (sharpness == IS_SHARP || w_class >= WEIGHT_CLASS_NORMAL)

/datum/action/item_action/organ_action/use/flight
	name = "Toggle Flying"
	desc = "Take to the skies or return to the ground."
	button_icon_state = "flight"

	var/flying = FALSE
	var/obj/effect/flyer_shadow/shadow

/datum/action/item_action/organ_action/use/flight/Destroy()
	if(shadow)
		QDEL_NULL(shadow)
	return ..()

/datum/action/item_action/organ_action/use/flight/do_effect(trigger_flags)
	. = ..()
	if(trigger_flags & TRIGGER_SECONDARY_ACTION)
		to_chat(owner, "I am currently [flying ? "" : "not"] flying.")
		return
	if(!flying)
		if(!can_fly())
			return
		if(do_after(owner, 5 SECONDS, owner))
			start_flying()
		return
	if(do_after(owner, 5 SECONDS, owner))
		stop_flying()

/datum/action/item_action/organ_action/use/flight/proc/can_fly()
	if(!isliving(owner))
		return FALSE
	var/mob/living/flier = owner
	if(flier.get_encumbrance() > 0.7)
		to_chat(owner, span_warning("I am too heavy!"))
		return FALSE
	if(!isturf(flier.loc))
		to_chat(flier, span_warning("I need space to fly!"))
		return FALSE
	if(flier.body_position != STANDING_UP)
		to_chat(flier, span_warning("I can't spread my wings!"))
		return FALSE
	if(IS_DEAD_OR_INCAP(flier))
		return FALSE

	return TRUE

// Start flying normally
/datum/action/item_action/organ_action/use/flight/proc/start_flying()
	var/turf/turf = get_turf(owner)
	if(owner.can_zTravel(direction = UP))
		if(isopenspace(GET_TURF_ABOVE(turf)))
			turf = GET_TURF_ABOVE(turf)
	owner.movement_type |= FLYING
	flying = TRUE
	to_chat(owner, span_notice("I start flying."))
	if(turf != get_turf(owner))
		var/matrix/original = owner.transform
		var/prev_alpha = owner.alpha
		var/prev_pixel_z = owner.pixel_z
		animate(owner, pixel_z = 156, alpha = 0, time = 1.5 SECONDS, easing = EASE_IN, flags = ANIMATION_PARALLEL|ANIMATION_RELATIVE)
		animate(owner, transform = matrix() * 6, time = 1 SECONDS, easing = EASE_IN, flags = ANIMATION_PARALLEL)
		animate(transform = original, time = 0.5 SECONDS, EASE_OUT)
		owner.pixel_z = prev_pixel_z
		owner.alpha = prev_alpha
		owner.forceMove(turf)

		var/turf/below_turf = GET_TURF_BELOW(turf)
		shadow = new /obj/effect/flyer_shadow(below_turf, owner)

	init_signals()

/datum/action/item_action/organ_action/use/flight/proc/init_signals()
	if(shadow)
		RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(cleanup_shadow))

	RegisterSignal(owner, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(check_damage))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_movement))
	RegisterSignal(owner, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(check_laying))

	RegisterSignal(owner, list(
		SIGNAL_ADDTRAIT(TRAIT_IMMOBILIZED),
		SIGNAL_ADDTRAIT(TRAIT_KNOCKEDOUT),
		SIGNAL_ADDTRAIT(TRAIT_FLOORED),
	), PROC_REF(fall))

// Stop flying normally
/datum/action/item_action/organ_action/use/flight/proc/stop_flying()
	var/turf/turf = get_turf(owner)
	if(isopenspace(turf))
		if(owner.can_zTravel(direction = DOWN))
			turf = GET_TURF_BELOW(turf)
	to_chat(owner, span_notice("I stop flying."))
	if(turf != get_turf(owner))
		var/matrix/original = owner.transform
		var/prev_alpha = owner.alpha
		var/prev_pixel_z = owner.pixel_z
		owner.alpha = 0
		owner.pixel_z = 156
		owner.transform = matrix() * 8
		owner.forceMove(turf)
		animate(owner, pixel_z = prev_pixel_z, alpha = prev_alpha, time = 1.2 SECONDS, easing = EASE_IN, flags = ANIMATION_PARALLEL)
		animate(owner, transform = original, time = 1.2 SECONDS, easing = EASE_IN, flags = ANIMATION_PARALLEL)

	remove_signals()

/datum/action/item_action/organ_action/use/flight/proc/remove_signals()
	owner.movement_type &= ~FLYING
	flying = FALSE

	// The fact we have to do this is awful
	var/turf/open = get_turf(owner)
	if(isopenspace(open))
		open.zFall(owner)

	UnregisterSignal(owner, list(
		COMSIG_PARENT_QDELETING,
		COMSIG_ATOM_WAS_ATTACKED,
		COMSIG_MOVABLE_MOVED,
		COMSIG_LIVING_SET_BODY_POSITION,
		SIGNAL_ADDTRAIT(TRAIT_IMMOBILIZED),
		SIGNAL_ADDTRAIT(TRAIT_KNOCKEDOUT),
		SIGNAL_ADDTRAIT(TRAIT_FLOORED),
	))

	if(shadow)
		QDEL_NULL(shadow)

// Fall out the sky like a brick, no animation
/datum/action/item_action/organ_action/use/flight/proc/fall(datum/source)
	SIGNAL_HANDLER

	remove_signals()

/datum/action/item_action/organ_action/use/flight/proc/check_damage(datum/source, mob/living/user, mob/living/attacker, damage)
	SIGNAL_HANDLER

	if(prob(damage))
		to_chat(owner, span_warning("The hit knocks you out of the air!"))
		fall()
		if(isliving(owner))
			var/mob/living/flier = owner
			flier.Knockdown(2 SECONDS)

/datum/action/item_action/organ_action/use/flight/proc/check_movement(datum/source)
	SIGNAL_HANDLER

	if(owner.movement_type & FLYING)
		if(!can_fly())
			stop_flying(owner)
			return

		if(!owner.adjust_stamina(-3))
			to_chat(owner, span_warning("You're too exhausted to keep flying!"))
			stop_flying(owner)
			return

		if(shadow)
			if(!istransparentturf(get_turf(owner)))
				shadow.alpha= 0
			else
				shadow.alpha = 255

			var/turf/below_turf = GET_TURF_BELOW(get_turf(owner))
			if(below_turf)
				shadow.forceMove(below_turf)
			return

		var/turf/below_turf = GET_TURF_BELOW(get_turf(owner))
		if(below_turf && istransparentturf(get_turf(owner)))
			shadow = new /obj/effect/flyer_shadow(below_turf, owner)
			RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(cleanup_shadow))

/datum/action/item_action/organ_action/use/flight/proc/check_laying(datum/source, new_pos, old_pos)
	SIGNAL_HANDLER

	if((old_pos == STANDING_UP ) && (old_pos == new_pos))
		return

	fall()

/datum/action/item_action/organ_action/use/flight/proc/cleanup_shadow(datum/source)
	SIGNAL_HANDLER

	if(shadow)
		QDEL_NULL(shadow)
