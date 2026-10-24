extends Node2D

const W = 1280.0
const H = 720.0
const ROOM = 1120.0
const BOSS_X = ROOM * 24
const END_X = BOSS_X + 1200
const CYAN = Color("63f4e6")
const PINK = Color("ff82c6")
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
var boss_hp = 160
var boss_max_hp = 160
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
	core_count = 0
	pickups.clear()
	for room in range(24):
		var x = room * ROOM
		var gap = room > 1 and room % 4 != 0 and room % 4 != 3
		if gap:
			platforms.append(Rect2(x, 610, 740, 130))
			platforms.append(Rect2(x + 900, 610, 220, 130))
		else: platforms.append(Rect2(x, 610, ROOM, 130))
		platforms.append(Rect2(x + 320, 480, 210, 24))
		if room % 2 == 0: platforms.append(Rect2(x + 600, 370, 200, 24))
		else: platforms.append(Rect2(x + 660, 465, 170, 24))
		pickups.append(Vector2(x + 700, 330 if room % 2 == 0 else 425))
		if room > 0:
			spawn_enemy(Vector2(x + 440, 600), 0, room)
			spawn_enemy(Vector2(x + 730, 415), 1, room)
		if room > 2: spawn_enemy(Vector2(x + 990, 600), 0, room)
		if room % 4 == 3:
			gates.append({"x": x + 1080, "room": room, "open": false})
			cores.append({"p":Vector2(x+740,420),"room":room,"got":false,"sync":18.0,"wave":false})
		if room >= 4 and room % 4 != 3:
			lasers.append({"x":x+575,"phase":float(room)*0.7})
	platforms.append(Rect2(BOSS_X, 610, 1400, 130))
	platforms.append(Rect2(BOSS_X + 260, 460, 180, 24))
	platforms.append(Rect2(BOSS_X + 730, 460, 180, 24))

func spawn_enemy(pos: Vector2, kind: int, room: int):
	enemies.append({"p": pos, "origin": pos, "kind": kind, "room": room, "hp": 8 if kind == 0 else 6, "t": rng.randf_range(0, 5), "shot": rng.randf_range(0.4, 2.0), "flash": 0.0})

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
	if state == "play": update_game(dt)

func update_game(dt: float):
	elapsed += dt
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
		velocity.x = move_toward(velocity.x, axis * 285, 2300 * dt)
		velocity.y = minf(900, velocity.y + 1600 * dt)
	var old_y = player.y
	player.x = clampf(player.x + velocity.x * dt, 24, END_X - 30)
	player.y += velocity.y * dt
	grounded = false
	for p in platforms:
		if player.x + 16 > p.position.x and player.x - 16 < p.end.x and old_y <= p.position.y + 1 and player.y >= p.position.y and velocity.y >= 0:
			player.y = p.position.y
			velocity.y = 0
			grounded = true
			jumps = 0
			if player.x - 30 > p.position.x and player.x + 30 < p.end.x: safe_pos = player
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
			if core.sync<10 and not core.wave:
				core.wave = true
				var base = core.room*ROOM
				spawn_enemy(Vector2(base+450,600),0,core.room)
				spawn_enemy(Vector2(base+650,400),1,core.room)
				spawn_enemy(Vector2(base+980,600),0,core.room)
				banner = "防衛ドローン接近！ コアの同期完了まで持ちこたえよう"
				banner_time = 3
		if not core.got and (player-Vector2(0,30)).distance_to(core.p)<45:
			core.got = true
			core_count += 1
			hp = mini(max_hp,hp+3)
			burst(core.p,Color("ffd27f"),24)
			sound("heal")
			banner = "スターコア回収  %d / 6  —  18秒間の同期、防衛開始！"%core_count
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
	shot_timer = 0.18
	bullets.append({"p":player+Vector2(facing*30,-48),"v":Vector2(facing*860,0),"enemy":false,"damage":7 if big else 2,"r":15.0 if big else 5.0,"life":1.8})
	sound("charge" if big else "shot")

func enemy_shot(pos: Vector2, vel: Vector2, radius = 8.0):
	bullets.append({"p":pos,"v":vel,"enemy":true,"damage":1 if easy else 2,"r":radius,"life":5.0})

func update_enemies(dt: float):
	for e in enemies:
		if e.hp <= 0 or absf(e.p.x-player.x)>1100: continue
		e.t += dt
		e.flash -= dt
		e.shot -= dt
		if e.kind == 0: e.p.x = e.origin.x + sin(e.t*1.4)*75
		else: e.p.y = e.origin.y + sin(e.t*2)*45
		if e.shot <= 0 and e.p.x > camera_x + 20 and e.p.x < camera_x + W - 20:
			e.shot = 2.6 if easy else 1.9
			enemy_shot(e.p+Vector2(0,-18),(player+Vector2(0,-30)-e.p).normalized()*(200 if easy else 260))
		if (player+Vector2(0,-27)).distance_to(e.p+Vector2(0,-10)) < 41: hurt(1 if easy else 2)

