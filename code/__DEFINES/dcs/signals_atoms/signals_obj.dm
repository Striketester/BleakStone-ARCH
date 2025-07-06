#define COMSIG_ITEM_ATTACK "item_attack"						//from base of obj/item/attack(): (/mob/living/target, /mob/living/user)

#define COMSIG_ITEM_ATTACK_SELF "item_attack_self"				//from base of obj/item/attack_self(): (/mob)
	#define COMPONENT_NO_INTERACT 1

#define COMSIG_ITEM_ATTACK_OBJ "item_attack_obj"				//from base of obj/item/attack_obj(): (/obj, /mob)
	#define COMPONENT_NO_ATTACK_OBJ 1

#define COMSIG_ITEM_PRE_ATTACK "item_pre_attack"				//from base of obj/item/pre_attack(): (atom/target, mob/user, params)
	#define COMPONENT_NO_ATTACK 1

#define COMSIG_ITEM_AFTERATTACK "item_afterattack"				//from base of obj/item/afterattack(): (atom/target, mob/user, params)
#define COMSIG_ITEM_ATTACK_QDELETED "item_attack_qdeleted"		//from base of obj/item/attack_qdeleted(): (atom/target, mob/user, params)
#define COMSIG_ITEM_EQUIPPED "item_equip"						//from base of obj/item/equipped(): (/mob/equipper, slot)
#define COMSIG_ITEM_SPEC_ATTACKEDBY "item_spec_attackedby"		//from base of datum/species/proc/spec_attacked_by: (atom/target, mob/user, params)

#define COMSIG_ITEM_AFTERATTACK_SECONDARY "item_afterattack_secondary"
