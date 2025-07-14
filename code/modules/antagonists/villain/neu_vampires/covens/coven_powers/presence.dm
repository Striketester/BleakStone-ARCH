/datum/coven/presence
	name = "Presence"
	desc = "Makes targets in radius more vulnerable to damages."
	icon_state = "presence"
	power_type = /datum/coven_power/presence

/datum/coven_power/presence
	name = "Presence power name"
	desc = "Presence power description"

//AWE
/datum/coven_power/presence/awe
	name = "Awe"
	desc = "Make those around you admire and want to be closer to you."

	level = 1

	check_flags = COVEN_CHECK_CAPABLE | COVEN_CHECK_SPEAK
	target_type = TARGET_HUMAN
	range = 7

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	duration_length = 5 SECONDS

/datum/coven_power/presence/awe/pre_activation_checks(mob/living/target)
	var/mypower = owner.STAINT
	var/theirpower = owner.STAINT - 5
	if((theirpower >= mypower))
		to_chat(owner, span_warning("[target]'s mind is too powerful to sway!"))
		return FALSE

	return TRUE

/datum/coven_power/presence/awe/activate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)
	var/mutable_appearance/presence_overlay = mutable_appearance('icons/effects/clan.dmi', "presence", -MUTATIONS_LAYER)
	presence_overlay.pixel_z = 1
	target.overlays_standing[MUTATIONS_LAYER] = presence_overlay
	target.apply_overlay(MUTATIONS_LAYER)

	var/datum/cb = CALLBACK(target, /mob/living/carbon/human/proc/walk_to_caster, owner)
	for(var/i in 1 to 30)
		addtimer(cb, (i - 1) * target.total_multiplicative_slowdown())
	to_chat(target, "<span class='userlove'><b>COME HERE</b></span>")
	owner.say("COME HERE!!")

/datum/coven_power/presence/awe/deactivate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)

/mob/living/carbon/human/proc/walk_to_caster(mob/living/step_to)
	walk(src, 0)
	if(!CheckFrenzyMove())
		set_glide_size(DELAY_TO_GLIDE_SIZE(total_multiplicative_slowdown()))
		step_to(src, step_to, 0)
		face_atom(step_to)

//DREAD GAZE
/datum/coven_power/presence/dread_gaze
	name = "Dread Gaze"
	desc = "Incite fear in others through only your words and gaze."

	level = 2

	check_flags = COVEN_CHECK_CAPABLE | COVEN_CHECK_SPEAK
	target_type = TARGET_HUMAN
	range = 7

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	duration_length = 5 SECONDS

/datum/coven_power/presence/dread_gaze/pre_activation_checks(mob/living/target)
	var/mypower = owner.STAINT
	var/theirpower = owner.STAINT - 5
	if((theirpower >= mypower))
		to_chat(owner, span_warning("[target]'s mind is too powerful to sway!"))
		return FALSE

	return TRUE

/datum/coven_power/presence/dread_gaze/activate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)
	var/mutable_appearance/presence_overlay = mutable_appearance('icons/effects/clan.dmi', "presence", -MUTATIONS_LAYER)
	presence_overlay.pixel_z = 1
	target.overlays_standing[MUTATIONS_LAYER] = presence_overlay
	target.apply_overlay(MUTATIONS_LAYER)

	to_chat(target, "<span class='userlove'><b>FEAR ME</b></span>")
	owner.say("FEAR ME!!")
	var/datum/cb = CALLBACK(target, TYPE_PROC_REF(/mob/living/carbon/human, step_away_caster), owner)
	for(var/i in 1 to 30)
		addtimer(cb, (i - 1) * target.total_multiplicative_slowdown())
	target.emote("scream")
	target.do_jitter_animation(3 SECONDS)

/datum/coven_power/presence/dread_gaze/deactivate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)

/mob/living/carbon/human/proc/step_away_caster(mob/living/step_from)
	walk(src, 0)
	if(!CheckFrenzyMove())
		set_glide_size(DELAY_TO_GLIDE_SIZE(total_multiplicative_slowdown()))
		step_away(src, step_from, 99)

/datum/coven_power/presence/fall
	name = "Kneel"
	desc = "Make those kneel before you."

	level = 3

	check_flags = COVEN_CHECK_CAPABLE|COVEN_CHECK_SPEAK
	target_type = TARGET_HUMAN
	range = 7

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	duration_length = 5 SECONDS

