extends SceneTree
## Writes the engine's own licence data, so the notices match the Godot version in use.

func _initialize() -> void:
	var sections: PackedStringArray = ["Godot Engine %s\n\n%s" % [Engine.get_version_info().string, Engine.get_license_text()]]
	for component: Dictionary in Engine.get_copyright_info():
		var section: PackedStringArray = ["Component: %s" % component.name]
		for part: Dictionary in component.parts:
			section.append("Files: %s" % ", ".join(part.files))
			for holder: String in part.copyright:
				section.append("Copyright: %s" % holder)
			section.append("License: %s" % part.license)
		sections.append("\n".join(section))
	var licenses: Dictionary = Engine.get_license_info()
	for license_name: String in licenses:
		sections.append("License text: %s\n\n%s" % [license_name, licenses[license_name]])
	var file := FileAccess.open("res://docs/GODOT_COPYRIGHT.txt", FileAccess.WRITE)
	file.store_string("\n\n-----\n\n".join(sections).strip_edges() + "\n")
	file.close()
	quit()