func update_boss(dt: float):
	if player.x < BOSS_X + 100 or boss_hp <= 0: return
	if not boss_active:
		boss_active = true
		boss_timer = 2.0
		banner = "星炉の守護者  /  ASTER GUARDIAN"
		banner_time = 3
	player.x = maxf(BOSS_X+35,player.x)
	boss_timer -= dt
	boss_warning = maxf(0,boss_timer) if boss_timer < 0.7 else 0
	boss_pos.y = 550 + sin(clock*2)*18
	if boss_timer <= 0:
		boss_cycle += 1
		boss_timer = (1.25 if boss_hp < 80 else 1.75) + (0.5 if easy else 0)
		if boss_cycle % 3 == 0:
			for j in range(9): enemy_shot(boss_pos+Vector2(-40,-55),Vector2.LEFT.rotated((j-4)*0.19)*240,10)
		elif boss_cycle % 3 == 1:
			enemy_shot(Vector2(boss_pos.x-40,585),Vector2(-360,0),18)
			enemy_shot(Vector2(boss_pos.x-40,550),Vector2(-360,0),13)
		else:
			var aim = (player+Vector2(0,-25)-boss_pos).normalized()
			for j in range(3): enemy_shot(boss_pos+Vector2(-50,-60),aim.rotated((j-1)*0.24)*310,10)
	if (player+Vector2(0,-30)).distance_to(boss_pos+Vector2(0,-60))<90: hurt(3)

func update_bullets(dt: float):
	for i in range(bullets.size()-1,-1,-1):
		var b = bullets[i]
		b.p += b.v*dt
		b.life -= dt
		var remove = b.life <= 0 or b.p.x < camera_x - 60 or b.p.x > camera_x + W + 60
		if b.enemy:
			if Rect2(player-Vector2(18,62),Vector2(36,62)).grow(b.r).has_point(b.p):
				hurt(b.damage)
				remove = true
		else:
			for e in enemies:
				if e.hp > 0 and Rect2(e.p-Vector2(28,48),Vector2(56,58)).grow(b.r).has_point(b.p):
					e.hp -= b.damage
					e.flash = 0.12
					burst(b.p,PINK,4)
					remove = true
					if e.hp <= 0:
						kills += 1
						burst(e.p,Color("ffc578"),18)
						if kills%4 == 0: pickups.append(e.p-Vector2(0,25))
					break
			if not remove and boss_active and boss_hp > 0 and Rect2(boss_pos-Vector2(70,160),Vector2(140,180)).grow(b.r).has_point(b.p):
				boss_hp -= b.damage
				boss_flash = 0.1
				remove = true
				burst(b.p,PINK,6)
				if boss_hp <= 0:
					burst(boss_pos,CYAN,100)
					state = "clear"
					music.stop()
					sound("win")
		if remove: bullets.remove_at(i)

func hurt(amount: int):
	if (invincible > 0 and amount < 99) or state != "play": return
	hp = maxi(0,hp-amount)
	invincible = 1.3
	shake = 8
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
	for room in range(24):
		var x = room*ROOM-camera_x
		if x < -ROOM or x > W: continue
		if room%4==0:
			draw_line(Vector2(x+130,610),Vector2(x+130,390),CYAN if int(room/4)<=checkpoint else Color("466477"),3)
			txt(Vector2(x+150,428),"RELAY %02d"%(room/4+1),18,CYAN)
		if room < 3:
			var tips = ["← → / A D  移動     Z / Space  ジャンプ（2回）", "X / J  長押しで連射     V  ためて離す", "Shift / C  ダッシュ・短時間無敵"]
			txt(Vector2(x+100,265),tips[room],22,CYAN)
		if room>1 and room%4!=0 and room%4!=3:
			draw_line(Vector2(x+750,680),Vector2(x+890,680),PINK,3)
	for gate in gates:
		if not gate.open and absf(gate.x-player.x)<1400:
			var x = gate.x-camera_x
			draw_rect(Rect2(x-5,250,10,360),Color(1,0.35,0.65,0.6+sin(clock*8)*0.2))
			txt(Vector2(x-300,235),"コアを回収・同期 ＋ 区画の敵を倒して解除",18,PINK)
	for core in cores:
		if core.got and core.sync>0 and absf(core.p.x-player.x)<1400:
			var c = core.p+offset
			txt(c+Vector2(-75,-40),"同期中  %02d 秒"%ceili(core.sync),18,Color("ffd27f"))
			draw_arc(c,29,-PI/2,-PI/2+TAU*(1-core.sync/18),32,CYAN,4)
		if not core.got and absf(core.p.x-player.x)<1400:
			var c = core.p+offset
			draw_arc(c,29,clock,clock+TAU,32,Color("ffd27f"),2)
			sprite(6,c+Vector2(0,17+sin(clock*3)*5),35,false,Color(1.8,1.1,0.5))
			txt(c+Vector2(-42,-40),"STAR CORE",14,Color("ffd27f"))
	for laser in lasers:
		var x = laser.x-camera_x
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
		if absf(p.x-player.x)<1300: sprite(6,p+offset+Vector2(0,sin(clock*3+p.x)*5),32)
	for e in enemies:
		if e.hp > 0 and absf(e.p.x-player.x)<1300:
			sprite(4+e.kind,e.p+offset+Vector2(0,10),60 if e.kind==0 else 58,e.p.x<player.x,Color(2,2,2) if e.flash>0 else Color.WHITE)
	if boss_hp>0 and player.x>BOSS_X-1000:
		sprite(7,boss_pos+offset+Vector2(0,25),210,false,Color(2,1,1) if boss_flash>0 else Color.WHITE)
		if boss_warning>0:
			draw_arc(boss_pos+offset-Vector2(0,65),110,0,TAU,48,PINK,3)
	for b in bullets:
		var color = PINK if b.enemy else CYAN
		draw_circle(b.p+offset,b.r+5,Color(color,0.16))
		draw_circle(b.p+offset,b.r,color)
		draw_circle(b.p+offset,b.r*0.45,Color.WHITE)
	for p in particles:
		draw_circle(p.p+offset,3,Color(p.c,clampf(p.life*2,0,1)))
	if invincible<=0 or int(clock*18)%2==0:
		var frame = 0
		if not grounded: frame = 3
		elif absf(velocity.x)>30: frame = 1+int(clock*12)%2
		sprite(frame,player+offset,80,facing<0)
	if charge>0.2:
		draw_arc(player+offset-Vector2(0,37),35+charge*8,clock*5,clock*5+TAU*charge/1.5,36,CYAN if charge>=0.8 else PINK,3)
	draw_hud()
	if state == "pause": panel("一時停止", "Enter / Esc / クリックで再開", "R：タイトルへ   M：音の切り替え   F11：全画面")
	if state == "dead": panel("もう一度、飛び出そう。", "Enter / クリックでチェックポイントから再開", "残機制限なし。ダッシュ中は短時間、攻撃をすり抜けます。")
	if state == "clear":
		panel("STAGE CLEAR", "星炉は、もう一度輝きはじめた。", "ルミナ、おかえり！   時間 %s   撃破 %d   リトライ %d"%[time_text(),kills,deaths])
		txt(Vector2(440,525),"Enter / クリックでもう一度",24,CYAN)

