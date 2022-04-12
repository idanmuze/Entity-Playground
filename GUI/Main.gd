extends Control


var firstProgramStart = false
var approvalToGenerate = false

var entities = {
	"Olya Oakschild" : {
		"Age": "25",
		"Species" : "Human",
		"Occupation" : "Bartender",
		"Titles" : ["Bartender"],
		"Personality": ["Talkative, Curious, Funny"],
		"Life-Story": [
			
		],
		"Recent-Event": [
			
		]
	},
	"Ser Jora Irondune" : {
		"Age": "40",
		"Species" : "Human",
		"Occupation" : "Knight",
		"Titles" : ["The Slayer of the Iron Dunes"],
		"Personality": ["Judgemental, Dutiful, Reserved"],
		"Life-Story": [
			
		],
		"Recent-Event": []
	},
	
}




















# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_GenerateButton_toggled(button_pressed):
	if !firstProgramStart:
		print("First generation started.")
		firstProgramStart = true
		approvalToGenerate = true
		$GenerateButton.text = "Generating Conversation"	
	elif button_pressed:
		print("Resuming generation now.")
		approvalToGenerate = true
		$GenerateButton.text = "Generating Conversation"
	elif !button_pressed:
		print("Stopping generation now.")
		approvalToGenerate = false
		$GenerateButton.text = "Generation Paused"
		
		
