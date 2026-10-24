extends Node2D

const W = 1280.0
const H = 720.0
const ROOM = 1120.0
const BOSS_X = ROOM * 24
const END_X = BOSS_X + 1200
const CYAN = Color("63f4e6")
const PINK = Color("ff82c6")
var layout: Array = []
var moving: Array[Dictionary] = []
var art: Dictionary = {}
var fx: Array[Dictionary] = []
var hitstop = 0.0
var drop_timer = 0.0
var hurt_pose = 0.0
var muzzle_time = 0.0
var boss_phase = 1
var boss_intro = 0.0
var boss_dash = 0.0
var boss_dash_dir = -1.0
var boss_rays: Array[Dictionary] = []
var ending_time = 0.0
var font: Font
var atlas: Texture2D
var backdrop: Texture2D
var regions: Array[Rect2] = []
var platforms: Array[Rect2] = []
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var pickups: Array[Vector2] = []
var gates: Array[Dictionary] = []
var cores: Array[Dictionary] = []
var lasers: Array[Dictionary] = []
var core_count = 0
var player = Vector2(130, 500)
var velocity = Vector2.ZERO
var camera_x = 0.0
var hp = 12
var max_hp = 12
var facing = 1
var jumps = 0
var grounded = false
var invincible = 0.0
var shot_timer = 0.0
var charge = 0.0
var dash_timer = 0.0
var dash_cooldown = 0.0
var coyote = 0.0
var jump_buffer = 0.0
var state = "title"
var elapsed = 0.0
var clock = 0.0
var kills = 0
var deaths = 0
var falls = 0
var safe_pos = Vector2(130, 610)
var checkpoint = 0
var easy = false
var muted = false
var banner = ""
var banner_time = 0.0
var boss_hp = 320
var boss_max_hp = 320
var boss_pos = Vector2(BOSS_X + 850, 540)
var boss_active = false
var boss_timer = 0.0
var boss_cycle = 0
var boss_flash = 0.0
var boss_warning = 0.0
var shake = 0.0
var prev_jump = false
var prev_dash = false
var prev_charge = false
var music: AudioStreamPlayer
var sfx: Dictionary = {}
var rng = RandomNumberGenerator.new()
var sector_names = ["01  星明かりの外壁", "02  配電回廊", "03  空中搬送路", "04  冷却プラント", "05  防衛区画", "06  コアへの道", "07  星炉の守護者"]

func _ready():
	rng.seed = 7234
	var measured = JSON.parse_string(FileAccess.get_file_as_string("res://assets/regions.json"))
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo", "sans-serif"])
	if ResourceLoader.exists("res://assets/atlas.png"):
		atlas = load("res://assets/atlas.png")
		var im = atlas.get_image()
		var cw = im.get_width() / 4
		var ch = im.get_height() / 2
		for i in range(8):
			var cell = Rect2i((i % 4) * cw, (i / 4) * ch, cw, ch)
			var bounds = im.get_region(cell).get_used_rect()
			regions.append(Rect2(Vector2(cell.position + bounds.position), Vector2(bounds.size)))
		regions.clear()
		for r in measured.atlas: regions.append(Rect2(r[0],r[1],r[2],r[3]))
	if ResourceLoader.exists("res://assets/background.png"):
		backdrop = load("res://assets/background.png")
	for name in ["shot", "hit", "jump", "dash", "heal", "win", "charge"]:
		if ResourceLoader.exists("res://assets/" + name + ".wav"):
			sfx[name] = load("res://assets/" + name + ".wav")
	music = AudioStreamPlayer.new()
	add_child(music)
	if ResourceLoader.exists("res://assets/music.wav"):
		music.stream = load("res://assets/music.wav")
		music.volume_db = -17
		music.finished.connect(func(): music.play())
	for entry in [["poses",4],["enemies",4],["explosion",6],["charge",6],["muzzle",6],["tiles",3],["core",1]]:
		var path = "res://assets/"+entry[0]+("-v2" if entry[0] in ["poses","enemies"] else "")+".png"
		if ResourceLoader.exists(path):
			var tex = load(path)
			var im = tex.get_image()
			var rects: Array[Rect2] = []
			var cols = 2 if entry[0] in ["poses","enemies"] else int(entry[1])
			var rows = 2 if entry[0] in ["poses","enemies"] else 1
			var cw = im.get_width()/cols
			for i in range(entry[1]):
				var cell = Rect2i((i%cols)*cw,(i/cols)*(im.get_height()/rows),cw,im.get_height()/rows)
				# Generated sheets use measured frame boundaries where equal slicing clips art.
				var cuts = {"tiles":[0.0,0.38,0.60,1.0],"explosion":[0.0,0.13,0.30,0.49,0.67,0.84,1.0],"muzzle":[0.0,0.11,0.29,0.515,0.69,0.90,1.0]}
				if cuts.has(entry[0]):
					var c = cuts[entry[0]]
					cell = Rect2i(int(c[i]*im.get_width()),0,int((c[i+1]-c[i])*im.get_width()),im.get_height())
				if entry[0]=="enemies" and i>=2:
					var split = int(im.get_width()*0.57)
					cell = Rect2i(0 if i==2 else split,im.get_height()/2,split if i==2 else im.get_width()-split,im.get_height()/2)
				var bounds = im.get_region(cell).get_used_rect()
				rects.append(Rect2(Vector2(cell.position+bounds.position),Vector2(bounds.size)))
			rects.clear()
			for r in measured[entry[0]]: rects.append(Rect2(r[0],r[1],r[2],r[3]))
			art[entry[0]] = {"texture":tex,"regions":rects}
	build_level()
	if "--self-test" in OS.get_cmdline_user_args():
		muted = true
		call_deferred("self_test")
	if "--capture-qa" in OS.get_cmdline_user_args():
		muted = true
		call_deferred("capture_qa")

func sound(name: String):
	if muted or not sfx.has(name): return
	var a = AudioStreamPlayer.new()
	add_child(a)
	a.stream = sfx[name]
	a.volume_db = -16
	a.finished.connect(a.queue_free)
	a.play()

