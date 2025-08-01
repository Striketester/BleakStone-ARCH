/**
 * ## List Target spells
 *
 * These spells will prompt the user with a tgui list
 * of all nearby targets that they select on to cast.
 *
 * To add effects on cast, override "cast(atom/cast_on)".
 * The cast_on atom is the atom that was selected by the list.
 */
/datum/action/cooldown/spell/undirected/list_target
	charge_required = FALSE
	has_visual_effects = FALSE

	/// The message displayed as the title of the tgui target input list.
	var/choose_target_message = "Choose a target."
	/// Radius around the caster that living targets are picked to choose from
	var/target_radius = 7

/datum/action/cooldown/spell/undirected/list_target/PreActivate(atom/caster)
	var/list/list_targets = get_list_targets(caster, target_radius)
	if(!length(list_targets))
		to_chat(caster, span_warning("No targets nearby!"))
		return FALSE

	var/atom/chosen = browser_input_list(caster, choose_target_message, name, sortList(list_targets))
	if(QDELETED(src) || QDELETED(caster) || QDELETED(chosen) || !can_cast_spell())
		return FALSE

	if(get_dist(chosen, caster) > target_radius)
		to_chat(caster, span_warning("They're too far!"))
		return FALSE

	return Activate(chosen)

/// Get a list of living targets in radius of the center to put in the target list.
/datum/action/cooldown/spell/undirected/list_target/proc/get_list_targets(atom/center, target_radius = 7)
	var/list/things = list()
	if(target_radius)
		for(var/mob/living/nearby_living in oview(target_radius, center))
			if(nearby_living == owner)
				continue
			things += nearby_living

	return things
