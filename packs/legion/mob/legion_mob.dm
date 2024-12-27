/mob/living/simple_animal/hostile/legion
	name = "legion"
	desc = "Some kind of robotic construct without any designation or markings. <span class='warning'>You feel some form of malicious intelligence behind its shell...</span>"
	abstract_type = /mob/living/simple_animal/hostile/legion
	icon = 'packs/legion/legion.dmi'
	icon_state = "hivebot"
	maxHealth = 15
	bleed_colour = SYNTH_BLOOD_COLOUR
	faction = "legion"
	say_list_type = /datum/say_list/legion
	ai_holder = /datum/ai_holder/legion

	/// The legion beacon this mob is linked to and spawned from.
	var/obj/structure/legion/beacon/linked_beacon = null


/mob/living/simple_animal/hostile/legion/Initialize(mapload, obj/structure/legion/beacon/spawner)
	health = maxHealth
	. = ..()
	set_beacon(spawner)

	add_language(LANGUAGE_HUMAN_EURO)
	add_language(LANGUAGE_LEGION_GLOBAL)


/mob/living/simple_animal/hostile/legion/Destroy()
	clear_beacon()
	return ..()


/mob/living/simple_animal/hostile/legion/get_bullet_impact_effect_type(def_zone)
	return BULLET_IMPACT_METAL


/mob/living/simple_animal/hostile/legion/death(gibbed, deathmessage, show_dead_message)
	..(FALSE, "blows apart!")
	var/turf/turf = get_turf(src)
	explosion(turf, 2, EX_ACT_LIGHT)
	new /obj/gibspawner/robot(turf)
	qdel_self()

	if (!rand(0, 1))
		return

	switch(rand(1, 2))
		if (1) // Normal brain
			var/obj/item/organ/internal/brain/brain = new(turf)
			brain.SetName("[name]'s [initial(brain.name)]")
			brain.die()

		if (2) // Positronic
			var/obj/item/organ/internal/posibrain/posibrain = new(turf)
			posibrain.SetName("[name]'s [initial(posibrain.name)]")
			posibrain.die()


/mob/living/simple_animal/hostile/legion/Process_Spacemove(allow_movement)
	return !is_physically_disabled()


/mob/living/simple_animal/hostile/legion/AirflowCanMove(n)
	return FALSE


/mob/living/simple_animal/hostile/legion/proc/set_beacon(obj/structure/legion/beacon/beacon)
	if (!beacon || beacon == linked_beacon)
		return
	if (linked_beacon)
		linked_beacon.linked_mobs -= src
	linked_beacon = beacon
	linked_beacon.linked_mobs += src
	ai_holder.home_turf = get_turf(linked_beacon)


/mob/living/simple_animal/hostile/legion/proc/clear_beacon()
	if (!linked_beacon)
		return
	linked_beacon.linked_mobs -= src
	linked_beacon = null
	ai_holder.home_turf = get_turf(src)