func build_level():
	platforms.clear()
	enemies.clear()
	gates.clear()
	cores.clear()
	lasers.clear()
	moving.clear()
	core_count = 0
	pickups.clear()
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://data/level.json")).rooms
	for room in range(layout.size()):
		var d = layout[room]
		var x = room*ROOM
		for f in d.floor: platforms.append(Rect2(x+f[0],610,f[1],130))
		for p in d.platforms: platforms.append(Rect2(x+p[0],p[1],p[2],24))
		for m in d.moving:
			var origin = Vector2(x+m[0],m[1])
			moving.append({"index":platforms.size(),"origin":origin,"amp":Vector2(m[3],m[4]),"speed":m[5],"delta":Vector2.ZERO})
			platforms.append(Rect2(origin,Vector2(m[2],24)))
		for e in d.enemies: spawn_enemy(Vector2(x+e[1],e[2]),int(e[0]),room)
		for l in d.lasers: lasers.append({"x":x+l,"phase":float(room)*0.7})
		if not d.platforms.is_empty():
			var top = d.platforms[-1]
			pickups.append(Vector2(x+top[0]+top[2]/2,top[1]-35))
		if d.has("core"):
			gates.append({"x":x+1080,"room":room,"open":false})
			cores.append({"p":Vector2(x+d.core[0],d.core[1]),"room":room,"got":false,"sync":12.0,"waves":0})
	platforms.append(Rect2(BOSS_X,610,1400,130))
	platforms.append(Rect2(BOSS_X+260,460,180,24))
	platforms.append(Rect2(BOSS_X+730,460,180,24))

func spawn_enemy(pos: Vector2, kind: int, room: int):
	enemies.append({"p":pos,"origin":pos,"kind":kind,"room":room,"hp":[8,6,12,10,8,10][kind],"shield":kind==2,"t":rng.randf_range(0,5),"shot":rng.randf_range(0.6,2),"flash":0.0})

func start_game():
	hp = 20 if easy else 12
	max_hp = hp
	player = Vector2(130, 500)
	velocity = Vector2.ZERO
	invincible = 0
	shot_timer = 0
	charge = 0
	dash_timer = 0
	dash_cooldown = 0
	jumps = 0
	grounded = false
	prev_jump = false
	prev_dash = false
	prev_charge = false
	camera_x = 0
	elapsed = 0
	kills = 0
	deaths = 0
	falls = 0
	safe_pos = Vector2(130, 610)
	checkpoint = 0
	boss_hp = boss_max_hp
	boss_phase = 1
	boss_intro = 0
	boss_dash = 0
	boss_pos = Vector2(BOSS_X+850,550)
	boss_rays.clear()
	fx.clear()
	hitstop = 0
	drop_timer = 0
	hurt_pose = 0
	ending_time = 0
	boss_active = false
	boss_cycle = 0
	boss_timer = 0
	bullets.clear()
	particles.clear()
	build_level()
	state = "play"
	banner = "ルミナ、発進！ 星炉の暴走を止めよう。"
	banner_time = 4
	if not muted: music.play()

func key(code: int) -> bool:
	return Input.is_physical_key_pressed(code)

func joy(button: int) -> bool:
	return Input.is_joy_button_pressed(0, button)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if event.keycode == KEY_M:
			muted = not muted
			if muted: music.stop()
			elif state in ["play", "pause", "dead"]: music.play()
		if event.keycode == KEY_ESCAPE:
			if state == "play": state = "pause"
			elif state == "pause": state = "play"
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if state == "title" or state == "clear": start_game()
			elif state == "dead": respawn()
			elif state == "pause": state = "play"
		if event.keycode == KEY_E and state == "title": easy = not easy
		if event.keycode == KEY_R and state == "pause": state = "title"; music.stop()
	if event is InputEventJoypadButton and event.pressed:
		if state == "title" and event.button_index in [JOY_BUTTON_Y,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]: easy = not easy
		if state == "pause" and event.button_index == JOY_BUTTON_BACK:
			state = "title"
			music.stop()
		if event.button_index == JOY_BUTTON_START:
			if state == "title" or state == "clear": start_game()
			elif state == "dead": respawn()
			elif state == "pause": state = "play"
			elif state == "play": state = "pause"
		if event.button_index == JOY_BUTTON_A and state in ["title", "clear", "dead"]:
			if state == "dead": respawn()
			else: start_game()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var m = get_global_mouse_position()
		if state == "title":
			if Rect2(100, 462, 360, 64).has_point(m): start_game()
			elif Rect2(100, 542, 480, 44).has_point(m): easy = not easy
		elif state == "dead": respawn()
		elif state == "clear": start_game()
		elif state == "pause": state = "play"

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play": state = "pause"

func _process(dt):
	clock += dt
	queue_redraw()

func _physics_process(dt):
	if state in ["play","defeat"]: update_game(dt)

