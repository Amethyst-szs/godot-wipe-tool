extends RefCounted

## A way to combine different signals together and create complex logic
## Call add_signal or add_signals to register a new signal in this object
## Once all signals have been emitted at least once, "composite_complete" is emitted from this object
## Remember to destroy this object once it is no longer in use
class_name CompositeSignal

## List of registered signal's names and if they have been triggered
var trigger_list: Dictionary = {}

## Signal for when every composited signal has been called
signal composite_complete

## Add one singular signal to the list of required signals
func add_signal(entry: Signal):
	trigger_list[entry.get_name()] = false
	await entry
	_on_signal_get(entry.get_name())

## Add any number of signals to the list of required signals
func add_signals(signals: Array[Signal]):
	for item in signals:
		add_signal(item)

## Called once one of the composited signals is emitted
func _on_signal_get(signal_name: String):
	trigger_list[signal_name] = true
	
	for value in trigger_list.values():
		if value == false:
			return
	
	composite_complete.emit()
