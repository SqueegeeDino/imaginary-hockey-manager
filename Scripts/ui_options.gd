extends PanelContainer

# x / 16 * 9 = y

func _set_window_size(xRes) -> void:
	var yRes: int = xRes/16*9
	get_window().size = Vector2i(xRes, yRes)
	print("[scn_Main] xRes: ", xRes)
	print("[scn_Main] yRes: ", yRes)
