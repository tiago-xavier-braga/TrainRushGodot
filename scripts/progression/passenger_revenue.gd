extends Node3D
## Pays every passenger's ticket when the train departs and shows a floating "+N".

var _train: Train
var _settings: ProgressionSettings

@onready var _floating_text: FloatingText = $FloatingText
@onready var _coin_sound: AudioStreamPlayer = $CoinSound


func setup(train: Train, settings: ProgressionSettings) -> void:
	_train = train
	_settings = settings
	_train.state_changed.connect(_on_train_state_changed)


func _on_train_state_changed(state: Train.State) -> void:
	if state != Train.State.DEPARTING:
		return
	var passengers := 0
	for wagon in _train.wagons:
		passengers += wagon.boarded
	var reward := passengers * _settings.ticket_price
	if reward == 0:
		return
	_floating_text.play("+%d" % reward)
	_coin_sound.play()
	Economy.add_coins(reward)
