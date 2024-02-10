/datum/action/ability/activable/xeno/proc/acid_puddle(atom/A, atom/OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/X = owner
	new/obj/effect/temp_visual/xenomorph/afterimage(get_turf(X), X)
	new /obj/effect/xenomorph/spray(get_turf(X), 15 SECONDS, X.acid_charge_damage)
	for(var/obj/O in get_turf(X))
		O.afterimage_act(X)
		O.acid_spray_act(X)
		playsound(X, "alien_footstep_large", 50)

/datum/action/ability/activable/xeno/proc/afterimage(atom/A, atom/OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/X = owner
	new/obj/effect/temp_visual/xenomorph/afterimage(get_turf(X), X)
	for(var/obj/O in get_turf(X))
		O.afterimage_act(X)
		playsound(X, "alien_footstep_large", 50)

// ***************************************
// *********** Acid Charge
// ***************************************
/datum/action/ability/activable/xeno/acid_charge
	name = "Acid Charge"
	action_icon_state = "bull_charge"
	desc = "The acid charge, deal small damage to yourself and start leaving acid puddles after your steps."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_ACIDCHARGE,
	)
	cooldown_duration = 30 SECONDS
	var/charge_duration
	var/obj/effect/abstract/particle_holder/particle_holder

/particles/bull_selfslash
	icon = 'icons/effects/effects.dmi'
	icon_state = "redslash"
	scale = 1.3
	count = 1
	spawning = 1
	lifespan = 4
	fade = 4
	rotation = -160
	friction = 0.6

/datum/action/ability/activable/xeno/acid_charge/use_ability()
	var/mob/living/carbon/xenomorph/X = owner
	if(!do_after(X, 10, NONE, X, BUSY_ICON_DANGER))
		if(!X.stat)
			X.set_canmove(TRUE)
		return fail_activate()
	X.apply_damage(40, BRUTE, TRUE, updating_health = TRUE)
	particle_holder = new(X, /particles/bull_selfslash)
	particle_holder.pixel_y = 12
	particle_holder.pixel_x = 18
	START_PROCESSING(SSprocessing, src)
	QDEL_NULL_IN(src, particle_holder, 5)
	playsound(X,'sound/weapons/alien_bite1.ogg', 75, 1)
	X.emote("hiss")
	X.set_canmove(TRUE)
	X.add_movespeed_modifier(MOVESPEED_ID_BULL_CHARGE, TRUE, 0, NONE, TRUE, X.xeno_caste.speed * 1.3)
	charge_duration = addtimer(CALLBACK(src, PROC_REF(acid_charge_deactivate)), 3 SECONDS,  TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)
	RegisterSignals(X, list(COMSIG_MOB_CLICK_RIGHT, COMSIG_MOB_MIDDLE_CLICK), PROC_REF(acid_charge_deactivate))
	RegisterSignal(X, COMSIG_MOVABLE_MOVED, PROC_REF(acid_puddle))
	X.icon_state = "[X.xeno_caste.caste_name][X.is_a_rouny ? " rouny" : ""] Charging"

	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/acid_charge/proc/acid_charge_deactivate()
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/X = owner
	X.remove_movespeed_modifier(MOVESPEED_ID_BULL_CHARGE)
	X.update_icons()

	UnregisterSignal(owner, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_MOB_CLICK_RIGHT,
		COMSIG_MOB_MIDDLE_CLICK,))

// ***************************************
// *********** Headbutt Charge
// ***************************************
/datum/action/ability/activable/xeno/headbutt
	name = "Headbutt Charge"
	action_icon_state = "bull_headbutt"
	desc = "The headbutt charge, when it hits a host, stops your charge while push them away."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLHEADBUTT,
	)
	var/turf/last_turf
	cooldown_duration = 15 SECONDS
	var/charge_duration

