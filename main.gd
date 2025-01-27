extends Node2D

const savefileLocation = "user://fishgamesave.json"

const secondsBetweenAutosave = 10
var lastSave = Time.get_ticks_msec()
var rng = RandomNumberGenerator.new()

@onready var moneyCounter = get_node("UI/Money")
@onready var fishContainer = get_node("/root/Node2D/Fish")

@export var tankSize:int : 
	set(new_value):
		tankSize = new_value
		saveGame()
	get: return tankSize
	
@export var money:int :
	set(new_value):
		money = new_value
		moneyCounter.text = str(money)
		saveGame()
	get: return money

@export var fish = []

func _process(delta):
	if (Time.get_ticks_msec() - lastSave > secondsBetweenAutosave*1000):
		print("autosaving")
		saveGame()
		

func addFish(spawnedFish): 
	var newFishData = {}
	newFishData.type = spawnedFish.scene_file_path.get_file().get_basename()
	newFishData.hunger = spawnedFish.hunger
	newFishData.id = rng.randi()
	spawnedFish.id = newFishData.id
	fish.append(newFishData)
	saveGame()
	
func spawnFish(fishData):
	var fishScene = load("res://fish/"+fishData.type+".tscn")
	var newFish = fishScene.instantiate()
	
	# Update all variables that are stored in fishdata
	newFish.id = fishData.id
	newFish.hunger = fishData.hunger
	
	# postion in tank
	newFish.position.x = rng.randi_range(20, 380)
	newFish.position.y = rng.randi_range(20, 250)
	fishContainer.add_child(newFish)
	fish.append(fishData)

var readyToSave = false

func _ready():
	if FileAccess.file_exists(savefileLocation):
		var gameData = FileAccess.open(savefileLocation, FileAccess.READ)
		var parsed = JSON.parse_string(gameData.get_as_text())
		money = parsed.money
		tankSize = parsed.tankSize
		for fish in parsed.fish: spawnFish(fish)
		print("loaded save data", parsed)
		readyToSave = true
	else:
		tankSize = 1
		money = 50
		fish = []
		print("initialized save data")
		readyToSave = true
		saveGame()
	
func saveGame():
	if (!readyToSave): return
	var file = FileAccess.open(savefileLocation, FileAccess.WRITE)
	var data = {}
	data.money = money
	data.tankSize = tankSize
	for f in fish: updateFishData(f)
	data.fish = fish	
	file.store_string(JSON.stringify(data))
	lastSave = Time.get_ticks_msec()
	print("saved save data")
	
func updateFishData(fish):
	var spawnedFish = fishContainer.get_children()
	for f in spawnedFish:
		if fish.id == f.id:
			fish.hunger = f.hunger
			return
	print("failed to find matching fish when saving fish data. id:",fish.id)