func update_game(dt: float):
	update_fx(dt)
	if state == "defeat":
		ending_time += dt
		shake = 8*(1-ending_time/2.6)
		if int(ending_time*12)>int((ending_time-dt)*12):
			fx.append({"p":boss_pos+Vector2(rng.randf_range(-85,85),rng.randf_range(-150,0)),"age":0.0,"size":140.0})
		if ending_time >= 2.6:
			state = "clear"
			sound("win")
		return
	if state != "play": return
	if hitstop>0:
		hitstop -= dt
		return
	hurt_pose = maxf(0,hurt_pose-dt)
	muzzle_time = maxf(0,muzzle_time-dt)
	for m in moving:
		var prev = platforms[m.index]
		var pos = m.origin+m.amp*sin((elapsed+dt)*m.speed)
		m.delta = pos-prev.position
		if grounded and absf(player.y-prev.position.y)<2 and player.x>prev.position.x-16 and player.x<prev.end.x+16: player += m.delta
		platforms[m.index] = Rect2(pos,prev.size)
	elapsed += dt
	drop_timer = maxf(0,drop_timer-dt)
	invincible = maxf(0, invincible - dt)
	shot_timer -= dt
	dash_cooldown -= dt
	banner_time -= dt
	boss_flash -= dt
	shake = maxf(0, shake - dt * 25)
	var axis = float(key(KEY_RIGHT) or key(KEY_D)) - float(key(KEY_LEFT) or key(KEY_A))
	var ja = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if absf(ja) > 0.25: axis = ja
	if joy(JOY_BUTTON_DPAD_LEFT): axis = -1
	if joy(JOY_BUTTON_DPAD_RIGHT): axis = 1
	var jump = key(KEY_SPACE) or key(KEY_Z) or joy(JOY_BUTTON_A)
	var dash = key(KEY_SHIFT) or key(KEY_C) or joy(JOY_BUTTON_B)
	var charging = key(KEY_V) or joy(JOY_BUTTON_Y)
	var fire = key(KEY_X) or key(KEY_J) or joy(JOY_BUTTON_X)
	if jump and not prev_jump: jump_buffer = 0.12
	if jump and not prev_jump and grounded and player.y<600 and (key(KEY_DOWN) or key(KEY_S) or joy(JOY_BUTTON_DPAD_DOWN)):
		drop_timer = 0.25
		grounded = false
		player.y += 5
		velocity.y = 80
		jump_buffer = 0
		coyote = 0
	jump_buffer -= dt
	if grounded: coyote = 0.12
	else: coyote -= dt
	if jump_buffer > 0 and (coyote > 0 or jumps < 2):
		velocity.y = -610
		jumps += 1
		grounded = false
		coyote = 0
		jump_buffer = 0
		sound("jump")
	if not jump and prev_jump and velocity.y < -220: velocity.y = -220
	if axis != 0: facing = 1 if axis > 0 else -1
	if dash and not prev_dash and dash_cooldown <= 0:
		dash_timer = 0.17
		dash_cooldown = 0.7
		invincible = maxf(invincible, 0.19)
		sound("dash")
	if charging:
		charge = minf(1.5, charge + dt)
	elif prev_charge:
		shoot(charge >= 0.8)
		charge = 0
	if fire and shot_timer <= 0 and not charging: shoot(false)
	prev_jump = jump
	prev_dash = dash
	prev_charge = charging
	if dash_timer > 0:
		dash_timer -= dt
		velocity.x = facing * 720
		velocity.y = 0
		burst(player + Vector2(0,-20), CYAN, 1)
	else:
		var on_ice = int(player.x/ROOM)<24 and layout[int(player.x/ROOM)].ice and grounded
		if hurt_pose<=0: velocity.x = move_toward(velocity.x, axis * 285, (430 if on_ice else 2300)*dt)
		velocity.y = minf(900, velocity.y + 1600 * dt)
	var old_y = player.y
	player.x = clampf(player.x + velocity.x * dt, 24, END_X - 30)
	player.y += velocity.y * dt
	grounded = false
	for p in platforms:
		if drop_timer>0 and p.size.y<30: continue
		if player.x + 16 > p.position.x and player.x - 16 < p.end.x and old_y <= p.position.y + 1 and player.y >= p.position.y and velocity.y >= 0:
			player.y = p.position.y
			velocity.y = 0
			grounded = true
			jumps = 0
			if player.x - 30 > p.position.x and player.x + 30 < p.end.x:
				var is_moving = false
				for m in moving:
					if platforms[m.index]==p: is_moving = true
				if not is_moving: safe_pos = player
	for gate in gates:
		if not gate.open:
			var alive = false
			for e in enemies:
				if e.room == gate.room and e.hp > 0: alive = true
			var has_core = false
			for core in cores:
				if core.room == gate.room and core.got and core.sync<=0: has_core = true
			if not alive and has_core:
				gate.open = true
				if absf(player.x - gate.x) < 1200: burst(Vector2(gate.x,500),CYAN,22)
			elif player.x > gate.x - 25 and player.x < gate.x + 110:
				player.x = gate.x - 25
				velocity.x = 0
	if player.y > 850:
		# 穴への落下は即死にせず、少し減って直前の足場へ戻る
		falls += 1
		invincible = 0
		hurt(2 if easy else 3)
		if state == "play":
			player = safe_pos
			velocity = Vector2.ZERO
			dash_timer = 0
	if state != "play": return
	for core in cores:
		if core.got and core.sync>0:
			core.sync = maxf(0,core.sync-dt)
			if (core.sync<8 and core.waves==0) or (core.sync<4 and core.waves==1):
				core.waves += 1
				var base = core.room*ROOM
				spawn_enemy(Vector2(base+450,600),4 if core.room>=12 else 0,core.room)
				spawn_enemy(Vector2(base+900,390),5 if core.room>=8 else 1,core.room)
				banner = "増援接近  %d / 2  —  同期完了まで守り抜こう"%core.waves
				banner_time = 2

		if not core.got and (player-Vector2(0,30)).distance_to(core.p)<45:
			core.got = true
			core_count += 1
			hp = mini(max_hp,hp+3)
			burst(core.p,Color("ffd27f"),24)
			sound("heal")
			banner = "スターコア回収  %d / 6  —  12秒間の同期、防衛開始！"%core_count
			banner_time = 3
	for laser in lasers:
		if fmod(elapsed+laser.phase,3.6)>2.2 and absf(player.x-laser.x)<55 and player.y>574:
			hurt(1 if easy else 2)
	var cp = mini(6, int(player.x / (ROOM * 4)))
	if cp > checkpoint:
		checkpoint = cp
		hp = max_hp
		banner = "CHECKPOINT  /  再開地点を更新・全回復"
		banner_time = 3
		sound("heal")
	for i in range(pickups.size()-1,-1,-1):
		if player.distance_to(pickups[i]+Vector2(0,25)) < 50 and hp < max_hp:
			hp = mini(max_hp,hp+4)
			burst(pickups[i],CYAN,14)
			pickups.remove_at(i)
			sound("heal")
	update_enemies(dt)
	update_boss(dt)
	update_bullets(dt)
	for i in range(particles.size()-1,-1,-1):
		var p = particles[i]
		p.p += p.v * dt
		p.v.y += 200 * dt
		p.life -= dt
		if p.life <= 0: particles.remove_at(i)
	camera_x = clampf(lerpf(camera_x,player.x-390,1-exp(-dt*8)),0,END_X-W)

