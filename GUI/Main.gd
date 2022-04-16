extends Control

############################### METADATA ###############################
const app_name = "Entity-Playground"
const app_version = "v0.01"
const app_description = "A procedural cinematic dialogue generation tool created in Godot."

var welcome_message = """Welcome to {app_name} {app_version}.\n{app_description}\n""".format({"app_name":app_name, "app_version":app_version, "app_description":app_description})
	

############################### RNG VARIABLES ###############################
var rng = RandomNumberGenerator.new()
var rngHash = "Godot"

var rng_message = """The current RNG seed is a hash of the string: "{hash}"\nThe resulting RNG seed is: {seed}\n""".format({"hash":rngHash, "seed":rng.seed})

############################### PROGRAM STATE VARIABLES ###############################
var queueCheckForWorkTimerTimeoutCounter = 0
var approvalToGenerate = false
var jobQueue = []

var program_states = [
	"entering_entity_values", 
	"waiting_to_generate",
	"generating", 
	"generation_paused", 
	"conversation_completed"]
var current_program_state

#If all are true and current_program_state == entering_entity_values, the generate button becomes availiable.
var selection_filled_states = [false, false, false, false]




############################### OUTPUT VARIABLES ###############################
var baseIntroductionsDict = {
	"1" : """
	Two disembodied voices stumble across each other. 
	One, {entity1Name}, is {entity1Personality}. The other, {entity2Name}, is {entity2Personality}.
	"""
}

# Collection of 10 synonyms for every non-trivial word in each Action Concept Speech Dictionary.
# Only compatible strings of words will be stung together.
var speechDictSynonyms = {
	
}

############################### ENTITY VARIABLES ###############################
# The ability to choose physical attributes, environment, and abilities will be added in version 0.02  
var entities = {
	"Entity1" : {
		"Name" : [],
		"Personality" : [],
		"Physical" : ["Disembodied"],
		"Environment" : ["Empty-Void"],
		# "Abilities" : ["Talking"],
		"personalityTypeProfile" : {},
		"ActionConcepts" : {}
	},
	"Entity2" : {
		"Name" : [],
		"Personality" : [],
		"Physical" : ["Disembodied"],
		"Environment" : ["Empty-Void"],
		# "Abilities" : ["Talking"],
		"personalityTypeProfile" : {},
		"ActionConcepts" : {}
	},

}

var personalityTypeProfiles = {
	"Happy": {
		"Complain": 0.1,
		"Celebrate": 0.7,
		"Joke": 0.7,
		"Ponder": 0.0,
		"Dismiss": 0.0,
		"Taunt": 0.0,
		"Insult": 0.0,
		"Choose": 0.2,
		"Dodge": 0.1,
		"Apologize": 0.1,
		"Lie": 0.2,
		"Comfort": 0.2
	},
	"Funny": {
		"Complain": 0.6,
		"Celebrate": 0.6,
		"Joke": 1.0,
		"Ponder": 0.6,
		"Dismiss": 0.0,
		"Taunt": 0.7,
		"Insult": 0.5,
		"Choose": 0.0,
		"Dodge": 0.0,
		"Apologize": 0.0,
		"Lie": 0.0,
		"Comfort": 0.0
	},
	"Curious": {
		"Complain": 0.3,
		"Celebrate": 0.0,
		"Joke": 0.1,
		"Ponder": 1.0,
		"Dismiss": 0.0,
		"Taunt": 0.0,
		"Insult": 0.0,
		"Choose": 0.4,
		"Dodge": 0.0,
		"Apologize": 0.0,
		"Lie": 0.0,
		"Comfort": 0.0
	},
	"Sad": {
		"Complain": 0.6,
		"Celebrate": 0.0,
		"Joke": 0.0,
		"Ponder": 0.8,
		"Dismiss": 0.8,
		"Taunt": 0.0,
		"Insult": 0.4,
		"Choose": 0.0,
		"Dodge": 0.5,
		"Apologize": 0.3,
		"Lie": 0.0,
		"Comfort": 0.0
	},
	"Calculating": {
		"Complain": 0.2,
		"Celebrate": 0.0,
		"Joke": 0.4,
		"Ponder": 1.0,
		"Dismiss": 0.7,
		"Taunt": 0.0,
		"Insult": 0.4,
		"Choose": 0.9,
		"Dodge": 0.4,
		"Apologize": 0.0,
		"Lie": 0.1,
		"Comfort": 0.0
	},
	"Grumpy": {
		"Complain": 1.0,
		"Celebrate": 0.0,
		"Joke": 0.0,
		"Ponder": 0.6,
		"Dismiss": 0.3,
		"Taunt": 0.6,
		"Insult": 0.9,
		"Choose": 0.2,
		"Dodge": 0.3,
		"Apologize": 0.0,
		"Lie": 0.0,
		"Comfort": 0.0
	},
}

