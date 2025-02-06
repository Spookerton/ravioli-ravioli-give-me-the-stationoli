// Code taken from /vg/station.

// Examples
/*
	-- Will call the proc for all computers in the world, thats dir is 2.
	CALL ex_act(EX_ACT_DEVASTATING) ON /obj/machinery/computer IN world WHERE dir == 2
	-- Will open a window with a list of all the closets in the world, with a link to VV them.
	SELECT /obj/structure/closet/secure_closet/security/cargo IN world WHERE icon_off == "secoff"
	-- Will change all the tube lights to green, and flicker them. The semicolon is important to separate the consecutive querys, but is not required for standard one-query use.
	UPDATE /obj/machinery/light SET color = "#0F0" WHERE icon_state == "tube1"; CALL flicker(1) ON /obj/machinery/light
	-- Will delete all pickaxes. "IN world" is not required.
	DELETE /obj/item/pickaxe

	--You can use operators other than ==, such as >, <=, != and etc..

	--Lists can be done through [], so say UPDATE /mob SET client.color = [1, 0.75, ...].
*/

// Used by update statements, this is to handle shit like preventing editing the /datum/admins though SDQL but WITHOUT +PERMISSIONS.
// Assumes the variable actually exists.
/datum/proc/SDQL_update(var_name, new_value)
	vars[var_name] = new_value
	return 1

/client/proc/SDQL2_query(query_text as message)
	set category = "Debug"

	if(!check_rights(R_DEBUG))  // Shouldn't happen... but just to be safe.
		message_admins(SPAN_WARNING("ERROR: Non-admin [usr.key] attempted to execute the following SDQL query: [query_text]"))
		log_admin("Non-admin [usr.key] attempted to execute the following SDQL query: [query_text]!")
		return

	if(!query_text || length(query_text) < 1)
		return

	var/query_log = "[key_name(src)] executed SDQL query: \"[query_text]\"."
	to_world_log(query_log)
	log_and_message_admins(query_log)
	sleep(-1) // Incase the server crashes due to a huge query, we allow the server to log the above things (it might just delay it).

	var/list/query_list = SDQL2_tokenize(query_text)

	if(!query_list || length(query_list) < 1)
		return

	var/list/querys = SDQL_parse(query_list)

	if(!querys || length(querys) < 1)
		return

	try
		for(var/list/query_tree in querys)
			var/list/from_objs = list()
			var/list/select_types = list()

			switch(query_tree[1])
				if("explain")
					SDQL_testout(query_tree["explain"])
					return

				if("call")
					if("on" in query_tree)
						select_types = query_tree["on"]
					else
						return

				if("select", "delete", "update")
					select_types = query_tree[query_tree[1]]


			from_objs = SDQL_from_objs(query_tree["from"])
			CHECK_TICK

			var/list/objs = list()

			for(var/type in select_types)
				objs += SDQL_get_all(type, from_objs)
				CHECK_TICK

			if("where" in query_tree)
				var/objs_temp = objs
				objs = list()
				for(var/datum/d in objs_temp)
					if(SDQL_expression(d, query_tree["where"]))
						objs += d
					CHECK_TICK

			switch(query_tree[1])
				if("call")
					for(var/datum/d in objs)
						SDQL_var(d, query_tree["call"][1], source = d)
						CHECK_TICK

				if("delete")
					for(var/datum/d in objs)
						if (isturf(d))
							// turfs are special snowflakes that explode if qdeleted
							var/turf/T = d
							T.ChangeTurf(world.turf)
						else
							qdel(d)
						CHECK_TICK

				if("select")
					var/text = ""
					for(var/datum/t in objs)
						text += "<A HREF='byond://?_src_=vars;Vars=\ref[t]'>\ref[t]</A>"
						if(isloc(t))
							var/atom/a = t

							if(a.x)
								text += ": [t] at <A HREF='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[a.x];Y=[a.y];Z=[a.z]'>([a.x], [a.y], [a.z])</a><br>"

							else if(a.loc && a.loc.x)
								text += ": [t] in <A HREF='byond://?_src_=vars;Vars=\ref[a.loc]'>[a.loc]</A> at <A HREF='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[a.loc.x];Y=[a.loc.y];Z=[a.loc.z]'>([a.loc.x], [a.loc.y], [a.loc.z])</a><br>"

							else
								text += ": [t]<br>"

						else
							text += ": [t]<br>"
						CHECK_TICK
					if(!text)
						text = "No results found."
					show_browser(usr, text, "window=SDQL-result")

				if("update")
					if("set" in query_tree)
						var/list/set_list = query_tree["set"]
						for(var/datum/d in objs)
							for(var/list/sets in set_list)
								var/datum/temp = d
								var/i = 0
								for(var/v in sets)
									if(++i == length(sets))
										if(isturf(temp) && (v == "x" || v == "y" || v == "z"))
											break

										temp.SDQL_update(v, SDQL_expression(d, set_list[sets]))
										break

									if(temp.vars.Find(v) && (istype(temp.vars[v], /datum) || istype(temp.vars[v], /client)))
										temp = temp.vars[v]

									else
										break

							CHECK_TICK

			to_chat(usr, SPAN_NOTICE("Query executed on [length(objs)] object\s."))
	catch(var/exception/e)
		to_chat(usr, SPAN_DANGER("An exception has occured during the execution of your query and your query has been aborted."))
		to_chat(usr, "exception name: [e.name]")
		to_chat(usr, "file/line: [e.file]/[e.line]")
		return