func shoot(big: bool):
	muzzle_time = 0.1
	shot_timer = 0.18
	bullets.append({"p":player+Vector2(facing*43,-60),"v":Vector2(facing*860,0),"enemy":false,"damage":7 if big else 2,"r":15.0 if big else 5.0,"life":1.8})
	sound("charge" if big else "shot")

func enemy_shot(pos: Vector2, vel: Vector2, radius = 8.0):
	bullets.append({"p":pos,"v":vel,"enemy":true,"damage":1 if easy else 2,"r":radius,"life":5.0})

func update_enemies(dt: float):
	for e in enemies:
		if e.hp<=0 or absf(e.p.x-player.x)>1300: continue
		e.t += dt
		e.flash -= dt
		e.shot -= dt
		match e.kind:
			0: e.p.x = e.origin.x+sin(e.t*1.4)*75
			1: e.p.y = e.origin.y+sin(e.t*2)*45
			2: e.p.x = e.origin.x+sin(e.t)*30
			4: e.p.x = e.origin.x+sin(e.t*2.5)*95
			5:
				e.p.x = e.origin.x+sin(e.t)*85
				e.p.y = e.origin.y+sin(e.t*2)*25
		if e.shot<=0 and e.p.x>camera_x+20 and e.p.x<camera_x+W-20:
			e.shot = (2.7 if easy else 1.9) if e.kind!=3 else 2.3
			var aim = (player+Vector2(0,-40)-e.p).normalized()
			if e.kind==5:
				enemy_shot(e.p,Vector2(0,220),13)
			elif e.kind==3:
				for j in range(3): enemy_shot(e.p+Vector2(0,-18),aim.rotated((j-1)*0.14)*(190 if easy else 250),7)
			elif e.kind!=4: enemy_shot(e.p+Vector2(0,-18),aim*(190 if easy else 250))
		if (player+Vector2(0,-40)).distance_to(e.p+Vector2(0,-10))<48: hurt(1 if easy else 2)

func update_boss(dt: float):
	if player.x<BOSS_X+100 or boss_hp<=0: return
	if not boss_active:
		boss_active = true
		boss_intro = 2.2
		boss_timer = 1.4
		banner = "星炉の守護者  /  ASTER GUARDIAN"
		banner_time = 3
	player.x = maxf(BOSS_X+35,player.x)
	if boss_hp<=boss_max_hp/2 and boss_phase==1:
		boss_phase = 2
		boss_intro = 1.6
		boss_timer = 0.8
		bullets.clear()
		shake = 15
		banner = "PHASE 02  /  コア解放 — 上空の予告に注意！"
		banner_time = 3
	if boss_intro>0:
		boss_intro -= dt
		boss_pos.y = lerpf(550,200,clampf(boss_intro/2.2,0,1))
		return
	boss_pos.y = 550+sin(elapsed*2)*12
	for i in range(boss_rays.size()-1,-1,-1):
		var ray = boss_rays[i]
		ray.t -= dt
		if ray.t<0.45 and absf(player.x-ray.x)<33: hurt(2 if easy else 3)
		if ray.t<=0: boss_rays.remove_at(i)
	if boss_dash>0:
		boss_dash -= dt
		boss_pos.x = clampf(boss_pos.x+boss_dash_dir*600*dt,BOSS_X+210,BOSS_X+1010)
	else:
		boss_pos.x = move_toward(boss_pos.x,BOSS_X+800+sin(elapsed*0.65)*140,85*dt)
	boss_timer -= dt
	boss_warning = maxf(0,boss_timer) if boss_timer<0.7 else 0
	if boss_timer<=0:
		boss_cycle += 1
		boss_timer = (1.55 if boss_phase==2 else 2.0)+(0.5 if easy else 0)
		var pattern = boss_cycle%(5 if boss_phase==2 else 3)
		var direction = -1 if player.x<boss_pos.x else 1
		match pattern:
			0:
				for j in range(7): enemy_shot(boss_pos+Vector2(0,-55),Vector2(direction,0).rotated((j-3)*0.22)*230,10)
			1:
				enemy_shot(Vector2(boss_pos.x,585),Vector2(direction*340,0),17)
			2:
				var aim = (player+Vector2(0,-40)-boss_pos).normalized()
				for j in range(3): enemy_shot(boss_pos+Vector2(0,-60),aim.rotated((j-1)*0.24)*280,10)
			3:
				for dx in [-150,0,150]: boss_rays.append({"x":clampf(player.x+dx,BOSS_X+60,END_X-60),"t":1.5})
			4:
				boss_dash = 0.75
				boss_dash_dir = direction
				banner = "突進！ ジャンプかダッシュで回避"
				banner_time = 1.5
	if (player+Vector2(0,-40)).distance_to(boss_pos+Vector2(0,-60))<95: hurt(3)

func update_bullets(dt: float):
	for i in range(bullets.size()-1,-1,-1):
		var b = bullets[i]
		b.p += b.v*dt
		b.life -= dt
		var remove = b.life <= 0 or b.p.x < camera_x - 60 or b.p.x > camera_x + W + 60
		if b.enemy:
			if Rect2(player-Vector2(21,80),Vector2(42,80)).grow(b.r).has_point(b.p):
				hurt(b.damage)
				remove = true
		else:
			for e in enemies:
				if e.hp > 0 and Rect2(e.p-Vector2(28,48),Vector2(56,58)).grow(b.r).has_point(b.p):
					if e.get("shield",false) and b.damage<7:
						burst(b.p,CYAN,3)
						remove = true
						break
					e.shield = false
					e.hp -= b.damage
					e.flash = 0.12
					burst(b.p,PINK,4)
					remove = true
					if e.hp <= 0:
						kills += 1
						hitstop = 0.045
						fx.append({"p":e.p-Vector2(0,20),"age":0.0,"size":100.0})
						burst(e.p,Color("ffc578"),18)
						if kills%4 == 0:
							var drop = e.p-Vector2(0,25)
							var floor_y = 610.0
							for platform in platforms:
								if drop.x>=platform.position.x and drop.x<=platform.end.x and platform.position.y>=drop.y: floor_y = minf(floor_y,platform.position.y)
							pickups.append(Vector2(drop.x,floor_y-30))
					break
			if not remove and boss_active and boss_intro<=0 and boss_hp > 0 and Rect2(boss_pos-Vector2(70,160),Vector2(140,180)).grow(b.r).has_point(b.p):
				boss_hp -= b.damage
				boss_flash = 0.1
				remove = true
				burst(b.p,PINK,6)
				if boss_hp <= 0:
					burst(boss_pos,CYAN,100)
					state = "defeat"
					ending_time = 0
					boss_rays.clear()
					music.stop()
					shake = 15
		if remove: bullets.remove_at(i)

