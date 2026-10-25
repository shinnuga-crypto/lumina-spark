extends SceneTree
var g
func _initialize(): call_deferred("run")
func snap(label: String):
	g.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	var result=g.get_viewport().get_texture().get_image().save_png("res://test-output/"+label+".png")
	print("PROPS CAPTURE ",label," ",result)
func fresh(stage: int):
	g.stage=stage; g.fixed_seed=true; g.start_game(); g.capture_mode=true; g.muted=true
	g.set_process(false); g.set_physics_process(false); g.banner_time=0; g.invincible=0; g.grounded=true
func run():
	g=load("res://game.gd").new(); root.add_child(g); g.muted=true; g.capture_mode=true; g.set_process(false); g.set_physics_process(false)
	g.state="title"; g.using_pad=true; g.open_settings(); g.settings_index=g.settings_rows().find("fire"); g.settings_column=4
	g.bind_pad("fire",JOY_BUTTON_LEFT_SHOULDER,3)
	await snap("settings-four-slots")
	g.settings_activate(); await snap("settings-slot-wait")
	g.clear_pad_slot("fire",1); await snap("settings-slot-cleared")
	g.reset_bindings(); fresh(2)
	g.player=Vector2(1350,610); g.campaign.camera=Vector2(1000,0); g.camera_x=1000
	for strike in g.campaign.strikes: strike.phase=0.5; strike.target=1600
	await snap("props-shelter")
	g.player=Vector2(2750,610); g.campaign.camera=Vector2(2200,0); g.camera_x=2200
	await snap("props-conveyor")
	fresh(3); g.player=Vector2(610,610); await snap("props-bulkhead")
	g.campaign.plugs[0].hp=5; await snap("props-bulkhead-damaged")
	g.player=Vector2(620,1800); g.campaign.camera=Vector2(0,1350)
	var item=g.campaign.data.crushers[0]
	g.elapsed=fposmod(1.6-item[1]/200,item[2])
	var crumble=g.campaign.crumbles[1]; crumble.timer=0.3
	await snap("props-crusher-extended")
	g.elapsed=fposmod(3.0-item[1]/200,item[2]); await snap("props-crusher-retracted")
	g.player=Vector2(450,6300); g.campaign.update(0); g.campaign.camera=Vector2(0,5660); g.banner_time=0
	await snap("props-seals")
	quit()
