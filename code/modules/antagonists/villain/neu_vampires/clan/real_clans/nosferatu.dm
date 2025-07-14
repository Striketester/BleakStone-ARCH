/datum/sprite_accessory/ears/nosferatu

/datum/sprite_accessory/hair/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_FACE)


/datum/clan/nosferatu
	name = "Nosferatu"
	desc = "The Nosferatu wear their curse on the outside. Their bodies horribly twisted and deformed through the Embrace, they lurk on the fringes of most cities, acting as spies and brokers of information. Using animals and their own supernatural capacity to hide, nothing escapes the eyes of the so-called Sewer Rats."
	curse = "Masquerade-violating appearance."
	alt_sprite = "nosferatu"
	clane_covens = list(
		/datum/coven/potence,
		/datum/coven/obfuscate
	)
	clane_traits = list(
		TRAIT_STRONGBITE,
		TRAIT_NOSTAMINA,
		TRAIT_NOHUNGER,
		TRAIT_NOBREATH,
		TRAIT_NOPAIN,
		TRAIT_TOXIMMUNE,
		TRAIT_STEELHEARTED,
		TRAIT_NOSLEEP,
		TRAIT_VAMPMANSION,
		TRAIT_VAMP_DREAMS,
		TRAIT_NOAMBUSH,
		TRAIT_DARKVISION,
		TRAIT_LIMBATTACHMENT,
	)

/datum/clan/nosferatu/on_gain(mob/living/carbon/human/H, is_vampire = TRUE)
	. = ..()

	if(is_vampire)
		var/obj/item/organ/eyes/night_vision/NV = new()
		NV.Insert(H, TRUE, FALSE)
		H.ventcrawler = VENTCRAWLER_ALWAYS //I don't think this does anything because we have no vents
		H.AddComponent(/datum/component/hideous_face, CALLBACK(TYPE_PROC_REF(/datum/clan/nosferatu, face_seen)))

/datum/clan/nosferatu/proc/face_seen(mob/living/carbon/human/nosferatu)
	nosferatu.AdjustMasquerade(-1)
