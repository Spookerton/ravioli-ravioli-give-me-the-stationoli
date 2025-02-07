//	Observer Pattern Implementation: See In Dark Set
//		Registration type: /mob
//
//		Raised when: A mob's see_in_dark value changes.
//
//		Arguments that the called proc should expect:
//			/mob/sightee:  The mob that had its see_in_dark set
//			/old_see_in_dark: see_in_dark before the change
//			/new_see_in_dark: see_in_dark after the change

GLOBAL_TYPED_NEW(see_in_dark_set_event, /singleton/observ/see_in_dark_set)

/singleton/observ/see_in_dark_set
	name = "See In Dark Set"
	expected_type = /mob

/***************************
* See In Dark Set Handling *
***************************/

/mob/proc/set_see_in_dark(new_see_in_dark, seedarkness)
	var/old_see_in_dark = sight
	if(old_see_in_dark != new_see_in_dark)
		see_in_dark  = new_see_in_dark
		GLOB.see_in_dark_set_event.raise_event(src, old_see_in_dark, new_see_in_dark)
