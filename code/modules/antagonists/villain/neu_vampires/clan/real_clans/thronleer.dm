
/datum/clan_leader/thronleer
	lord_spells = list(
		/datum/action/cooldown/spell/undirected/mansion_portal,
		/datum/action/cooldown/spell/undirected/shapeshift/mist
	)
	lord_verbs = list(
		/mob/living/carbon/human/proc/demand_submission,
		/mob/living/carbon/human/proc/punish_spawn
	)
	lord_traits = list(TRAIT_HEAVYARMOR)
	lord_title = "Elder"

/datum/clan/thronleer
	name = "House Thronleer"
	desc = "TBA"
	curse = "Weakness of the soul."
	clane_covens = list(
		/datum/coven/obfuscate,
		/datum/coven/presence,
	)
	leader = /datum/clan_leader/thronleer