func hurt(amount: int):
	if (invincible > 0 and amount < 99) or state != "play": return
	hp = maxi(0,hp-amount)
	invincible = 1.3
	shake = 8
	hurt_pose = 0.24
	velocity = Vector2(-facing*250,-180)
	dash_timer = 0
	sound("hit")
	burst(player-Vector2(0,30),PINK,15)
	if hp <= 0:
		state = "dead"
		deaths += 1

func respawn():
	player = Vector2(checkpoint*ROOM*4+130,500)
	safe_pos = Vector2(player.x, 610)
	velocity = Vector2.ZERO
	hp = max_hp
	invincible = 2
	bullets.clear()
	charge = 0
	jumps = 0
	dash_timer = 0
	camera_x = clampf(player.x-390,0,END_X-W)
	if checkpoint == 6:
		boss_hp = boss_max_hp
		boss_phase = 1
		boss_rays.clear()
		boss_intro = 0
		boss_dash = 0
		boss_active = false
		boss_cycle = 0
	state = "play"

func burst(pos: Vector2, col: Color, count: int):
	for i in range(count):
		particles.append({"p":pos,"v":Vector2(rng.randf_range(-160,160),rng.randf_range(-180,100)),"life":rng.randf_range(0.18,0.6),"c":col})

func txt(pos: Vector2, value: String, size = 22, color = Color.WHITE):
	draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func sprite(index: int, feet: Vector2, height: float, flip = false, tint = Color.WHITE):
	if not atlas or regions.size()<8:
		draw_circle(feet-Vector2(0,height/2),height/3,PINK)
		return
	var region = regions[index]
	var width = height*region.size.x/maxf(1,region.size.y)
	draw_set_transform(feet,0,Vector2(-1 if flip else 1,1))
	draw_texture_rect_region(atlas,Rect2(-width/2,-height,width,height),region,tint)
	draw_set_transform(Vector2.ZERO)