/proc/SDQL_parse(list/query_list)
	var/datum/SDQL_parser/parser = new()
	var/list/querys = list()
	var/list/query_tree = list()
	var/pos = 1
	var/querys_pos = 1
	var/do_parse = 0
	for(var/val in query_list)
		if(val == ";")
			do_parse = 1
		else if(pos >= length(query_list))
			query_tree += val
			do_parse = 1
		if(do_parse)
			parser.query = query_tree
			var/list/parsed_tree
			parsed_tree = parser.parse()
			if(length(parsed_tree) > 0)
				LIST_RESIZE(querys, querys_pos)
				querys[querys_pos] = parsed_tree
				querys_pos++
			else //There was an error so don't run anything, and tell the user which query has errored.
				to_chat(usr, SPAN_DANGER("Parsing error on [querys_pos]\th query. Nothing was executed."))
				return list()
			query_tree = list()
			do_parse = 0
		else
			query_tree += val
		pos++

	qdel(parser)

	return querys



/proc/SDQL_testout(list/query_tree, indent = 0)
	var/spaces = ""
	for(var/s = 0, s < indent, s++)
		spaces += "&nbsp;&nbsp;&nbsp;&nbsp;"

	for(var/item in query_tree)
		if(islist(item))
			to_chat(usr, "[spaces](")
			SDQL_testout(item, indent + 1)
			to_chat(usr, "[spaces])")

		else
			to_chat(usr, "[spaces][item]")

		if(!isnum(item) && query_tree[item])

			if(islist(query_tree[item]))
				to_chat(usr, "[spaces]&nbsp;&nbsp;&nbsp;&nbsp;(")
				SDQL_testout(query_tree[item], indent + 2)
				to_chat(usr, "[spaces]&nbsp;&nbsp;&nbsp;&nbsp;)")

			else
				to_chat(usr, "[spaces]&nbsp;&nbsp;&nbsp;&nbsp;[query_tree[item]]")

/proc/SDQL_from_objs(list/tree)
	if("world" in tree)
		return world

	return SDQL_expression(world, tree)


/proc/SDQL_get_all(type, location)
	var/list/out = list()

	// If only a single object got returned, wrap it into a list so the for loops run on it.
	if (!islist(location) && location != world)
		location = list(location)

	type = text2path(type)

	if(ispath(type, /mob))
		for(var/mob/d in location)
			if(istype(d, type))
				out += d

	else if(ispath(type, /turf))
		for(var/turf/d in location)
			if(istype(d, type))
				out += d

	else if(ispath(type, /obj))
		for(var/obj/d in location)
			if(istype(d, type))
				out += d

	else if(ispath(type, /area))
		for(var/area/d in location)
			if(istype(d, type))
				out += d

	else if(ispath(type, /atom))
		for(var/atom/d in location)
			if(istype(d, type))
				out += d

	else
		for(var/datum/d in location)
			if(istype(d, type))
				out += d

	return out


