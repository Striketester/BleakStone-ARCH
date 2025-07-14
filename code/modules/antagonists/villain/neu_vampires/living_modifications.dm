/proc/CheckZoneCoven(mob/target)
	var/area/area = get_area(target)
	return !area.coven_protected

/mob/living
	var/enhanced_strip = FALSE
	var/datum/clan/clan
	var/bloodpool = 1000
	var/maxbloodpool = 3000
	var/masquerade = 5
	var/datum/weakref/conditioner
	var/conditioned = FALSE
	var/last_masquerade_violation = 0
	var/resistant_to_covens = FALSE

	var/coven_time_plus = 0
	var/bloodpower_time_plus = 0

	var/last_rage_hit = 0
	var/antifrenzy = FALSE
	var/in_frenzy = FALSE
	var/frenzy_hardness = 1
	var/last_frenzy_check = 0
	var/atom/frenzy_target = null

	var/last_drinkblood_use = 0
	var/last_bloodpower_click = 0
	var/last_drinkblood_click = 0

	var/list/drunked_of = list()

	var/frenzy_chance_boost = 10
	var/humanity = 7

	/// List of covens this mob possesses
	var/list/datum/coven/covens
	var/datum/clan_menu_interface/clan_menu_interface
	var/datum/clan_hierarchy_node/clan_position


/mob/living/proc/has_bloodpool_cost(cost)
	if(cost > bloodpool)
		return FALSE
	return TRUE

/datum/clan/proc/grant_hierarchy_actions(mob/living/carbon/human/H)
	if(!H.clan_position)
		return

	for(var/datum/action/clan_hierarchy/action in H.actions)
		action.Remove(H)

	if(length(H.clan_position.subordinates))
		var/datum/action/clan_hierarchy/command_subordinate/command_action = new()
		command_action.Grant(H)

		var/datum/action/clan_hierarchy/locate_subordinate/locate_action = new()
		locate_action.Grant(H)

	if(H.clan_position.can_assign_positions)
		var/datum/action/clan_hierarchy/summon_subordinate/summon_action = new()
		summon_action.Grant(H)

		var/datum/action/clan_hierarchy/mass_command/mass_action = new()
		mass_action.Grant(H)

/mob/living/proc/adjust_bloodpool(adjust)
	bloodpool = CLAMP(bloodpool + adjust, 0, maxbloodpool)

/mob/living/proc/CheckEyewitness(mob/living/source, mob/attacker, range = 0, affects_source = FALSE)
	var/actual_range = max(1, round(range*(attacker.alpha/255)))
	var/list/seenby = list()
	for(var/mob/living/carbon/human/human in oviewers(1, source))
		if(get_turf(src) != turn(human.dir, 180))
			seenby |= human
	for(var/mob/living/carbon/human/human in viewers(actual_range, source))
		if(affects_source)
			if(human == source)
				seenby |= human
		if(!human.pulledby)
			var/turf/LC = get_turf(attacker)
			if(LC.get_lumcount() > 0.25 || get_dist(human, attacker) <= 1)
				if(!attacker.InCone(human))
					if((human == source) && !affects_source)
						continue
					seenby |= human
	if(length(seenby) >= 1)
		return TRUE
	return FALSE


/mob/living/carbon/human/proc/AdjustMasquerade(value, forced = FALSE)
	if(!clan)
		return
	if (!forced)
		if(value > 0)
			if(HAS_TRAIT(src, TRAIT_VIOLATOR))
				return
		if(!CheckZoneCoven(src))
			return
	if(!is_special_character(src) || forced)
		if(((last_masquerade_violation + 10 SECONDS) < world.time) || forced)
			last_masquerade_violation = world.time
			if(value < 0)
				if(masquerade > 0)
					masquerade = max(0, masquerade+value)
					to_chat(src, "<span class='userdanger'><b>MASQUERADE VIOLATION!</b></span>")
			if(value > 0)
				if(masquerade < 5)
					masquerade = min(5, masquerade+value)
					to_chat(src, "<span class='userhelp'><b>MASQUERADE REINFORCED!</b></span>")

	if(src in GLOB.coven_breakers_list)
		if(masquerade > 2)
			GLOB.coven_breakers_list -= src
	else if(masquerade < 3)
		GLOB.coven_breakers_list |= src

