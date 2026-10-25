extends SceneTree
var g
var failures: Array[String]=[]
var held: Dictionary={}
var shaft_target=-1.0

func _initialize(): call_deferred("run")
func check(ok: bool, note: String):
	if not ok: failures.append(note)
func press(code: int, down: bool):
	if held.get(code,false)==down: return
	held[code]=down
	var e=InputEventKey.new(); e.physical_keycode=code; e.keycode=code; e.pressed=down
	Input.parse_input_event(e); Input.flush_buffered_events()
func release():
	for code in held.keys(): press(code,false)
func fresh(number: int):
	release(); g.aim_override=Vector2.ZERO; g.stage=number; g.fixed_seed=true; g.start_game()
	g.muted=true; g.set_process(false); g.set_physics_process(false)
func run():
	g=load("res://game.gd").new(); root.add_child(g)
	g.set_process(false); g.set_physics_process(false); g.muted=true
	fresh(1)
	g.enemies.clear(); g.player=Vector2(400,500); g.grounded=true; g.velocity=Vector2.ZERO
	for grounded in [true,false]:
		g.grounded=grounded
		for direction in range(16):
			g.aim_override=Vector2.RIGHT.rotated(direction*TAU/16); g.bullets.clear(); g.saber_time=0; g.hurt_pose=0
			g.shoot(false)
			var gun=g.walk_arm(0,true)
			var root_world=g.player+Vector2(gun.root.x*g.facing,gun.root.y)
			var muzzle=g.muzzle_position()
			check(g.bullets[-1].p.distance_to(muzzle)<0.01,"shot starts at bone muzzle")
			check(g.bullets[-1].v.normalized().dot(g.aim_override)>0.999,"16 direction velocity")
			check((muzzle-root_world).normalized().dot(g.aim_override)>0.999,"16 direction cannon alignment")
	# Keyboard diagonals and vertical aim still permit ordinary movement.
	g.aim_override=Vector2.ZERO; press(KEY_UP,true); press(KEY_RIGHT,true); g.update_aim()
	check(g.aim_direction.distance_to(Vector2(1,-1).normalized())<0.01,"keyboard upward diagonal")
	release(); press(KEY_DOWN,true); g.update_aim(); check(g.aim_direction==Vector2.DOWN,"keyboard straight down"); release()
	g.player=Vector2(500,610); g.grounded=true; g.velocity=Vector2(285,0); g.facing=-1; g.walk_phase=3
	g.aim_override=Vector2.LEFT; g.aim_time=0.25
	var planted_before=g.player.x+g.gait_foot(g.walk_phase).x*g.facing
	g.update_game(1.0/60)
	var planted_after=g.player.x+g.gait_foot(g.walk_phase).x*g.facing
	check(absf(planted_before-planted_after)<0.1,"backward aiming keeps stance foot planted")
	check(g.walk_lean()<0,"backward aiming leans toward actual travel")
	fresh(2)
	check(g.campaign.width>10000 and g.campaign.height==720,"surface horizontal geography")
	check(g.enemies.filter(func(e): return e.kind in [7,8,9]).size()>g.enemies.size()*0.75,"surface mostly airborne enemies")
	check(g.campaign.sheltered(Vector2(1250,610)),"shelter blocks overhead airstrike")
	check(not g.campaign.sheltered(Vector2(1800,610)),"outside shelter exposed")
	fresh(3)
	check(g.campaign.height>6000 and g.campaign.width==1280,"underground vertical geography")
	var plug=g.campaign.plugs[0]
	check(g.campaign.hit_device({"p":plug.rect.get_center(),"r":5,"damage":12}),"shootable downward bulkhead")
	check(plug.hp<=0 and g.platforms[plug.index].size==Vector2.ZERO,"bulkhead opens physical descent")
	var ledge=g.campaign.crumbles[0].rect
	g.player=Vector2(ledge.get_center().x,ledge.position.y); g.grounded=true; press(KEY_DOWN,true); press(KEY_SPACE,true)
	g.update_game(1.0/60)
	check(g.drop_timer>0 and g.player.y>ledge.position.y,"drop through thin ledge deep underground")
	# The shaft zigzags: no band leaves the centre open, so Lumina has to run to a side gap.
	var open_column=true
	for p in g.platforms:
		if p.position.y>700 and p.position.y<5500 and p.position.x<=640 and p.end.x>=640 and p.size.y>=35: open_column=false
	check(not open_column,"shaft centre is blocked")
	release()
	var crumble=g.campaign.crumbles[0]
	g.player=Vector2(crumble.rect.get_center().x,crumble.rect.position.y); g.grounded=true
	g.campaign.update(0.1); check(crumble.timer>0 and crumble.timer<0.65,"crumble timer triggered by landing")
	g.grounded=false; g.campaign.update(0.7); check(g.platforms[crumble.index].size==Vector2.ZERO,"crumble removes collision")
	g.boss_active=true; var anchored=g.boss_pos
	for i in range(120): g.campaign.update_boss(1.0/60)
	check(g.boss_pos==anchored,"final boss fixed to wall")
	check(not g.campaign.boss_vulnerable(),"seals shield final boss")
	for seal in g.campaign.seals: g.campaign.hit_device({"p":seal.p,"r":5,"damage":12})
	check(g.campaign.boss_vulnerable(),"destroying both seals opens core")
	g.campaign.respawn(); check(g.campaign.seals[0].hp>0 and g.boss_hp==g.boss_max_hp,"boss retry resets seals and health")
	# Enemies off screen hold their fire.
	fresh(2); g.bullets.clear()
	var far=g.enemies[-1]; far.shot=0; far.origin=g.campaign.camera+Vector2(1400,300); far.p=far.origin
	g.campaign.update_enemies(1.0/60)
	check(g.bullets.is_empty(),"off-screen enemy does not shoot")
	# A launch pad only fires for someone standing on it, not on a ledge above.
	fresh(2); var vent=g.campaign.data.vents[0]
	g.player=Vector2(vent[0]+vent[2]/2,vent[1]-140); g.grounded=true; g.velocity=Vector2.ZERO
	g.campaign.update(1.0/60); check(g.velocity.y==0,"launch pad ignores a ledge above it")
	g.player.y=vent[1]; g.grounded=true; g.campaign.update(1.0/60); check(g.velocity.y<-500,"launch pad launches from its top")
	# The saber cuts the bulkhead underfoot and the boss seals.
	fresh(3); var bulkhead=g.campaign.plugs[0]
	g.player=Vector2(bulkhead.rect.get_center().x,bulkhead.rect.position.y); g.grounded=true
	g.begin_saber(2); g.saber_time=g.saber_total-g.saber_startup-0.03; g.update_saber()
	check(bulkhead.hp<=0,"saber breaks the bulkhead underfoot")
	g.boss_active=true; g.reset_saber_action()
	var seal=g.campaign.seals[0]; g.player=seal.p+Vector2(-90,55); g.facing=1; g.grounded=true
	g.begin_saber(2); g.saber_time=g.saber_total-g.saber_startup-0.03; g.update_saber()
	check(seal.hp<12,"saber damages a seal")
	g.boss_active=false; g.reset_saber_action()
	for number in [2,3]: route(number)
	g.state="clear"; g.stage=1; g.complete_or_start(); check(g.stage==2,"stage 1 continues to 2")
	g.state="clear"; g.complete_or_start(); check(g.stage==3,"stage 2 continues to 3")
	g.state="clear"; g.complete_or_start(); check(g.state=="title","final clear returns to title")
	print("CAMPAIGN TEST: ","PASS" if failures.is_empty() else "FAIL"," ",failures)
	quit(0 if failures.is_empty() else 1)

