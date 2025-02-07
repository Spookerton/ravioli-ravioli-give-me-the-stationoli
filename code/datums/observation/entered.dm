//	Observer Pattern Implementation: Entered
//		Registration type: /atom
//
//		Raised when: An /atom/movable instance has entered an atom.
//
//		Arguments that the called proc should expect:
//			/atom/entered: The atom that was entered
//			/atom/movable/enterer: The instance that entered the atom
//			/atom/old_loc: The atom the enterer came from
//

GLOBAL_TYPED_NEW(entered_event, /singleton/observ/entered)

/singleton/observ/entered
	name = "Entered"
	expected_type = /atom

/*******************
* Entered Handling *
*******************/

/atom/Entered(atom/movable/enterer, atom/old_loc)
	..()
	GLOB.entered_event.raise_event(src, enterer, old_loc)
