@tool
extends EditorPlugin

const cfg_name = "editor_settings-4.tres"


func _enter_tree():
	if "--override" in OS.get_cmdline_user_args():
		run()
		get_tree().quit()


func run():
	var current_cfg_path = get_cfg_dir().path_join(cfg_name)
	if not FileAccess.file_exists(current_cfg_path):
		push_error("Config file was not found at %s" % current_cfg_path)
		return
	print("Found cfg at %s" % current_cfg_path)
	
	var left = get_left_cfg()
	var right = get_right_cfg()
	
	if left == null or right == null:
		return
	
	copy(left.get_path())
	
	var load_err = left.load()
	if load_err != OK:
		push_error("%s. Failed to load left config at %s" % [load_err, left.get_path()])
	else:
		print("Loaded left cfg at %s" % left.get_path())
	
	load_err = right.load()
	if load_err != OK:
		push_error("%s. Failed to load right config at %s" % [load_err, right.get_path()])
	else:
		print("Loaded right cfg at %s" % right.get_path())
	
	for prop in right.setting_keys():
		left.set_setting(prop, right.get_setting(prop))
	
	var err = left.save()
	if err:
		push_error("Failed to save cfg: %s" % err)
	else:
		print("Success")


func get_left_cfg() -> Cfg:
	var godots_cfg_path = get_key_value_arg("--godots-cfg")
	if not godots_cfg_path.is_empty():
		if not FileAccess.file_exists(godots_cfg_path):
			push_error("Config file was not found at %s" % godots_cfg_path)
			return null
		return CfgGodotsSettings.new(godots_cfg_path)
	else:
		var current_cfg_path = get_cfg_dir().path_join(cfg_name)
		if not FileAccess.file_exists(current_cfg_path):
			push_error("Config file was not found at %s" % current_cfg_path)
			return null
		return CfgEditorSettings.new(current_cfg_path)


func get_right_cfg() -> Cfg:
	var cfg_override_path = get_key_value_arg("--cfg")
	if cfg_override_path.is_empty():
		push_error("Config to override was not provided by user argument 'cfg'. Example: --cfg <abs_path_to_cfg_file>")
		return null
	if not FileAccess.file_exists(cfg_override_path):
		push_error("Config to override was not found at %s" % cfg_override_path)
		return null
	return CfgEditorSettings.new(cfg_override_path)


func get_key_value_arg(key):
	var arg_idx = OS.get_cmdline_user_args().find(key)
	if arg_idx == -1:
		return ""
	if arg_idx + 1 < len(OS.get_cmdline_user_args()):
		return OS.get_cmdline_user_args()[arg_idx + 1]
	return ""


func copy(cfg_path):
	var copy_path = "%s.%s.old" % [cfg_path, Time.get_datetime_string_from_system(false)]
	var err = DirAccess.copy_absolute(cfg_path, copy_path)
	if err:
		push_error("Failed to make a copy of the current config file: %s" % err)
	else:
		print("Successfuly made a copy of the current config file at %s" % copy_path)


func get_cfg_dir():
	if get_editor_interface().get_editor_paths().is_self_contained():
		var executable_dir = OS.get_executable_path().get_base_dir()
		if OS.has_feature("macos"):
			executable_dir = executable_dir.get_base_dir().get_base_dir().get_base_dir()
		return executable_dir.path_join("editor_data")
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
	
	func get_setting(key):
		pass
	
	func save() -> int:
		return FAILED


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
			var prop_name = prop.name
			if _settings.has_setting(prop_name) or prop_name in ["shortcuts", "builtin_action_overrides"]:
				result.append(prop_name)
		return result
	
	func set_setting(key, value):
		_settings.set(key, value)

	func get_setting(key):
		return _settings.get(key)
	
	func save() -> int:
		return ResourceSaver.save(_settings, _path)


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

	func get_setting(key):
		return _settings.get_value("theme", key)
	
	func save() -> int:
		return _settings.save(_path)