func route(number: int):
	fresh(number)
	var ticks=0
	var jump_age=100
	shaft_target=-1.0
	for i in range(24000):
		g.invincible=999
		var target=Vector2(640,g.player.y) if number==3 else Vector2(g.campaign.arena.position.x+330,610)
		if number==3 and not g.boss_active:
			# Run to the open end of the band underfoot; on a bulkhead floor, stand over the bulkhead.
			target.x=shaft_target if g.grounded or shaft_target<0 else shaft_target
			if g.grounded:
				for p in g.platforms:
					if absf(g.player.y-p.position.y)<3 and g.player.x>=p.position.x-1 and g.player.x<=p.end.x+1:
						if p.size.y>=60 or p.size.x<300: shaft_target=620.0
						elif p.position.x>1: shaft_target=p.position.x-90
						else: shaft_target=p.end.x+90
			target.x=shaft_target if shaft_target>=0 else 640.0
		press(KEY_RIGHT,g.player.x<target.x-18); press(KEY_LEFT,g.player.x>target.x+18)
		if number==2 and not g.boss_active:
			if g.grounded and not g.on_ground(g.player.x+55,g.player.y): jump_age=0
			elif not g.grounded and g.velocity.y>100 and not g.on_ground(g.player.x+75,610) and g.jumps<2: jump_age=0
		press(KEY_SPACE,jump_age<22)
		jump_age+=1
		var aim=Vector2.DOWN if number==3 else Vector2.RIGHT
		if g.boss_active:
			var point=g.boss_hit_rect().get_center()
			if number==3:
				for seal in g.campaign.seals:
					if seal.hp>0: point=seal.p; break
			aim=(point-(g.player-Vector2(0,75))).normalized()
		g.aim_override=aim
		press(KEY_X,i%8<4)
		g.update_game(1.0/60); ticks+=1
		if g.state=="clear": break
		if g.state=="dead": break
	check(g.state=="clear","stage %d end-to-end clear, state %s pos %s boss %d"%[number,g.state,g.player,g.boss_hp])
	check(g.falls==0,"stage %d route has no out-of-world falls"%number)
	print("CAMPAIGN ROUTE ",number," ticks=",ticks," seconds=",ticks/60," player=",g.player," boss=",g.boss_hp," kills=",g.kills," falls=",g.falls)
	release()
