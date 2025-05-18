extends Control
class_name OreDescription

var description_tag: String
var title_tag: String

func _ready() -> void:
	Events.LanguageChanged.connect(language_changed)
	var description = description_tag
	var title = title_tag
	$title/text.text = title
	$description/text.text = format_description(TranslationServer.translate(description))

func language_changed(locale):
	$description/text.text = format_description(TranslationServer.translate(description_tag))

func format_description(text: String) -> String:
	var words = text.split(" ")
	var new_words = []
	for word in words:
		if word.begins_with("+"):
			new_words.append("[color=gold]%s[/color]" % [word])
			continue
		
		if word.begins_with("$"):
			new_words.append("[img width=%s]Icons/%s.png[/img]" % [$description/text.get_theme_font_size("normal_font_size"),word.substr(1).to_lower()])
			continue
		
		new_words.append(word)
	
	return " ".join(new_words)
