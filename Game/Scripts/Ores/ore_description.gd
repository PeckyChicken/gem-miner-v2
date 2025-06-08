extends Control
class_name OreDescription

var description_tag: String
var title_tag: String
var ore_data: Dictionary

func _ready() -> void:
	Events.LanguageChanged.connect(language_changed)
	var description = description_tag
	var title = title_tag
	$title/text.text = title
	$description/text.text = format_description(TranslationServer.translate(description))

func language_changed(_locale):
	$description/text.text = format_description(TranslationServer.translate(description_tag))

func parse_data_ref(word):
	var start: int = word.find("#")
	var end: int = word.find(";")
	var data_ref: String = word.substr(start+1,end-start-1)
	var data: String
	if ore_data.get(data_ref,"ERROR") is float:
		var _temp_data: float = ore_data.get(data_ref)
		if _temp_data == floor(_temp_data):
			data = str(int(_temp_data))
		else:
			data = str(_temp_data)
	else:
		data = str(ore_data.get(data_ref,"ERROR"))
	var final_word = word.substr(0,start) + data + word.substr(end+1)
	return final_word

func format_description(text: String) -> String:
	var words = text.split(" ")
	var new_words = []
	for word in words:
		
		if "#" in word and ";" in word: #Data reference
			new_words.append(format_description(parse_data_ref(word)))
			continue
		
		if word.begins_with("+"):
			new_words.append("[color=gold]%s[/color]" % [word])
			continue
		
		if word.begins_with("$"):
			new_words.append("[img width=%s]Icons/%s.png[/img]" % [$description/text.get_theme_font_size("normal_font_size"),word.substr(1).to_lower()])
			continue
		
		new_words.append(word)
	
	return " ".join(new_words)
