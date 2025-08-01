/*!
## Debugging GC issues

In order to debug `qdel()` failures, there are several tools available.
To enable these tools, define `TESTING` in [_compile_options.dm](https://github.com/tgstation/-tg-station/blob/master/code/_compile_options.dm).

First is a verb called "Find References", which lists **every** refererence to an object in the world. This allows you to track down any indirect or obfuscated references that you might have missed.

Complementing this is another verb, "qdel() then Find References".
This does exactly what you'd expect; it calls `qdel()` on the object and then it finds all references remaining.
This is great, because it means that `Destroy()` will have been called before it starts to find references,
so the only references you'll find will be the ones preventing the object from `qdel()`ing gracefully.

If you have a datum or something you are not destroying directly (say via the singulo),
the next tool is `QDEL_HINT_FINDREFERENCE`. You can return this in `Destroy()` (where you would normally `return ..()`),
to print a list of references once it enters the GC queue.

Finally is a verb, "Show qdel() Log", which shows the deletion log that the garbage subsystem keeps. This is helpful if you are having race conditions or need to review the order of deletions.

Note that for any of these tools to work `TESTING` must be defined.
By using these methods of finding references, you can make your life far, far easier when dealing with `qdel()` failures.
*/

SUBSYSTEM_DEF(garbage)
	name = "Garbage"
	priority = FIRE_PRIORITY_GARBAGE
	wait = 1//2 SECONDS
	flags = SS_POST_FIRE_TIMING|SS_BACKGROUND|SS_NO_INIT
	runlevels = RUNLEVELS_DEFAULT | RUNLEVEL_LOBBY
	init_order = INIT_ORDER_GARBAGE

	/// deciseconds to wait before moving something up in the queue to the next level
	var/list/collection_timeout = list(GC_FILTER_QUEUE, GC_CHECK_QUEUE, GC_DEL_QUEUE)

	//Stat tracking
	/// number of del()'s we've done this tick
	var/delslasttick = 0
	/// number of things that gc'ed last tick
	var/gcedlasttick = 0
	var/totaldels = 0
	var/totalgcs = 0

	var/highest_del_ms = 0
	var/highest_del_type_string = ""

	var/list/pass_counts
	var/list/fail_counts

	/// Holds our qdel_item statistics datums
	var/list/items = list()

	//Queue
	var/list/queues
#ifdef REFERENCE_TRACKING
	var/list/reference_find_on_fail = list()
#ifdef REFERENCE_TRACKING_DEBUG
	//Should we save found refs. Used for unit testing
	var/should_save_refs = FALSE
#endif
#endif

	/// Toggle for enabling/disabling hard deletes. Objects that don't explicitly request hard deletion with this disabled will leak.
	var/enable_hard_deletes = FALSE
	var/list/failed_hard_deletes = list()

/datum/controller/subsystem/garbage/PreInit()
	InitQueues()

/datum/controller/subsystem/garbage/Initialize(start_timeofday)
	. = ..()
#ifdef REFERENCE_TRACKING
	enable_hard_deletes = TRUE
#else
	if(CONFIG_GET(flag/hard_deletes_enabled))
		enable_hard_deletes = TRUE
#endif

/datum/controller/subsystem/garbage/stat_entry(msg)
	var/list/counts = list()
	for (var/list/L in queues)
		counts += length(L)
	msg += "Q:[counts.Join(",")]|D:[delslasttick]|G:[gcedlasttick]|"
	msg += "GR:"
	if (!(delslasttick+gcedlasttick))
		msg += "n/a|"
	else
		msg += "[round((gcedlasttick/(delslasttick+gcedlasttick))*100, 0.01)]%|"

	msg += "TD:[totaldels]|TG:[totalgcs]|"
	if (!(totaldels+totalgcs))
		msg += "n/a|"
	else
		msg += "TGR:[round((totalgcs/(totaldels+totalgcs))*100, 0.01)]%"
	msg += " P:[pass_counts.Join(",")]"
	msg += "|F:[fail_counts.Join(",")]"
	return ..()