func _draw():
	draw_background()
	if state == "title":
		draw_title()
		return
	var offset = Vector2(-camera_x + sin(clock*81)*shake,0)
	for p in platforms:
		if p.end.x<camera_x or p.position.x>camera_x+W: continue
		var r = Rect2(p.position+offset,p.size)
		draw_rect(r,Color("18233d"))
		draw_rect(Rect2(r.position,Vector2(r.size.x,5)),CYAN)
		draw_rect(Rect2(r.position+Vector2(0,5),Vector2(r.size.x,8)),Color("255568"))
		for x in range(int(r.position.x)+10,int(r.end.x),80):
			draw_line(Vector2(x,r.position.y+22),Vector2(x+28,r.position.y+42),Color("324461"),3)
		if art.has("tiles"):
			var region = art.tiles.regions[0 if p.size.y>30 else (2 if p.size.x>230 else 1)]
			var ice = int(p.position.x/ROOM)<24 and layout[int(p.position.x/ROOM)].ice
			var tint = Color(0.65,0.9,1.25) if ice else Color.WHITE
			if p.size.y>30:
				for tile_x in range(0,int(r.size.x),240):
					var width = minf(240,r.size.x-tile_x)
					var source = Rect2(region.position,Vector2(region.size.x*width/240,region.size.y))
					draw_texture_rect_region(art.tiles.texture,Rect2(r.position+Vector2(tile_x,0),Vector2(width,68)),source,tint)
			else: draw_texture_rect_region(art.tiles.texture,Rect2(r.position,Vector2(r.size.x,24)),region,tint)
	for room in range(24):
		var x = room*ROOM+offset.x
		if x < -ROOM or x > W: continue
		if room%4==0:
			draw_line(Vector2(x+130,610),Vector2(x+130,390),CYAN if int(room/4)<=checkpoint else Color("466477"),3)
			txt(Vector2(x+150,428),"RELAY %02d"%(room/4+1),18,CYAN)
		if room < 3:
			var tips = ["← → / A D  移動     Z / Space  ジャンプ（2回）", "X / J  長押しで連射     V  ためて離す", "Shift / C  ダッシュ・短時間無敵"]
			txt(Vector2(x+100,265),tips[room],22,CYAN)
		if room in [4,8,12,16,20]:
			var tips = {4:"配電回廊：予告を見てレーザーを飛び越えよう",8:"空中搬送路：動く足場を利用しよう",12:"冷却プラント：氷の床では止まりにくい！",16:"防衛区画：Vをためて盾を壊そう",20:"コアへの道：二段ジャンプで上へ！"}
			txt(Vector2(x+100,235),tips[room],20,CYAN)

	for gate in gates:
		if not gate.open and absf(gate.x-player.x)<1400:
			var x = gate.x+offset.x
			draw_rect(Rect2(x-5,250,10,360),Color(1,0.35,0.65,0.6+sin(clock*8)*0.2))
			txt(Vector2(x-300,235),"コアを回収・同期 ＋ 区画の敵を倒して解除",18,PINK)
	for core in cores:
		if core.got and core.sync>0 and absf(core.p.x-player.x)<1400:
			var c = core.p+offset
			txt(c+Vector2(-75,-40),"同期中  %02d 秒"%ceili(core.sync),18,Color("ffd27f"))
			draw_arc(c,29,-PI/2,-PI/2+TAU*(1-core.sync/12),32,CYAN,4)
		if not core.got and absf(core.p.x-player.x)<1400:
			var c = core.p+offset
			draw_arc(c,29,clock,clock+TAU,32,Color("ffd27f"),2)
			art_sprite("core",0,c+Vector2(0,25+sin(clock*3)*5),54)
			txt(c+Vector2(-42,-40),"STAR CORE",14,Color("ffd27f"))
	for laser in lasers:
		var x = laser.x+offset.x
		if x < -100 or x > W+100: continue
		var cycle = fmod(elapsed+laser.phase,3.6)
		draw_rect(Rect2(x-55,602,110,8),Color("66314d"))
		if cycle>2.2:
			draw_rect(Rect2(x-50,574,100,30),Color(1,0.2,0.4,0.4))
			draw_line(Vector2(x-50,590),Vector2(x+50,590),PINK,6)
		elif cycle>1.5:
			txt(Vector2(x-28,570),"注意",16,PINK)
			draw_line(Vector2(x-50,600),Vector2(x+50,600),PINK,2)
	for p in pickups:
		if absf(p.x-player.x)<1300: sprite(6,p+offset+Vector2(0,sin(clock*3+p.x)*5),32,false,Color(0.5,0.6,0.6,0.55) if hp==max_hp else Color.WHITE)
	for e in enemies:
		if e.hp > 0 and absf(e.p.x-player.x)<1300:
			if e.kind<2: sprite(4+e.kind,e.p+offset+Vector2(0,10),76,e.p.x<player.x,Color(2,2,2) if e.flash>0 else Color.WHITE)
			else: art_sprite("enemies",e.kind-2,e.p+offset+Vector2(0,10),82,e.p.x<player.x,Color(2,2,2) if e.flash>0 else Color.WHITE)
			if e.get("shield",false):
				draw_arc(e.p+offset-Vector2(0,30),48,-PI/2 if e.p.x<player.x else PI/2,PI/2 if e.p.x<player.x else PI*1.5,24,Color("ffda77"),4)
				txt(e.p+offset+Vector2(-55,-90),"V チャージで破壊",13,Color("ffda77"))
	if boss_hp>0 and player.x>BOSS_X-1000:
		sprite(7,boss_pos+offset+Vector2(0,25),240,boss_pos.x<player.x,Color(2,1,1) if boss_flash>0 else (Color(1.4,0.75,1.25) if boss_phase==2 else Color.WHITE))
		if boss_phase==2:
			draw_circle(boss_pos+offset+Vector2(50 if boss_pos.x<player.x else -50,-125),12+sin(clock*12)*2,Color(1,0.9,1,0.65))
		if boss_warning>0:
			draw_arc(boss_pos+offset-Vector2(0,65),110,0,TAU,48,PINK,3)
	if boss_active:
		draw_rect(Rect2(BOSS_X+offset.x,200,12,410),PINK)
		for ray in boss_rays:
			var x = ray.x+offset.x
			draw_line(Vector2(x,140),Vector2(x,610),Color(1,0.35,0.6,0.3) if ray.t>0.45 else Color(1,0.8,0.9),2 if ray.t>0.45 else 45)
			if ray.t>0.45: txt(Vector2(x-17,180),"▼",24,PINK)
	for b in bullets:
		if not b.enemy and b.damage>=7:
			art_sprite("charge",int(clock*18)%6,b.p+offset+Vector2(0,28),56,b.v.x<0)
			continue
		var color = PINK if b.enemy else CYAN
		draw_circle(b.p+offset,b.r+5,Color(color,0.16))
		if b.enemy:
			draw_colored_polygon(PackedVector2Array([b.p+offset+Vector2(0,-b.r),b.p+offset+Vector2(b.r,0),b.p+offset+Vector2(0,b.r),b.p+offset+Vector2(-b.r,0)]),color)
		else: draw_circle(b.p+offset,b.r,color)
		draw_circle(b.p+offset,b.r*0.45,Color.WHITE)
	for p in particles:
		draw_circle(p.p+offset,3,Color(p.c,clampf(p.life*2,0,1)))
	for effect in fx: art_sprite("explosion",mini(5,int(effect.age*12)),effect.p+offset+Vector2(0,effect.size/2),effect.size)
	if dash_timer>0:
		for i in range(1,4): art_sprite("poses",0,player+offset-Vector2(facing*i*25,0),104,facing<0,Color(0.4,1,1,0.35/i))
	if invincible<=0 or int(clock*18)%2==0:
		var frame = 0
		if not grounded: frame = 3
		elif absf(velocity.x)>30: frame = 1+int(clock*12)%2
		if hurt_pose>0: art_sprite("poses",1,player+offset,104,facing<0)
		elif dash_timer>0: art_sprite("poses",0,player+offset,104,facing<0)
		elif charge>0.3: art_sprite("poses",2,player+offset,104,facing<0)
		else: sprite(frame,player+offset,104,facing<0)
	if muzzle_time>0: art_sprite("muzzle",mini(5,int((0.1-muzzle_time)*60)),player+offset+Vector2(facing*53,-36),50,facing<0)
	if charge>0.2:
		draw_arc(player+offset-Vector2(0,37),35+charge*8,clock*5,clock*5+TAU*charge/1.5,36,CYAN if charge>=0.8 else PINK,3)
	if state=="defeat": draw_rect(Rect2(0,0,W,H),Color(1,0.9,0.95,maxf(0,1-absf(ending_time-2.0)*5)))
	draw_hud()
	if state == "pause": panel("一時停止", "Enter / Esc / クリックで再開", "R / パッドBack：タイトルへ   M：音   F11：全画面")
	if state == "dead": panel("もう一度、飛び出そう。", "Enter / クリックでチェックポイントから再開", "残機制限なし。ダッシュ中は短時間、攻撃をすり抜けます。")
	if state == "clear":
		panel("STAGE CLEAR", "星炉は、もう一度輝きはじめた。", "ルミナ、おかえり！   時間 %s   撃破 %d   リトライ %d"%[time_text(),kills,deaths])
		art_sprite("poses",3,Vector2(1090,535),220)
		txt(Vector2(440,525),"Enter / A / クリックでもう一度",24,CYAN)