/datum/action/ability/activable/xeno/headbutt/use_ability()
	var/mob/living/carbon/xenomorph/X = owner
	if(!do_after(X, 10, NONE, X, BUSY_ICON_DANGER))
		if(!X.stat)
			X.set_canmove(TRUE)
		return fail_activate()
	X.emote("roar")
	X.set_canmove(TRUE)
	X.add_movespeed_modifier(MOVESPEED_ID_BULL_CHARGE, TRUE, 0, NONE, TRUE, X.xeno_caste.speed * 1.3)
	charge_duration = addtimer(CALLBACK(src, PROC_REF(headbutt_charge_deactivate)), 3 SECONDS, TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)
	RegisterSignals(X, list(COMSIG_MOB_CLICK_RIGHT, COMSIG_MOB_MIDDLE_CLICK), PROC_REF(headbutt_charge_deactivate))
	RegisterSignal(X, COMSIG_LIVING_STATUS_STAGGER, PROC_REF(headbutt_charge_deactivate))
	RegisterSignal(X, COMSIG_XENOMORPH_ATTACK_LIVING, PROC_REF(bull_charge_slash))
	RegisterSignal(X, COMSIG_MOVABLE_MOVED, PROC_REF(afterimage))
	X.icon_state = "[X.xeno_caste.caste_name][X.is_a_rouny ? " rouny" : ""] Charging"

	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/headbutt/proc/bull_charge_slash(datum/source, mob/living/target, damage, list/damage_mod)
	var/mob/living/carbon/xenomorph/X = owner
	var/headbutt_throw_range = 6

	target.knockback(X, headbutt_throw_range, 1)
	target.Paralyze(1 SECONDS)

	playsound(target,'sound/weapons/alien_knockdown.ogg', 75, 1)
	X.visible_message(span_danger("[X] pushed away [target]!"),
		span_xenowarning("We push away [target] and skid to a halt!"))
	headbutt_charge_deactivate()

/datum/action/ability/activable/xeno/headbutt/proc/headbutt_charge_deactivate()
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/X = owner
	X.remove_movespeed_modifier(MOVESPEED_ID_BULL_CHARGE)
	X.update_icons()

	UnregisterSignal(owner, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_MOB_CLICK_RIGHT,
		COMSIG_MOB_MIDDLE_CLICK,
		COMSIG_LIVING_STATUS_STAGGER,))

// ***************************************
// *********** Gore Charge
// ***************************************
/datum/action/ability/activable/xeno/gore
	name = "Gore Charge"
	action_icon_state = "bull_gore"
	desc = "The gore charge, when it hits a host, stops your charge while dealing a large amount of damage."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLGORE,
	)
	var/turf/last_turf
	cooldown_duration = 5 SECONDS
	var/charge_duration

/datum/action/ability/activable/xeno/gore/use_ability()
	var/mob/living/carbon/xenomorph/X = owner
	if(!do_after(X, 5, NONE, X, BUSY_ICON_DANGER))
		if(!X.stat)
			X.set_canmove(TRUE)
		return fail_activate()
	X.emote("roar")
	X.set_canmove(TRUE)
	X.add_movespeed_modifier(MOVESPEED_ID_BULL_CHARGE, TRUE, 0, NONE, TRUE, X.xeno_caste.speed * 1.3)
	charge_duration = addtimer(CALLBACK(src, PROC_REF(gore_charge_deactivate)), 2 SECONDS, TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)
	RegisterSignals(X, list(COMSIG_MOB_CLICK_RIGHT, COMSIG_MOB_MIDDLE_CLICK), PROC_REF(gore_charge_deactivate))
	RegisterSignal(X, COMSIG_LIVING_STATUS_STAGGER, PROC_REF(gore_charge_deactivate))
	RegisterSignal(X, COMSIG_XENOMORPH_ATTACK_LIVING, PROC_REF(bull_charge_slash))
	RegisterSignal(X, COMSIG_MOVABLE_MOVED, PROC_REF(afterimage))
	X.icon_state = "[X.xeno_caste.caste_name][X.is_a_rouny ? " rouny" : ""] Charging"

	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/gore/proc/bull_charge_slash(datum/source, mob/living/target, damage, list/damage_mod)
	var/mob/living/carbon/xenomorph/X = owner
	damage = X.xeno_caste.melee_damage * X.xeno_melee_damage_modifier * 4
	target.apply_damage(damage, BRUTE, X.zone_selected, MELEE)
	playsound(target,'sound/weapons/alien_tail_attack.ogg', 75, 1)
	target.emote_gored()
	X.visible_message(span_danger("[X] gores [target]!"),
		span_xenowarning("We gore [target] and skid to a halt!"))
	gore_charge_deactivate()

