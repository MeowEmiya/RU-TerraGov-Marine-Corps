// ***************************************
// *********** Bull charge types
// ***************************************

/datum/action/ability/activable/xeno/bull_charge
	name = "Plow Charge"
	action_icon_state = "bull_charge"
	desc = "The plow charge is dealing damage and throws anyone hit out of your way."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLCHARGE,
	)
	var/new_charge_type = CHARGE_BULL
	cooldown_duration = 1  SECONDS


/datum/action/ability/activable/xeno/bull_charge/on_selection()
	SEND_SIGNAL(owner, COMSIG_XENOACTION_TOGGLECHARGETYPE, new_charge_type)

/datum/action/ability/activable/xeno/bull_charge/use_ability(atom/A)
	var/mob/living/carbon/xenomorph/X = owner
	X.face_atom(A)
	X.set_canmove(FALSE)
	owner.icon_state = "[X.xeno_caste.caste_name][X.is_a_rouny ? " rouny" : ""] Charging"
	if(!do_after(X, 5, NONE, X, BUSY_ICON_DANGER))
		if(!X.stat)
			X.set_canmove(TRUE)
		return fail_activate()
	X.set_canmove(TRUE)

	var/datum/action/ability/xeno_action/ready_charge/bull_charge/charge = X.actions_by_path[/datum/action/ability/xeno_action/ready_charge/bull_charge]
	var/aimdir = get_dir(X,A)
	var/mob/living/carbon/xenomorph/xeno = owner
	if(charge)
		charge.charge_on(FALSE)
		charge.valid_steps_taken = charge.max_steps_buildup - 1
		charge.charge_dir = aimdir
		X.emote("roar")
		X.stop_pulling()
	for(var/i=0 to get_dist(X, A))
		if(i % 2)
			playsound(X, "alien_footstep_large", 50)
			new /obj/effect/temp_visual/xenomorph/afterimage(get_turf(X), X)
		X.Move(get_step(X, aimdir), aimdir)
		aimdir = get_dir(X,A)
	charge.charge_off(FALSE)
	succeed_activate()
	add_cooldown()
	addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, update_icons)), 0.5 SECONDS)
	owner.icon_state = "[xeno.xeno_caste.caste_name][xeno.is_a_rouny ? " rouny" : ""] Charging"


/datum/action/ability/activable/xeno/bull_charge/headbutt
	name = "Headbutt Charge"
	action_icon_state = "bull_headbutt"
	desc = "The headbutt charge, when it hits a host, stops your charge while knocking them down stunned for some time."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLHEADBUTT,
	)
	new_charge_type = CHARGE_BULL_HEADBUTT
	cooldown_duration = 15  SECONDS

/datum/action/ability/activable/xeno/bull_charge/gore
	name = "Gore Charge"
	action_icon_state = "bull_gore"
	desc = "The gore charge, when it hits a host, stops your charge while dealing a large amount of damage where you are targeting."
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_BULLGORE,
	)
	new_charge_type = CHARGE_BULL_GORE
	cooldown_duration = 15 SECONDS
