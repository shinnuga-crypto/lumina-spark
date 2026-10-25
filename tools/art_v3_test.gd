extends SceneTree
var g
var errors: Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	if not ok: errors.append(label)
func fresh():
	g.stage=1; g.fixed_seed=true; g.start_game(); g.enemies.clear(); g.gates.clear()
	g.muted=true; g.set_process(false); g.set_physics_process(false)
	g.player=Vector2(400,610); g.grounded=true; g.velocity=Vector2.ZERO; g.facing=1; g.aim_override=Vector2.ZERO
func run():
	g=load("res://game.gd").new(); root.add_child(g)
	check(g.action_art.textures.size()==10,"ten atlas textures load")
	var count=0
	for key in g.action_art.sets:
		var info=g.action_art.sets[key]
		var size=g.action_art.textures[key].get_size()
		for f in info.get("frames",info.get("regions",[])):
			var r=f.region if f is Dictionary else f
			check(r[0]>=0 and r[1]>=0 and r[0]+r[2]<=size.x and r[1]+r[3]<=size.y,"region stays in atlas "+key)
			count+=1
	check(count==62,"24 character frames and 38 VFX/boss regions")
	for airborne in [false,true]:
		for tier in range(3):
			fresh(); g.grounded=not airborne; g.begin_saber(tier)
			g.saber_time=g.saber_total-g.saber_startup-0.01
			var v=g.hero_visual()
			check(v.has("v3") and v.region.size.x>256,"large atlas region used")
			check(v.name==("air_saber" if airborne else "saber"),"air/ground art selected")
			check(v.v3==(("heavy-air" if airborne else "heavy") if tier==2 else ("air" if airborne else "ground")),"charge tier artwork selected")
			var socket=g.muzzle_position()-g.player
			g.facing=-1
			check((g.muzzle_position()-g.player).distance_to(Vector2(-socket.x,socket.y))<0.01,"socket mirrors with artwork")
	fresh(); g.dash_timer=0.15; g.velocity.x=720
	check(g.hero_visual().v3=="dash" and g.hero_visual().frame==0,"dash kick pose")
	g.dash_timer=0.07; check(g.hero_visual().frame==1,"dash glide pose")
	g.aim_override=Vector2.RIGHT; g.aim_time=0.25; g.update_aim(); g.shoot(false)
	check(g.hero_visual().frame==2 and g.bullets[-1].p.distance_to(g.muzzle_position())<0.01,"dash shot and drawn cannon socket")
	g.aim_override=Vector2(1,-1).normalized(); g.update_aim()
	check(not g.hero_visual().has("texture"),"angled dash fire keeps cannon bones")
	g.aim_override=Vector2.ZERO; g.begin_saber(2)
	g.saber_time=g.saber_total-g.saber_startup-0.025
	check(g.hero_visual().v3=="dash" and g.hero_visual().frame==3,"dash slash has its own thrust art")
	fresh(); g.saber_charge=1.6
	check(not g.hero_visual().has("texture") and g.saber_blade_length()==76,"stationary MAX keeps shared rig and long blade")
	g.aim_override=Vector2.UP; g.aim_time=0.3; g.update_aim()
	check(not g.hero_visual().has("texture"),"aim while charging keeps independent cannon")
	fresh(); g.enemy_shot(Vector2(600,400),Vector2.DOWN*80,11,"bomb")
	check(g.bullets[-1].solid and g.action_art.projectile_frame(g.bullets[-1])==3,"uncuttable bomb uses bomb artwork before solid spike fallback")
	g.enemy_shot(Vector2(600,400),Vector2.LEFT*80,8,"solid")
	check(g.action_art.projectile_frame(g.bullets[-1])<0,"ordinary solid shots keep spike appearance")
	fresh(); g.grounded=false; g.begin_saber(2); g.saber_time=g.saber_total-g.saber_startup-0.025
	check(not g.saber_catches(g.player+Vector2(-170,-55),6) and g.saber_catches(g.player+Vector2(170,-55),6),"air MAX only cuts the forward side")
	print("ART V3 TEST: ","PASS" if errors.is_empty() else "FAIL"," ",errors)
	call_deferred("finish")

func finish():
	# Release run() locals that hold atlas textures before shutting down.
	g.queue_free(); await process_frame; g=null; await process_frame
	call_deferred("quit",0 if errors.is_empty() else 1)