/datum/controller/subsystem/garbage/Shutdown()
	//Adds the del() log to the qdel log file
	var/list/dellog = list()

	//sort by how long it's wasted hard deleting
	sortTim(items, cmp = GLOBAL_PROC_REF(cmp_qdel_item_time), associative = TRUE)
	for(var/path in items)
		var/datum/qdel_item/I = items[path]
		dellog += "Path: [path]"
		if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			dellog += "\tSUSPENDED FOR LAG"
		if (I.failures)
			dellog += "\tFailures: [I.failures]"
		dellog += "\tqdel() Count: [I.qdels]"
		dellog += "\tDestroy() Cost: [I.destroy_time]ms"
		if (I.hard_deletes)
			dellog += "\tTotal Hard Deletes [I.hard_deletes]"
			dellog += "\tTime Spent Hard Deleting: [I.hard_delete_time]ms"
			dellog += "\tHighest Time Spent Hard Deleting: [I.hard_delete_max]ms"
			if (I.hard_deletes_over_threshold)
				dellog += "\tHard Deletes Over Threshold: [I.hard_deletes_over_threshold]"
		if (I.slept_destroy)
			dellog += "\tSleeps: [I.slept_destroy]"
		if (I.no_respect_force)
			dellog += "\tIgnored force: [I.no_respect_force] times"
		if (I.no_hint)
			dellog += "\tNo hint: [I.no_hint] times"
		if(LAZYLEN(I.extra_details))
			var/details = I.extra_details.Join("</li><li>")
			dellog += "<li>Extra Info: <ul><li>[details]</li></ul>"

	log_qdel(dellog.Join("\n"))

/datum/controller/subsystem/garbage/fire()
	//the fact that this resets its processing each fire (rather then resume where it left off) is intentional.
	var/queue = GC_QUEUE_FILTER

	while (state == SS_RUNNING)
		switch (queue)
			if (GC_QUEUE_FILTER)
				HandleQueue(GC_QUEUE_FILTER)
				queue = GC_QUEUE_FILTER+1
			if (GC_QUEUE_CHECK)
				HandleQueue(GC_QUEUE_CHECK)
				queue = GC_QUEUE_CHECK+1
			if (GC_QUEUE_HARDDELETE)
				HandleQueue(GC_QUEUE_HARDDELETE)
				if (state == SS_PAUSED) //make us wait again before the next run.
					state = SS_RUNNING
				break

/datum/controller/subsystem/garbage/proc/InitQueues()
	if (isnull(queues)) // Only init the queues if they don't already exist, prevents overriding of recovered lists
		queues = new(GC_QUEUE_COUNT)
		pass_counts = new(GC_QUEUE_COUNT)
		fail_counts = new(GC_QUEUE_COUNT)
		for(var/i in 1 to GC_QUEUE_COUNT)
			queues[i] = list()
			pass_counts[i] = 0
			fail_counts[i] = 0

/datum/controller/subsystem/garbage/proc/HandleQueue(level = GC_QUEUE_FILTER)
	if (level == GC_QUEUE_FILTER)
		delslasttick = 0
		gcedlasttick = 0
	var/cut_off_time = world.time - collection_timeout[level] //ignore entries newer then this
	var/list/queue = queues[level]
	var/static/lastlevel
	var/static/count = 0
	if (count) //runtime last run before we could do this.
		var/c = count
		count = 0 //so if we runtime on the Cut, we don't try again.
		var/list/lastqueue = queues[lastlevel]
		lastqueue.Cut(1, c+1)

	lastlevel = level

