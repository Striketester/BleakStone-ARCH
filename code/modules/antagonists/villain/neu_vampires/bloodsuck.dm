/mob/living/carbon/human/proc/add_bite_animation()
	remove_overlay(BITE_LAYER)
	var/mutable_appearance/bite_overlay = mutable_appearance('icons/effects/clan.dmi', "bite", -BITE_LAYER)
	overlays_standing[BITE_LAYER] = bite_overlay
	apply_overlay(BITE_LAYER)
	spawn(15)
		if(src)
			remove_overlay(BITE_LAYER)

/proc/get_needed_difference_between_numbers(number1, number2)
	if(number1 > number2)
		return number1 - number2
	else if(number1 < number2)
		return number2 - number1
	else
		return 1

/mob/living/carbon/human/proc/drinksomeblood(mob/living/mob)
	last_drinkblood_use = world.time

	if(mob.bloodpool <= 1 && mob.maxbloodpool > 1)
		to_chat(src, "<span class='warning'>You feel small amount of <b>BLOOD</b> in your victim.</span>")
		if(mob.clan)
			if(!mob.client)
				to_chat(src, "<span class='warning'>You need [mob]'s attention to do that...</span>")
				return
			message_admins("[ADMIN_LOOKUPFLW(src)] is attempting to Diablerize [ADMIN_LOOKUPFLW(mob)]")
			log_attack("[key_name(src)] is attempting to Diablerize [key_name(mob)].")
			if(mob.key)
				var/vse_taki = FALSE
				if(clan)
					if(clan.name != "Caitiff")
						if(!mind.special_role)
							to_chat(src, "<span class='warning'>You find the idea of drinking your own <b>KIND's</b> blood disgusting!</span>")
							last_drinkblood_use = 0
							return
						else
							vse_taki = TRUE
					else
						vse_taki = TRUE

				if(vse_taki)
					to_chat(src, "<span class='userdanger'><b>YOU TRY TO COMMIT DIABLERIE ON [mob].</b></span>")
				else
					to_chat(src, "<span class='warning'>You find the idea of drinking your own <b>KIND</b> disgusting!</span>")
					return
			else
				to_chat(src, "<span class='warning'>You need [mob]'s attention to do that...</span>")
				return

	/*
	if(!HAS_TRAIT(src, TRAIT_BLOODY_LOVER))
		if(CheckEyewitness(src, src, 7, FALSE))
			AdjustMasquerade(-1)
	*/
	if(do_after(src, 3 SECONDS, target = mob, timed_action_flags = NONE, progress = FALSE))
		mob.bloodpool = max(0, mob.bloodpool-1)
		if(ishuman(mob))
			var/mob/living/carbon/human/H = mob
			drunked_of |= "[H.dna.real_name]"
			H.blood_volume = max(H.blood_volume-50, 150)
			if(H.reagents)
				if(length(H.reagents.reagent_list))
					if(prob(50))
						H.reagents.trans_to(src, min(10, H.reagents.total_volume), transfered_by = mob)
		/*
		if(HAS_TRAIT(src, TRAIT_PAINFUL_VAMPIRE_KISS))
			mob.adjustBruteLoss(20, TRUE)
		*/
		to_chat(src, "<span class='warning'>You sip some <b>BLOOD</b> from your victim. It feels good.</span>")
		bloodpool = min(maxbloodpool, bloodpool+1)
		adjustBruteLoss(-10, TRUE)
		adjustFireLoss(-10, TRUE)
		update_damage_overlays()
		update_health_hud()
		if(mob.bloodpool <= 0)
			if(ishuman(mob))
				var/mob/living/carbon/human/K = mob
				if(mob.clan && clan)
					AdjustMasquerade(-1)
					message_admins("[ADMIN_LOOKUPFLW(src)] successfully Diablerized [ADMIN_LOOKUPFLW(mob)]")
					log_attack("[key_name(src)] successfully Diablerized [key_name(mob)].")
					mob.death()
					adjustBruteLoss(-50, TRUE)
					adjustFireLoss(-50, TRUE)
					return
				else
					K.blood_volume = 0
			if(ishuman(mob) && !mob.clan)
				if(mob.stat != DEAD)
					to_chat(src, "<span class='warning'>This sad sacrifice for your own pleasure affects something deep in your mind.</span>")
					AdjustMasquerade(-1)
					mob.death()
			if(!ishuman(mob))
				if(mob.stat != DEAD)
					mob.death()
			last_drinkblood_use = 0
			return
		if(grab_state >= GRAB_PASSIVE)
			drinksomeblood(mob)
	else
		last_drinkblood_use = 0

		/*
		if(!(SEND_SIGNAL(mob, COMSIG_MOB_VAMPIRE_SUCKED, mob) & COMPONENT_RESIST_VAMPIRE_KISS))
			mob.SetSleeping(50)
		*/
		mob.SetSleeping(5 SECONDS)
