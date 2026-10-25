extends SceneTree
var g
var errors: Array[String]=[]
var held={}
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	if not ok: errors.append(label)
func press(code: int, value: bool):
	if held.get(code,false)==value: return
	held[code]=value; g.test_key(code,value)
func step(count: int):
	for i in range(count): g.update_game(1.0/60)
func fresh():
	for key in held.keys(): press(key,false)
	g.stage=1; g.fixed_seed=true; g.start_game(); g.muted=true; g.set_process(false); g.set_physics_process(false)
	g.enemies.clear(); g.bullets.clear(); g.gates.clear(); g.cores.clear(); g.moving.clear(); g.lasers.clear(); g.pickups.clear()
	g.platforms.clear(); g.platforms.append(Rect2(0,610,6000,140)); g.player=Vector2(300,610); g.grounded=true; g.velocity=Vector2.ZERO; g.invincible=999
	g.facing=1; g.aim_override=Vector2.ZERO; g.mouse_aim=false
func waves() -> Array:
	return g.bullets.filter(func(b): return b.get("slash_wave",0)>0)
func run():
	g=load("res://game.gd").new(); root.add_child(g)
	for duration in [12,30,60,95]:
		fresh(); press(KEY_K,true); step(duration); press(KEY_K,false); step(1)
		check(g.saber_tier==1 and g.saber_time>0,"first charge available from delay through near MAX %d"%duration)
	fresh(); press(KEY_K,true); step(10); press(KEY_K,false); step(3)
	check(g.saber_tier==0,"release before delay stays tap")
	fresh(); press(KEY_K,true); step(100); press(KEY_K,false); step(3)
	check(g.saber_tier==2,"full threshold still 1.6 seconds")
	fresh(); g.begin_saber(1); g.saber_time=g.saber_total-g.saber_startup-0.025
	check(g.saber_catches(g.player+Vector2(170,-55),5),"first charge reaches 180 instead of 150")
	for vx in [0,285]:
		fresh(); g.velocity.x=vx
		for amount in [0.2,0.8,1.59,1.6]:
			g.saber_charge=amount
			check(g.saber_blade_length()==(76 if amount>=1.6 else 42),"small blade until MAX at speed %d"%vx)
			check(not g.hero_visual().has("texture"),"held pose uses same rig at speed %d"%vx)
	fresh(); g.grounded=false; g.begin_saber(2); g.saber_time=g.saber_total-g.saber_startup-0.025
	for facing in [-1,1]:
		g.facing=facing; g.saber_facing=facing
		check(g.saber_catches(g.player+Vector2(facing*170,-55),5) and not g.saber_catches(g.player+Vector2(-facing*170,-55),5),"air MAX directional on both facings")
	for order in ["saber","both","fire"]:
		fresh(); press(KEY_X,true); press(KEY_K,true); step(65); g.bullets.clear()
		if order in ["saber","both"]: press(KEY_K,false)
		if order in ["fire","both"]: press(KEY_X,false)
		step(8)
		check(waves().size()==1 and waves()[0].slash_wave==1,"combined charge release order "+order)
		check(g.charge==0 and g.charge_release<0,"combined charge consumes cannon "+order)
		check(g.bullets.size()==waves().size(),"no extra cannon charge shot "+order)
		step(20); check(waves().size()==1,"double cut emits just one wave "+order)
	fresh(); press(KEY_X,true); press(KEY_K,true); step(105); g.bullets.clear(); press(KEY_K,false); step(10)
	check(waves().size()==1 and waves()[0].slash_wave==2 and waves()[0].damage==30,"double MAX makes stronger golden wave")
	check(g.fire_charge_spent and g.charge==0,"held fire cannot recharge until released after combined move")
	fresh(); press(KEY_K,true); step(35); press(KEY_K,false); step(8)
	check(waves().is_empty(),"saber alone never emits flying slash")
	fresh(); g.charge=1; g.begin_saber(1); g.saber_time=g.saber_total-g.saber_startup-0.025; g.update_saber()
	g.spawn_enemy(Vector2(600,610),0,0); var target=g.enemies[-1]; target.hp=100
	for i in range(45): g.update_bullets(1.0/60)
	check(target.hp==86,"flying slash hits once beyond melee reach")
	fresh(); g.gates.append({"x":400.0,"passed":true,"open":false,"kind":"sync","room":0})
	g.charge=1; g.begin_saber(1); g.saber_time=g.saber_total-g.saber_startup-0.025; g.update_saber()
	g.spawn_enemy(Vector2(600,610),0,0); var behind=g.enemies[-1]; behind.hp=100
	for i in range(45): g.update_bullets(1.0/60)
	check(behind.hp==100 and waves().is_empty(),"closed wall stops flying slash")
	for tier in range(3):
		fresh(); g.dash_timer=0.15; g.begin_saber(tier); g.saber_time=g.saber_total-g.saber_startup-0.025
		check(g.hero_visual().frame==3 and g.action_art.sets.lance.regions.size()==6,"dash thrust and lance art exist for tier %d"%tier)
	for key in held.keys(): press(key,false)
	print("CHARGE V4 TEST: ","PASS" if errors.is_empty() else "FAIL"," ",errors)
	g.queue_free(); await process_frame; g=null; await process_frame
	quit(0 if errors.is_empty() else 1)