// 1 from the hard reference in the queue, and 1 from the variable used before this
#define REFS_WE_EXPECT 2

	//We do this rather then for(var/list/ref_info in queue) because that sort of for loop copies the whole list.
	//Normally this isn't expensive, but the gc queue can grow to 40k items, and that gets costly/causes overrun.
	for(var/i in 1 to length(queue))
		var/list/L = queue[i]
		if(length(L) < GC_QUEUE_ITEM_INDEX_COUNT)
			count++
			if (MC_TICK_CHECK)
				break
			continue

		var/queued_at_time = L[GC_QUEUE_ITEM_QUEUE_TIME]
		if(queued_at_time > cut_off_time)
			break // Everything else is newer, skip them
		count++

		var/datum/D = L[GC_QUEUE_ITEM_REF]

		// 1 from the hard reference in the queue, and 1 from the variable used before this
		// If that's all we've got, send er off
		if(refcount(D) == REFS_WE_EXPECT)
			++gcedlasttick
			++totalgcs
			pass_counts[level]++
			#ifdef REFERENCE_TRACKING
			reference_find_on_fail -= text_ref(D)	//It's deleted we don't care anymore.
			#endif
			if (MC_TICK_CHECK)
				break
			continue

		#ifdef REFERENCE_TRACKING
		var/ref_searching = FALSE
		#endif

		// Something's still referring to the qdel'd object.
		fail_counts[level]++
		switch(level)
			if(GC_QUEUE_CHECK)
				#ifdef REFERENCE_TRACKING
				// Decides how many refs to look for (potentially)
				// Based off the remaining and the ones we can account for
				var/remaining_refs = refcount(D) - REFS_WE_EXPECT
				if(reference_find_on_fail[text_ref(D)])
					INVOKE_ASYNC(D, TYPE_PROC_REF(/datum,find_references), remaining_refs)
					ref_searching = TRUE
				#ifdef GC_FAILURE_HARD_LOOKUP
				else
					INVOKE_ASYNC(D, TYPE_PROC_REF(/datum,find_references), remaining_refs)
					ref_searching = TRUE
				#endif
				reference_find_on_fail -= text_ref(D)
				#endif
				var/type = D.type
				var/datum/qdel_item/I = items[type]

				var/message = "## TESTING: GC: -- [text_ref(D)] | [type] was unable to be GC'd --"
				message = "[message] (ref count of [refcount(D)])"
				log_world(message)

				#ifdef TESTING
				for(var/c in GLOB.admins) //Using testing() here would fill the logs with ADMIN_VV garbage
					var/client/admin = c
					if(!check_rights_for(admin, R_ADMIN))
						continue
					to_chat(admin, "## TESTING: GC: -- [ADMIN_VV(D)] | [type] was unable to be GC'd --")
				#endif
				I.failures++
				if(I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
					#ifdef REFERENCE_TRACKING
					if(ref_searching)
						return //ref searching intentionally cancels all further fires while running so things that hold references don't end up getting deleted, so we want to return here instead of continue
					#endif
					continue
			if(GC_QUEUE_HARDDELETE)
				if(!HardDelete(D))
					D = null
				if (MC_TICK_CHECK)
					break
				continue

		Queue(D, level+1)

		#ifdef REFERENCE_TRACKING
		if(ref_searching)
			return
		#endif

		if(MC_TICK_CHECK)
			break
	if(count)
		queue.Cut(1,count+1)
		count = 0

#undef REFS_WE_EXPECT

/datum/controller/subsystem/garbage/proc/Queue(datum/D, level = GC_QUEUE_FILTER)
	if (isnull(D))
		return
	if (level > GC_QUEUE_COUNT)
		HardDelete(D)
		return

	var/queue_time = world.time

	if (D.gc_destroyed <= 0)
		D.gc_destroyed = queue_time

	var/list/queue = queues[level]

	queue[++queue.len] = list(queue_time, D, D.gc_destroyed) // not += for byond reasons

//this is mainly to separate things profile wise.
/datum/controller/subsystem/garbage/proc/HardDelete(datum/D, override = FALSE)
	if(!D)
		return
	if(!enable_hard_deletes && !override)
		failed_hard_deletes |= D
		return
	++delslasttick
	++totaldels
	var/type = D.type
	var/refID = text_ref(D)
	var/datum/qdel_item/type_info = items[type]
	var/detail = D.dump_harddel_info()
	if(detail)
		LAZYADD(type_info.extra_details, detail)

	var/tick_usage = TICK_USAGE
	del(D)
	tick_usage = TICK_USAGE_TO_MS(tick_usage)

	type_info.hard_deletes++
	type_info.hard_delete_time += tick_usage
	if(tick_usage > type_info.hard_delete_max)
		type_info.hard_delete_max = tick_usage
	if(tick_usage > highest_del_ms)
		highest_del_ms = tick_usage
		highest_del_type_string = "[type]"

	var/time = MS2DS(tick_usage)

	if(time > 0.1 SECONDS)
		postpone(time)
	var/threshold = CONFIG_GET(number/hard_deletes_overrun_threshold)
	if(threshold && (time > threshold SECONDS))
		if(!(type_info.qdel_flags & QDEL_ITEM_ADMINS_WARNED))
			log_game("Error: [type]([refID]) took longer than [threshold] seconds to delete (took [round(time/10, 0.1)] seconds to delete)")
			message_admins("Error: [type]([refID]) took longer than [threshold] seconds to delete (took [round(time/10, 0.1)] seconds to delete).")
			type_info.qdel_flags |= QDEL_ITEM_ADMINS_WARNED
		type_info.hard_deletes_over_threshold++
		var/overrun_limit = CONFIG_GET(number/hard_deletes_overrun_limit)
		if(overrun_limit && type_info.hard_deletes_over_threshold >= overrun_limit)
			type_info.qdel_flags |= QDEL_ITEM_SUSPENDED_FOR_LAG

/datum/controller/subsystem/garbage/Recover()
	InitQueues()
	if (istype(SSgarbage.queues))
		for (var/i in 1 to length(SSgarbage.queues))
			queues[i] |= SSgarbage.queues[i]

/// Qdel Item: Holds statistics on each type that passes thru qdel
/datum/qdel_item
	var/name = "" //!Holds the type as a string for this type
	var/qdels = 0 //!Total number of times it's passed thru qdel.
	var/destroy_time = 0 //!Total amount of milliseconds spent processing this type's Destroy()
	var/failures = 0 //!Times it was queued for soft deletion but failed to soft delete.
	var/hard_deletes = 0 //!Different from failures because it also includes QDEL_HINT_HARDDEL deletions
	var/hard_delete_time = 0 //!Total amount of milliseconds spent hard deleting this type.
	var/hard_delete_max = 0 //!Highest time spent hard_deleting this in ms.
	var/hard_deletes_over_threshold = 0 //!Number of times hard deletes took longer than the configured threshold
	var/no_respect_force = 0 //!Number of times it's not respected force=TRUE
	var/no_hint = 0 //!Number of times it's not even bother to give a qdel hint
	var/slept_destroy = 0 //!Number of times it's slept in its destroy
	var/qdel_flags = 0 //!Flags related to this type's trip thru qdel.
	var/list/extra_details //!Lazylist of string metadata about the deleted objects

/datum/qdel_item/New(mytype)
	name = "[mytype]"

/// Should be treated as a replacement for the 'del' keyword.
///
/// Datums passed to this will be given a chance to clean up references to allow the GC to collect them.
/proc/qdel(datum/to_delete, force = FALSE, ...)
	if(!istype(to_delete))
		del(to_delete)
		return

	var/datum/qdel_item/trash = SSgarbage.items[to_delete.type]
	if (isnull(trash))
		trash = SSgarbage.items[to_delete.type] = new /datum/qdel_item(to_delete.type)
	trash.qdels++

	if(!isnull(to_delete.gc_destroyed))
		if(to_delete.gc_destroyed == GC_CURRENTLY_BEING_QDELETED)
			CRASH("[to_delete.type] destroy proc was called multiple times, likely due to a qdel loop in the Destroy logic")
		return

	if (SEND_SIGNAL(to_delete, COMSIG_PARENT_PREQDELETED, force)) // Give the components a chance to prevent their parent from being deleted
		return

	to_delete.gc_destroyed = GC_CURRENTLY_BEING_QDELETED
	var/start_time = world.time
	var/start_tick = world.tick_usage
	SEND_SIGNAL(to_delete, COMSIG_PARENT_QDELETING, force) // Let the (remaining) components know about the result of Destroy
	var/hint = to_delete.Destroy(arglist(args.Copy(2))) // Let our friend know they're about to get fucked up.

	if(world.time != start_time)
		trash.slept_destroy++
	else
		trash.destroy_time += TICK_USAGE_TO_MS(start_tick)

	if(isnull(to_delete))
		return

	switch(hint)
		if (QDEL_HINT_QUEUE) //qdel should queue the object for deletion.
			SSgarbage.Queue(to_delete)
		if (QDEL_HINT_IWILLGC)
			to_delete.gc_destroyed = world.time
			return
		if (QDEL_HINT_LETMELIVE) //qdel should let the object live after calling destory.
			if(!force)
				to_delete.gc_destroyed = null //clear the gc variable (important!)
				return
			// Returning LETMELIVE after being told to force destroy
			// indicates the objects Destroy() does not respect force
			#ifdef TESTING
			if(!trash.no_respect_force)
				testing("WARNING: [to_delete.type] has been force deleted, but is \
					returning an immortal QDEL_HINT, indicating it does \
					not respect the force flag for qdel(). It has been \
					placed in the queue, further instances of this type \
					will also be queued.")
			#endif
			trash.no_respect_force++

			SSgarbage.Queue(to_delete)
		if (QDEL_HINT_HARDDEL) //qdel should assume this object won't gc, and queue a hard delete
			SSgarbage.Queue(to_delete, GC_QUEUE_HARDDELETE)
		if (QDEL_HINT_HARDDEL_NOW) //qdel should assume this object won't gc, and hard del it post haste.
			SSgarbage.HardDelete(to_delete)
		#ifdef REFERENCE_TRACKING
		if (QDEL_HINT_FINDREFERENCE) //qdel will, if REFERENCE_TRACKING is enabled, display all references to this object, then queue the object for deletion.
			SSgarbage.Queue(to_delete)
			INVOKE_ASYNC(to_delete, TYPE_PROC_REF(/datum, find_references))
		if (QDEL_HINT_IFFAIL_FINDREFERENCE) //qdel will, if REFERENCE_TRACKING is enabled and the object fails to collect, display all references to this object.
			SSgarbage.Queue(to_delete)
			SSgarbage.reference_find_on_fail[text_ref(to_delete)] = TRUE
		#endif
		else
			#ifdef TESTING
			if(!trash.no_hint)
				testing("WARNING: [to_delete.type] is not returning a qdel hint. It is being placed in the queue. Further instances of this type will also be queued.")
			#endif
			trash.no_hint++
			SSgarbage.Queue(to_delete)