/datum/coven_power/presence/fall/pre_activation_checks(mob/living/target)
	var/mypower = owner.STAINT
	var/theirpower = owner.STAINT - 5
	if((theirpower >= mypower))
		to_chat(owner, span_warning("[target]'s mind is too powerful to sway!"))
		return FALSE

	return TRUE

/datum/coven_power/presence/fall/activate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)
	var/mutable_appearance/presence_overlay = mutable_appearance('icons/effects/clan.dmi', "presence", -MUTATIONS_LAYER)
	presence_overlay.pixel_z = 1
	target.overlays_standing[MUTATIONS_LAYER] = presence_overlay
	target.apply_overlay(MUTATIONS_LAYER)

	target.Stun(1 SECONDS)
	to_chat(target, "<span class='userlove'><b>KNEEL</b></span>")
	owner.say("KNEEL!!")
	if(target.body_position == STANDING_UP)
		target.set_body_position(LYING_DOWN)

/datum/coven_power/presence/fall/deactivate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)


//SUMMON
/datum/coven_power/presence/summon
	name = "Summon"
	desc = "Call anyone you've ever met to be by your side."

	level = 4

	check_flags = COVEN_CHECK_CAPABLE|COVEN_CHECK_SPEAK
	target_type = TARGET_HUMAN
	range = 7

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	duration_length = 5 SECONDS

/datum/coven_power/presence/summon/pre_activation_checks(mob/living/target)
	var/mypower = owner.STAINT
	var/theirpower = owner.STAINT - 5
	if((theirpower >= mypower))
		to_chat(owner, span_warning("[target]'s mind is too powerful to sway!"))
		return FALSE

	return TRUE

/datum/coven_power/presence/summon/activate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)
	var/mutable_appearance/presence_overlay = mutable_appearance('icons/effects/clan.dmi', "presence", -MUTATIONS_LAYER)
	presence_overlay.pixel_z = 1
	target.overlays_standing[MUTATIONS_LAYER] = presence_overlay
	target.apply_overlay(MUTATIONS_LAYER)

	to_chat(target, "<span class='userlove'><b>TO ME</b></span>")
	owner.say("TO ME!!")
	var/datum/cb = CALLBACK(target, TYPE_PROC_REF(/mob/living/carbon/human, step_toward_caster), owner)
	for(var/i in 1 to 30)
		addtimer(cb, (i - 1) * target.total_multiplicative_slowdown())
	target.emote("scream")
	target.do_jitter_animation(3 SECONDS)

/datum/coven_power/presence/summon/deactivate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)

/mob/living/carbon/human/proc/step_toward_caster(mob/living/step_to)
	walk(src, 0)
	if(!CheckFrenzyMove())
		set_glide_size(DELAY_TO_GLIDE_SIZE(total_multiplicative_slowdown()))
		step_towards(src, step_to, 99)

//MAJESTY
/datum/coven_power/presence/majesty
	name = "Majesty"
	desc = "Become so grand that others find it nearly impossible to disobey or harm you."

	level = 5

	check_flags = COVEN_CHECK_CAPABLE|COVEN_CHECK_SPEAK
	target_type = TARGET_HUMAN
	range = 7

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	duration_length = 5 SECONDS

/datum/coven_power/presence/majesty/pre_activation_checks(mob/living/target)
	var/mypower = owner.STAINT
	var/theirpower = owner.STAINT - 5
	if((theirpower >= mypower))
		to_chat(owner, span_warning("[target]'s mind is too powerful to sway!"))
		return FALSE

	return TRUE

/datum/coven_power/presence/majesty/activate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)
	var/mutable_appearance/presence_overlay = mutable_appearance('icons/effects/clan.dmi', "presence", -MUTATIONS_LAYER)
	presence_overlay.pixel_z = 1
	target.overlays_standing[MUTATIONS_LAYER] = presence_overlay
	target.apply_overlay(MUTATIONS_LAYER)

	to_chat(target, "<span class='userlove'><b>UNDRESS YOURSELF</b></span>")
	owner.say("UNDRESS YOURSELF!!")
	target.Immobilize(1 SECONDS)
	for(var/obj/item/clothing/W in target.contents)
		target.dropItemToGround(W, TRUE)

/datum/coven_power/presence/majesty/deactivate(mob/living/carbon/human/target)
	. = ..()
	target.remove_overlay(MUTATIONS_LAYER)
