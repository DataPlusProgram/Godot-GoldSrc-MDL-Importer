@tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func _get_importer_name():
	return "Mdl importer"
	
func _get_recognized_extensions():
	return ["mdl"]
	

func _get_visible_name():
	return "GoldSrc mdl"

func _get_preset_count():
	return Presets.size()
	
func _get_preset_name(preset):
	match preset:
		Presets.DEFAULT: return "Default"
		_: return "Unknown"


func _get_import_options(preset, intvar):
	match preset:
		Presets.DEFAULT: return[{"name":"texture_filtering", "default_value":false}]
		_: return[]
	
func _get_option_visibility(option, options, dictiovar):
	return true
	
func _get_save_extension():
	return "tscn"
	
func _get_resource_type():
	return "PackedScene"

func _get_priority():
	return 1.0

func _get_import_order():
	return 0

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var mdlLoader = MdlLoader.new()
	var skel = mdlLoader.mdlParse(source_file, false)
	if skel == null:
		return false
	var packed_scene = PackedScene.new()
	packed_scene.pack(skel)
	
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(packed_scene, filename)

