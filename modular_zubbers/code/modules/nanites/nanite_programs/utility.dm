//Programs that interact with other programs or nanites directly, or have other special purposes.
/datum/nanite_program/viral
	name = "Viral Replica"
	desc = "The nanites constantly send encrypted signals attempting to forcefully copy their own programming into other nanite clusters, also overriding or disabling their cloud sync."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/toxic)
	var/pulse_cooldown = 0

/datum/nanite_program/viral/register_extra_settings()
	extra_settings[NES_PROGRAM_OVERWRITE] = new /datum/nanite_extra_setting/type("Add To", list("Overwrite", "Add To", "Ignore"))
	extra_settings[NES_CLOUD_OVERWRITE] = new /datum/nanite_extra_setting/number(0, 0, 100)

/datum/nanite_program/viral/active_effect()
	if(world.time < pulse_cooldown)
		return
	var/datum/nanite_extra_setting/program = extra_settings[NES_PROGRAM_OVERWRITE]
	var/datum/nanite_extra_setting/cloud = extra_settings[NES_CLOUD_OVERWRITE]
	for(var/mob/M in orange(host_mob, 5))
		if(SEND_SIGNAL(M, COMSIG_NANITE_IS_STEALTHY))
			continue
		switch(program.get_value())
			if("Overwrite")
				SEND_SIGNAL(M, COMSIG_NANITE_SYNC, nanites, TRUE)
			if("Add To")
				SEND_SIGNAL(M, COMSIG_NANITE_SYNC, nanites, FALSE)
		SEND_SIGNAL(M, COMSIG_NANITE_SET_CLOUD, cloud.get_value())
	pulse_cooldown = world.time + 75

/datum/nanite_program/monitoring
	name = "Monitoring"
	desc = "The nanites monitor the host's vitals and location, sending them to the suit sensor network."
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/monitoring/enable_passive_effect()
	. = ..()
	ADD_TRAIT(host_mob, TRAIT_NANITE_MONITORING, NANITES_TRAIT) //Shows up in diagnostic and medical HUDs as a small blinking icon
	if(ishuman(host_mob))
		GLOB.nanite_sensors_list |= host_mob
	host_mob.hud_set_nanite_indicator()

/datum/nanite_program/monitoring/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_NANITE_MONITORING, "nanites")
	if(ishuman(host_mob))
		GLOB.nanite_sensors_list -= host_mob

	host_mob.hud_set_nanite_indicator()

/datum/nanite_program/self_scan
	name = "Host Scan"
	desc = "The nanites display a detailed readout of a body scan to the host."
	unique = FALSE
	can_trigger = TRUE
	trigger_cost = 3
	trigger_cooldown = 50
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/self_scan/register_extra_settings()
	extra_settings[NES_SCAN_TYPE] = new /datum/nanite_extra_setting/type("Medical", list("Medical", "Chemical", "Wound", "Nanite"))

/datum/nanite_program/self_scan/on_trigger(comm_message)
	if(host_mob.stat == DEAD)
		return
	var/datum/nanite_extra_setting/NS = extra_settings[NES_SCAN_TYPE]
	switch(NS.get_value())
		if("Medical")
			healthscan(host_mob, host_mob)
		if("Chemical")
			chemscan(host_mob, host_mob)
		if("Wound")
			woundscan(host_mob, host_mob)
		if("Nanite")
			SEND_SIGNAL(host_mob, COMSIG_NANITE_SCAN, host_mob, TRUE)

/datum/nanite_program/stealth
	name = "Stealth"
	desc = "The nanites mask their activity from superficial scans, becoming undetectable by HUDs and non-specialized scanners."
	rogue_types = list(/datum/nanite_program/toxic)
	use_rate = 0.2

/datum/nanite_program/stealth/enable_passive_effect()
	. = ..()
	nanites.stealth = TRUE

/datum/nanite_program/stealth/disable_passive_effect()
	. = ..()
	nanites.stealth = FALSE

/datum/nanite_program/nanite_debugging
	name = "Nanite Debugging"
	desc = "Enables various high-cost diagnostics in the nanites, making them able to communicate their program list to portable scanners. \
			Doing so uses some power, slightly decreasing their replication speed."
	rogue_types = list(/datum/nanite_program/toxic)
	use_rate = 0.1

/datum/nanite_program/nanite_debugging/enable_passive_effect()
	. = ..()
	nanites.diagnostics = TRUE

/datum/nanite_program/nanite_debugging/disable_passive_effect()
	. = ..()
	nanites.diagnostics = FALSE

/datum/nanite_program/relay
	name = "Relay"
	desc = "The nanites receive and relay long-range nanite signals."
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/relay/register_extra_settings()
	extra_settings[NES_RELAY_CHANNEL] = new /datum/nanite_extra_setting/number(1, 1, 9999)

/datum/nanite_program/relay/enable_passive_effect()
	. = ..()
	SSnanites.nanite_relays |= src

/datum/nanite_program/relay/disable_passive_effect()
	. = ..()
	SSnanites.nanite_relays -= src

