/mob/living/carbon
	blood_volume = BLOOD_VOLUME_NORMAL
	gender = MALE
	base_intents = list(INTENT_HELP, INTENT_HARM)
	hud_possible = list(ANTAG_HUD)
	held_items = list(null, null)
	// Populated on init through list/bodyparts
	num_legs = 0
	// Populated on init through list/bodyparts
	usable_legs = 0
	// Populated on init through list/bodyparts
	num_hands = 0
	// Populated on init through list/bodyparts
	usable_hands = 0
	/// List of /obj/item/organ in the mob. They don't go in the contents for some reason I don't want to know.
	var/list/internal_organs = list()
	/// Same as internal_organs, but stores "slot ID" - "organ" pairs for easy access.
	var/list/internal_organs_slot = list()
	/// Can't talk. Value goes down every life proc. //NOTE TO FUTURE CODERS: DO NOT INITIALIZE NUMERICAL VARS AS NULL OR I WILL MURDER YOU.
	var/silent = FALSE
	/// How many dream images we have left to send
	var/dreaming = 0

	/// Whether or not the mob is handcuffed
	var/obj/item/handcuffed = null
	/// Same as handcuffs but for legs. Bear traps use this.
	var/obj/item/legcuffed = null

	var/disgust = 0

	/* inventory slots */

	var/obj/item/wear_back_right = null
	var/obj/item/wear_back_left = null
	var/obj/item/clothing/face/wear_mask = null
	var/obj/item/mouth = null
	var/obj/item/clothing/neck/wear_neck = null
	var/obj/item/clothing/head = null

	var/obj/item/clothing/gloves = null //only used by humans
	var/obj/item/clothing/shoes = null //only used by humans.

	/// dna datum of this carbon
	var/datum/dna/dna = null
	//last mind to control this mob
	var/datum/mind/last_mind = null

	/// This is used to determine if the mob failed a breath. If they did fail a brath, they will attempt to breathe each tick, otherwise just once per 4 ticks.
	var/failed_last_breath = 0

	var/obj/item/reagent_containers/food/snacks/meat/steak/type_of_meat = /obj/item/reagent_containers/food/snacks/meat/steak

	/// what kind of gibs splurt out when this mob is gibbed
	var/gib_type = /obj/effect/decal/cleanable/blood/gibs

	/// should this mob be rotated when they lie down?
	var/rotate_on_lying = TRUE

	/// Total level of visualy impairing items
	var/tinttotal = 0

	var/list/bodyparts = list(/obj/item/bodypart/chest, /obj/item/bodypart/head, /obj/item/bodypart/l_arm,
					/obj/item/bodypart/r_arm, /obj/item/bodypart/r_leg, /obj/item/bodypart/l_leg)
	//Gets filled up in create_bodyparts()

	/// a collection of arms (or actually whatever the fug /bodyparts you monsters use to wreck my systems)
	var/list/hand_bodyparts = list()

	var/icon_render_key = ""
	var/static/list/limb_icon_cache = list()

	//halucination vars
	var/image/halimage
	var/image/halbody
	var/obj/halitem
	var/hal_screwyhud = SCREWYHUD_NONE
	var/next_hallucination = 0
	var/damageoverlaytemp = 0

	var/drunkenness = 0 //Overall drunkenness - check handle_alcohol() in life.dm for effects

	var/tiredness = 0
	/// How much total vitae a vampire can absorb from this mob. Once expended, you can't gain more from them.
	var/vitae_pool = 5000

	/// is this mob currently in advsetup?
	var/advsetup = 0

	/// if they get a mana pool
	has_initial_mana_pool = TRUE
