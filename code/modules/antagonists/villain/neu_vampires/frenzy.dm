//Here's things for future madness

//add_client_colour(/datum/client_colour/glass_colour/red)
//remove_client_colour(/datum/client_colour/glass_colour/red)
/client/Click(object,location,control,params)
	if(isatom(object))
		if(ishuman(mob))
			var/mob/living/carbon/human/H = mob
			if(H.in_frenzy)
				return
	..()


/mob/proc/dice_roll(dices_num = 1, hardness = 1, atom/rollviewer)
	var/wins = 0
	var/crits = 0
	var/brokes = 0
	for(var/i in 1 to dices_num)
		var/roll = rand(1, 10)
		if(roll == 10)
			crits += 1
		if(roll == 1)
			brokes += 1
		else if(roll >= hardness)
			wins += 1
	if(crits > brokes)
		if(rollviewer)
			to_chat(rollviewer, "<b>Critical <span class='nicegreen'>hit</span>!</b>")
			return DICE_CRIT_WIN
	if(crits < brokes)
		if(rollviewer)
			to_chat(rollviewer, "<b>Critical <span class='danger'>failure</span>!</b>")
			return DICE_CRIT_FAILURE
	if(crits == brokes && !wins)
		if(rollviewer)
			to_chat(rollviewer, "<span class='danger'>Failed</span>")
			return DICE_FAILURE
	if(wins)
		switch(wins)
			if(1)
				to_chat(rollviewer, "<span class='tinynotice'>Maybe</span>")
				return DICE_WIN
			if(2)
				to_chat(rollviewer, "<span class='smallnotice'>Okay</span>")
				return DICE_WIN
			if(3)
				to_chat(rollviewer, "<span class='notice'>Good</span>")
				return DICE_WIN
			if(4)
				to_chat(rollviewer, "<span class='notice'>Lucky</span>")
				return DICE_WIN
			else
				to_chat(rollviewer, "<span class='boldnotice'>Phenomenal</span>")
				return DICE_WIN

/mob/living/carbon/proc/rollfrenzy()
	if(client)
		if(clan)
			clan.frenzy_message(src)
		var/check = dice_roll(max(1, round(humanity/2)), min(frenzy_chance_boost, frenzy_hardness), src)

		// Modifier for frenzy duration
		var/length_modifier = 1

		switch(check)
			if (DICE_CRIT_FAILURE)
				enter_frenzymod()
				addtimer(CALLBACK(src, PROC_REF(exit_frenzymod)), 20 SECONDS * length_modifier)
				frenzy_hardness = 1
			if (DICE_FAILURE)
				enter_frenzymod()
				addtimer(CALLBACK(src, PROC_REF(exit_frenzymod)), 10 SECONDS * length_modifier)
				frenzy_hardness = 1
			if (DICE_CRIT_WIN)
				frenzy_hardness = max(1, frenzy_hardness - 1)
			else
				frenzy_hardness = min(10, frenzy_hardness + 1)

/mob/living/carbon/proc/enter_frenzymod()
	if (in_frenzy)
		return
	in_frenzy = TRUE
	add_client_colour(/datum/client_colour/glass_colour/red)
	GLOB.frenzy_list += src

/mob/living/carbon/proc/exit_frenzymod()
	if (!in_frenzy)
		return

	in_frenzy = FALSE
	remove_client_colour(/datum/client_colour/glass_colour/red)
	GLOB.frenzy_list -= src

/mob/living/carbon/proc/CheckFrenzyMove()
	if(stat >= SOFT_CRIT)
		return TRUE
	if(IsSleeping())
		return TRUE
	if(IsUnconscious())
		return TRUE
	if(IsParalyzed())
		return TRUE
	if(IsKnockdown())
		return TRUE
	if(IsStun())
		return TRUE
	if(HAS_TRAIT(src, TRAIT_RESTRAINED))
		return TRUE

/mob/living/carbon/proc/frenzystep()
	if(!isturf(loc) || CheckFrenzyMove())
		return
	if(m_intent == MOVE_INTENT_WALK)
		toggle_move_intent(src)
	set_glide_size(DELAY_TO_GLIDE_SIZE(total_multiplicative_slowdown()))

	var/atom/fear
	var/list/fears = GLOB.fires_list + SShotspots.hotspots
	for(var/obj/F in fears)
		if(F)
			if(get_dist(src, F) < 7 && F.z == src.z)
				if(get_dist(src, F) < 6)
					fear = F
				if(get_dist(src, F) < 5)
					fear = F
				if(get_dist(src, F) < 4)
					fear = F
				if(get_dist(src, F) < 3)
					fear = F
				if(get_dist(src, F) < 2)
					fear = F
				if(get_dist(src, F) < 1)
					fear = F

//	if(!fear && !frenzy_target)
//		return

	if(clan)
		if(fear)
			step_away(src,fear,99)
			if(prob(25))
				emote("scream")
		else
			var/mob/living/carbon/human/H = src
			if(get_dist(frenzy_target, src) <= 1)
				if(isliving(frenzy_target))
					var/mob/living/L = frenzy_target
					if(L.bloodpool && L.stat != DEAD && last_drinkblood_use+95 <= world.time)
						L.grabbedby(src)
						if(ishuman(L))
							L.emote("scream")
							var/mob/living/carbon/human/BT = L
							BT.add_bite_animation()
						if(CheckEyewitness(L, src, 7, FALSE))
							H.AdjustMasquerade(-1)
						L.visible_message("<span class='warning'><b>[src] bites [L]'s neck!</b></span>", "<span class='warning'><b>[src] bites your neck!</b></span>")
						face_atom(L)
						H.drinksomeblood(L)
			else
				step_to(src,frenzy_target,0)
				face_atom(frenzy_target)
	else
		if(get_dist(frenzy_target, src) <= 1)
			if(isliving(frenzy_target))
				var/mob/living/L = frenzy_target
				if(L.stat != DEAD)
					a_intent = INTENT_HARM
					if(last_rage_hit+5 < world.time)
						last_rage_hit = world.time
						UnarmedAttack(L)
		else
			step_to(src,frenzy_target,0)
			face_atom(frenzy_target)

/mob/living/carbon/proc/get_frenzy_targets()
	var/list/targets = list()
	if(clan)
		for(var/mob/living/L in oviewers(7, src))
			if(L.bloodpool && L.stat != DEAD)
				targets += L
				if(L == frenzy_target)
					return L
	else
		for(var/mob/living/L in oviewers(7, src))
			if(L.stat != DEAD)
				targets += L
				if(L == frenzy_target)
					return L
	if(length(targets) > 0)
		return pick(targets)
	else
		return null


/mob/living/carbon/proc/handle_automated_frenzy()
	if(isturf(loc))
		frenzy_target = get_frenzy_targets()
		if(frenzy_target)
			var/datum/cb = CALLBACK(src, PROC_REF(frenzystep))
			var/reqsteps = SSfrenzy_handler.wait / total_multiplicative_slowdown()
			for(var/i in 1 to reqsteps)
				addtimer(cb, (i - 1)*total_multiplicative_slowdown())
		else
			if(!CheckFrenzyMove())
				if(isturf(loc))
					var/turf/T = get_step(loc, pick(NORTH, SOUTH, WEST, EAST))
					face_atom(T)
					Move(T)