/datum/action/ability/activable/xeno/gore/proc/gore_charge_deactivate()
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/X = owner
	X.remove_movespeed_modifier(MOVESPEED_ID_BULL_CHARGE)
	X.update_icons()

	UnregisterSignal(owner, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_MOB_CLICK_RIGHT,
		COMSIG_MOB_MIDDLE_CLICK,
		COMSIG_LIVING_STATUS_STAGGER,))

// ***************************************
// *********** Shattering Charge
// ***************************************

/datum/action/ability/activable/xeno/shattering_charge
	name = "Shattering Charge"
	action_icon_state = "bull_ready_charge"
	desc = "The shattering charge, when it hits a host, stops your charge while breaking up victim's item in hands."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLSHATTER,
	)
	var/turf/last_turf
	cooldown_duration = 480 SECONDS
	var/charge_duration
	var/obj/item/broken_item = FALSE
	var/should_cooldown_on_start = TRUE

/datum/action/ability/activable/xeno/shattering_charge/give_action(mob/living/X)
	. = ..()
	if(should_cooldown_on_start)
		add_cooldown()

/datum/action/ability/activable/xeno/shattering_charge/use_ability()
	var/mob/living/carbon/xenomorph/X = owner
	if(!do_after(X, 1 SECONDS, NONE, X, BUSY_ICON_DANGER))
		if(!X.stat)
			X.set_canmove(TRUE)
		return fail_activate()
	X.emote("roar")
	X.set_canmove(TRUE)
	X.add_movespeed_modifier(MOVESPEED_ID_BULL_CHARGE, TRUE, 0, NONE, TRUE, X.xeno_caste.speed * 1.3)
	charge_duration = addtimer(CALLBACK(src, PROC_REF(shattering_charge_deactivate)), 3 SECONDS, TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)
	RegisterSignals(X, list(COMSIG_MOB_CLICK_RIGHT, COMSIG_MOB_MIDDLE_CLICK), PROC_REF(shattering_charge_deactivate))
	RegisterSignal(X, COMSIG_XENOMORPH_ATTACK_LIVING, PROC_REF(bull_charge_slash))
	RegisterSignal(X, COMSIG_LIVING_STATUS_STAGGER, PROC_REF(shattering_charge_deactivate))
	RegisterSignal(X, COMSIG_MOVABLE_MOVED, PROC_REF(afterimage))
	X.icon_state = "[X.xeno_caste.caste_name][X.is_a_rouny ? " rouny" : ""] Charging"

	succeed_activate()
	add_cooldown()

/datum/action/ability/activable/xeno/shattering_charge/proc/bull_charge_slash(datum/source, mob/living/target, damage, list/damage_mod)
	var/mob/living/carbon/xenomorph/X = owner
	playsound(target,'sound/effects/metalhit.ogg', 75, 1)
	broken_item = target.get_active_held_item()
	broken_item.deconstruct(FALSE)
	X.visible_message(span_danger("[X] shatter [target]'s [broken_item]!"),
		span_xenowarning("We shatter [target]'s [broken_item] and skid to a halt!"))
	shattering_charge_deactivate()

/datum/action/ability/activable/xeno/shattering_charge/proc/shattering_charge_deactivate()
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/X = owner
	X.remove_movespeed_modifier(MOVESPEED_ID_BULL_CHARGE)
	X.update_icons()

	UnregisterSignal(owner, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_XENOMORPH_ATTACK_LIVING,
		COMSIG_MOB_CLICK_RIGHT,
		COMSIG_MOB_MIDDLE_CLICK,
		COMSIG_LIVING_STATUS_STAGGER,))
