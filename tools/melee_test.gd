extends SceneTree
var g
var errors: Array[String]=[]
var held: Dictionary={}
func _initialize(): call_deferred("run")
func check(ok: bool, note: String):
	if not ok: errors.append(note)
func press(code: int, down: bool):
	if held.get(code,false)==down: return
	held[code]=down; g.test_key(code,down)
func release():
	for code in held.keys(): press(code,false)
func step(count: int):
	for i in range(count): g.update_game(1.0/60)
func fresh():
	release(); g.stage=1; g.fixed_seed=true; g.start_game(); g.muted=true; g.invincible=999
	g.enemies.clear(); g.gates.clear(); g.cores.clear(); g.moving.clear(); g.lasers.clear(); g.pickups.clear()
	g.platforms.clear(); g.platforms.append(Rect2(0,610,6000,140))
	g.player=Vector2(300,610); g.grounded=true; g.velocity=Vector2.ZERO; g.facing=1; g.aim_override=Vector2.ZERO
func activate(tier: int, kind="ground"):
	g.grounded=kind=="ground"; g.dash_timer=0.1 if kind=="dash" else 0.0
	g.begin_saber(tier); g.saber_kind=kind
	g.saber_time=g.saber_total-g.saber_startup-0.025
func run():
	g=load("res://game.gd").new(); root.add_child(g); g.muted=true; g.set_process(false); g.set_physics_process(false)
	check(g.hero_actions.weapon!=null,"GPTImage weapon loads")
	for tier in range(3):
		fresh(); press(KEY_K,true); step([3,52,100][tier])
		# Tier 0 is a tap: it slashes on the press. Longer holds have finished that tap and only charge.
		if tier>0: check(g.saber_time==0 and not g.saber_active(),"held saber has no passive attack %d"%tier)
		var prep=g.walk_arm(0,false).muzzle
		press(KEY_K,false); step(1)
		check(g.saber_tier==tier and g.saber_time>0,"release selects charge tier %d"%tier)
		if tier>0: check(g.walk_arm(0,false).muzzle.distance_to(prep)<12,"charged pose flows into release")
		check(g.saber_reach()==[140.0,150.0,220.0][tier],"tier reach")
		g.saber_time=g.saber_total-g.saber_startup-0.025
		g.spawn_enemy(g.player+Vector2(g.saber_reach()-8,0),0,0); var enemy=g.enemies[-1]; enemy.hp=100
		g.update_saber(); g.update_saber()
		check(enemy.hp==100-g.SABER_DAMAGE[tier],"one hit with tier damage")
		g.spawn_enemy(g.player+Vector2(g.saber_reach()+110,0),0,0); var far=g.enemies[-1]; far.hp=100
		g.update_saber(); check(far.hp==100,"outside reach remains unharmed")
		g.boss_active=true; g.boss_intro=0; g.boss_hp=100; g.boss_pos=g.player+Vector2(g.saber_reach()-8,30)
		g.update_saber(); g.update_saber(); check(g.boss_hp==100-g.SABER_BOSS_DAMAGE[tier],"one boss hit at tier damage")
	fresh(); press(KEY_RIGHT,true); step(15); press(KEY_K,true); step(100); press(KEY_K,false); step(1)
	check(absf(g.velocity.x-285)<1,"charged slash keeps running speed")
	check(g.hero_visual().name=="saber" and g.walk_phase>0,"running feet continue during slash")
	fresh(); press(KEY_K,true); step(52); press(KEY_SPACE,true); press(KEY_K,false); step(1)
	check(g.saber_kind=="air" and g.velocity.y< -550 and g.jumps==1,"jump release selects air slash without changing jump")
	g.grounded=true; check(g.hero_visual().name=="air_saber","landing finishes the same air swing")
	fresh(); press(KEY_K,true); step(52); press(KEY_SHIFT,true); press(KEY_K,false); step(1)
	check(g.saber_kind=="dash" and g.velocity.x==720 and g.dash_timer>0,"dash release selects thrust without canceling dash")
	fresh(); activate(0,"air")
	# The drawn air slash sweeps from overhead down through the front, not behind.
	check(g.saber_catches(g.player+Vector2(80,-55),5) and g.saber_catches(g.player+Vector2(10,-150),5) and not g.saber_catches(g.player+Vector2(-80,-55),5),"air slash sweeps overhead and front")
	fresh(); activate(0,"ground")
	check(not g.saber_catches(g.player+Vector2(-80,-55),5),"ground slash stays directional")
	fresh(); activate(2,"dash")
	check(g.saber_catches(g.player+Vector2(180,-60),5) and not g.saber_catches(g.player+Vector2(100,-180),5),"dash thrust has a long narrow hit area")
	fresh(); press(KEY_K,true); step(100)
	g.enemy_shot(g.player+Vector2(60,-50),Vector2.ZERO); g.update_bullets(0)
	check(g.bullets[0].enemy,"holding charge does not reflect")
	press(KEY_K,false); step(1); g.saber_time=g.saber_total-g.saber_startup-0.025; g.update_bullets(0)
	check(not g.bullets[0].enemy and g.bullets[0].get("reflected",false),"charged release has timed reflection")
	g.bullets.clear(); g.enemy_shot(g.player+Vector2(60,-50),Vector2.ZERO,9,"solid"); g.update_bullets(0)
	check(g.bullets.size()==1 and g.bullets[0].enemy,"even max charge cannot erase solid shots")
	fresh(); var door={"x":400.0,"passed":true,"open":false,"kind":"sync","room":0}
	g.gates.append(door); g.player=Vector2(350,610); activate(2)
	g.spawn_enemy(Vector2(430,610),0,0); g.enemies[-1].hp=100; g.update_saber()
	check(g.enemies[-1].hp==100,"max charge cannot cut through a locked wall")
	fresh(); g.grounded=false
	var legs=[]
	for vy in [-600,0,700]:
		g.velocity.y=vy; var pose=g.hero_actions.leg(0,"near"); legs.append(pose.ankle)
		check(absf(g.hero_actions.hip(0).distance_to(pose.knee)-24)<0.1 and absf(pose.knee.distance_to(pose.ankle)-29)<0.1,"jump legs keep bone lengths")
	check(legs[0].distance_to(legs[1])>4 and legs[1].distance_to(legs[2])>6,"rise apex and descent have different leg poses")
	fresh(); activate(1); g.saber_time=0.0001; g.aim_time=0.3
	var returning=g.walk_arm(0,true).muzzle; g.saber_time=0
	check(returning.distance_to(g.walk_arm(0,true).muzzle)<0.1,"gun returns continuously after recovery")
	fresh(); press(KEY_K,true); step(70); g.invincible=0; g.hurt(1)
	check(g.saber_charge==0 and g.saber_pending<0 and g.saber_time==0,"damage cancels charge and queued slash")
	release()
	fresh(); press(KEY_K,true); step(1)
	check(g.saber_time>0 and g.saber_tier==0 and not g.saber_seq.is_empty(),"press slashes at once with drawn frames")
	release(); fresh(); press(KEY_K,true); step(49); press(KEY_K,false); step(1)
	check(g.saber_tier==1,"charge is counted from the press, not from the delay")
	fresh(); activate(1)
	g.saber_time=g.saber_total
	g.spawn_enemy(g.player+Vector2(80,0),0,0); var target=g.enemies[-1]; target.hp=100
	while g.saber_time>0:
		g.update_saber(); g.saber_time=maxf(0,g.saber_time-1.0/60)
	check(target.hp==100-2*g.SABER_DAMAGE[1],"first charge cuts twice")
	release()
	# Standing still and mashing: each tap waits longer. Moving resets it.
	fresh()
	var waits=[]
	for tap in range(3):
		press(KEY_K,true); step(1); waits.append(g.saber_cooldown); press(KEY_K,false)
		while g.saber_cooldown>0 or g.saber_time>0: step(1)
	check(waits[1]>waits[0]+0.1 and waits[2]>waits[1]+0.1,"standing mash adds delay")
	press(KEY_RIGHT,true); step(3); press(KEY_RIGHT,false)
	press(KEY_K,true); step(1); press(KEY_K,false)
	check(absf(g.saber_cooldown-g.TAP_COOLDOWN)<0.03,"moving resets the mash delay")
	release()
	# Only the part of the arc swept so far hits.
	fresh(); activate(0); g.saber_time=g.saber_total-g.saber_startup-0.002
	check(not g.saber_catches(g.player+Vector2(90,-30),5) and g.saber_catches(g.player+Vector2(-20,-150),5),"slash hits only what it has swept")
	print("MELEE TEST: ","PASS" if errors.is_empty() else "FAIL"," ",errors)
	quit(0 if errors.is_empty() else 1)
