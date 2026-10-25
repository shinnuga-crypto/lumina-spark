extends SceneTree
var g
func _initialize(): call_deferred("run")
func snap(label: String):
	g.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	var code=g.get_viewport().get_texture().get_image().save_png("res://test-output/art-v3-"+label+".png")
	print("ART V3 CAPTURE ",label," ",code)
func fresh(stage=2):
	g.stage=stage; g.fixed_seed=true; g.start_game(); g.capture_mode=true; g.muted=true
	g.enemies.clear(); g.banner_time=0; g.bullets.clear(); g.player=Vector2(480,610); g.grounded=true; g.velocity=Vector2.ZERO
	g.aim_override=Vector2.ZERO; g.set_process(false); g.set_physics_process(false)
func run():
	g=load("res://game.gd").new(); root.add_child(g)
	for airborne in [false,true]:
		for tier in range(3):
			fresh(); g.grounded=not airborne; g.player.y=520 if airborne else 610; g.begin_saber(tier)
			for frame in range(4):
				g.saber_time=g.saber_total-[0.01,g.saber_startup+0.025,g.saber_total*0.62,g.saber_total-0.02][frame]
				await snap("%s-tier%d-%d"%["air" if airborne else "ground",tier,frame])
	fresh(); g.saber_charge=1.6; await snap("charge-ground")
	g.grounded=false; g.player.y=520; await snap("charge-air")
	fresh(); g.dash_timer=0.15; g.velocity.x=720; await snap("dash-kick")
	g.dash_timer=0.07; await snap("dash-glide")
	g.aim_override=Vector2.RIGHT; g.shoot(false); await snap("dash-shot")
	g.aim_override=Vector2(1,-1).normalized(); g.bullets.clear(); g.shoot(false); await snap("dash-aim-up")
	g.begin_saber(2); g.saber_time=g.saber_total-g.saber_startup-0.02; await snap("dash-thrust")
	fresh(); g.facing=-1; g.begin_saber(0); g.saber_time=g.saber_total-g.saber_startup-0.02; await snap("slash-left")
	fresh(); g.campaign.add_beam(730.0)
	for stage in range(4):
		g.campaign.beams[0].t=[0.2,0.85,1.15,1.62][stage]
		await snap("beam-%d"%stage)
	g.campaign.beams.clear(); g.campaign.add_beam(1200.0); g.campaign.beams[0].t=1.15; await snap("beam-roof")
	fresh(3); g.player=Vector2(500,6300); g.campaign.camera=Vector2(0,5660)
	g.campaign.add_beam(6080.0,true,65,1); g.campaign.beams[0].t=1.15; await snap("beam-horizontal")
	fresh(); g.campaign.spawn_raid()
	for i in range(g.enemies.size()): g.enemies[i].p=Vector2(430+i*230,250+i*20); g.enemies[i].t=i/12.0
	g.enemy_shot(Vector2(730,430),Vector2(0,80),11,"bomb")
	for side in [-1,1]:
		g.add_enemy_bullet(Vector2(670+side*160,593),Vector2(side*210,0),7); g.bullets[-1].floor_fire=true
	await snap("raid-bombs-fire")
	print("ART V3 CAPTURE PASS: 39 frames")
	quit()