func draw_background():
	if backdrop:
		var scroll = 240.0*camera_x/END_X
		draw_texture_rect(backdrop,Rect2(-scroll,-60,1520,855),false,[Color(0.48,0.53,0.65),Color(0.60,0.43,0.62),Color(0.42,0.62,0.75),Color(0.50,0.72,0.82),Color(0.65,0.40,0.50),Color(0.66,0.53,0.70),Color(0.55,0.35,0.55)][mini(6,int(player.x/(ROOM*4)))])
	else: draw_rect(Rect2(0,0,W,H),Color("0b1029"))
	for i in range(45):
		var x = fposmod(i*193.1-camera_x*0.05,W)
		var y = fposmod(i*89.3,420)
		draw_circle(Vector2(x,y),1.3,Color(0.7,0.9,1,0.3+sin(clock+i)*0.15))

func draw_title():
	draw_rect(Rect2(0,0,1280,720),Color(0.025,0.035,0.09,0.48))
	draw_circle(Vector2(950,365),230,Color(0.3,0.9,0.9,0.055))
	draw_arc(Vector2(950,365),225,clock*0.1,clock*0.1+5,96,CYAN,2)
	sprite(0,Vector2(950,610+sin(clock*2)*7),440)
	txt(Vector2(100,130),"ONE GIRL. ONE SPARK. A SKY FULL OF STARS.",17,CYAN)
	txt(Vector2(94,245),"LUMINA",82)
	txt(Vector2(94,326),"SPARK",82,PINK)
	txt(Vector2(100,374),"ルミナ・スパーク",26)
	txt(Vector2(100,417),"夜空の発電都市へ。暴走した星炉を止めよう。",21,Color("bdcbe2"))
	draw_rect(Rect2(100,462,360,64),CYAN)
	txt(Vector2(145,504),"出撃する  /  ENTER",25,Color("102536"))
	draw_rect(Rect2(100,542,480,44),Color("21314a"))
	txt(Vector2(116,571),"E / Y：難易度  " + ("アシスト（体力多め・弾速ゆっくり）" if easy else "ノーマル"),18)
	txt(Vector2(100,627),"移動：← → / A D   ジャンプ：Z / Space   射撃：X / J",18,Color("bdcbe2"))
	txt(Vector2(100,659),"チャージ：V   ダッシュ：Shift / C   ポーズ：Esc   音：M",18,Color("bdcbe2"))
	txt(Vector2(100,690),"1 STAGE / 6 SECTORS + BOSS     •     GAMEPAD対応     •     F11 全画面",14,CYAN)

func time_text() -> String:
	return "%02d:%02d"%[int(elapsed)/60,int(elapsed)%60]

func draw_hud():
	draw_rect(Rect2(24,20,1232,82),Color(0.025,0.04,0.1,0.93))
	draw_rect(Rect2(42,32,62,58),Color("32405c"))
	if atlas:
		var head = Rect2(75,15,205,180)
		draw_texture_rect_region(atlas,Rect2(43,32,60,58),head)
	txt(Vector2(118,49),"LUMINA  %d / %d"%[hp,max_hp],17,PINK)
	draw_rect(Rect2(118,63,190,17),Color("29344b"))
	draw_rect(Rect2(118,63,190*float(hp)/max_hp,17),CYAN)
	txt(Vector2(340,50),sector_names[mini(6,int(player.x/(ROOM*4)))],22)
	txt(Vector2(340,80),"DASH  " + ("READY" if dash_cooldown<=0 else "…") + "     CHARGE  " + ("READY" if charge>=0.8 else "V 長押し") + "     CORE  %d / 6"%core_count,14,CYAN)
	txt(Vector2(1045,50),time_text(),25)
	txt(Vector2(1045,80),"撃破 %02d  /  M 音"%kills,15,Color("bdcbe2"))
	draw_rect(Rect2(24,104,1232*clampf(player.x/END_X,0,1),3),PINK)
	if banner_time>0:
		draw_rect(Rect2(290,130,730,48),Color(0.02,0.06,0.13,0.85))
		txt(Vector2(320,162),banner,22,CYAN)
	if boss_active and boss_hp>0:
		draw_rect(Rect2(370,665,540,24),Color("30233f"))
		draw_rect(Rect2(370,665,540*float(boss_hp)/boss_max_hp,24),PINK)
		txt(Vector2(470,651),"ASTER GUARDIAN",19)

func panel(title: String, subtitle: String, detail: String):
	draw_rect(Rect2(0,0,W,H),Color(0.015,0.025,0.06,0.85))
	draw_line(Vector2(260,245),Vector2(1020,245),CYAN,2)
	txt(Vector2(300,330),title,45,PINK)
	txt(Vector2(300,402),subtitle,26)
	txt(Vector2(300,465),detail,19,Color("bdcbe2"))
	draw_line(Vector2(260,555),Vector2(1020,555),CYAN,2)

