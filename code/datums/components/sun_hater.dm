
/datum/component/sunlight_vulnerability
	/// How much damage per tick in sunlight
	var/burn_damage = 5
	/// How much bloodpool drain per tick
	var/bloodpool_drain = 10
	/// Whether this mob is currently in sunlight
	var/in_sunlight = FALSE

/datum/component/sunlight_vulnerability/Initialize(damage = 5, drain = 10)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	burn_damage = damage
	bloodpool_drain = drain

	RegisterSignal(parent, COMSIG_HUMAN_LIFE, PROC_REF(check_sunlight))

/datum/component/sunlight_vulnerability/proc/check_sunlight(mob/living/source)
	var/mob/living/carbon/human/H = source
	if(!H || H.stat == DEAD || H.advsetup)
		return

	// Only check during day
	if(GLOB.tod != "day")
		in_sunlight = FALSE
		return

	// Check if outside and in light
	if(isturf(H.loc))
		var/turf/T = H.loc
		if(T.can_see_sky() && T.get_lumcount() > 0.15)
			if(!in_sunlight)
				in_sunlight = TRUE
				to_chat(H, span_danger("The sunlight burns my flesh!"))

			apply_sunlight_damage(H)
		else
			in_sunlight = FALSE
	else
		in_sunlight = FALSE

/datum/component/sunlight_vulnerability/proc/apply_sunlight_damage(mob/living/carbon/human/H)
	// Force undisguise if disguised
	var/datum/component/vampire_disguise/disguise_comp = H.GetComponent(/datum/component/vampire_disguise)
	if(disguise_comp && disguise_comp.disguised)
		disguise_comp.force_undisguise(H)
		to_chat(H, span_warning("The sunlight breaks my disguise!"))

	// Apply fire damage
	H.fire_act(1, burn_damage)

	// Drain bloodpool
	H.bloodpool = max(0, H.bloodpool - bloodpool_drain)

	// Freak out if on fire
	if(H.on_fire)
		H.freak_out()
