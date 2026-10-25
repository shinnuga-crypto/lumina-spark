extends SceneTree
var g
var count=0
func _initialize(): call_deferred("run")
func snap(label: String):
	g.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
	var code=g.get_viewport().get_texture().get_image().save_png("res://test-output/charge-v4-"+label+".png")
	count+=1; print("CHARGE V4 CAPTURE ",label," ",code)
func fresh():
	g.stage=2; g.fixed_seed=true; g.start_game(); g.capture_mode=true; g.muted=true
	g.enemies.clear(); g.bullets.clear(); g.banner_time=0; g.player=Vector2(430,610); g.grounded=true
	g.velocity=Vector2.ZERO; g.aim_override=Vector2.ZERO; g.facing=1
	g.set_process(false); g.set_physics_process(false)
func run():
	g=load("res://game.gd").new(); root.add_child(g)
	for posture in ["idle","run","air"]:
		for amount in [0.4,1.6]:
			fresh(); g.saber_charge=amount
			g.grounded=posture!="air"; g.player.y=520 if posture=="air" else 610
			g.velocity=Vector2(285 if posture=="run" else 0,0); g.walk_phase=2
			await snap("hold-%s-%d"%[posture,int(amount*10)])
	for facing in [-1,1]:
		fresh(); g.grounded=false; g.player.y=510; g.facing=facing; g.begin_saber(2)
		g.saber_time=g.saber_total-g.saber_startup-0.025; await snap("air-max-%s"%["left" if facing<0 else "right"])
	for tier in range(3):
		fresh(); g.dash_timer=0.13; g.velocity.x=720; g.begin_saber(tier)
		for phase in range(3):
			g.saber_time=g.saber_total-[g.saber_startup*0.7,g.saber_startup+0.035,g.saber_total-g.saber_recovery*0.5][phase]
			await snap("lance-%d-%d"%[tier,phase])
	for airborne in [false,true]:
		for tier in [1,2]:
			fresh(); g.grounded=not airborne; g.player.y=510 if airborne else 610
			g.charge=1.0 if tier==1 else 1.6; g.begin_saber(tier)
			g.saber_time=g.saber_total-g.saber_startup-0.025; g.update_saber(); g.update_bullets(0.42)
			await snap("wave-%s-%d"%["air" if airborne else "ground",tier])
	print("CHARGE V4 CAPTURE PASS: ",count," frames")
	quit()
