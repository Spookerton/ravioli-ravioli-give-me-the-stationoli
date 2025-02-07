//	Observer Pattern Implementation: Stat Set
//		Registration type: /mob/living
//
//		Raised when: A /mob/living changes stat, using the set_stat() proc
//
//		Arguments that the called proc should expect:
//			/mob/living/stat_mob: The mob whose stat changed
//			/old_stat: Status before the change.
//			/new_stat: Status after the change.

GLOBAL_TYPED_NEW(stat_set_event, /singleton/observ/stat_set)

/singleton/observ/stat_set
	name = "Stat Set"
	expected_type = /mob/living

/****************
* Stat Handling *
****************/
/mob/living/set_stat(new_stat)
	var/old_stat = stat
	. = ..()
	if(stat != old_stat)
		GLOB.stat_set_event.raise_event(src, old_stat, new_stat)