func self_test():
	set_physics_process(false)
	var errors: Array[String] = []
	if not atlas or regions.size()!=8: errors.append("atlas unavailable")
	if not backdrop: errors.append("background unavailable")
	if platforms.size()<60: errors.append("platform count")
	if enemies.size()<45: errors.append("enemy count: %d"%enemies.size())
	if gates.size()!=6: errors.append("gate count")
	start_game()
	for i in range(120): update_game(1.0/60)
	if not grounded or absf(player.y-610)>1: errors.append("landing")
	var old_x = player.x
	test_key(KEY_SHIFT,true)
	for i in range(6): update_game(1.0/60)
	test_key(KEY_SHIFT,false)
	if player.x-old_x < 60 or invincible<=0: errors.append("dash input")
	for i in range(60): update_game(1.0/60)
	test_key(KEY_V,true)
	for i in range(60): update_game(1.0/60)
	test_key(KEY_V,false)
	update_game(1.0/60)
	if bullets.is_empty() or bullets[-1].damage!=7: errors.append("charge input")
	var pause_event = InputEventKey.new()
	pause_event.keycode = KEY_ESCAPE
	pause_event.pressed = true
	_unhandled_input(pause_event)
	var paused_time = elapsed
	_physics_process(1.0)
	if state!="pause" or elapsed!=paused_time: errors.append("pause")
	_unhandled_input(pause_event)
	if state!="play": errors.append("resume")
	shoot(true)
	if bullets[-1].damage!=7: errors.append("charge damage")
	invincible=0
	hurt(2)
	if hp!=max_hp-2: errors.append("damage")
	hurt(2)
	if hp!=max_hp-2: errors.append("invincibility")
	checkpoint=3
	hurt(99)
	if state!="dead": errors.append("death")
	respawn()
	if hp!=max_hp or player.x<ROOM*12: errors.append("checkpoint")
	player=Vector2(BOSS_X+200,610)
	camera_x=END_X-W
	update_boss(0.016)
	if not boss_active: errors.append("boss activation")
	boss_intro=0
	boss_hp=2
	bullets.clear()
	bullets.append({"p":boss_pos-Vector2(0,60),"v":Vector2.ZERO,"enemy":false,"damage":7,"r":15.0,"life":1.0})
	update_bullets(0.016)
	if state!="defeat": errors.append("defeat cinematic")
	for i in range(180): update_game(1.0/60)
	if state!="clear": errors.append("clear")
	start_game()
	if art.size()!=7: errors.append("new art missing")
	if layout.size()!=24 or moving.size()<5: errors.append("authored layout")
	spawn_enemy(player+Vector2(100,0),2,0)
	var shield = enemies[-1]
	bullets.clear()
	bullets.append({"p":shield.p-Vector2(0,25),"v":Vector2.ZERO,"enemy":false,"damage":2,"r":5.0,"life":1.0})
	update_bullets(0.016)
	if shield.hp!=12 or not shield.shield: errors.append("shield blocks normal")
	bullets.append({"p":shield.p-Vector2(0,25),"v":Vector2.ZERO,"enemy":false,"damage":7,"r":15.0,"life":1.0})
	update_bullets(0.016)
	if shield.hp!=5 or shield.shield: errors.append("charge breaks shield")
	player=Vector2(350,490)
	velocity=Vector2.ZERO
	grounded=true
	prev_jump=false
	invincible=999
	test_key(KEY_DOWN,true)
	test_key(KEY_SPACE,true)
	update_game(1.0/60)
	test_key(KEY_DOWN,false)
	test_key(KEY_SPACE,false)
	if drop_timer<=0 or player.y<=490: errors.append("drop through platform")
	drop_timer=0
	var mover=moving[0]
	var support=platforms[mover.index]
	player=Vector2(support.get_center().x,support.position.y)
	grounded=true
	velocity=Vector2.ZERO
	update_game(1.0/60)
	if absf(player.y-platforms[mover.index].position.y)>2 or not grounded: errors.append("moving platform support")
	player = Vector2(BOSS_X+200,610)
	boss_hp = 140
	update_boss(0.016)
	if boss_phase!=2: errors.append("boss phase transition")
	boss_intro=0
	boss_cycle=2
	boss_timer=0
	update_boss(0.016)
	if boss_rays.size()!=3: errors.append("phase2 sky lasers")
	boss_timer=0
	update_boss(0.016)
	if boss_dash<=0: errors.append("phase2 dash")
	state="title"
	var pad = InputEventJoypadButton.new()
	pad.pressed=true
	pad.button_index=JOY_BUTTON_Y
	var old_easy=easy
	_unhandled_input(pad)
	if easy==old_easy: errors.append("pad difficulty")
	state="pause"
	pad.button_index=JOY_BUTTON_BACK
	_unhandled_input(pad)
	if state!="title": errors.append("pad return title")
	print("SELF TEST: ", "PASS" if errors.is_empty() else "FAIL", " ", errors)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if errors.is_empty() else 1)

func test_key(code: int, down: bool):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func capture_qa():
	set_process(false)
	set_physics_process(false)
	for scene in ["title", "stage", "movers", "ice", "defense", "summit", "boss", "phase2", "clear"]:
		if scene == "stage":
			start_game()
			player = Vector2(1500,610)
			camera_x = 1100
			grounded = true
			banner_time = 0
		if scene in ["movers","ice","defense","summit"]:
			var room = {"movers":8,"ice":12,"defense":16,"summit":23}[scene]
			player = Vector2(room*ROOM+180,610)
			camera_x = room*ROOM
			if scene=="defense": charge = 1.1
			else: charge = 0
		if scene == "boss":
			player = Vector2(BOSS_X+300,610)
			camera_x = END_X-W
			boss_active = true
			boss_timer = 0.1
			update_boss(0.2)
		if scene=="phase2":
			boss_hp = 140
			update_boss(0.01)
			update_boss(2.0)
			boss_cycle = 2
			boss_timer = 0
			update_boss(0.01)
			banner_time = 0
		if scene == "clear":
			boss_hp = 0
			state = "clear"
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var result = get_viewport().get_texture().get_image().save_png("res://test-output/"+scene+".png")
		print("CAPTURE ",scene," ",result)
	get_tree().quit()



func art_sprite(name: String, frame: int, feet: Vector2, height: float, flip = false, tint = Color.WHITE):
	if not art.has(name): return
	var region = art[name].regions[frame]
	var width = height*region.size.x/maxf(1,region.size.y)
	draw_set_transform(feet,0,Vector2(-1 if flip else 1,1))
	draw_texture_rect_region(art[name].texture,Rect2(-width/2,-height,width,height),region,tint)
	draw_set_transform(Vector2.ZERO)

func update_fx(dt: float):
	for i in range(fx.size()-1,-1,-1):
		fx[i].age += dt
		if fx[i].age>=0.5: fx.remove_at(i)