/**
 * Creates an action button and applies post_gain effects of the given Coven.
 * Now properly stores the coven on the mob.
 *
 * Arguments:
 * * coven - Coven datum/path that is being given to this mob.
 */
/mob/living/carbon/human/proc/give_coven(datum/coven/coven)
	if(ispath(coven))
		var/datum/coven/new_coven = new coven(1)
		coven = new_coven

	// Store the coven on the mob
	if(!length(covens))
		covens = list()

	// Assign the mob as owner
	coven.assign(src)

	// Store by name for easy access
	covens[coven.name] = coven

	if(coven.level > 0)
		var/datum/action/coven/action = new(src, coven)
		action.Grant(src)

/mob/living/carbon/human/proc/get_coven(datum/coven/coven_type)
	if(!length(covens))
		return null
	for(var/datum/coven/coven as anything in covens)
		if(coven.type != coven_type)
			continue
		return coven
	return null

/**
 * Opens the unified clan menu showing all covens and research trees
 */
/mob/living/carbon/human/proc/open_clan_menu()
	if(!clan)
		to_chat(src, "<span class='warning'>You have no clan!</span>")
		return
	if(!covens || !length(covens))
		to_chat(src, "<span class='warning'>You have no covens to manage!</span>")
		return

	// Clean up existing interface
	if(clan_menu_interface)
		qdel(clan_menu_interface)

	// Create new interface and store it
	clan_menu_interface = new /datum/clan_menu_interface(src)
	clan_menu_interface.generate_interface()


/mob/living/carbon/human/proc/process_vampire_life()
	if(!clan)
		return

	// Handle low bloodpool effects
	handle_bloodpool_effects()

	// Coffin regeneration
	if(stat && istype(loc, /obj/structure/closet/crate/coffin))
		fully_heal()
		bloodpool = min(maxbloodpool, bloodpool + 10)

/mob/living/carbon/human/proc/handle_bloodpool_effects()
	// Apply thirst effects based on bloodpool levels
	switch(bloodpool)
		if(VITAE_LEVEL_HUNGRY to VITAE_LEVEL_FED)
			apply_status_effect(/datum/status_effect/debuff/thirstyt1)
			remove_status_effect(/datum/status_effect/debuff/thirstyt2)
			remove_status_effect(/datum/status_effect/debuff/thirstyt3)
		if(VITAE_LEVEL_STARVING to VITAE_LEVEL_HUNGRY)
			apply_status_effect(/datum/status_effect/debuff/thirstyt2)
			remove_status_effect(/datum/status_effect/debuff/thirstyt1)
			remove_status_effect(/datum/status_effect/debuff/thirstyt3)
		if(-INFINITY to VITAE_LEVEL_STARVING)
			apply_status_effect(/datum/status_effect/debuff/thirstyt3)
			remove_status_effect(/datum/status_effect/debuff/thirstyt1)
			remove_status_effect(/datum/status_effect/debuff/thirstyt2)
			if(prob(3))
				playsound(get_turf(src), pick('sound/vo/hungry1.ogg','sound/vo/hungry2.ogg','sound/vo/hungry3.ogg'), 100, TRUE, -1)

	// Maintain blood volume for vampires
	if(bloodpool > 0)
		blood_volume = BLOOD_VOLUME_NORMAL

/mob/living/carbon/human/proc/get_clan_hierarchy_examine(mob/living/carbon/human/examiner)
	if(!clan || !clan_position || !examiner.clan)
		return ""

	if(examiner.clan != clan)
		return ""

	var/examine_text = ""

	examine_text += "<span class='info'><b>Clan Position:</b> [clan_position.name]</span>\n"

	if(clan_position.superior && clan_position.superior.assigned_member)
		var/mob/living/carbon/human/superior = clan_position.superior.assigned_member
		examine_text += "<span class='info'><b>Reports to:</b> [superior.real_name] ([clan_position.superior.name])</span>\n"

	if(examiner.clan_position && (examiner.clan_position.can_assign_positions || examiner.clan_position.is_superior_to(clan_position)))
		if(length(clan_position.subordinates))
			examine_text += "<span class='info'><b>Subordinates:</b> "
			var/list/sub_names = list()
			for(var/datum/clan_hierarchy_node/sub in clan_position.subordinates)
				if(sub.assigned_member)
					sub_names += "[sub.assigned_member.real_name] ([sub.name])"
			examine_text += english_list(sub_names)
			examine_text += "</span>\n"

	return examine_text