func draw_background():
	if backdrop:
		var scroll = 240.0*camera_x/END_X
		draw_texture_rect(backdrop,Rect2(-scroll,-60,1520,855),false,Color(0.48,0.53,0.65))
	else: draw_rect(Rect2(0,0,W,H),Color("0b1029"))
	for i in range(45):
		var x = fposmod(i*193.1-camera_x*0.05,W)
		var y = fposmod(i*89.3,420)
		draw_circle(Vector2(x,y),1.3,Color(0.7,0.9,1,0.3+sin(clock+i)*0.15))
	for i in range(15):
		var x = fposmod(i*147.0-camera_x*0.28,1500)-150
		var h = 100+fposmod(i*79,260)
		draw_rect(Rect2(x,640-h,90,h),Color(0.04,0.08,0.17,0.65))
		draw_line(Vector2(x,640-h),Vector2(x+90,640-h),Color(0.3,0.8,0.9,0.2),2)
		for y in range(int(660-h),600,30): draw_rect(Rect2(x+12,y,6,10),Color(0.4,0.9,0.9,0.25))

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
	txt(Vector2(116,571),"E：難易度  " + ("アシスト（体力多め・弾速ゆっくり）" if easy else "ノーマル"),18)
	txt(Vector2(100,627),"移動：← → / A D   ジャンプ：Z / Space   射撃：X / J",18,Color("bdcbe2"))
	txt(Vector2(100,659),"チャージ：V   ダッシュ：Shift / C   ポーズ：Esc   音：M",18,Color("bdcbe2"))
	txt(Vector2(100,690),"1 STAGE / 6 SECTORS + BOSS     •     GAMEPAD対応     •     F11 全画面",14,CYAN)

func time_text() -> String:
	return "%02d:%02d"%[int(elapsed)/60,int(elapsed)%60]

func draw_hud():
	draw_rect(Rect2(24,20,1232,82),Color(0.025,0.04,0.1,0.93))
	txt(Vector2(44,49),"LUMINA",19,PINK)
	for i in range(max_hp):
		draw_rect(Rect2(44+i*13,62,9,19),CYAN if i<hp else Color("29344b"))
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
	if enemies.size()!=67: errors.append("enemy count: %d"%enemies.size())
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
	boss_hp=2
	bullets.clear()
	bullets.append({"p":boss_pos-Vector2(0,60),"v":Vector2.ZERO,"enemy":false,"damage":7,"r":15.0,"life":1.0})
	update_bullets(0.016)
	if state!="clear": errors.append("clear")
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
	for scene in ["title", "stage", "boss", "clear"]:
		if scene == "stage":
			start_game()
			player = Vector2(1500,610)
			camera_x = 1100
			grounded = true
			banner_time = 0
		if scene == "boss":
			player = Vector2(BOSS_X+300,610)
			camera_x = END_X-W
			boss_active = true
			boss_timer = 0.1
			update_boss(0.2)
		if scene == "clear": state = "clear"
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var result = get_viewport().get_texture().get_image().save_png("res://test-output/"+scene+".png")
		print("CAPTURE ",scene," ",result)
	get_tree().quit()