/proc/SDQL_expression(datum/object, list/expression, start = 1)
	var/result = 0
	var/val

	for(var/i = start, i <= length(expression), i++)
		var/op = ""

		if(i > start)
			op = expression[i]
			i++

		var/list/ret = SDQL_value(object, expression, i)
		val = ret["val"]
		i = ret["i"]

		if(op != "")
			switch(op)
				if("+")
					result += val
				if("-")
					result -= val
				if("*")
					result *= val
				if("/")
					result /= val
				if("&")
					result &= val
				if("|")
					result |= val
				if("^")
					result ^= val
				if("=", "==")
					result = (result == val)
				if("!=", "<>")
					result = (result != val)
				if("<")
					result = (result < val)
				if("<=")
					result = (result <= val)
				if(">")
					result = (result > val)
				if(">=")
					result = (result >= val)
				if("and", "&&")
					result = (result && val)
				if("or", "||")
					result = (result || val)
				else
					to_chat(usr, SPAN_WARNING("SDQL2: Unknown op [op]"))
					result = null
		else
			result = val

	return result

/proc/SDQL_value(datum/object, list/expression, start = 1)
	var/i = start
	var/val = null

	if(i > length(expression))
		return list("val" = null, "i" = i)

	if(islist(expression[i]))
		val = SDQL_expression(object, expression[i])

	else if(expression[i] == "!")
		var/list/ret = SDQL_value(object, expression, i + 1)
		val = !ret["val"]
		i = ret["i"]

	else if(expression[i] == "~")
		var/list/ret = SDQL_value(object, expression, i + 1)
		val = ~ret["val"]
		i = ret["i"]

	else if(expression[i] == "-")
		var/list/ret = SDQL_value(object, expression, i + 1)
		val = -ret["val"]
		i = ret["i"]

	else if(expression[i] == "null")
		val = null

	else if(isnum(expression[i]))
		val = expression[i]

	else if(copytext(expression[i], 1, 2) in list("'", "\""))
		val = copytext(expression[i], 2, length(expression[i]))

	else if(expression[i] == "\[")
		var/list/expressions_list = expression[++i]
		val = list()
		for(var/list/expression_list in expressions_list)
			var/result = SDQL_expression(object, expression_list)
			var/assoc
			if (expressions_list[expression_list] != null)
				assoc = SDQL_expression(object, expressions_list[expression_list])

			if (assoc != null)
				// Need to insert the key like this to prevent duplicate keys fucking up.
				var/list/dummy = list()
				dummy[result] = assoc
				result = dummy

			val += result

	else
		val = SDQL_var(object, expression, i, object)
		i = length(expression)

	return list("val" = val, "i" = i)

/proc/SDQL_var(datum/object, list/expression, start = 1, source)
	var/v
	var/static/list/exclude = list("usr", "src", "marked", "global")
	var/long = start < length(expression)

	if (object == world && (!long || expression[start + 1] == ".") && !(expression[start] in exclude))
		var/name = expression[start]
		v = global.vars[name]

	else if (expression [start] == "{" && long)
		if (lowertext(copytext(expression[start + 1], 1, 3)) != "0x")
			to_chat(usr, SPAN_DANGER("Invalid pointer syntax: [expression[start + 1]]"))
			return null
		v = locate("\[[expression[start + 1]]]")
		if (!v)
			to_chat(usr, SPAN_DANGER("Invalid pointer: [expression[start + 1]]"))
			return null
		start++

	else if ((!long || expression[start + 1] == ".") && (expression[start] in object.vars))
		v = object.vars[expression[start]]

	else if (long && expression[start + 1] == ":" && hascall(object, expression[start]))
		v = expression[start]

	else if (!long || expression[start + 1] == ".")
		switch(expression[start])
			if("usr")
				v = usr
			if("src")
				v = source
			if("marked")
				if(usr.client && usr.client.holder && usr.client.holder.marked_datum())
					v = usr.client.holder.marked_datum()
				else
					return null
			if("global")
				v = world // World is mostly a token, really.
			else
				return null

	else if (object == world) // Shitty ass hack kill me.
		v = expression[start]

	if(long)
		if (expression[start + 1] == ".")
			return SDQL_var(v, expression[start + 2], source = source)

		else if (expression[start + 1] == ":")
			return SDQL_function(object, v, expression[start + 2], source)

		else if (expression[start + 1] == "\[" && islist(v))
			var/list/L = v
			var/index = SDQL_expression(source, expression[start + 2])
			if (isnum(index) && (!IsInteger(index) || length(L) < index))
				to_chat(usr, SPAN_DANGER("Invalid list index: [index]"))
				return null

			return L[index]

	return v