/datum/nanite_program/relay/proc/relay_signal(code, relay_code, source)
	if(!activated)
		return
	if(!host_mob)
		return
	var/datum/nanite_extra_setting/NS = extra_settings[NES_RELAY_CHANNEL]
	if(relay_code != NS.get_value())
		return
	SEND_SIGNAL(host_mob, COMSIG_NANITE_SIGNAL, code, source)

/datum/nanite_program/relay/proc/relay_comm_signal(comm_code, relay_code, comm_message)
	if(!activated)
		return
	if(!host_mob)
		return
	var/datum/nanite_extra_setting/NS = extra_settings[NES_RELAY_CHANNEL]
	if(relay_code != NS.get_value())
		return
	SEND_SIGNAL(host_mob, COMSIG_NANITE_COMM_SIGNAL, comm_code, comm_message)

/datum/nanite_program/metabolic_synthesis
	name = "Metabolic Synthesis"
	desc = "The nanites use the metabolic cycle of the host to speed up their replication rate, using their extra nutrition as fuel."
	use_rate = -0.5 //generates nanites
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/metabolic_synthesis/check_conditions()
	if(!iscarbon(host_mob))
		return FALSE
	var/mob/living/carbon/C = host_mob
	if(C.nutrition <= NUTRITION_LEVEL_WELL_FED)
		return FALSE
	return ..()

/datum/nanite_program/metabolic_synthesis/active_effect()
	host_mob.adjust_nutrition(-0.5)

/datum/nanite_program/access
	name = "Subdermal ID"
	desc = "The nanites store the host's ID access rights in a subdermal magnetic strip. Updates when triggered, copying the host's current access."
	can_trigger = TRUE
	trigger_cost = 3
	trigger_cooldown = 30
	rogue_types = list(/datum/nanite_program/skin_decay)
	var/access = list()

//Syncs the nanites with the cumulative current mob's access level. Can potentially wipe existing access.
/datum/nanite_program/access/on_trigger(comm_message)
	var/list/potential_items = list()

	potential_items += host_mob.get_active_held_item()
	potential_items += host_mob.get_inactive_held_item()
	potential_items += host_mob.pulling

	if(ishuman(host_mob))
		var/mob/living/carbon/human/H = host_mob
		potential_items += H.wear_id
	else if(isanimal(host_mob))
		var/mob/living/simple_animal/A = host_mob
		potential_items += A.access_card

	var/list/new_access = list()
	for(var/obj/item/I in potential_items)
		new_access += I.GetAccess()

	access = new_access

/datum/nanite_program/spreading
	name = "Infective Exo-Locomotion"
	desc = "The nanites gain the ability to survive for brief periods outside of the human body, as well as the ability to start new colonies without an integration process; \
			resulting in an extremely infective strain of nanites."
	use_rate = 1.50
	rogue_types = list(/datum/nanite_program/aggressive_replication, /datum/nanite_program/necrotic)
	var/spread_cooldown = 0

/datum/nanite_program/spreading/active_effect()
	if(world.time < spread_cooldown)
		return
	spread_cooldown = world.time + 50
	var/list/mob/living/target_hosts = list()
	for(var/mob/living/L in oview(5, host_mob))
		if(!prob(25))
			continue
		if(!CAN_HAVE_NANITES(L))
			continue
		target_hosts += L
	if(!target_hosts.len)
		return
	var/mob/living/infectee = pick(target_hosts)
	if(prob(100 - infectee.getarmor(null, BIO)))
		//this will potentially take over existing nanites!
		infectee.AddComponent(/datum/component/nanites, 10)
		SEND_SIGNAL(infectee, COMSIG_NANITE_SYNC, nanites)
		SEND_SIGNAL(infectee, COMSIG_NANITE_SET_CLOUD, nanites.cloud_id)
		infectee.investigate_log("was infected by spreading nanites with cloud ID [nanites.cloud_id] by [key_name(host_mob)] at [AREACOORD(infectee)].", INVESTIGATE_NANITES)

/datum/nanite_program/nanite_sting
	name = "Nanite Sting"
	desc = "When triggered, builds a invisible spikes of nanites on the host's skin that \
			can infect a nearby non-host with a copy of the host's nanites cluster \
			that is unlinked from the cloud. \
			Will not work on hosts or those already infected."
	can_trigger = TRUE
	trigger_cost = 5
	trigger_cooldown = 100
	rogue_types = list(/datum/nanite_program/glitch, /datum/nanite_program/toxic)
	var/decay_timer

/datum/nanite_program/nanite_sting/Destroy()
	. = ..()
	if(!decay_timer)
		return
	decay_sting()

/datum/nanite_program/nanite_sting/on_trigger(comm_message)
	consume_nanites(-15)
	to_chat(host_mob, span_warning("Your hands becomes sharp and prickly."))
	RegisterSignal(host_mob, COMSIG_LIVING_EARLY_UNARMED_ATTACK, PROC_REF(on_attack_hand))
	decay_timer = addtimer(CALLBACK(src, PROC_REF(decay_sting)), 30 SECONDS, TIMER_STOPPABLE)