# 12 for now. More will be added in version 0.02
# Each entity has a copy of this that morphs as the conversation flows.
var actionConcepts = {
	"Complain": {
		"referencing_what" : null,
		"complain_about" : null
	},
	"Celebrate": {
		"referencing_what" : null,
		"celebrate_what" : null
	},
	"Joke": {
		"referencing_what" : null,
		"joke_about" : null
	},
	"Ponder": {
		"referencing_what" : null,
		"ponder_what" : null
	},
	"Dismiss": {
		"referencing_what" : null,
		"dismiss_what" : null
	},
	"Taunt": {
		"referencing_what" : null,
		"taunt_about" : null
	},
	"Insult": {
		"referencing_what" : null,
		"insult_what" : null,
		"insult_who" : null
	},
	"Choose": {
		"referencing_what" : null,
		"choose_what" : null,
		"options" : [null, null]
	},
	"Dodge": {
		"referencing_what" : null,
		"dodge_what" : null,
		"why_dodge" : null,
	},
	"Apologize": {
		"referencing_what" : null,
		"apologize_about" : null
	},
	"Lie": {
		"referencing_what" : null,
		"lie_about" : null,
	},
	"Comfort": {
		"referencing_what" : null,
		"comfort_concerning" : null
		
	}
}

# Variations of action concepts that. Utilized according to the personality type profiles.
var actionConceptToSpeechDict = {
	"Complain" : {
		"standard_complain" : {
			"utterance" : "We're talking about {referencing_what} here. {complain_about}?! Yikes.",
			"retort" :    "We're talking about {referencing_what} here. {complain_about}?! Yikes.",
			"question":   "We're talking about {referencing_what} here. {complain_about}?! Isn't that a mess?" 
		},
		"celebratory_complain" : {
			"utterance" : "Though {referecing_what}'s {complain_about} isn't the best. I've found that {referencing_what}'s with the issue tend to end up being cool anyway.",
			"retort" :    "I mean. Though {referencing_what}'s {complain_about} isn't the best. I've found that {referencing_what}'s with the issue tend to end up being cool anyway.",
			"question" : "{referecing_what}'s {complain_about} isn't the best. Don't {referencing_what}'s with the issue tend to end up being cool anyway?"
		},
		"jokey_complain" : {
			"utterance" : "{referencing_what} doesn't have issues, well, save for its {complain_about}... Yikes.",
			"retort" :    "{referencing_what} doesn't have issues, well, save for its {complain_about}... Yikes.",
			"question" : "{referencing_what} doesn't have issues, well, save for its {complain_about}... Yikes. Why is that such a mess?"
		},
		"ponderous_complain" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dismissive_complain": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_complain" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insulting_complain" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_complain" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_complain" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_complain" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_complain" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_complain" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Celebrate" : {
		"complain_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"standard_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"jokey_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dismissive_celebrate": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insulting_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_celebrate" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Joke" : {
		"complain_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dismissive_joke": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insulting_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_joke" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Ponder" : {
		"complain_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dismissive_ponder": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insulting_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_ponder" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Dismiss" : {
		"complain_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_dismiss": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insulting_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_dismiss" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Taunt" : {
		"complain_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dimissive_taunt": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insulting_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_taunt" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Insult" : {
		"complain_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dimissive_insult": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_insult" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Choose" : {
		"complain_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dimissive_choose": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insult_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_choose" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Dodge" : {
		"complain_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dimissive_dodge": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insult_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_dodge" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Apologize" : {
		"complain_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dimissive_apologize": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insult_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_apologize" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Lie" : {
		"complain_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dimissive_lie": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insult_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"comforting_lie" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
	"Comfort" : {
		"complain_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question":   "" 
		},
		"celebratory_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"joke_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"ponderous_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dimissive_comfort": {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"taunting_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"insult_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"choosey_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"dodge_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"apologetic_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"lying_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		},
		"standard_comfort" : {
			"utterance" : "",
			"retort" :    "",
			"question" : ""
		}
	},
}

# The will be added to all utterances and retorts to make the speech more natural.
# Three each for now. Will go up to ten.
var affirmAndContestDict = {
	"Affirmations": [
		{
			"before": "Exactly.",
			"after" : ""
		},
		{
			"before": "Right.",
			"after" : ""
		},
		{
			"before": "",
			"after" : "That's exactly right."
		}
	],
	"Contests" : [
		{
			"before": "I don't know about that.",
			"after" : ""
		},
		{
			"before": "I don't know.",
			"after" : ""
		},
		{
			"before": "",
			"after" : "Wouldn't you say?"
		}
	]
}

var topicDict = {
	"Topic1" : {
		"Name" : "entitiesCanNotSeeEachOther",
		"Subject1" : {
			"Data": "",
			"Profile": ""
		},
		"Subject2" : {
			"Data": "",
			"Profile": ""
		},
		"Subject3" : {
			"Data": "",
			"Profile": ""
		},
		"Subject4" : {
			"Data": "",
			"Profile": ""
		},
		"Subject5" : {
			"Data": "",
			"Profile": ""
		},
		"Subject6" : {
			"Data": "",
			"Profile": ""
		},
		"Subject7" : {
			"Data": "",
			"Profile": ""
		},
		"Subject8" : {
			"Data": "",
			"Profile": ""
		},
		"Subject9" : {
			"Data": "",
			"Profile": ""
		},
		"Subject10" : {
			"Data": "",
			"Profile": ""
		}
	},
	"Topic2" : {
		"Name" : "entityHasBeenWanderingForALongTime",
		"Subject1" : {
			"Data": "",
			"Profile": ""
		},
		"Subject2" : {
			"Data": "",
			"Profile": ""
		},
		"Subject3" : {
			"Data": "",
			"Profile": ""
		},
		"Subject4" : {
			"Data": "",
			"Profile": ""
		},
		"Subject5" : {
			"Data": "",
			"Profile": ""
		},
		"Subject6" : {
			"Data": "",
			"Profile": ""
		},
		"Subject7" : {
			"Data": "",
			"Profile": ""
		},
		"Subject8" : {
			"Data": "",
			"Profile": ""
		},
		"Subject9" : {
			"Data": "",
			"Profile": ""
		},
		"Subject10" : {
			"Data": "",
			"Profile": ""
		}
	},
	"Topic3" : {
		"Name" : "entityDoesNotKnowWhatItLooksLike",
		"Subject1" : {
			"Data": "",
			"Profile": ""
		},
		"Subject2" : {
			"Data": "",
			"Profile": ""
		},
		"Subject3" : {
			"Data": "",
			"Profile": ""
		},
		"Subject4" : {
			"Data": "",
			"Profile": ""
		},
		"Subject5" : {
			"Data": "",
			"Profile": ""
		},
		"Subject6" : {
			"Data": "",
			"Profile": ""
		},
		"Subject7" : {
			"Data": "",
			"Profile": ""
		},
		"Subject8" : {
			"Data": "",
			"Profile": ""
		},
		"Subject9" : {
			"Data": "",
			"Profile": ""
		},
		"Subject10" : {
			"Data": "",
			"Profile": ""
		}
	},
	"Topic4" : {
		"Name" : "entityDoesNotHaveAnyFriends",
		"Subject1" : {
			"Data": "",
			"Profile": ""
		},
		"Subject2" : {
			"Data": "",
			"Profile": ""
		},
		"Subject3" : {
			"Data": "",
			"Profile": ""
		},
		"Subject4" : {
			"Data": "",
			"Profile": ""
		},
		"Subject5" : {
			"Data": "",
			"Profile": ""
		},
		"Subject6" : {
			"Data": "",
			"Profile": ""
		},
		"Subject7" : {
			"Data": "",
			"Profile": ""
		},
		"Subject8" : {
			"Data": "",
			"Profile": ""
		},
		"Subject9" : {
			"Data": "",
			"Profile": ""
		},
		"Subject10" : {
			"Data": "",
			"Profile": ""
		}
	},
	"Topic5" : {
		"Name" : "entityDoesNotKnowWhereTheyAre",
		"Subject1" : {
			"Data": "",
			"Profile": ""
		},
		"Subject2" : {
			"Data": "",
			"Profile": ""
		},
		"Subject3" : {
			"Data": "",
			"Profile": ""
		},
		"Subject4" : {
			"Data": "",
			"Profile": ""
		},
		"Subject5" : {
			"Data": "",
			"Profile": ""
		},
		"Subject6" : {
			"Data": "",
			"Profile": ""
		},
		"Subject7" : {
			"Data": "",
			"Profile": ""
		},
		"Subject8" : {
			"Data": "",
			"Profile": ""
		},
		"Subject9" : {
			"Data": "",
			"Profile": ""
		},
		"Subject10" : {
			"Data": "",
			"Profile": ""
		}
	}
}


############################### GUI VARIABLES ###############################
onready var outputStream = $OutputText

onready var selectionMenu = $SelectionMenu
onready var generateButton = $GenerateButton

# WILL HAVE TO BE REWRITTEN FOR THE NON-GUI AND API VERSIONS
var allInputNames = {
	"0" : "",
	"1" : ""
}

# var allInputPersonalities = []

onready var entity1NameEntry = $SelectionMenu/entity1Block/entityNameEntry
onready var entity1PersonalityEntry = $SelectionMenu/entity1Block/entityPersonalityEntry


onready var entity2NameEntry = $SelectionMenu/entity2Block/entityNameEntry
onready var entity2PersonalityEntry = $SelectionMenu/entity2Block/entityPersonalityEntry

onready var selectionMenuSubmitButton = $SelectionMenu/selectionMenuSubmit


############################### BASE FUNCTIONS ###############################
func _ready():
	rng.seed = hash("Godot")
	
	print(welcome_message)
	print(rng_message)
	
	current_program_state = program_states[0]
	
func _process(delta):
	if current_program_state == program_states[0]:
		
		#True temporarily
		var readyToSubmit = true
		
		for selection in selection_filled_states:
			if selection == true:
				pass
			else:
				readyToSubmit = false
				selectionMenuSubmitButton.disabled = true
				break
				
		if readyToSubmit:
			selectionMenuSubmitButton.disabled = false	
	
############################### GUI FUNCTIONS ###############################

func entity1NameSelectionStateChecker(newText):
	allInputNames["0"] = newText
	
	if entity1NameEntry.text.length() >= 3:
		selection_filled_states[0] = true
	else: 
		selection_filled_states[0] = false
		
func entity1PersonalitySelectionStateChecker(_selectedItemIndex):
	if entity1PersonalityEntry.is_anything_selected():
		selection_filled_states[1] = true
	else:
		selection_filled_states[1] = false
		
func entity2NameSelectionStateChecker(newText):
	allInputNames["1"] = newText
	
	if entity2NameEntry.text.length() >= 3:
		selection_filled_states[2] = true
	else: 
		selection_filled_states[2] = false

func entity2PersonalitySelectionStateChecker(_selectedItemIndex):
	if entity2PersonalityEntry.is_anything_selected():
		selection_filled_states[3] = true
	else:
		selection_filled_states[3] = false
		
func submitSelectionMenu():
	entitySetup(entities)
	addToOutputQueue("introduction", introductionMessageCreator())
	current_program_state = program_states[1]
	selectionMenu.visible = false
	outputStream.visible = true
	generateButton.disabled = false
	

func _on_GenerateButton_toggled(button_pressed):	
	if button_pressed:
		print("Resuming generation now.")
		approvalToGenerate = true
		current_program_state = program_states[2]
		$GenerateButton.text = "Generating Conversation"
	elif !button_pressed:
		print("Stopping generation now.")
		approvalToGenerate = false
		current_program_state = program_states[3]
		$GenerateButton.text = "Generation Paused"

############################### ENTITY FUNCTIONS ###############################

func entitySetup(entityDict):
	entityNameSetup()
	entityPersonalitySetup()
	entityPersonalityProfileSetup(entityDict)
	entityActionConceptsSetup(entityDict)
			
##################
# BOTH OF THESE FUNCTIONS WILL HAVE TO BE REWRITTEN FOR THE NON-GUI AND API VERSIONS
func entityNameSetup():
	entities["Entity1"]["Name"].push_back(allInputNames["0"])
	entities["Entity2"]["Name"].push_back(allInputNames["1"])

func entityPersonalitySetup():
	entities["Entity1"]["Personality"].push_back(entity1PersonalityEntry.get_item_text(entity1PersonalityEntry.get_selected_items()[0]))
	entities["Entity2"]["Personality"].push_back(entity2PersonalityEntry.get_item_text(entity2PersonalityEntry.get_selected_items()[0]))

	
##################

func entityPersonalityProfileSetup(entityDict):
	var arrayOfEntityNames = returnArrayOfNamesOfAllEntitiesInEntityDict(entityDict)
	
	for current_entity in arrayOfEntityNames:
		entityDict[current_entity]["personalityTypeProfile"] = returnPersonalityProfile(entityDict[current_entity]["Personality"]) 

func entityActionConceptsSetup(entityDict):
	var arrayOfEntityNames = returnArrayOfNamesOfAllEntitiesInEntityDict(entityDict)
	
	for current_entity in arrayOfEntityNames:
		entityDict[current_entity]["ActionConcepts"] = returnFreshActionConceptDict()

func returnFreshActionConceptDict():
	return actionConcepts

func findFinalEntityInEntityDict(entityDict):
	var finalEntityFound = false
	var finalEntityNumber = 1
	while !finalEntityFound:
		if "Entity%s" % finalEntityNumber in entityDict:
			finalEntityNumber += 1
		else:
			finalEntityNumber -= 1
			finalEntityFound = true
	return finalEntityNumber

func returnArrayOfNamesOfAllEntitiesInEntityDict(entityDict):
	var arrayOfNamesOfAllEntitiesInEntityDict = []
	for entityNum in range(1, findFinalEntityInEntityDict(entityDict) + 1):
		arrayOfNamesOfAllEntitiesInEntityDict.append("Entity%s" % entityNum)
	return arrayOfNamesOfAllEntitiesInEntityDict

func returnPersonalityProfile(personality):
	return personalityTypeProfiles.get(personality[0])

############################### CONVERSATION FUNCTIONS (SOLUTION 2) ###############################
# (This is where the magic happens)



############################### OUTPUT FUNCTIONS ###############################

### QUEUE JOB TYPES
# Introduction
# Conversation
# Goodbye

func performOutputJob(job):
	outputStream.append_bbcode(job[1])
	
func addToOutputQueue(jobType, job):
	jobQueue.push_back([jobType, job])

func subtractFromOutputQueue():
	jobQueue.pop_front()

func returnQueueStateForPrinting(infoNeeded):
	if jobQueue.empty():
		return "Empty"
	elif infoNeeded == "entireQueue":
		return jobQueue
	elif infoNeeded == "nextInQueue":
		return jobQueue[0][0]
	
func _on_QueueWorkerCheckForWorkTimer_timeout():
	queueCheckForWorkTimerTimeoutCounter += 1
	print("Output: %s" % queueCheckForWorkTimerTimeoutCounter)
	print("The current program_state is: %s" % current_program_state)
	
	if !jobQueue.empty() and approvalToGenerate:
		print("Performing next job.")
		performOutputJob(jobQueue[0])
		subtractFromOutputQueue()
	else: 
		# print("The jobQueue is currently: %s" % returnQueueStateForPrinting("entireQueue"))
		print("Next in jobQueue is currently: %s" % returnQueueStateForPrinting("nextInQueue"))
		print("Approval to generate is: %s\n" % approvalToGenerate)

func introductionMessageCreator():
	# Will be updated in version 0.02 to support an arbitrary amount of entities.
		
	return baseIntroductionsDict["1"].format({
		"entity1Name" : entities["Entity1"]["Name"][0],
		"entity1Personality" : entities["Entity1"]["Personality"][0],
		"entity2Name" : entities["Entity2"]["Name"][0],
		"entity2Personality" : entities["Entity2"]["Personality"][0],
	})
	