/proc/SDQL_function(datum/object, procname, list/arguments, source)
	set waitfor = FALSE

	var/list/new_args = list()
	for(var/arg in arguments)
		new_args[LIST_PRE_INC(new_args)] = SDQL_expression(source, arg)

	if (object == world) // Global proc.
		procname = "/proc/[procname]"
		return call(procname)(arglist(new_args))

	return call(object, procname)(arglist(new_args)) // Spawn in case the function sleeps.


/proc/SDQL2_tokenize(query_text)


	var/list/whitespace = list(" ", "\n", "\t")
	var/list/single = list("(", ")", ",", "+", "-", ".", "\[", "]", "{", "}", ";", ":")
	var/list/multi = list(
					"=" = list("", "="),
					"<" = list("", "=", ">"),
					">" = list("", "="),
					"!" = list("", "="))

	var/word = ""
	var/list/query_list = list()
	var/len = length(query_text)

	for(var/i = 1, i <= len, i++)
		var/char = copytext(query_text, i, i + 1)

		if(char in whitespace)
			if(word != "")
				query_list += word
				word = ""

		else if(char in single)
			if(word != "")
				query_list += word
				word = ""

			query_list += char

		else if(char in multi)
			if(word != "")
				query_list += word
				word = ""

			var/char2 = copytext(query_text, i + 1, i + 2)

			if(char2 in multi[char])
				query_list += "[char][char2]"
				i++

			else
				query_list += char

		else if(char == "'")
			if(word != "")
				to_chat(usr, SPAN_WARNING("SDQL2: You have an error in your SDQL syntax, unexpected ' in query: \"[SPAN_COLOR("gray", query_text)]\" following \"[SPAN_COLOR("gray", word)]\". Please check your syntax, and try again."))
				return null

			word = "'"

			for(i++, i <= len, i++)
				char = copytext(query_text, i, i + 1)

				if(char == "'")
					if(copytext(query_text, i + 1, i + 2) == "'")
						word += "'"
						i++

					else
						break

				else
					word += char

			if(i > len)
				to_chat(usr, SPAN_WARNING("SDQL2: You have an error in your SDQL syntax, unmatched ' in query: \"[SPAN_COLOR("gray", "[query_text]")]\". Please check your syntax, and try again."))
				return null

			query_list += "[word]'"
			word = ""

		else if(char == "\"")
			if(word != "")
				to_chat(usr, SPAN_WARNING("SDQL2: You have an error in your SDQL syntax, unexpected \" in query: \"[SPAN_COLOR("gray", query_text)]\" following \"[SPAN_COLOR("gray", word)]\". Please check your syntax, and try again."))
				return null

			word = "\""

			for(i++, i <= len, i++)
				char = copytext(query_text, i, i + 1)

				if(char == "\"")
					if(copytext(query_text, i + 1, i + 2) == "'")
						word += "\""
						i++

					else
						break

				else
					word += char

			if(i > len)
				to_chat(usr, SPAN_WARNING("SDQL2: You have an error in your SDQL syntax, unmatched \" in query: \"[SPAN_COLOR("gray", "[query_text]")]\". Please check your syntax, and try again."))
				return null

			query_list += "[word]\""
			word = ""

		else
			word += char

	if(word != "")
		query_list += word
	return query_list
