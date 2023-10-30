@tool
extends EditorPlugin

const cfg_name = "editor_settings-4.tres"


func _enter_tree():
	run()
	get_tree().quit()


func run():
	var current_cfg_path = get_cfg_dir().path_join(cfg_name)
	if not FileAccess.file_exists(current_cfg_path):
		printerr("Config file was not found at %s" % current_cfg_path)
		return
	print("Found cfg at %s" % current_cfg_path)
	
	copy(current_cfg_path)
	
	var cfg_override_path = find_cfg_override_path()
	if cfg_override_path.is_empty():
		printerr("Config to override was not provided by user argument 'cfg'. Example: --cfg <abs_path_to_cfg_file>")
		return
	if not FileAccess.file_exists(cfg_override_path):
		printerr("Config to override was not found at %s" % cfg_override_path)
		return
	
	
	var current_cfg = ResourceLoader.load(current_cfg_path) as EditorSettings
	var override_cfg = ResourceLoader.load(cfg_override_path) as EditorSettings
	
	for prop in prop_names_of(override_cfg):
		if current_cfg.has_setting(prop):
			print("Overriding setting %s with value %s" % [prop, override_cfg.get_setting(prop)])
			current_cfg.set_setting(prop, override_cfg.get_setting(prop))
	
	var err = ResourceSaver.save(current_cfg, current_cfg_path)
	if err:
		printerr("Failed to save cfg: %s" % err)
	else:
		print("Success")


func prop_names_of(obj: Object) -> Array[String]:
	var result: Array[String] = []
	for prop in obj.get_property_list():
		result.append(prop.name)
	return result


func find_cfg_override_path():
	var cfg_arg_idx = OS.get_cmdline_user_args().find("--cfg")
	if cfg_arg_idx == -1:
		return ""
	if cfg_arg_idx + 1 < len(OS.get_cmdline_user_args()):
		return OS.get_cmdline_user_args()[cfg_arg_idx + 1]
	return ""


func copy(cfg_path):
	var copy_path = "%s.%s.old" % [cfg_path, Time.get_ticks_usec()]
	var err = DirAccess.copy_absolute(cfg_path, copy_path)
	if err:
		printerr("Failed to make a copy of the current config file: %s" % err)
	else:
		print("Successfuly made a copy of the current config file at %s" % copy_path)


func get_cfg_dir():
	if get_editor_interface().get_editor_paths().is_self_contained():
		return OS.get_executable_path().get_base_dir().path_join("editor_data")
	else:
		return OS.get_config_dir().path_join("Godot")


class Cfg:
	func load() -> int:
		return FAILED
	
	func get_path() -> String:
		return ""
	
	func setting_keys() -> Array[String]:
		return []
	
	func set_setting(key, value):
		pass


class CfgEditorSettings extends Cfg:
	var _path: String
	var _settings: EditorSettings
	
	func _init(path: String):
		_path = path
	
	func load():
		_settings = ResourceLoader.load(_path)
		return OK
	
	func get_path() -> String:
		return _path
	
	func setting_keys() -> Array[String]:
		var result: Array[String] = []
		for prop in _settings.get_property_list():
			result.append(prop.name)
		return result
	
	func set_setting(key, value):
		if _settings.has_setting(key):
			_settings.set_setting(key, value)


class CfgGodotsSettings extends Cfg:
	var _path: String
	var _settings: ConfigFile
	
	func _init(path: String):
		_path = path
	
	func load() -> int:
		_settings = ConfigFile.new()
		return _settings.load(_path)
	
	func get_path() -> String:
		return _path
	
	func setting_keys() -> Array[String]:
		var result: Array[String] = []
		for prop in _settings.get_section_keys("theme"):
			result.append(prop)
		return result
	
	func set_setting(key, value):
		_settings.set_value("theme", key, value)
