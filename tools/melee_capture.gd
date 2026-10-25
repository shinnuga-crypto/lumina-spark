extends SceneTree
var g
func _initialize(): call_deferred("run")
func snap(label: String):
	g.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	var result=g.get_viewport().get_texture().get_image().save_png("res://test-output/"+label+".png")
	print("MELEE CAPTURE ",label," ",result)
func run():
	g=load("res://game.gd").new(); root.add_child(g); g.muted=true; g.capture_mode=true; g.set_process(false); g.set_physics_process(false)
	g.stage=2; g.fixed_seed=true; g.start_game(); g.player=Vector2(480,610); g.enemies.clear(); g.banner_time=0; g.grounded=true
	for kind in ["ground","air","dash"]:
		for tier in range(3):
			g.reset_saber_action(); g.grounded=kind=="ground"; g.player.y=610 if g.grounded else 530
			g.velocity=Vector2(720 if kind=="dash" else 285,0); g.dash_timer=0.1 if kind=="dash" else 0
			g.begin_saber(tier); g.saber_kind=kind; g.saber_air=kind=="air"
			for frame in range(8):
				g.saber_time=g.saber_total*(1-(frame+0.25)/8.0); g.walk_phase=fmod(frame*0.65,8); g.clock=frame/18.0
				await snap("melee-%s-%d-%02d"%[kind,tier,frame])
	g.reset_saber_action(); g.dash_timer=0; g.velocity=Vector2.ZERO; g.grounded=true; g.player.y=610
	for amount in [0.4,0.9,1.6]:
		g.saber_charge=amount; await snap("melee-charge-%d"%int(amount*10))
	g.reset_saber_action(); g.grounded=false; g.player.y=540; g.aim_override=Vector2(1,-1).normalized(); g.aim_time=0.3
	for i in range(3):
		g.velocity=Vector2(180,[-600,0,700][i]); g.update_aim()
		await snap("aim-jump-phase-%d"%i)
	quit()
