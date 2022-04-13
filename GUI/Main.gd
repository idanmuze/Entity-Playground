extends Control

var rng = RandomNumberGenerator.new()

onready var outputStream = $OutputText

var approvalToGenerate = false
var jobQueue = []
var programState = null

var baseIntroductionsDict = {
	"1" : """
	Two disembodied voices stumble across each other. 
	One, {entity1Name}, is {entity1Personality}. The other, {entity2Name}, is {entity2Personality}.
	"""
}

var entities = {
	"Entity1" : {
		"Name" : ["John"],
		"Personality" : ["Happy"],
		"Physical" : ["Disembodied"],
		"Environment" : ["Empty-Void"],
		"Abilities" : ["Talking"],
		"ActionConcepts" : {}
	},
	"Entity2" : {
		"Name" : ["Jane"],
		"Personality" : ["Grumpy"],
		"Physical" : ["Disembodied"],
		"Environment" : ["Empty-Void"],
		"Abilities" : ["Talking"],
		"ActionConcepts" : {}
	},

}

#Start with 12
var actionConcepts = {
	"Complain": {},
	"Celebrate": {},
	"Joke": {},
	"Ponder": {},
	"Dismiss": {},
	"Taunt": {},
	"Insult": {},
	"Choose": {},
	"Dodge": {},
	"Apologize": {},
	"Lie": {},
	"Comfort": {}
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
		"Dismiss": 0.6,
		"Taunt": 0.0,
		"Insult": 0.4,
		"Choose": 0.9,
		"Dodge": 0.0,
		"Apologize": 0.0,
		"Lie": 0.0,
		"Comfort": 0.0
	},
	"Grumpy": {
		"Complain": 1.0,
		"Celebrate": 0.0,
		"Joke": 0.0,
		"Ponder": 0.6,
		"Dismiss": 0.3,
		"Taunt": 0.0,
		"Insult": 0.9,
		"Choose": 0.0,
		"Dodge": 0.3,
		"Apologize": 0.0,
		"Lie": 0.0,
		"Comfort": 0.0
	},
}
### QUEUE JOB TYPES
# Introduction
# Introduction
# Segway
# Conversation
# Goodbye

# Called when the node enters the scene tree for the first time.
func _ready():
	var rngHash = "Godot"
	rng.seed = hash("Godot")
	print(
	"""
	The current seed is a hash of {hash}. 
	The seed is {seed}.
	""".format({"hash":rngHash, "seed":rng.seed})
	)
	
	addToOutputQueue("introduction", introductionMessageCreator())
	
func _process(delta):
	pass

func _on_GenerateButton_toggled(button_pressed):	
	if button_pressed:
		print("Resuming generation now.")
		approvalToGenerate = true
		$GenerateButton.text = "Generating Conversation"
	elif !button_pressed:
		print("Stopping generation now.")
		approvalToGenerate = false
		$GenerateButton.text = "Generation Paused"
		

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
	if !jobQueue.empty() and approvalToGenerate:
		print("Performing next job.")
		performOutputJob(jobQueue[0])
		subtractFromOutputQueue()
	else: 
		# print("The jobQueue is currently: %s" % returnQueueStateForPrinting("entireQueue"))
		print("Next in jobQueue is currently: %s" % returnQueueStateForPrinting("nextInQueue"))
		print("Approval to generate is: %s" % approvalToGenerate)

func introductionMessageCreator():
	return baseIntroductionsDict["1"].format({
		"entity1Name" : entities["Entity1"]["Name"][0],
		"entity1Personality" : entities["Entity1"]["Personality"][0],
		"entity2Name" : entities["Entity2"]["Name"][0],
		"entity2Personality" : entities["Entity2"]["Personality"][0],
	})
	



