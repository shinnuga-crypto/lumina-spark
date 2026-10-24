extends SceneTree
var g
func _initialize(): call_deferred("run")
func snap(label: String):
	g.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	var error=g.get_viewport().get_texture().get_image().save_png("res://test-output/"+label+".png")
	print("CAMPAIGN CAPTURE ",label," ",error)
func fresh(number: int):
	g.stage=number; g.fixed_seed=true; g.start_game(); g.set_process(false); g.set_physics_process(false)
	g.capture_mode=true; g.muted=true; g.banner_time=0; g.invincible=0; g.grounded=true; g.aim_override=Vector2.ZERO
func run():
	g=load("res://game.gd").new(); root.add_child(g); g.set_process(false); g.set_physics_process(false)
	fresh(2); g.player=Vector2(460,610); g.aim_override=Vector2(1,-1).normalized(); g.shoot(false)
	await snap("surface-start")
	g.player=Vector2(1600,610); g.campaign.camera=Vector2(1050,0); g.camera_x=1050
	for s in g.campaign.strikes: s.phase=0.6; s.target=1500
	await snap("surface-shelter")
	g.player=Vector2(10300,610); g.campaign.update(0.01); g.campaign.camera=Vector2(10000,0); g.camera_x=10000
	g.boss_intro=0; g.campaign.update_boss(1); g.aim_override=(g.boss_hit_rect().get_center()-g.player+Vector2(0,75)).normalized(); g.bullets.clear(); g.shoot(true)
	await snap("surface-boss")
	fresh(3); g.player=Vector2(620,610); g.aim_override=Vector2.DOWN; g.shoot(false)
	await snap("shaft-entry")
	g.player=Vector2(650,1800); g.grounded=false; g.campaign.camera=Vector2(0,1400); g.aim_override=Vector2(-1,1).normalized(); g.shoot(false)
	await snap("shaft-descent")
	g.player=Vector2(510,6300); g.campaign.update(0.01); g.campaign.camera=Vector2(0,5660); g.camera_x=0
	g.boss_intro=0; g.aim_override=Vector2(1,-1).normalized(); g.shoot(true)
	await snap("shaft-boss-sealed")
	for seal in g.campaign.seals: seal.hp=0
	g.campaign.boss_clock=1; g.campaign.rays=[{"y":6200.0,"t":0.7}]
	await snap("shaft-boss-open")
	for stage in [1,2,3]:
		g.state="title"; g.selected_stage=stage; await snap("title-stage%d"%stage)
	fresh(1); g.player=Vector2(500,570); g.enemies.clear()
	for airborne in [false,true]:
		g.grounded=not airborne
		for i in range(8):
			g.aim_override=Vector2.RIGHT.rotated(i*TAU/8); g.bullets.clear(); g.shoot(i==7)
			if not g.bullets.is_empty(): g.bullets[-1].p+=g.bullets[-1].v*0.13
			await snap("aim-%s-%d"%["air" if airborne else "ground",i])
	quit()
