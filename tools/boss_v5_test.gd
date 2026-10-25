extends SceneTree
var g
var errors: Array[String]=[]
var held={}
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	if not ok: errors.append(label)
func key(code: int, down: bool):
	if held.get(code,false)==down: return
	held[code]=down; g.test_key(code,down)
func step(count: int):
	for i in range(count): g.update_game(1.0/60)
func fresh(stage=3):
	for code in held.keys(): key(code,false)
	g.stage=stage; g.fixed_seed=true; g.start_game(); g.muted=true; g.capture_mode=true
	g.set_process(false); g.set_physics_process(false); g.enemies.clear(); g.bullets.clear()
	g.player=Vector2(550,6300) if stage==3 else Vector2(500,610)
	g.velocity=Vector2.ZERO; g.grounded=true; g.invincible=999; g.aim_override=Vector2.ZERO; g.mouse_aim=false
func boss():
	g.boss_active=true; g.boss_intro=0; g.campaign.camera=Vector2(0,5660)
func run():
	g=load("res://game.gd").new(); root.add_child(g)
	for stage in [1,2,3]:
		fresh(stage); g.aim_override=Vector2(1,-0.25).normalized()
		for full in [false,true]:
			g.bullets.clear(); g.shoot(true,full)
			check(g.action_art.uses_charge_art(g.bullets[-1]) and g.art.charge.texture!=null,"same charged projectile artwork in stage %d"%stage)
	for tier in range(3):
		fresh(1); g.player=Vector2(400,610); g.begin_saber(tier)
		check(absf(g.saber_startup-[0.035,0.12,0.22][tier])<0.001,"tier-specific startup %d"%tier)
		if tier>0:
			check(absf(g.saber_cooldown-[0,0.70,1.0][tier])<0.001,"tier-specific cooldown")
			g.spawn_enemy(g.player+Vector2(80,0),0,0); var e=g.enemies[-1]; e.hp=100
			g.saber_time=g.saber_total-g.saber_startup+0.001; g.update_saber()
			check(e.hp==100 and not g.saber_active(),"charged wind-up cannot hit or parry")
			g.saber_time=g.saber_total-g.saber_startup-0.025; g.update_saber()
			check(e.hp<100,"charged attack hits after its delay")
	fresh(1); g.begin_saber(1); g.saber_time=0; g.saber_cooldown=0.25; g.saber_pending=1; g.saber_buffer=0.3
	step(1); check(g.saber_time==0,"another charged release cannot bypass charged cooldown")
	step(18); check(g.saber_time>0 and g.saber_tier==1,"buffered charged release starts when recovery is ready")
	fresh(); boss(); check(g.campaign.encounter.core_index()==0,"seals keep armored iris closed")
	for seal in g.campaign.seals: seal.hp=0
	g.campaign.boss_clock=1; check(g.campaign.encounter.core_index()==1,"open iris matches damage window")
	g.campaign.boss_clock=5.5; check(g.campaign.encounter.core_index()==0,"timed closure uses closed art")
	g.boss_hp=g.boss_max_hp/2; g.campaign.update_boss(1.0/60)
	check(g.boss_phase==2 and g.campaign.encounter.overdrive>0 and g.campaign.encounter.core_index()==0,"half HP starts invulnerable overdrive transition")
	var helpers=g.enemies.filter(func(e): return e.get("boss_add",false) and e.hp>0)
	check(helpers.size()==2,"phase 2 brings two helpers")
	var size=g.enemies.size(); g.campaign.update_boss(0.1)
	check(g.enemies.size()==size,"phase transition does not repeatedly spawn helpers")
	var count=g.pickups.size(); helpers[0].hp=0; g.register_enemy_defeat(helpers[0])
	check(g.pickups.size()==count+1 and g.pickups[-1].x<=850,"helper guarantees a reachable healing drop")
	g.campaign.encounter.overdrive=0; g.campaign.boss_clock=1
	check(g.campaign.encounter.core_index()==2,"overdrive opening uses stronger core artwork")
	g.campaign.encounter.launch_missiles()
	check(g.bullets.any(func(b): return b.get("boss_missile",false) and b.get("home",0)>0),"new attack launches pictured homing missiles")
	g.campaign.respawn(); check(g.boss_phase==1 and g.campaign.encounter.overdrive==0 and g.campaign.encounter.pressure_time<0,"retry resets enhanced boss and pressure")
	fresh(); boss(); g.player=Vector2(550,5900); g.grounded=true; g.velocity=Vector2.ZERO
	g.campaign.encounter.pressure_camp=2.69; g.campaign.encounter.update(0.02)
	check(g.campaign.encounter.pressure_time>=0 and g.velocity.y==0,"upper camping starts a harmless pressure warning")
	g.campaign.encounter.update(0.5); check(g.velocity.y==0,"pressure respects telegraph time")
	g.campaign.encounter.update(0.42)
	check(g.velocity.y>=480 and g.drop_timer>0 and g.jumps==2,"pressure forces a drop through upper ledges")
	key(KEY_SPACE,true); step(60); key(KEY_SPACE,false)
	check(g.player.y>=6190,"holding jump cannot camp through pressure")
	fresh(); g.player=Vector2(90,6300); g.grounded=true
	key(KEY_RIGHT,true)
	var climbed=false
	for i in range(100):
		if g.player.x>265: key(KEY_RIGHT,false)
		step(1)
		if g.grounded and g.player.y<=6190.1: climbed=true; break
	check(climbed,"bottom launch pad returns player to first ledge with real movement")
	key(KEY_RIGHT,true)
	for i in range(50):
		if g.player.x>=345: break
		step(1)
	key(KEY_SPACE,true)
	var reached=false
	for i in range(60):
		step(1)
		if g.grounded and g.player.y<=6080.1: reached=true; break
	key(KEY_SPACE,false); key(KEY_RIGHT,false); step(1)
	check(reached,"first ledge connects to the second by a normal jump")
	for code in held.keys(): key(code,false)
	print("BOSS V5 TEST: ","PASS" if errors.is_empty() else "FAIL"," ",errors)
	g.queue_free(); await process_frame; g=null; await process_frame
	call_deferred("quit",0 if errors.is_empty() else 1)