/datum/nanite_program/nanite_sting/proc/on_attack_hand(atom/source, mob/user, modifiers)
	SIGNAL_HANDLER
	var/mob/living/living = source
	if(!istype(living)) return
	if(!CAN_HAVE_NANITES(living) || SEND_SIGNAL(living, COMSIG_HAS_NANITES) || !living.Adjacent(host_mob)) return

	if(prob(100 - living.getarmor(null, BIO)))
		//unlike with Infective Exo-Locomotion, this can't take over existing nanites, because Nanite Sting only targets non-hosts.
		living.AddComponent(/datum/component/nanites, 5)
		SEND_SIGNAL(living, COMSIG_NANITE_SYNC, nanites)
		// SEND_SIGNAL(living, COMSIG_NANITE_SET_CLOUD, nanites.cloud_id) won't set the cloud
		// SEND_SIGNAL(living, COMSIG_NANITE_SET_CLOUD_SYNC, NANITE_CLOUD_DISABLE)
		living.investigate_log("was infected by a nanite cluster with cloud ID [nanites.cloud_id] by [key_name(host_mob)] at [AREACOORD(living)].", INVESTIGATE_NANITES)
		to_chat(living, span_warning("You feel a tiny prick."))
	decay_sting()

/datum/nanite_program/nanite_sting/proc/decay_sting()
	to_chat(host_mob, span_warning("Your hands no longer feel like they're covered in spines."))
	deltimer(decay_timer)
	decay_timer = null
	UnregisterSignal(host_mob, COMSIG_LIVING_EARLY_UNARMED_ATTACK)

/datum/nanite_program/mitosis
	name = "Mitosis"
	desc = "The nanites gain the ability to self-replicate, using bluespace to power the process. Becomes more effective the more nanites are already in the host; \
			For every 50 nanite volume in the host, the production rate is increased by 0.5. The replication has also a chance to corrupt the nanite programming \
			due to copy faults - constant cloud sync is highly recommended."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/mitosis/active_effect()
	var/rep_rate = round(nanites.nanite_volume / 50, 1) //0.5 per 50 nanite volume
	rep_rate *= 0.5
	nanites.adjust_nanites(null, rep_rate)
	if(prob(rep_rate))
		var/datum/nanite_program/fault = pick(nanites.programs)
		if(fault == src)
			return
		fault.software_error()
		host_mob.investigate_log("[fault] nanite program received a software error due to Mitosis program.", INVESTIGATE_NANITES)

/datum/nanite_program/dermal_button
	name = "Dermal Button"
	desc = "Displays a button on the host's skin, which can be used to send a signal to the nanites."
	unique = FALSE
	var/datum/action/innate/nanite_button/button

/datum/nanite_program/dermal_button/register_extra_settings()
	extra_settings[NES_SENT_CODE] = new /datum/nanite_extra_setting/number(1, 1, 9999)
	extra_settings[NES_BUTTON_NAME] = new /datum/nanite_extra_setting/text("Button")
	extra_settings[NES_ICON] = new /datum/nanite_extra_setting/type("power", list("blank","one","two","three","four","five","plus","minus","exclamation","question","cross","info","heart","skull","brain","brain_damage","injection","blood","shield","reaction","network","power","radioactive","electricity","magnetism","scan","repair","id","wireless","say","sleep","bomb"))

/datum/nanite_program/dermal_button/enable_passive_effect()
	. = ..()
	var/datum/nanite_extra_setting/bn_name = extra_settings[NES_BUTTON_NAME]
	var/datum/nanite_extra_setting/bn_icon = extra_settings[NES_ICON]
	if(!button)
		button = new(src, bn_name.get_value(), bn_icon.get_value())
	button.target = host_mob
	button.Grant(host_mob)

/datum/nanite_program/dermal_button/disable_passive_effect()
	. = ..()
	if(button)
		button.Remove(host_mob)

/datum/nanite_program/dermal_button/on_mob_remove()
	. = ..()
	QDEL_NULL(button)

/datum/nanite_program/dermal_button/proc/press()
	if(activated)
		host_mob.visible_message(span_notice("[host_mob] presses a button on [host_mob.p_their()] forearm."),
								span_notice("You press the nanite button on your forearm."), null, 2)
		var/datum/nanite_extra_setting/sent_code = extra_settings[NES_SENT_CODE]
		SEND_SIGNAL(host_mob, COMSIG_NANITE_SIGNAL, sent_code.get_value(), "a [name] program")

/datum/action/innate/nanite_button
	name = "Button"
	button_icon = 'icons/mob/actions/actions_items.dmi'
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_CONSCIOUS
	button_icon_state = "bci_power"
	var/datum/nanite_program/dermal_button/program

/datum/action/innate/nanite_button/New(datum/nanite_program/dermal_button/_program, _name, _icon)
	..()
	program = _program
	name = _name
	button_icon_state = "bci_[_icon]"

/datum/action/innate/nanite_button/Activate()
	program.press()
