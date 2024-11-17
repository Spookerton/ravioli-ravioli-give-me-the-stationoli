/obj/item/reagent_containers/chem_disp_cartridge
	name = "chemical dispenser cartridge"
	desc = "This goes in a chemical dispenser."
	icon_state = "cartridge"
	w_class = ITEM_SIZE_NORMAL
	reagents_volume = CARTRIDGE_VOLUME_LARGE
	amount_per_transfer_from_this = 50
	possible_transfer_amounts = "50;100"
	unacidable = TRUE


/obj/item/reagent_containers/chem_disp_cartridge/small
	reagents_volume = CARTRIDGE_VOLUME_SMALL


/obj/item/reagent_containers/chem_disp_cartridge/medium
	reagents_volume = CARTRIDGE_VOLUME_MEDIUM


/obj/item/reagent_containers/chem_disp_cartridge/Initialize()
	var/datum/reagent/reagent = reagents
	AddLabel(initial(reagent.name))
	return ..()


/obj/item/reagent_containers/chem_disp_cartridge/examine(mob/user)
	. = ..()
	to_chat(user, "It has a capacity of [reagents_volume] units.")
	if (reagents.total_volume <= 0)
		to_chat(user, "It is empty.")
	else
		to_chat(user, "It contains [reagents.total_volume] units of liquid.")
	if (!is_open_container())
		to_chat(user, "The cap is sealed.")


/obj/item/reagent_containers/chem_disp_cartridge/attack_self()
	..()
	if (is_open_container())
		to_chat(usr, SPAN_NOTICE("You put the cap on \the [src]."))
		atom_flags ^= ATOM_FLAG_OPEN_CONTAINER
	else
		to_chat(usr, SPAN_NOTICE("You take the cap off \the [src]."))
		atom_flags |= ATOM_FLAG_OPEN_CONTAINER


/obj/item/reagent_containers/chem_disp_cartridge/use_after(atom/target, mob/living/user, click_parameters)
	if (!is_open_container())
		to_chat(user, SPAN_WARNING("\The [src] is covered with a cap."))
		return TRUE
	if(istype(target, /obj/structure/reagent_dispensers)) //A dispenser. Transfer FROM it TO us.
		if(!target.reagents.total_volume && target.reagents)
			to_chat(user, SPAN_WARNING("\The [target] is empty."))
			return TRUE
		if(reagents.total_volume >= reagents.maximum_volume)
			to_chat(user, SPAN_WARNING("\The [src] is full."))
			return TRUE
		var/trans = target.reagents.trans_to(src, target:amount_per_transfer_from_this)
		to_chat(user, SPAN_NOTICE("You fill \the [src] with [trans] units of the contents of \the [target]."))
		return TRUE
	if(target.is_open_container() && target.reagents) //Something like a glass. Player probably wants to transfer TO it.
		if(!reagents.total_volume)
			to_chat(user, SPAN_WARNING("\The [src] is empty."))
			return TRUE
		if(target.reagents.total_volume >= target.reagents.maximum_volume)
			to_chat(user, SPAN_WARNING("\The [target] is full."))
			return TRUE
		var/trans = src.reagents.trans_to(target, amount_per_transfer_from_this)
		to_chat(user, SPAN_NOTICE("You transfer [trans] units of the solution to \the [target]."))
		return TRUE
