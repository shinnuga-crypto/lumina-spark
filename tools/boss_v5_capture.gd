extends SceneTree
var g
var count=0
func _initialize(): call_deferred("run")
func snap(label: String):
	g.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	var code=g.get_viewport().get_texture().get_image().save_png("res://test-output/boss-v5-"+label+".png")
	count+=1; print("BOSS V5 CAPTURE ",label," ",code)
func fresh(stage: int):
	g.stage=stage; g.fixed_seed=true; g.start_game(); g.capture_mode=true; g.muted=true
	g.set_process(false); g.set_physics_process(false); g.enemies.clear(); g.bullets.clear(); g.banner_time=0
	g.velocity=Vector2.ZERO; g.grounded=true; g.invincible=0; g.aim_override=Vector2.ZERO; g.facing=1
	g.player=Vector2(500,6300 if stage==3 else 610)
	if stage==3: g.campaign.camera=Vector2(0,5660)
func final_boss():
	fresh(3); g.boss_active=true; g.boss_intro=0; g.campaign.boss_clock=1
func run():
	g=load("res://game.gd").new(); root.add_child(g)
	for stage in [1,2,3]:
		for full in [false,true]:
			fresh(stage); g.aim_override=Vector2(1,-0.3).normalized(); g.shoot(true,full)
			g.bullets[-1].p+=g.bullets[-1].v*0.18
			g.charge=1.6 if full else 0.8
			await snap("stage%d-charge%d"%[stage,2 if full else 1])
	for stage in [2,3]:
		fresh(stage); g.dash_timer=0.1; g.aim_override=Vector2.RIGHT; g.shoot(false)
		await snap("stage%d-muzzle-dash"%stage)
	final_boss(); await snap("sealed")
	for seal in g.campaign.seals: seal.hp=0
	await snap("open")
	g.campaign.boss_clock=5.5; await snap("closed-window")
	g.boss_hp=g.boss_max_hp/2; g.boss_phase=2; g.campaign.encounter.enrage(); await snap("overdrive")
	g.campaign.encounter.overdrive=0; g.campaign.boss_clock=1; await snap("overdrive-open")
	final_boss(); g.campaign.encounter.launch_missiles()
	for b in g.bullets: b.p+=b.v*0.6
	await snap("missiles")
	g.player=Vector2(550,5900); g.campaign.encounter.pressure_time=0.4; await snap("pressure-warning")
	g.campaign.encounter.pressure_time=1.2; await snap("pressure-active")
	final_boss(); g.player=Vector2(90,6300); await snap("return-pad")
	g.campaign.encounter.spawn_helpers(); g.enemies[0].hp=0; g.register_enemy_defeat(g.enemies[0]); g.hp=6
	await snap("helper-heal")
	for tier in [1,2]:
		fresh(2); g.begin_saber(tier); g.saber_time=g.saber_total-g.saber_startup*0.5
		await snap("windup-%d"%tier)
	print("BOSS V5 CAPTURE PASS: ",count," frames")
	call_deferred("quit")
