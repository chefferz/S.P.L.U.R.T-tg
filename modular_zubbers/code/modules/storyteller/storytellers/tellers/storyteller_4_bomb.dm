/datum/storyteller/bomb
	name = "Bomb (Medium-High Chaos)"
	desc = "The Bomb will try to make more destructive events. For when you have a full engineering team. Or not, because they all cryo'd."
	welcome_text = "Somebody set up us the bomb."
	track_data = /datum/storyteller_data/tracks/bomb

	tag_multipliers = list(
		TAG_DESTRUCTIVE = 1.5
	)
	population_min = 25
	antag_divisor = 10
	storyteller_type = STORYTELLER_TYPE_INTENSE

/datum/storyteller_data/tracks/bomb
	threshold_mundane = 1800
	threshold_moderate = 1400
	threshold_major = 5500
