tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func get_importer_name():
	return "GoldSrc mdl importer"
	
func get_recognized_extensions():
	return ["mdl"]
	

func get_visible_name():
	return "GoldSrc mdl"

func get_preset_count():
	return Presets.size()
	
func get_preset_name(preset):
	match preset:
		Presets.DEFAULT: return "Default"
		_: return "Unknown"


func get_import_options(preset):
	match preset:
		Presets.DEFAULT: return[{"name":"texture_filtering", "default_value":false}]
		_: return[]
	
func get_option_visibility(option, options):
	return true
	
func get_save_extension():
	return ".tscn"
	
func get_resource_type():
	return "PackedScene"

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var textureFiltering  = options["texture_filtering"]

	var mdlLoader = load("res://addons/GoldSRC_mdl_importer/mdlLoad.gd").new()
	var skel = mdlLoader.mdlParse(source_file,textureFiltering)
	if skel == null:
		return false
	var packed_scene = PackedScene.new()
	packed_scene.pack(skel)
	
	var filename = save_path + "." + get_save_extension()
	return ResourceSaver.save(filename, packed_scene)

