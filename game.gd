extends Node2D

const W = 1280.0
const H = 720.0
const ROOM = 1120.0
const BOSS_X = ROOM * 24
const END_X = BOSS_X + 1200
const CYAN = Color("63f4e6")
const PINK = Color("ff82c6")
const GAME_TITLE = "LUMINA SPARK — 星炉のリベリオン —"
# Elbow pivot inside each arm texture (pixels); the arm is drawn as two slices around it.
const ARM_ELBOW = {"gun_arm":[135,268],"free_arm":[118,318]}
const ARM_OVERLAP = 22.0
var layout: Array = []
var moving: Array[Dictionary] = []
var art: Dictionary = {}
var environment_art: Dictionary = {}
var score = 0
var combo = 0
var max_combo = 0
var combo_timer = 0.0
var damage_taken = 0
var area_damage = 0
var just_reflections = 0
var just_dodges = 0
var clear_rewarded = false
var best_score = 0
var record_path = "user://records.cfg"
var parry_marks: Array[Dictionary] = []
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
var motions: Dictionary = {}
var motion_meta: Dictionary = {}
var rig_textures: Dictionary = {}
var capture_mode = false
var walk_phase = 0.0
var saber_time = 0.0
var saber_air = false
var aim_time = 0.0
var saber_cooldown = 0.0
var saber_facing = 1
var saber_hits: Array = []
var saber_boss_hit = false
var prev_saber = false
var parries = 0
var font: Font
var atlas: Texture2D
var backdrop: Texture2D
var title_keyart: Texture2D
var title_logo: Texture2D
var title_logo_region = Rect2()
var title_font: Font
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
var prev_fire = false
var fire_buffer = 0.0
var popups: Array[Dictionary] = []
const SABER_COOLDOWN = 0.85
# Danmaku mode: triple enemy fire, a quick saber that can be swung while dashing.
const DANMAKU_SABER_COOLDOWN = 0.22
const DASH_COOLDOWN = 0.45
const FULL_CHARGE = 1.6
# The saber is active while saber_time is 0.07..0.28; only its first 0.05 s reflects.
const JUST_WINDOW = 0.245
const DANMAKU_JUST_WINDOW = 0.2
var danmaku = false
var dodge_charge = 0.0
var slow_time = 0.0
var slow_cool = 0.0
const DOOR_KINDS = ["sync","switch","kill","break","sync","switch"]
const DOOR_FLOOR = 610.0
const DOOR_TOP = 438.0
const DOOR_HALF_WIDTH = 24.0
const PLAYER_HALF_WIDTH = 20.0
const DOOR_PLAYER_HEIGHT = 100.0
var fixed_seed = false
const ACTIONS = ["left","right","down","jump","fire","saber","dash"]
const ACTION_NAMES = {"left":"左へ移動","right":"右へ移動","down":"下（足場から降りる・急降下）","jump":"ジャンプ","fire":"射撃（長押しでため撃ち）","saber":"セーバー","dash":"ダッシュ"}
const PAD_LT = 100
const PAD_RT = 101
const DEFAULT_KEYS = {"left":[KEY_LEFT,KEY_A],"right":[KEY_RIGHT,KEY_D],"down":[KEY_DOWN,KEY_S],"jump":[KEY_SPACE,KEY_Z],"fire":[KEY_X,KEY_J,KEY_V],"saber":[KEY_K],"dash":[KEY_SHIFT,KEY_C]}
const DEFAULT_PAD = {"left":[JOY_BUTTON_DPAD_LEFT],"right":[JOY_BUTTON_DPAD_RIGHT],"down":[JOY_BUTTON_DPAD_DOWN],"jump":[JOY_BUTTON_A],"fire":[JOY_BUTTON_X,JOY_BUTTON_Y],"saber":[JOY_BUTTON_RIGHT_SHOULDER],"dash":[JOY_BUTTON_B]}
var key_binds: Dictionary = {}
var pad_binds: Dictionary = {}
var using_pad = false
var bgm_level = 5
var sfx_level = 5
var settings_path = "user://settings.cfg"
var settings_from = "title"
var settings_index = 0
var rebinding = ""
var settings_note = ""
var stick_nav: Dictionary = {}
var charge_release = -1
var drop_buffer = 0.0
var run_seed = 7234
var alert_cool = 0.0
var music: AudioStreamPlayer
var bgm: Dictionary = {}
var music_track = ""
var music_fade: Tween
var sfx: Dictionary = {}
var rng = RandomNumberGenerator.new()
var sector_names = ["01  星明かりの外壁", "02  配電回廊", "03  空中搬送路", "04  冷却プラント", "05  防衛区画", "06  コアへの道", "07  星炉の守護者"]

func _ready():
	rng.seed = 7234
	var measured = JSON.parse_string(FileAccess.get_file_as_string("res://assets/regions.json"))
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo", "sans-serif"])
	title_font=SystemFont.new()
	title_font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo","sans-serif"])
	title_font.font_weight=700
	if DisplayServer.get_name()!="headless": DisplayServer.window_set_title(GAME_TITLE)
	if ResourceLoader.exists("res://assets/title/keyart.png"):
		title_keyart=load("res://assets/title/keyart.png")
		title_logo=load("res://assets/title/logo.png")
		var title_regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/title/regions.json"))
		var r=title_regions.logo
		title_logo_region=Rect2(r[0],r[1],r[2],r[3])
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
	for entry in [["stage","heroic-quest.mp3"],["boss","untitled.mp3"]]:
		var stream=load("res://assets/audio/"+entry[1])
		stream.loop=true
		bgm[entry[0]]=stream
	music.stream=bgm.stage
	load_settings()
	music.volume_db=level_db(bgm_level,-18.0)
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
	motion_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/motion/animation.json"))
	for name in ["saber","air_saber"]:
		var frames: Array = []
		for entry in motion_meta[name].frames:
			frames.append(load("res://assets/motion/"+entry.file))
		motions[name] = frames
	for name in motion_meta.rig:
		rig_textures[name] = load("res://assets/motion/"+motion_meta.rig[name].file)
	if FileAccess.file_exists("res://assets/improvements/regions.json"):
		var additions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/improvements/regions.json"))
		for name in additions:
			var rects: Array[Rect2] = []
			for r in additions[name].regions: rects.append(Rect2(r[0],r[1],r[2],r[3]))
			environment_art[name]={"texture":load("res://assets/improvements/"+name+".png"),"regions":rects,"anchors":additions[name].get("anchors",[]),"scale":additions[name].get("scale",1.0)}
	var records = ConfigFile.new()
	if records.load(record_path)==OK: best_score=int(records.get_value("records","score",0))
	build_level()
	fixed_seed = OS.get_cmdline_user_args().size()>0
	if "--self-test" in OS.get_cmdline_user_args():
		muted = true
		call_deferred("self_test")
	if "--motion-test" in OS.get_cmdline_user_args():
		muted = true
		call_deferred("motion_test")
	if "--capture-motion" in OS.get_cmdline_user_args():
		muted = true
		call_deferred("capture_motion")
	if "--capture-qa" in OS.get_cmdline_user_args():
		muted = true
		call_deferred("capture_qa")

func sound(name: String):
	if muted or sfx_level<=0 or not sfx.has(name): return
	var a = AudioStreamPlayer.new()
	add_child(a)
	a.stream = sfx[name]
	a.volume_db = level_db(sfx_level,-16.0)
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
		for e in d.enemies: place_enemy(Vector2(x+e[1],e[2]),int(e[0]),room)
		for l in d.lasers: lasers.append({"x":x+l,"phase":float(room)*0.7})
		if not d.platforms.is_empty():
			var top = d.platforms[-1]
			pickups.append(Vector2(x+top[0]+top[2]/2,top[1]-35))
		if d.has("core"):
			# Each area's door opens a different way so the exits do not repeat.
			var kind = DOOR_KINDS[gates.size()%DOOR_KINDS.size()]
			var gate = {"x":x+1080,"room":room,"open":false,"entered":false,"passed":false,"kind":kind,"lift":0.0,"hp":21,"switches":[]}
			if kind=="switch":
				for y in ([470,370] if room==23 else [450]): gate.switches.append({"p":Vector2(x+1058,y),"on":false})
			gates.append(gate)
			cores.append({"p":Vector2(x+d.core[0],d.core[1]),"room":room,"got":false,"sync":12.0,"waves":0})
	platforms.append(Rect2(BOSS_X,610,1400,130))
	platforms.append(Rect2(BOSS_X+260,460,180,24))
	platforms.append(Rect2(BOSS_X+730,460,180,24))

# Layout positions are only a starting point: each run shifts enemies around
# and sometimes swaps in another enemy of the same family already met in this area.
func place_enemy(pos: Vector2, kind: int, room: int):
	var area = int(room/4)
	var ground = kind in [0,2,4]
	if rng.randf()<0.3:
		var pool = ([0]+([4] if area>=3 else [])+([2] if area>=4 else [])) if ground else ([1]+([5] if area>=2 else []))
		if kind!=3: kind = pool[rng.randi()%pool.size()]
	var lo = room*ROOM+180
	var hi = room*ROOM+1030
	for attempt in range(8):
		var p = pos
		if ground or kind==3:
			p.x = clampf(pos.x+rng.randf_range(-170,170),lo,hi)
			if kind==3 and pos.y<590: p.x = clampf(pos.x+rng.randf_range(-60,60),lo,hi)
			if pos.y>=590 and not on_ground(p.x-30,610) or pos.y>=590 and not on_ground(p.x+30,610): continue
			if kind==3 and pos.y<590 and not on_ground(p.x,pos.y+50): continue
		else:
			p = Vector2(clampf(pos.x+rng.randf_range(-180,180),lo,hi),clampf(pos.y+rng.randf_range(-60,50),300,460))
		pos = p
		break
	spawn_enemy(pos,kind,room)

func spawn_enemy(pos: Vector2, kind: int, room: int):
	enemies.append({"p":pos,"origin":pos,"kind":kind,"room":room,"hp":[8,6,12,10,8,10,112][kind],"shield":kind==2,"t":rng.randf_range(0,5),"shot":rng.randf_range(0.6,2),"flash":0.0})
	if kind==6:
		enemies[-1].mode="intro"
		enemies[-1].mt=1.2
		enemies[-1].cycle=0
		enemies[-1].dir=-1.0

func start_game():
	# Tests replay the same run; normal play gets a fresh enemy arrangement every time.
	if fixed_seed: rng.seed = run_seed
	else: rng.randomize()
	hp = 20 if easy else 12
	dodge_charge = 0
	slow_time = 0
	slow_cool = 0
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
	prev_fire = false
	alert_cool = 0
	fire_buffer = 0
	popups.clear()
	camera_x = 0
	elapsed = 0
	kills = 0
	score=0
	combo=0
	max_combo=0
	combo_timer=0
	damage_taken=0
	area_damage=0
	just_reflections=0
	just_dodges=0
	clear_rewarded=false
	parry_marks.clear()
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
	walk_phase = 0
	saber_time = 0
	saber_air = false
	aim_time = 0
	saber_cooldown = 0
	prev_saber = false
	parries = 0
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
	set_bgm("stage",true)

func key(code: int) -> bool:
	return Input.is_physical_key_pressed(code)

func joy(button: int) -> bool:
	return Input.is_joy_button_pressed(0, button)

# --- Rebindable controls, volume and the settings screen ---
func joy_any(button: int) -> bool:
	if button==PAD_LT: return Input.get_joy_axis(0,JOY_AXIS_TRIGGER_LEFT)>0.5
	if button==PAD_RT: return Input.get_joy_axis(0,JOY_AXIS_TRIGGER_RIGHT)>0.5
	return joy(button)

func act(name: String) -> bool:
	for code in key_binds[name]:
		if key(code): return true
	for button in pad_binds[name]:
		if joy_any(button): return true
	if name=="down" and Input.get_joy_axis(0,JOY_AXIS_LEFT_Y)>0.55: return true
	return false

func key_name(code: int) -> String:
	var symbols = {KEY_LEFT:"←",KEY_RIGHT:"→",KEY_UP:"↑",KEY_DOWN:"↓",KEY_SPACE:"SPACE",KEY_SHIFT:"SHIFT",KEY_CTRL:"CTRL",KEY_ALT:"ALT",KEY_TAB:"TAB",KEY_ENTER:"ENTER"}
	return symbols.get(code,OS.get_keycode_string(code).to_upper())

func pad_name(button: int) -> String:
	var names = {JOY_BUTTON_A:"A",JOY_BUTTON_B:"B",JOY_BUTTON_X:"X",JOY_BUTTON_Y:"Y",JOY_BUTTON_LEFT_SHOULDER:"LB",JOY_BUTTON_RIGHT_SHOULDER:"RB",JOY_BUTTON_LEFT_STICK:"L3",JOY_BUTTON_RIGHT_STICK:"R3",JOY_BUTTON_DPAD_UP:"十字↑",JOY_BUTTON_DPAD_DOWN:"十字↓",JOY_BUTTON_DPAD_LEFT:"十字←",JOY_BUTTON_DPAD_RIGHT:"十字→",PAD_LT:"LT",PAD_RT:"RT"}
	return names.get(button,"パッド%d"%button)

# The label for an action on whichever device the player touched last.
func lbl(name: String) -> String:
	var parts: Array[String] = []
	if using_pad:
		if name in ["left","right","down"]: return {"left":"←","right":"→","down":"↓"}[name]+"（十字／スティック）"
		for button in pad_binds[name]: parts.append(pad_name(button))
	else:
		for code in key_binds[name]: parts.append(key_name(code))
	return " / ".join(parts) if not parts.is_empty() else "未設定"

func move_label() -> String:
	return "十字／スティック" if using_pad else lbl("left")+"  "+lbl("right")

func confirm_label() -> String:
	return "A" if using_pad else "ENTER"

func level_db(level: int, base: float) -> float:
	return -80.0 if level<=0 else base+20.0*log(level/5.0)/log(10.0)

func apply_volume():
	if music_fade and music_fade.is_valid(): music_fade.kill()
	music.volume_db = level_db(bgm_level,-18.0)
	if bgm_level<=0: music.stop()
	elif not muted and not music.playing and state in ["play","pause","dead","settings"] and not (state=="settings" and settings_from=="title"): music.play()

func reset_bindings():
	key_binds = DEFAULT_KEYS.duplicate(true)
	pad_binds = DEFAULT_PAD.duplicate(true)

func settings_testing() -> bool:
	# Tests always use the default controls and never overwrite the player's file.
	return OS.get_cmdline_user_args().size()>0 or Engine.get_main_loop().get_script()!=null

func load_settings():
	reset_bindings()
	if settings_testing(): return
	var cfg = ConfigFile.new()
	if cfg.load(settings_path)!=OK: return
	bgm_level = clampi(int(cfg.get_value("audio","bgm",5)),0,10)
	sfx_level = clampi(int(cfg.get_value("audio","sfx",5)),0,10)
	for name in ACTIONS:
		var keys = cfg.get_value("keys",name,null)
		if keys is Array: key_binds[name] = keys.map(func(v): return int(v))
		var pads = cfg.get_value("pad",name,null)
		if pads is Array and not name in ["left","right","down"]: pad_binds[name] = pads.map(func(v): return int(v))

func save_settings():
	if settings_testing(): return
	var cfg = ConfigFile.new()
	cfg.set_value("audio","bgm",bgm_level)
	cfg.set_value("audio","sfx",sfx_level)
	for name in ACTIONS:
		cfg.set_value("keys",name,key_binds[name])
		cfg.set_value("pad",name,pad_binds[name])
	cfg.save(settings_path)

func settings_rows() -> Array:
	return ["bgm","sfx"]+ACTIONS+["reset","back"]

func open_settings():
	settings_from = state
	settings_index = 0
	rebinding = ""
	settings_note = ""
	state = "settings"

func close_settings():
	rebinding = ""
	save_settings()
	state = settings_from

# A key or button may belong to only one action, so a new assignment takes it from the others.
func bind_key(name: String, code: int):
	for other in ACTIONS: key_binds[other] = key_binds[other].filter(func(c): return c!=code)
	key_binds[name] = [code]
	rebinding = ""
	settings_note = ACTION_NAMES[name]+" を "+key_name(code)+" にしました"

func bind_pad(name: String, button: int):
	for other in ACTIONS: pad_binds[other] = pad_binds[other].filter(func(b): return b!=button)
	pad_binds[name] = [button]
	rebinding = ""
	settings_note = ACTION_NAMES[name]+" を "+pad_name(button)+" にしました"

func settings_activate(direction = 0):
	var row = settings_rows()[settings_index]
	match row:
		"bgm":
			bgm_level = clampi(bgm_level+(direction if direction!=0 else 1),0,10)
			apply_volume()
		"sfx":
			sfx_level = clampi(sfx_level+(direction if direction!=0 else 1),0,10)
			sound("shot")
		"reset":
			if direction==0:
				reset_bindings()
				bgm_level = 5
				sfx_level = 5
				apply_volume()
				settings_note = "初期設定に戻しました"
		"back":
			if direction==0: close_settings()
		_:
			if direction==0:
				rebinding = row
				settings_note = ""

func settings_move(step: int):
	var count = settings_rows().size()
	settings_index = (settings_index+step+count)%count

func settings_input(event):
	if rebinding!="":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode==KEY_ESCAPE: rebinding = ""
			elif event.physical_keycode in [KEY_F11,KEY_M]: settings_note = "F11 と M は変更できません"
			else: bind_key(rebinding,event.physical_keycode)
		elif event is InputEventJoypadButton and event.pressed:
			if event.button_index in [JOY_BUTTON_START,JOY_BUTTON_BACK]: rebinding = ""
			elif rebinding in ["left","right","down"]: settings_note = "パッドの方向は十字キーとスティックで固定です"
			else: bind_pad(rebinding,event.button_index)
		elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and event.axis_value>0.6:
			if not rebinding in ["left","right","down"]: bind_pad(rebinding,PAD_LT if event.axis==JOY_AXIS_TRIGGER_LEFT else PAD_RT)
		elif event is InputEventMouseButton and event.pressed: rebinding = ""
		return
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_UP, KEY_W: settings_move(-1)
			KEY_DOWN, KEY_S: settings_move(1)
			KEY_LEFT, KEY_A: settings_activate(-1)
			KEY_RIGHT, KEY_D: settings_activate(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if not event.echo: settings_activate()
			KEY_ESCAPE, KEY_BACKSPACE, KEY_O:
				if not event.echo: close_settings()
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP: settings_move(-1)
			JOY_BUTTON_DPAD_DOWN: settings_move(1)
			JOY_BUTTON_DPAD_LEFT: settings_activate(-1)
			JOY_BUTTON_DPAD_RIGHT: settings_activate(1)
			JOY_BUTTON_A: settings_activate()
			JOY_BUTTON_B, JOY_BUTTON_START, JOY_BUTTON_BACK: close_settings()
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
		var dir = 0 if absf(event.axis_value)<0.6 else int(signf(event.axis_value))
		var held = stick_nav.get(event.axis,0)
		if dir!=0 and dir!=held:
			if event.axis==JOY_AXIS_LEFT_Y: settings_move(dir)
			else: settings_activate(dir)
		stick_nav[event.axis] = dir
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var m = get_global_mouse_position()
		for i in range(settings_rows().size()):
			if settings_row_rect(i).has_point(m):
				settings_index = i
				var row = settings_rows()[i]
				if row in ["bgm","sfx"]: settings_activate(-1 if m.x<settings_row_rect(i).get_center().x+200 else 1)
				else: settings_activate()

func settings_row_rect(i: int) -> Rect2:
	return Rect2(250,150+i*44,780,38)

func draw_settings():
	draw_rect(Rect2(0,0,W,H),Color(0.015,0.025,0.06,0.9))
	txt(Vector2(250,110),"設定",36,PINK)
	txt(Vector2(380,108),("十字 / スティックで選択   A 決定   B 戻る" if using_pad else "↑↓ 選択   ←→ 音量   ENTER 決定   ESC 戻る"),16,Color("bdcbe2"))
	txt(Vector2(640,140),"キーボード",14,Color("84d9e2"))
	txt(Vector2(870,140),"コントローラー",14,Color("84d9e2"))
	var rows = settings_rows()
	for i in range(rows.size()):
		var r = settings_row_rect(i)
		var row = rows[i]
		var selected = i==settings_index
		draw_rect(r,Color(0.08,0.2,0.28,0.95) if selected else Color(0.03,0.07,0.13,0.8))
		if selected: draw_rect(Rect2(r.position,Vector2(4,r.size.y)),Color("ffe28a"))
		var y = r.position.y+26
		match row:
			"bgm", "sfx":
				var level = bgm_level if row=="bgm" else sfx_level
				txt(Vector2(272,y),"BGMの音量" if row=="bgm" else "効果音の音量",19)
				for k in range(10):
					draw_rect(Rect2(640+k*30,r.position.y+10,24,18),CYAN if k<level else Color("29344b"))
				txt(Vector2(950,y),"切" if level==0 else str(level),18,Color("ffe28a"))
			"reset": txt(Vector2(272,y),"初期設定に戻す",19)
			"back": txt(Vector2(272,y),"戻る（自動で保存）",19)
			_:
				txt(Vector2(272,y),ACTION_NAMES[row],19)
				if rebinding==row:
					txt(Vector2(640,y),"新しいキーかボタンを押してください（ESC / START で取り消し）",16,Color("ffe28a") if int(clock*4)%2==0 else PINK)
				else:
					var keys: Array[String] = []
					for code in key_binds[row]: keys.append(key_name(code))
					var pads: Array[String] = []
					for button in pad_binds[row]: pads.append(pad_name(button))
					txt(Vector2(640,y)," / ".join(keys) if not keys.is_empty() else "未設定",18,Color("edf6ff"))
					txt(Vector2(870,y),("十字 / スティック" if row in ["left","right","down"] else (" / ".join(pads) if not pads.is_empty() else "未設定")),18,Color("edf6ff"))
	if settings_note!="": txt(Vector2(250,H-24),settings_note,17,Color("ffe28a"))
	else: txt(Vector2(250,H-24),"項目を決定してから、割り当てたいキーやボタンを押します。同じキーは他の操作から外れます。",15,Color("bdcbe2"))

func _unhandled_input(event):
	if event is InputEventKey and event.pressed: using_pad = false
	elif event is InputEventMouseButton and event.pressed: using_pad = false
	elif event is InputEventJoypadButton and event.pressed: using_pad = true
	elif event is InputEventJoypadMotion and absf(event.axis_value)>0.5: using_pad = true
	if state == "settings":
		settings_input(event)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_O and state in ["title","pause"]:
			open_settings()
			return
		if event.keycode == KEY_F11:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if event.keycode == KEY_M:
			muted = not muted
			if muted: music.stop()
			elif bgm_level>0 and state in ["play", "pause", "dead"]: music.play()
		if event.keycode == KEY_ESCAPE:
			if state == "play": state = "pause"
			elif state == "pause": state = "play"
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if state == "title" or state == "clear": start_game()
			elif state == "dead": respawn()
			elif state == "pause": state = "play"
		if event.keycode == KEY_E and state == "title": cycle_difficulty(1)
		if event.keycode == KEY_R and state == "pause": state = "title"; music.stop()
	if event is InputEventJoypadButton and event.pressed:
		if (state == "title" and event.button_index == JOY_BUTTON_BACK) or (state == "pause" and event.button_index == JOY_BUTTON_Y):
			open_settings()
			return
		if state == "title" and event.button_index in [JOY_BUTTON_Y,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]: cycle_difficulty(-1 if event.button_index==JOY_BUTTON_DPAD_UP else 1)
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
			elif Rect2(100, 542, 480, 44).has_point(m): cycle_difficulty(1)
			elif Rect2(100, 596, 480, 40).has_point(m): open_settings()
		elif state == "dead": respawn()
		elif state == "clear": start_game()
		elif state == "pause": state = "play"

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play" and not capture_mode: state = "pause"

func _process(dt):
	clock += dt
	queue_redraw()

func _physics_process(dt):
	if state in ["play","defeat"]: update_game(dt)

func update_game(dt: float):
	# A just dodge briefly slows the whole game to half speed.
	if state=="play" and slow_time>0:
		slow_time -= dt
		dt *= 0.5
	slow_cool = maxf(0,slow_cool-dt)
	dodge_charge = maxf(0,dodge_charge-dt)
	update_fx(dt)
	if state == "defeat":
		ending_time += dt
		shake = 8*(1-ending_time/2.6)
		if int(ending_time*12)>int((ending_time-dt)*12):
			fx.append({"p":boss_pos+Vector2(rng.randf_range(-85,85),rng.randf_range(-150,0)),"age":0.0,"size":140.0})
		if ending_time >= 2.6:
			state = "clear"
			reward_clear()
			sound("win")
		return
	if state != "play": return
	if hitstop>0:
		hitstop -= dt
		# Keep presses made during the freeze so a jump or shot is not lost.
		var held_jump = act("jump")
		var held_fire = act("fire")
		if held_jump and not prev_jump:
			jump_buffer = 0.12+maxf(0,hitstop)
			drop_buffer = jump_buffer if act("down") else 0.0
		if held_fire and not prev_fire: fire_buffer = 0.12+maxf(0,hitstop)
		prev_jump = held_jump
		return
	combo_timer=maxf(0,combo_timer-dt)
	if combo_timer<=0: combo=0
	saber_time = maxf(0,saber_time-dt)
	aim_time = maxf(0,aim_time-dt)
	saber_cooldown = maxf(0,saber_cooldown-dt)
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
	var axis = float(act("right")) - float(act("left"))
	var ja = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if absf(ja) > 0.25: axis = ja
	if joy(JOY_BUTTON_DPAD_LEFT): axis = -1
	if joy(JOY_BUTTON_DPAD_RIGHT): axis = 1
	var jump = act("jump")
	var dash = act("dash")
	var down = act("down")
	var saber_input = act("saber")
	# The saber has no gauge; its cooldown is the only limit. A charge keeps building through the swing.
	if saber_input and not prev_saber and saber_cooldown<=0 and (dash_timer<=0 or danmaku) and hurt_pose<=0:
		# Danmaku swings come out almost at once so shots can be returned one after another.
		saber_time = 0.34 if danmaku else 0.42
		saber_air = not grounded
		muzzle_time = 0
		saber_cooldown = DANMAKU_SABER_COOLDOWN if danmaku else SABER_COOLDOWN
		saber_facing = facing
		saber_hits.clear()
		saber_boss_hit = false
		sound("dash")
	prev_saber = saber_input
	# Each press fires one shot; holding the same button builds a two-stage charge.
	var fire = act("fire")
	var shot_request = -1
	if fire and not prev_fire and saber_time<=0: fire_buffer = 0.12
	fire_buffer -= dt
	if fire_buffer>0 and shot_timer<=0 and saber_time<=0:
		shot_request = 0
		fire_buffer = 0
	if fire: charge = minf(FULL_CHARGE,charge+dt)
	elif prev_fire:
		if charge>=0.8: charge_release = 2 if charge>=FULL_CHARGE else 1
		charge = 0
	# A charge let go mid-swing fires the moment the swing ends.
	if charge_release>0 and saber_time<=0 and hurt_pose<=0:
		shot_request = charge_release
		charge_release = -1
	prev_fire = fire
	var charging = fire and charge>=0.2
	if jump and not prev_jump:
		jump_buffer = 0.12
		drop_buffer = 0.12 if down else 0.0
	drop_buffer -= dt
	# Down + jump on a thin platform drops through it instead of jumping.
	if drop_buffer>0 and grounded and player.y<600:
		drop_timer = 0.25
		grounded = false
		player.y += 5
		velocity.y = 80
		jump_buffer = 0
		drop_buffer = 0
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
		drop_buffer = 0
		sound("jump")
	if not jump and prev_jump and velocity.y < -220: velocity.y = -220
	if axis != 0 and saber_time<=0: facing = 1 if axis > 0 else -1
	if dash and not prev_dash and dash_cooldown <= 0 and saber_time<=0:
		dash_timer = 0.17
		dash_cooldown = DASH_COOLDOWN
		invincible = maxf(invincible, 0.24)
		sound("dash")
	prev_jump = jump
	prev_dash = dash
	if dash_timer > 0:
		dash_timer -= dt
		velocity.x = facing * 720
		velocity.y = 0
		burst(player + Vector2(0,-20), CYAN, 1)
	else:
		var on_ice = int(player.x/ROOM)<24 and layout[int(player.x/ROOM)].ice and grounded
		# Ice barely grips and lets Lumina slide faster than she can run.
		var move_accel = 150.0 if on_ice else (650.0 if field_area()==5 and not grounded else 2300.0)
		if hurt_pose<=0: velocity.x = move_toward(velocity.x, axis * (340.0 if on_ice else 285.0) * (0.55 if charging else 1.0) * (0.4 if saber_time>0 else 1.0), move_accel*dt)
		var low_gravity = field_area()==5
		var low_gravity_air = low_gravity and not grounded
		velocity.y = minf(560.0 if low_gravity else 900.0, velocity.y + (900.0 if low_gravity else 1600.0) * dt)
		if low_gravity_air and down:
			velocity.y=move_toward(velocity.y,800.0,2100.0*dt)
	var old_y = player.y
	var old_x = player.x
	player.x = clampf(player.x + (velocity.x + wind_push()) * dt, backtrack_limit(), END_X - 30)
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
	update_doors(dt,Vector2(old_x,old_y))
	if player.y > 850:
		# 穴への落下は即死にせず、少し減って直前の足場へ戻る
		falls += 1
		invincible = 0
		hurt(2 if easy else 3)
		if state == "play":
			player = safe_pos
			player.x = maxf(player.x,backtrack_limit())
			velocity = Vector2.ZERO
			dash_timer = 0
	if state != "play": return
	for core in cores:
		if core.got and core.sync>0:
			core.sync = maxf(0,core.sync-dt)
			if (core.sync<8 and core.waves==0) or (core.sync<4 and core.waves==1):
				core.waves += 1
				var base = core.room*ROOM
				place_enemy(Vector2(base+450,600),4 if core.room>=12 else 0,core.room)
				place_enemy(Vector2(base+900,390),5 if core.room>=8 else 1,core.room)
				banner = "増援接近  %d / 2  —  同期完了まで守り抜こう"%core.waves
				banner_time = 2

		if not core.got and (player-Vector2(0,30)).distance_to(core.p)<45:
			core.got = true
			score += 500
			core_count += 1
			hp = mini(max_hp,hp+3)
			burst(core.p,Color("ffd27f"),24)
			sound("heal")
			banner_time = 3
			var door = gate_of(core.room)
			match door.kind:
				"sync": banner = "スターコア回収  %d / 6  —  12秒間の同期、防衛開始！"%core_count
				"switch":
					core.sync = 0
					banner = "スターコア回収  %d / 6  —  扉のスイッチを撃ち抜け！"%core_count
				"break":
					core.sync = 0
					banner = "スターコア回収  %d / 6  —  ため撃ちで扉のロックを破壊しよう"%core_count
				"kill":
					core.sync = 0
					var base = core.room*ROOM
					spawn_enemy(Vector2(base+820,600),6,core.room)
					banner = "搬送路の番人、起動！ 予告を見て射撃・突進・衝撃波を避けよう"
	for laser in lasers:
		if fmod(elapsed+laser.phase,3.6)>2.2 and absf(player.x-laser.x)<55 and player.y>574:
			hurt(1 if easy else 2)
	update_field(dt)
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
	if grounded and absf(velocity.x)>15:
		walk_phase = fmod(walk_phase+absf(velocity.x)*dt/13.0,8.0)
	else: walk_phase = 0
	if saber_time>0 and not grounded: saber_air = true
	# A just dodge loads the next shot as a full charge.
	if shot_request==0 and dodge_charge>0:
		shot_request = 2
		dodge_charge = 0
	if shot_request>=0: shoot(shot_request>=1,shot_request==2)
	for i in range(popups.size()-1,-1,-1):
		popups[i].age += dt
		if popups[i].age>0.8: popups.remove_at(i)
	update_enemies(dt)
	update_boss(dt)
	update_saber()
	update_bullets(dt)
	for i in range(particles.size()-1,-1,-1):
		var p = particles[i]
		p.p += p.v * dt
		p.v.y += 200 * dt
		p.life -= dt
		if p.life <= 0: particles.remove_at(i)
	camera_x = clampf(lerpf(camera_x,camera_goal(),1-exp(-dt*8)),0,END_X-W)
	update_music_state()

func shoot(big: bool, full = false):
	if saber_time>0 or hurt_pose>0: return
	aim_time = 0.25
	muzzle_time = 0.1
	shot_timer = 0.14
	# A full charge pierces every enemy in its path.
	var damage = 12 if full else (7 if big else 2)
	var radius = 21.0 if full else (15.0 if big else 5.0)
	var origin = muzzle_position()
	# The cannon may extend past a wall when standing close. Keep the shot on this side.
	for gate in gates:
		if door_blocks_at(gate,origin.y) and gate.x>minf(player.x,origin.x) and gate.x<maxf(player.x,origin.x):
			origin.x = gate.x-facing*(DOOR_HALF_WIDTH+radius+1)
	bullets.append({"p":origin,"v":Vector2(facing*(980 if full else 860),0),"enemy":false,"damage":damage,"r":radius,"life":1.8,"pierce":full,"hits":[]})
	if full: shake = maxf(shake,4)
	sound("charge" if big else "shot")

# kind: "solid" cannot be cut by the saber, "home" steers toward Lumina, "bomb" falls and splits on the floor.
func enemy_shot(pos: Vector2, vel: Vector2, radius = 8.0, kind = ""):
	if danmaku and vel.length()>1:
		# Three times the fire: floor waves come at three speeds, everything else fans out.
		var floor_wave = absf(vel.y)<1 and pos.y>=585
		for k in [-1,0,1]:
			add_enemy_bullet(pos,vel*(1.0+k*0.28) if floor_wave else vel.rotated(k*0.2),radius,kind)
	else: add_enemy_bullet(pos,vel,radius,kind)

func add_enemy_bullet(pos: Vector2, vel: Vector2, radius = 8.0, kind = ""):
	var b = {"p":pos,"v":vel,"enemy":true,"damage":1 if easy or danmaku else 2,"r":radius,"life":5.0,"solid":kind in ["solid","bomb"]}
	if kind=="home": b.home = 1.6
	if kind=="bomb": b.bomb = true
	bullets.append(b)

# Area field effects: 1 floor surge, 2 wind gusts, 3 ice (in move code), 4 searchlights, 5 low gravity.
func field_area() -> int:
	var area = int(player.x/(ROOM*4))
	return area if area<6 else -1

func surge_phase() -> String:
	var c = fmod(elapsed,8.0)
	return "on" if c>=7.0 else ("warn" if c>=5.6 else "off")

func wind_dir() -> float:
	return 1.0 if int(elapsed/7.0)%2==0 else -1.0

# Gusts blow for 3 s of every 7, alternating direction, strongest mid-gust.
func wind_push() -> float:
	if field_area()!=2: return 0.0
	var c = fmod(elapsed,7.0)
	if c>=3.0: return 0.0
	return wind_dir()*sin(PI*c/3.0)*(150.0 if easy else 210.0)*(1.25 if not grounded else 1.0)

func searchlight_x(room: int, k: int) -> float:
	return room*ROOM+560+sin(elapsed*(0.7+k*0.35)+room*1.3+k*2.0)*430

func update_field(dt: float):
	alert_cool = maxf(0,alert_cool-dt)
	match field_area():
		1:
			if surge_phase()=="on" and grounded and player.y>=605: hurt(1 if easy else 2)
		2:
			var c = fmod(elapsed,7.0)
			if c<dt*1.5:
				banner = "突風！  " + ("→ 右へ流される" if wind_dir()>0 else "← 左へ流される")
				banner_time = 1.5
		4:
			var room = int(player.x/ROOM)
			for k in range(2):
				if alert_cool<=0 and absf(player.x-searchlight_x(room,k))<45:
					alert_cool = 4.0
					popup(player-Vector2(0,110),"発見！",Color("ffe28a"))
					sound("hit")
					for e in enemies:
						if e.hp>0 and e.room==room: e.shot = minf(e.shot,rng.randf_range(0.05,0.35))
		5:
			if player.y<244:
				player.y=244
				velocity.y=maxf(0,velocity.y)
				if ceiling_phase()=="on":
					hurt(1 if easy else 2)
					velocity.y=260
					jump_buffer=0

func ceiling_phase() -> String:
	var cycle=fmod(elapsed,6.0)
	return "on" if cycle>=4.0 else ("warn" if cycle>=3.1 else "off")

func gate_of(room: int) -> Dictionary:
	for gate in gates:
		if gate.room==room: return gate
	return {"kind":"sync"}

func door_ready(gate: Dictionary) -> bool:
	if gate.passed: return false
	for core in cores:
		if core.room==gate.room and (not core.got or core.sync>0): return false
	if gate.kind in ["sync","kill"]:
		for e in enemies:
			if e.room==gate.room and e.hp>0 and (gate.kind=="sync" or e.kind==6): return false
	if gate.kind=="break" and gate.hp>0: return false
	for s in gate.switches:
		if not s.on: return false
	return true

func door_gap_top(gate: Dictionary) -> float:
	return DOOR_FLOOR-(DOOR_FLOOR-DOOR_TOP)*gate.lift

func door_blocks_at(gate: Dictionary, y: float) -> bool:
	return gate.passed or not gate.open or y<door_gap_top(gate) or y>DOOR_FLOOR

func backtrack_limit() -> float:
	var limit = 24.0
	for gate in gates:
		if gate.passed: limit=maxf(limit,gate.x+DOOR_HALF_WIDTH+PLAYER_HALF_WIDTH)
	return limit

func update_doors(dt: float, previous: Vector2):
	for gate in gates:
		if gate.passed:
			gate.lift = maxf(0,gate.lift-dt*4.0)
			var stop = gate.x+DOOR_HALF_WIDTH+PLAYER_HALF_WIDTH
			if player.x<=stop:
				player.x=stop
				if velocity.x<0: velocity.x=0
			continue
		else:
			if not gate.open and door_ready(gate):
				gate.open = true
				shake = maxf(shake,5)
				sound("win" if gate.kind=="break" else "heal")
				if absf(player.x-gate.x)<1200: burst(Vector2(gate.x,500),CYAN,22)
			if gate.open: gate.lift=minf(1,gate.lift+dt*1.8)
		var gap_top = door_gap_top(gate)
		var overlaps = absf(player.x-gate.x)<DOOR_HALF_WIDTH+PLAYER_HALF_WIDTH
		# A persistent header above the opening also acts as a ceiling inside the doorway.
		if gate.open and not gate.passed and overlaps and previous.y-DOOR_PLAYER_HEIGHT>=gap_top and player.y-DOOR_PLAYER_HEIGHT<gap_top and velocity.y<0:
			player.y=gap_top+DOOR_PLAYER_HEIGHT
			velocity.y=0
		var fits = gate.open and not gate.passed and player.y-DOOR_PLAYER_HEIGHT>=gap_top and player.y<=DOOR_FLOOR+1
		if fits and player.x>=gate.x: gate.entered=true
		if gate.open and gate.entered and player.x>=gate.x+DOOR_HALF_WIDTH+PLAYER_HALF_WIDTH+8:
			gate.passed=true
			gate.open=false
			# A fall immediately after crossing must recover on the destination side.
			safe_pos=Vector2(maxf(player.x,gate.x+90),DOOR_FLOOR)
			if area_damage==0:
				score+=300
				popup(player-Vector2(0,110),"ノーダメージ区間 +300",Color("ffe28a"))
			area_damage=0
			sound("dash")
			burst(Vector2(gate.x,525),PINK,10)
			if absf(player.x-gate.x)<500:
				banner="後方の扉をロック — この先へ進もう"
				banner_time=2
			continue
		if not fits:
			var clearance = DOOR_HALF_WIDTH+PLAYER_HALF_WIDTH
			if previous.x<=gate.x and player.x>gate.x-clearance:
				player.x=gate.x-clearance
				velocity.x=0
			elif previous.x>gate.x and player.x<gate.x+clearance:
				player.x=gate.x+clearance
				velocity.x=0

# Without a height, used to keep enemies on the far side inactive until passage opens.
func door_between(a: float, b: float, y = INF) -> bool:
	for gate in gates:
		var blocked = gate.passed or not gate.open or gate.lift<0.99
		if y!=INF: blocked=door_blocks_at(gate,y)
		if blocked and gate.x>minf(a,b) and gate.x<maxf(a,b): return true
	return false

# Lumina's shot hits a door switch or the breakable door face. Returns true when the bullet is spent.
func hit_door_parts(b: Dictionary) -> bool:
	for gate in gates:
		if gate.open or gate.passed or absf(gate.x-b.p.x)>60: continue
		for s in gate.switches:
			if not s.on and Rect2(s.p-Vector2(16,24),Vector2(32,48)).grow(b.r).has_point(b.p):
				s.on = true
				burst(s.p,Color("ffe28a"),14)
				popup(s.p-Vector2(0,30),"SWITCH ON",Color("ffe28a"))
				sound("charge")
				return true
		if gate.kind=="break" and b.p.x>gate.x-26 and b.p.y>250:
			if b.damage>=7:
				gate.hp -= b.damage
				shake = maxf(shake,4)
				burst(b.p,Color("ffb35a"),16)
				popup(b.p-Vector2(30,30),"CRACK!" if gate.hp>0 else "BREAK!",Color("ffb35a"))
			else: burst(b.p,Color("9fb4c8"),3)
			return true
	return false

func popup(pos: Vector2, text: String, color: Color):
	popups.append({"p":pos,"text":text,"c":color,"age":0.0})

func on_ground(x: float, y: float) -> bool:
	for p in platforms:
		if x>=p.position.x and x<=p.end.x and absf(p.position.y-y)<24: return true
	return false

func update_enemies(dt: float):
	for e in enemies:
		if e.hp<=0 or absf(e.p.x-player.x)>1300: continue
		var previous_pos = e.p
		e.t += dt
		e.flash -= dt
		e.shot -= dt
		if e.kind==6:
			update_miniboss(e,dt)
			continue
		var on_screen = e.p.x>camera_x+20 and e.p.x<camera_x+W-20 and not door_between(e.p.x,player.x)
		var speed = 190.0 if easy else 250.0
		var aim = (player+Vector2(0,-40)-e.p).normalized()
		var mode = e.get("mode","walk")
		e.mt = e.get("mt",0.0)-dt
		e.cool = e.get("cool",0.0)-dt
		# Beetles and rollers telegraph with a blink, then rush along the floor.
		if e.kind in [0,4]:
			if mode=="walk":
				e.p.x = e.origin.x+sin(e.t*(1.4 if e.kind==0 else 2.5))*(75 if e.kind==0 else 95)
				var reach = 300.0 if e.kind==0 else 520.0
				if on_screen and e.cool<=0 and absf(player.x-e.p.x)<reach and absf(player.y-e.p.y)<80:
					e.mode = "wind"
					e.mt = 0.5 if e.kind==0 else 0.6
					e.dir = 1.0 if player.x>e.p.x else -1.0
			elif mode=="wind":
				if int(e.mt*16)%2==0: e.flash = 0.04
				if e.mt<=0:
					e.mode = "rush"
					e.mt = 0.45 if e.kind==0 else 1.1
			elif mode=="rush":
				var next_x = e.p.x+e.dir*(430.0 if e.kind==0 else 380.0)*dt
				if on_ground(next_x+e.dir*20,e.p.y+10) and not door_between(e.p.x,next_x+e.dir*40): e.p.x = next_x
				else: e.mt = 0
				if e.mt<=0:
					e.mode = "walk"
					e.cool = 2.4 if e.kind==0 else 1.6
					e.origin.x = e.p.x-sin(e.t*(1.4 if e.kind==0 else 2.5))*(75 if e.kind==0 else 95)
		match e.kind:
			1:
				# Drones wander between random points near home, sometimes darting fast.
				e.gt = e.get("gt",0.0)-dt
				if e.gt<=0 or e.p.distance_to(e.get("goal",e.p))<4:
					e.goal = e.origin+Vector2(rng.randf_range(-170,170),rng.randf_range(-80,60))
					var room_x = e.room*ROOM
					e.goal.x = clampf(e.goal.x,room_x+60,room_x+1040)
					e.dart = rng.randf()<0.3
					e.gt = rng.randf_range(0.7,1.6)
				e.p = e.p.move_toward(e.goal,(330.0 if e.dart else 120.0)*dt)+Vector2(0,sin(e.t*7)*0.6)
			2: e.p.x = move_toward(e.p.x,clampf(player.x,e.origin.x-90,e.origin.x+90),40*dt)
			5:
				e.p.x = e.origin.x+sin(e.t)*85
				e.p.y = e.origin.y+sin(e.t*2)*25
		# Patrols and shield movement must obey the same persistent bulkheads as rushes.
		for gate in gates:
			if not door_blocks_at(gate,e.p.y-20): continue
			if previous_pos.x<=gate.x and e.p.x>gate.x-DOOR_HALF_WIDTH-30:
				e.p.x=gate.x-DOOR_HALF_WIDTH-30
			elif previous_pos.x>gate.x and e.p.x<gate.x+DOOR_HALF_WIDTH+30:
				e.p.x=gate.x+DOOR_HALF_WIDTH+30
		# Bursts fire the rest of a volley a few frames apart.
		if e.get("burst",0)>0:
			if not on_screen: e.burst=0
			e.bt = e.get("bt",0.0)-dt
			if e.bt<=0 and e.burst>0:
				e.burst -= 1
				e.bt = 0.14
				enemy_shot(e.p+Vector2(0,-18),aim*speed*1.1)
		if e.shot<=0 and on_screen and mode=="walk":
			e.n = e.get("n",0)+1
			e.shot = (2.7 if easy else 2.0) if e.kind!=3 else 2.4
			match e.kind:
				0: enemy_shot(e.p+Vector2(0,-18),aim*speed)
				1:
					if e.n%2==0: e.burst = 3
					else: enemy_shot(e.p+Vector2(0,-18),aim*speed)
				2:
					# Shield bot alternates an aimed shot with a floor wave that must be jumped.
					if e.n%2==0: enemy_shot(Vector2(e.p.x,596),Vector2(signf(player.x-e.p.x)*270,0),12,"solid")
					else: enemy_shot(e.p+Vector2(0,-30),aim*speed)
				3:
					if e.n%2==0: enemy_shot(e.p+Vector2(0,-18),aim*170,10,"home")
					else:
						for j in range(3): enemy_shot(e.p+Vector2(0,-18),aim.rotated((j-1)*0.16)*speed,7)
				5:
					enemy_shot(e.p,Vector2(signf(player.x-e.p.x)*70,40),13,"bomb")
		if not door_between(player.x,e.p.x) and (player+Vector2(0,-40)).distance_to(e.p+Vector2(0,-10))<48: hurt(1 if easy else 2)

func update_boss(dt: float):
	# Once the fight starts the boss keeps acting even when Lumina backs into the left wall.
	if boss_hp<=0 or (not boss_active and player.x<BOSS_X+100): return
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
		var order = [0,1,2,3,4,6] if boss_phase==2 else [0,1,2,5]
		var pattern = order[boss_cycle%order.size()]
		var direction = -1 if player.x<boss_pos.x else 1
		match pattern:
			0:
				for j in range(7): enemy_shot(boss_pos+Vector2(0,-55),Vector2(direction,0).rotated((j-3)*0.22)*230,10)
			1:
				enemy_shot(Vector2(boss_pos.x,585),Vector2(direction*340,0),17,"solid")
			5:
				# Two homing orbs from the shoulders.
				for side in [-1,1]: enemy_shot(boss_pos+Vector2(side*60,-130),Vector2(side*120,-160),11,"home")
			6:
				# A ring where every other bullet is solid: cut the soft ones to open a gap.
				for j in range(14): enemy_shot(boss_pos+Vector2(0,-70),Vector2.RIGHT.rotated(j*TAU/14+elapsed)*200,10,"solid" if j%2==0 else "")
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
		var old_x = b.p.x
		b.p += b.v*dt
		if not b.enemy and hit_door_parts(b):
			bullets.remove_at(i)
			continue
		# Closed doors are solid walls: nothing crosses them.
		if door_between(old_x-b.r*signf(b.v.x),b.p.x+b.r*signf(b.v.x),b.p.y):
			burst(b.p,Color("9fb4c8"),3)
			bullets.remove_at(i)
			continue
		b.life -= dt
		var remove = b.life <= 0 or b.p.x < camera_x - 60 or b.p.x > camera_x + W + 60
		if b.enemy:
			if b.get("home",0.0)>0:
				b.home -= dt
				var want = (player+Vector2(0,-40)-b.p).normalized()*b.v.length()
				b.v = b.v.lerp(want,minf(1,dt*2.2)).normalized()*maxf(170,b.v.length())
			if b.get("bomb",false):
				b.v.y += 520*dt
				if on_ground(b.p.x,b.p.y+b.r) and b.v.y>0:
					for side in [-1,1]: add_enemy_bullet(Vector2(b.p.x,594),Vector2(side*210,0),7)
					burst(b.p,Color("ffb35a"),10)
					bullets.remove_at(i)
					continue
			if saber_active() and not b.get("solid",false) and saber_rect().grow(b.r).has_point(b.p):
				parries += 1
				# The first frames of the swing reflect the shot back as a homing bolt.
				if saber_time>(DANMAKU_JUST_WINDOW if danmaku else JUST_WINDOW):
					b.enemy = false
					b.v = Vector2(saber_facing*900,0)
					b.damage = 1 if danmaku else 3
					b.reflected=true
					b.seek = true
					b.life = 2.0
					b.hits = []
					b.erase("home")
					score+=100
					just_reflections+=1
					parry_marks.append({"p":b.p,"age":0.0})
					burst(b.p,Color("ffe28a"),12)
					popup(b.p,"JUST!",Color("ffe28a"))
					hitstop = maxf(hitstop,0.03)
					sound("charge")
				else:
					# A late block only cancels the shot and leaves the saber slower to come back.
					if not danmaku: saber_cooldown = minf(1.4,saber_cooldown+0.2)
					burst(b.p,CYAN,8)
					bullets.remove_at(i)
				continue
			if Rect2(player-Vector2(21,80),Vector2(42,80)).grow(b.r).has_point(b.p):
				# Slipping through a shot during the dash readies the saber at once.
				if dash_timer>0:
					if not b.get("grazed",false):
						b.grazed = true
						just_dodge_reward()
					continue
				hurt(b.damage)
				remove = true
		else:
			if b.get("seek",false): steer_reflection(b,dt)
			var pierce = b.get("pierce",false)
			for ei in range(enemies.size()):
				var e = enemies[ei]
				if pierce and ei in b.hits: continue
				if e.hp > 0 and enemy_rect(e).grow(b.r).has_point(b.p):
					if e.get("shield",false) and b.damage<7:
						burst(b.p,CYAN,3)
						remove = true
						break
					e.shield = false
					var damage = b.damage*(2 if e.kind==6 and b.get("reflected",false) else 1)
					e.hp -= damage
					if e.kind==6 and b.get("reflected",false): reflection_reward(b.p)
					e.flash = 0.12
					burst(b.p,PINK,4)
					if pierce: b.hits.append(ei)
					else: remove = true
					if e.hp <= 0:
						register_enemy_defeat(e)
					break
			if not remove and boss_active and boss_intro<=0 and boss_hp > 0 and Rect2(boss_pos-Vector2(70,160),Vector2(140,180)).grow(b.r).has_point(b.p):
				boss_hp -= b.damage*(2 if b.get("reflected",false) else 1)
				if b.get("reflected",false): reflection_reward(b.p)
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
	damage_taken+=mini(hp,amount)
	area_damage+=mini(hp,amount)
	combo=0
	combo_timer=0
	hp = maxi(0,hp-amount)
	invincible = 1.3
	shake = 8
	hurt_pose = 0.24
	saber_time = 0
	velocity = Vector2(-facing*250,-180)
	dash_timer = 0
	sound("hit")
	burst(player-Vector2(0,30),PINK,15)
	if hp <= 0:
		state = "dead"
		deaths += 1

func respawn():
	player = Vector2(checkpoint*ROOM*4+130,500)
	player.x=maxf(player.x,backtrack_limit()+60)
	safe_pos = Vector2(player.x, 610)
	velocity = Vector2.ZERO
	hp = max_hp
	invincible = 2
	bullets.clear()
	charge = 0
	saber_time = 0
	saber_air = false
	aim_time = 0
	saber_cooldown = 0
	prev_saber = false
	prev_fire = false
	alert_cool = 0
	fire_buffer = 0
	popups.clear()
	walk_phase = 0
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
	if state == "title" or (state == "settings" and settings_from == "title"):
		draw_title()
		if state == "settings": draw_settings()
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
		if room < 4:
			var tips = [move_label()+"  移動     "+lbl("jump")+"  ジャンプ（2回）", lbl("fire")+"  押すたびに射撃     長押しでため撃ち（金色で貫通）", lbl("dash")+"  ダッシュ・無敵     弾をくぐると次の1発がMAXため撃ち＋スロー", lbl("saber")+"  セーバー：弾を消す     振り始めで当てると敵を追う反射弾"]
			txt(Vector2(x+100,265),tips[room],22,CYAN)
			if room==1: txt(Vector2(x+100,235),lbl("down").get_slice("（",0)+" ＋ "+lbl("jump").get_slice(" / ",0)+"  足場から飛び降りる",18,Color("bdcbe2"))
			if room==3: txt(Vector2(x+100,235),"オレンジのトゲ弾はセーバーで消せない — 跳ぶかダッシュで避けよう",18,Color("ff9a3c"))
		if room in [4,8,12,16,20]:
			var tips = {4:"配電回廊：ときどき床に電流が走る！ 予告が出たら足場へ",8:"空中搬送路：突風が吹く — 風下の穴に注意",12:"冷却プラント：氷の床はほとんど止まれない！",16:"防衛区画：サーチライトに見つかると一斉射撃",20:"低重力：天井の電流と空中の慣性に注意 — "+lbl("down").get_slice("（",0)+"で急降下"}
			txt(Vector2(x+100,235),tips[room],20,CYAN)

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
			if e.kind==6: draw_miniboss(e,offset)
			elif e.kind<2: sprite(4+e.kind,e.p+offset+Vector2(0,10),76,e.p.x<player.x,Color(2,2,2) if e.flash>0 else Color.WHITE)
			else: art_sprite("enemies",e.kind-2,e.p+offset+Vector2(0,10),82,e.p.x<player.x,Color(2,2,2) if e.flash>0 else Color.WHITE)
			if e.get("shield",false):
				draw_arc(e.p+offset-Vector2(0,30),48,-PI/2 if e.p.x<player.x else PI/2,PI/2 if e.p.x<player.x else PI*1.5,24,Color("ffda77"),4)
				txt(e.p+offset+Vector2(-55,-90),"ため撃ちで破壊",13,Color("ffda77"))
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
			if b.get("pierce",false): draw_circle(b.p+offset,36,Color(1,0.85,0.45,0.25))
			art_sprite("charge",int(clock*18)%6,b.p+offset+Vector2(0,b.r*1.9),b.r*3.7,b.v.x<0,Color(1.3,1.1,0.7) if b.get("pierce",false) else Color.WHITE)
			continue
		if b.enemy and b.get("solid",false):
			# Solid shots: orange with a spiked ring, the saber cannot cut them.
			var c = b.p+offset
			draw_circle(c,b.r+6,Color(1,0.55,0.15,0.22))
			var spikes = PackedVector2Array()
			for k in range(16): spikes.append(c+Vector2.RIGHT.rotated(k*TAU/16+clock*6)*(b.r+(5 if k%2==0 else 0)))
			draw_colored_polygon(spikes,Color("ff9a3c"))
			draw_circle(c,b.r*0.55,Color("4a1c08"))
			continue
		if b.enemy and b.get("home",0.0)>0:
			draw_circle(b.p+offset,b.r+7,Color(0.75,0.4,1,0.25))
			draw_circle(b.p+offset,b.r,Color("c784ff"))
			draw_circle(b.p+offset,b.r*0.45,Color.WHITE)
			continue
		var color = PINK if b.enemy else (Color("ffe28a") if b.get("reflected",false) else CYAN)
		if b.get("reflected",false): draw_line(b.p+offset,b.p+offset-b.v.normalized()*30,Color(1,0.85,0.4,0.6),4)
		draw_circle(b.p+offset,b.r+5,Color(color,0.16))
		if b.enemy:
			draw_colored_polygon(PackedVector2Array([b.p+offset+Vector2(0,-b.r),b.p+offset+Vector2(b.r,0),b.p+offset+Vector2(0,b.r),b.p+offset+Vector2(-b.r,0)]),color)
		else: draw_circle(b.p+offset,b.r,color)
		draw_circle(b.p+offset,b.r*0.45,Color.WHITE)
	for p in particles:
		draw_circle(p.p+offset,3,Color(p.c,clampf(p.life*2,0,1)))
	for p in popups:
		txt(p.p+offset+Vector2(-40,-p.age*50),p.text,18,Color(p.c,clampf(2-p.age*2.5,0,1)))
	for effect in fx: art_sprite("explosion",mini(5,int(effect.age*12)),effect.p+offset+Vector2(0,effect.size/2),effect.size)
	if dash_timer>0:
		for i in range(1,4): draw_hero(player+offset-Vector2(facing*i*25,0),Color(0.4,1,1,0.35/i))
	if invincible<=0 or int(clock*18)%2==0: draw_hero(player+offset)
	if muzzle_time>0 and saber_time<=0:
		var region = art.muzzle.regions[mini(5,int((0.1-muzzle_time)*60))]
		var point = muzzle_position()+offset
		draw_set_transform(point,0,Vector2(facing,1))
		draw_texture_rect_region(art.muzzle.texture,Rect2(0,-12,24*region.size.x/region.size.y,24),region)
		draw_set_transform(Vector2.ZERO)
	if saber_active():
		var center = player+offset-Vector2(0,45)
		var progress = (0.42-saber_time-0.14)/0.21
		var angle = -1.15+2.2*progress
		if saber_facing<0: angle = PI-angle
		draw_arc(center,88,angle-0.45,angle+0.45,18,Color(0.4,1,0.9,0.55),4)
	if charge>0.2:
		var full = charge>=FULL_CHARGE
		draw_arc(muzzle_position()+offset,10+charge*6,clock*5,clock*5+TAU*charge/FULL_CHARGE,36,Color("ffe28a") if full else (CYAN if charge>=0.8 else PINK),3 if full else 2)
		if full: draw_circle(player+offset-Vector2(0,45),46+sin(clock*20)*3,Color(1,0.85,0.45,0.12))
	for mark in parry_marks:
		var age = mark.age/0.28
		var center = mark.p+offset
		draw_arc(center,12+age*55,0,TAU,40,Color(1,0.9,0.45,1-age),3)
		draw_arc(center,8+age*35,-age*3,PI-age*3,24,Color(1,1,1,1-age),4)
	draw_field(offset)
	for gate in gates:
		if absf(gate.x-player.x)<1500: draw_door(gate,offset)
	if state=="defeat": draw_rect(Rect2(0,0,W,H),Color(1,0.9,0.95,maxf(0,1-absf(ending_time-2.0)*5)))
	draw_hud()
	if state == "settings": draw_settings()
	if state == "pause": panel("一時停止", ("START" if using_pad else "ENTER / ESC")+" / クリックで再開", ("Y：設定（キー・音量）   BACK：タイトルへ" if using_pad else "O：設定（キー・音量）   R：タイトルへ   M：音を切る"))
	if state == "dead": panel("もう一度、飛び出そう。", confirm_label()+" / クリックでチェックポイントから再開", "残機制限なし。ダッシュ中は短時間、攻撃をすり抜けます。")
	if state == "clear":
		panel("STAGE CLEAR", "星炉は、もう一度輝きはじめた。", "ルミナ、おかえり！   時間 %s   撃破 %d   リトライ %d"%[time_text(),kills,deaths])
		art_sprite("poses",3,Vector2(1090,535),220)
		txt(Vector2(835,305),"CLEAR RANK"+(" / ASSIST" if easy else (" / 弾幕" if danmaku else "")),14,Color("ffe28a"))
		txt(Vector2(875,395),clear_rank(),78,Color("ffe28a"))
		txt(Vector2(300,501),"SCORE %07d   最大コンボ %d   被ダメージ %d"%[score,max_combo,damage_taken],20,Color("ffe28a"))
		txt(Vector2(440,525),confirm_label()+" / クリックでもう一度",24,CYAN)

func draw_field(offset: Vector2):
	var first_room = int(camera_x/ROOM)
	for room in range(first_room,mini(24,first_room+3)):
		if room<16 or room>19: continue
		for k in range(2):
			var lx = searchlight_x(room,k)+offset.x
			if lx<-80 or lx>W+80: continue
			draw_colored_polygon(PackedVector2Array([Vector2(lx-6,132),Vector2(lx+6,132),Vector2(lx+55,610),Vector2(lx-55,610)]),Color(1,0.95,0.6,0.16 if alert_cool<=0 else 0.3))
			env_sprite("devices",2,Rect2(lx-20,96,40,48))
	match field_area():
		1:
			var phase = surge_phase()
			if phase=="off": return
			for p in platforms:
				if p.size.y<30 or p.end.x<camera_x or p.position.x>camera_x+W: continue
				var left = p.position.x+offset.x
				if phase=="warn":
					draw_rect(Rect2(left,600,p.size.x,10),Color(1,0.3,0.6,0.3+0.25*sin(clock*22)))
				else:
					draw_rect(Rect2(left,594,p.size.x,18),Color(0.6,1,1,0.18))
					env_strip("electricity",int(clock*18)%4,Rect2(left,587,p.size.x,30),110)
			if phase=="warn": txt(Vector2(W/2-150,220),"⚡ 床に電流 — 足場へ上がれ！",22,PINK)
		2:
			var push = wind_push()
			if push==0: return
			for i in range(26):
				var x = fposmod(i*157.0+clock*1100*signf(push),W+200)-100
				var y = 140+fmod(i*53.0,440)
				env_sprite("wind",int(clock*14)%4,Rect2(x-95,y-15,190,30),push<0,Color(1,1,1,0.36))
		5:
			draw_rect(Rect2(0,119,W,24),Color("26344a"))
			for x in range(0,int(W),64): draw_circle(Vector2(x+12,127),3,Color("687e92"))
			var phase=ceiling_phase()
			if phase=="on": env_strip("electricity",int(clock*18)%4,Rect2(0,130,W,20),110)
			elif phase=="warn": draw_rect(Rect2(0,134,W,10),Color(1,0.75,0.3,0.4+sin(clock*18)*0.3))
			txt(Vector2(26,195),"空中は慣性が強い / "+lbl("down").get_slice("（",0)+"で急降下",17,CYAN)
			if phase!="off":
				draw_rect(Rect2(340,678,610,32),Color(0.02,0.04,0.1,0.88))
				txt(Vector2(365,701),"天井の電流に注意！ 上がりすぎる前に"+lbl("down").get_slice("（",0)+"で急降下",18,PINK if phase=="on" else Color("ffe28a"))
			for i in range(32):
				var x = fposmod(i*97.3-camera_x*0.3,W)
				var y = fposmod(600-clock*35-i*41,480)+120
				draw_circle(Vector2(x,y),2,Color(0.6,1,1,0.45))

# Placeholder door art (shapes only) until the GPTImage door sprites exist.
func draw_door(gate: Dictionary, offset: Vector2):
	var x = gate.x+offset.x
	# What lies past a closed door stays hidden.
	if player.x<gate.x and not gate.passed: draw_rect(Rect2(x+24,0,maxf(0,W-x-24),H),Color(0.01,0.015,0.04,0.97*(1-gate.lift)))
	# Permanent bulkhead and jambs; only the lower doorway retracts.
	for y in range(0,int(DOOR_TOP),172):
		var height=minf(172,DOOR_TOP-y)
		env_sprite("doors",3,Rect2(x-24,y,48,height),false,Color.WHITE,Vector2(1,height/172.0))
	draw_rect(Rect2(x-30,0,8,DOOR_FLOOR),Color("42536b"))
	draw_rect(Rect2(x+22,0,8,DOOR_FLOOR),Color("42536b"))
	draw_rect(Rect2(x-30,DOOR_TOP-20,60,20),Color("5b7188"))
	var panel = Rect2(x-22,DOOR_TOP,44,maxf(0,door_gap_top(gate)-DOOR_TOP))
	var cracked = gate.kind=="break" and gate.hp<21
	if panel.size.y>0:
		var frame=clampi(3-ceili(gate.hp/7.0),0,2) if cracked and not gate.passed else 0
		env_sprite("doors",frame,panel,false,Color.WHITE,Vector2(1,panel.size.y/(DOOR_FLOOR-DOOR_TOP)))
	var ready = door_ready(gate)
	var light = PINK if gate.passed else (CYAN if gate.open or ready else (Color("ffe28a") if gate.kind=="switch" else (Color("ffb35a") if gate.kind=="break" else PINK)))
	draw_circle(Vector2(x,DOOR_TOP-10),6,Color(light,0.7+sin(clock*6)*0.2))
	for s in gate.switches:
		var c = s.p+offset
		env_sprite("devices",1 if s.on else 0,Rect2(c-Vector2(14,22),Vector2(28,44)))
	if gate.passed:
		txt(Vector2(x-44,DOOR_TOP-30),"後方ロック",15,PINK)
		return
	if gate.open:
		txt(Vector2(x-150,DOOR_TOP-30),"通過後に閉鎖・逆走できません",16,CYAN)
		return
	var hint = {"sync":"コアを同期 ＋ 区画の敵を全滅で開く","switch":"光るスイッチを撃って開ける","kill":"コア回収後、搬送路の番人を倒して開く","break":"ため撃ちで扉のロックを破壊"}[gate.kind]
	txt(Vector2(x-320,235),hint,18,light)

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
	if title_keyart:
		var source=Rect2(Vector2.ZERO,title_keyart.get_size())
		var ratio=W/H
		if source.size.x/source.size.y>ratio:
			var width=source.size.y*ratio
			source.position.x=(source.size.x-width)/2
			source.size.x=width
		else:
			var height=source.size.x/ratio
			source.position.y=(source.size.y-height)/2
			source.size.y=height
		draw_texture_rect_region(title_keyart,Rect2(0,0,W,H),source)
	for x in range(0,800,8):
		var shade=0.82*pow(1-float(x)/800,1.6)
		draw_rect(Rect2(x,0,8,H),Color(0.018,0.028,0.06,shade))
	for y in range(500,720,8):
		draw_rect(Rect2(0,y,W,8),Color(0.015,0.025,0.05,0.58*pow(float(y-500)/220,1.2)))
	for i in range(14):
		var x=720+fmod(i*137.3+sin(clock*0.25+i)*15,530)
		var y=fposmod(710-i*73-clock*(12+i%4*5),H)
		draw_circle(Vector2(x,y),1.2,Color(1,0.85,0.55,0.28))
	txt(Vector2(100,94),"THE NIGHT BELONGS TO YOUR SPARK.",14,Color("a1eef0"))
	if title_logo:
		var scale=minf(540/title_logo_region.size.x,205/title_logo_region.size.y)
		var size=title_logo_region.size*scale
		draw_texture_rect_region(title_logo,Rect2(Vector2(80,121)+(Vector2(540,205)-size)/2,size),title_logo_region)
	title_txt(Vector2(100,367),"星炉のリベリオン",31,Color("f3f6ff"))
	draw_line(Vector2(383,356),Vector2(582,356),Color(0.4,1,1,0.4),1)
	draw_line(Vector2(383,361),Vector2(451,361),PINK,2)
	txt(Vector2(100,407),"その一閃で、夜を撃ち抜け。",21,Color("f5d5e5"))
	txt(Vector2(100,442),"BEST SCORE  %07d"%best_score,16,Color("ffe28a"))
	var hover=Rect2(100,462,360,64).has_point(get_global_mouse_position())
	var points=PackedVector2Array([Vector2(100,462),Vector2(442,462),Vector2(460,480),Vector2(460,526),Vector2(118,526),Vector2(100,508)])
	draw_colored_polygon(points,Color("b3fff8") if hover else Color("6af3df"))
	draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[4],points[5],points[0]]),Color(1,1,1,0.6),1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(122,483),Vector2(122,504),Vector2(138,494)]),Color("102c36"))
	title_txt(Vector2(156,503),"出撃する",27,Color("102c36"))
	txt(Vector2(333,500),confirm_label(),13,Color("102c36"))
	draw_rect(Rect2(100,542,480,44),Color(0.03,0.07,0.13,0.86))
	draw_rect(Rect2(100,542,480,44),Color(0.4,0.8,0.85,0.38),false,1)
	draw_rect(Rect2(100,542,3,44),Color("ffe28a"))
	txt(Vector2(117,570),("Y / 十字↑↓" if using_pad else "E")+"  難易度："+("アシスト" if easy else ("弾幕" if danmaku else "ノーマル")),17,Color("edf6ff"))
	txt(Vector2(390,570),"体力増 / 弾速低下" if easy else ("敵弾3倍 / 連続反射" if danmaku else "基本ルール"),13,Color("b2c7da"))
	var settings_hover=Rect2(100,596,480,40).has_point(get_global_mouse_position())
	draw_rect(Rect2(100,596,480,40),Color(0.06,0.14,0.22,0.92) if settings_hover else Color(0.03,0.07,0.13,0.86))
	draw_rect(Rect2(100,596,480,40),Color(0.4,0.8,0.85,0.38),false,1)
	txt(Vector2(117,622),("BACK" if using_pad else "O")+"  設定：キー設定・音量",17,Color("edf6ff"))
	txt(Vector2(100,662),"移動 "+move_label()+"   ジャンプ "+lbl("jump")+"   射撃 "+lbl("fire")+"   セーバー "+lbl("saber")+"   ダッシュ "+lbl("dash"),14,Color("bdcbe2"))
	txt(Vector2(100,690),"1 STAGE / 6 SECTORS + BOSS   •   "+("コントローラー操作中" if using_pad else "キーボード操作中（パッドのボタンを押すと表示が切り替わります）"),12,Color("84d9e2"))
	txt(Vector2(1112,682),"F11 全画面",13,Color("b9d4df"))

func title_txt(at: Vector2, value: String, size: int, color: Color):
	draw_string(title_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

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
	txt(Vector2(780,45),"%07d pt"%score,21,Color("ffe28a"))
	if combo>1: txt(Vector2(780,64),"連続撃破 %d  ×%.1f"%[combo,combo_multiplier()],13,Color("ffe28a"))
	var charge_text = "MAX（ジャスト）" if dodge_charge>0 else ("MAX" if charge>=FULL_CHARGE else ("READY" if charge>=0.8 else lbl("fire").get_slice(" / ",0)+" 長押し"))
	txt(Vector2(340,80),"DASH  " + ("READY" if dash_cooldown<=0 else "…") + "     CHARGE  " + charge_text + "     SABER  " + ("READY" if saber_cooldown<=0 else "…") + "     CORE  %d / 6"%core_count,14,CYAN)
	txt(Vector2(1045,50),time_text(),25)
	txt(Vector2(1045,80),"撃破 %02d"%kills+("" if using_pad else "  /  M 音"),15,Color("bdcbe2"))
	draw_rect(Rect2(24,104,1232*clampf(player.x/END_X,0,1),3),PINK)
	if banner_time>0:
		draw_rect(Rect2(290,130,730,48),Color(0.02,0.06,0.13,0.85))
		txt(Vector2(320,162),banner,22,CYAN)
	if boss_active and boss_hp>0:
		draw_rect(Rect2(370,665,540,24),Color("30233f"))
		draw_rect(Rect2(370,665,540*float(boss_hp)/boss_max_hp,24),PINK)
		txt(Vector2(470,651),"ASTER GUARDIAN",19)
	else:
		for enemy in enemies:
			if enemy.kind==6 and enemy.hp>0 and absf(enemy.p.x-player.x)<1300:
				draw_rect(Rect2(430,668,420,14),Color("30233f"))
				draw_rect(Rect2(430,668,420*enemy.hp/112.0,14),Color("ffb35a"))
				txt(Vector2(485,654),"搬送路の番人 / CARGO SENTINEL",18,Color("ffb35a"))

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
	capture_mode = true
	set_process(false)
	set_physics_process(false)
	for scene in ["title", "title-assist", "title-pad", "settings", "settings-pad", "stage", "surge", "door", "door-open", "door-locked", "movers", "miniboss", "miniboss-rush", "ice", "breakdoor", "defense", "summit", "low-gravity", "ceiling", "boss", "phase2", "bullets", "reflect", "combo", "clear"]:
		if scene in ["title","title-assist"]:
			state="title"
			easy=scene=="title-assist"
			using_pad=false
		if scene in ["title-pad","settings","settings-pad"]:
			state="title"
			easy=false
			using_pad=scene!="settings"
			if scene!="title-pad":
				open_settings()
				settings_index=5
				if scene=="settings-pad": rebinding="fire"
		if scene == "stage":
			using_pad=false
			rebinding=""
			easy=false
			start_game()
			player = Vector2(1500,610)
			camera_x = 1100
			grounded = true
			banner_time = 0
		if scene in ["surge","door","breakdoor"]:
			var spot = {"surge":[5,300,7.4],"door":[7,560,0.0],"breakdoor":[15,560,0.0]}[scene]
			player = Vector2(spot[0]*ROOM+spot[1],610)
			camera_x = player.x-390
			elapsed = spot[2]
			charge = 0
		if scene in ["door-open","door-locked"]:
			var door=gate_of(7)
			var locked=scene=="door-locked"
			door.open=not locked
			door.passed=locked
			door.entered=locked
			door.lift=0 if locked else 1
			for s in door.switches: s.on=true
			player=Vector2(door.x+(90 if locked else -65),610)
			camera_x=door.x-500
			banner_time=0
		if scene in ["movers","ice","defense","summit"]:
			if scene=="ice":
				for e in enemies:
					if e.kind==6: e.hp=0
			var room = {"movers":8,"ice":12,"defense":16,"summit":23}[scene]
			elapsed = 1.5 if scene=="movers" else 0.0
			player = Vector2(room*ROOM+180,610)
			camera_x = room*ROOM
			if scene=="defense": charge = 1.1
			else: charge = 0
		if scene in ["miniboss","miniboss-rush"]:
			var base=11*ROOM
			for core in cores:
				if core.room<=11: core.got=true;core.sync=0
			core_count=3
			score=1500
			if scene=="miniboss": spawn_enemy(Vector2(base+820,600),6,11)
			for e in enemies:
				if e.kind!=6: continue
				e.mode="tell" if scene=="miniboss" else "rush"
				e.mt=0.6
				e.cycle=0 if scene=="miniboss" else 1
				e.dir=-1.0
			player=Vector2(base+500,610)
			camera_x=base+100
			elapsed=1.5
			banner_time=0
		if scene in ["low-gravity","ceiling"]:
			player=Vector2(21*ROOM+500,310 if scene=="low-gravity" else 244)
			camera_x=player.x-390
			elapsed=3.6 if scene=="low-gravity" else 4.6
			grounded=false
			banner_time=0
			velocity=Vector2(220,100)
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
		if scene=="bullets":
			# One of each shot type for a visual check.
			bullets.clear()
			boss_rays.clear()
			enemy_shot(player+Vector2(160,-40),Vector2.LEFT,17,"solid")
			enemy_shot(player+Vector2(260,-120),Vector2.LEFT,11,"home")
			enemy_shot(player+Vector2(360,-60),Vector2.LEFT,10)
			enemy_shot(player+Vector2(460,-200),Vector2.DOWN,13,"bomb")
			shoot(true,true)
			charge = FULL_CHARGE
			popup(player-Vector2(0,110),"JUST!",Color("ffe28a"))
		if scene == "clear":
			boss_hp = 0
			boss_active=false
			player=Vector2(BOSS_X+350,610)
			camera_x=END_X-W
			velocity=Vector2.ZERO
			charge=0
			popups.clear()
			state = "clear"
			elapsed=565
			score=23600
			max_combo=8
			damage_taken=4
			deaths=0
			core_count=6
			kills=62
			reward_clear()
		if scene=="reflect":
			bullets.clear()
			boss_rays.clear()
			player=Vector2(BOSS_X+350,610)
			grounded=true
			boss_intro=0
			boss_hp=240
			parry_marks.append({"p":player+Vector2(90,-65),"age":0.08})
			bullets.append({"p":player+Vector2(150,-65),"v":Vector2(900,0),"enemy":false,"reflected":true,"damage":4,"r":9.0,"life":1.0})
			popup(player+Vector2(15,-110),"反射ダメージ ×2",Color("ffe28a"))
		if scene=="combo":
			boss_active=false
			popups.clear()
			player=Vector2(15*ROOM+400,610)
			camera_x=player.x-390
			grounded=true
			velocity=Vector2.ZERO
			score=15850
			combo=6
			max_combo=8
			combo_timer=2.5
			parry_marks.clear()
			bullets.clear()
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
	for i in range(parry_marks.size()-1,-1,-1):
		parry_marks[i].age+=dt
		if parry_marks[i].age>=0.28: parry_marks.remove_at(i)
	for i in range(fx.size()-1,-1,-1):
		fx[i].age += dt
		if fx[i].age>=0.5: fx.remove_at(i)

# One pose descriptor drives drawing, cannon socket, and muzzle flash.
func motion_test():
	set_process(false)
	set_physics_process(false)
	start_game()
	var errors = []
	if rig_textures.size()!=7 or motions.saber.size()!=6 or motions.air_saber.size()!=6: errors.append("rig and saber assets")
	velocity=Vector2(285,0)
	if walk_lean()<deg_to_rad(8): errors.append("moving torso lean")
	var gun0=walk_arm(0,true)
	var gun4=walk_arm(4,true)
	var free0=walk_arm(0,false)
	var free4=walk_arm(4,false)
	if absf(gun0.angle-gun4.angle)<0.8 or absf(free0.angle-free4.angle)<0.8: errors.append("arm swing")
	if (gun0.angle-gun4.angle)*(free0.angle-free4.angle)>=0: errors.append("opposed arms")
	test_key(KEY_X,true)
	for phase in range(8):
		var gun=walk_arm(phase,true)
		if Vector2.DOWN.rotated(gun.angle).distance_to(Vector2.RIGHT)>0.01: errors.append("cannon horizontal while firing")
	test_key(KEY_X,false)
	if gait_foot(0).x<=0 or gait_foot(4).x>=0: errors.append("same leg always in front")
	for direction in [-1,1]:
		for frame in range(5):
			if absf(frame*13*direction+gait_foot(frame).x*direction-26*direction)>0.01: errors.append("stance sliding")
	for frame in range(32):
		var phase = frame/4.0
		for side in ["near","far"]:
			var leg = gait_leg(phase,side)
			if absf(walk_hip(phase).distance_to(leg.knee)-24)>0.1 or absf(leg.knee.distance_to(leg.ankle)-29)>0.1: errors.append("leg length drift")
			if absf(boot_floor(side,leg.knee,leg.ankle,leg.pitch)-leg.sole)>0.1: errors.append("foot below floor")
	for calibrated in motion_meta.legacy_pose.values():
		if absf(calibrated.head_metric*calibrated.scale-motion_meta.reference_head_metric)>0.1: errors.append("pose skull scale")
	player = Vector2(180,610)
	grounded = true
	velocity = Vector2(285,0)
	for direction in [-1,1]:
		facing = direction
		for frame in range(8):
			walk_phase = frame
			bullets.clear()
			shoot(false)
			if bullets.is_empty() or bullets[-1].p.distance_to(muzzle_position())>0.01: errors.append("muzzle socket")
			if (muzzle_position().x-player.x)*direction<20: errors.append("muzzle facing")
	test_key(KEY_RIGHT,true)
	test_key(KEY_V,true)
	for i in range(20): update_game(1.0/60)
	if absf(velocity.x-156.75)>1 or hero_visual().name!="walk": errors.append("slow charge walk")
	test_key(KEY_RIGHT,false)
	test_key(KEY_V,false)
	update_game(1.0/60)
	test_key(KEY_K,true)
	update_game(1.0/60)
	if saber_time<=0 or saber_active(): errors.append("saber input startup")
	test_key(KEY_K,false)
	bullets.clear()
	for direction in [-1,1]:
		facing=direction
		saber_facing=direction
		saber_time=0.25
		var front=player+Vector2(direction*70,-60)
		var back=player+Vector2(-direction*70,-60)
		bullets.append({"p":front,"v":Vector2.ZERO,"enemy":true,"damage":2,"r":5.0,"life":2.0})
		bullets.append({"p":back,"v":Vector2.ZERO,"enemy":true,"damage":2,"r":5.0,"life":2.0})
		update_bullets(0)
		var hostile = bullets.filter(func(b): return b.enemy)
		if hostile.size()!=1 or hostile[0].p!=back: errors.append("directional parry")
		if bullets.size()!=2 or bullets[0].enemy or bullets[0].v.x*direction<=0: errors.append("just parry reflect")
		bullets.clear()
	saber_time=0.06
	if saber_active(): errors.append("saber recovery")
	saber_time=0.21
	facing=1
	saber_facing=1
	enemies.clear()
	spawn_enemy(player+Vector2(80,0),0,0)
	enemies[0].hp=20
	saber_hits.clear()
	update_saber()
	update_saber()
	if enemies[0].hp!=14: errors.append("one hit per swing")
	start_game()
	player=Vector2(180,610)
	grounded=true
	invincible=999
	test_key(KEY_SPACE,true)
	test_key(KEY_K,true)
	update_game(1.0/60)
	test_key(KEY_SPACE,false)
	test_key(KEY_K,false)
	if grounded or not saber_air or hero_visual().name!="air_saber": errors.append("jump and air saber input")
	saber_time=0.21
	saber_facing=1
	bullets.clear()
	bullets.append({"p":player+Vector2(70,-60),"v":Vector2.ZERO,"enemy":true,"damage":2,"r":5.0,"life":2.0})
	update_bullets(0)
	if not bullets.filter(func(b): return b.enemy).is_empty(): errors.append("air saber parry")
	grounded=true
	if hero_visual().name!="air_saber": errors.append("air swing landing continuity")
	# Saber cooldown, solid shots, late parry, just dodge, tap fire and full charge.
	saber_time=0
	saber_cooldown=0.5
	prev_saber=false
	hurt_pose=0
	test_key(KEY_K,true)
	update_game(1.0/60)
	test_key(KEY_K,false)
	update_game(1.0/60)
	if saber_time>0: errors.append("saber cooldown blocks")
	saber_cooldown=0
	saber_time=0.21
	saber_facing=1
	facing=1
	bullets.clear()
	enemy_shot(player+Vector2(70,-60),Vector2.ZERO,10,"solid")
	update_bullets(0)
	if bullets.size()!=1: errors.append("solid ignores saber")
	bullets.clear()
	saber_time=0.15
	enemy_shot(player+Vector2(70,-60),Vector2.ZERO)
	update_bullets(0)
	if not bullets.is_empty(): errors.append("late parry cancels only")
	saber_time=0
	dash_timer=0.1
	saber_cooldown=0.5
	enemy_shot(player+Vector2(0,-40),Vector2.ZERO)
	update_bullets(0)
	if saber_cooldown>0 or hp<=0: errors.append("just dodge readies saber")
	dash_timer=0
	bullets.clear()
	start_game()
	player=Vector2(180,610)
	grounded=true
	invincible=999
	for tap in range(3):
		test_key(KEY_X,true)
		update_game(1.0/60)
		test_key(KEY_X,false)
		for f in range(9): update_game(1.0/60)
	if bullets.filter(func(b): return not b.enemy).size()!=3: errors.append("tap fire")
	bullets.clear()
	test_key(KEY_X,true)
	for f in range(int(FULL_CHARGE*60)+3): update_game(1.0/60)
	test_key(KEY_X,false)
	update_game(1.0/60)
	if bullets.is_empty() or not bullets[-1].get("pierce",false): errors.append("full charge pierce")
	# A charge survives a saber swing and fires as soon as the swing ends.
	bullets.clear()
	saber_cooldown=0
	prev_saber=false
	test_key(KEY_X,true)
	for f in range(55): update_game(1.0/60)
	test_key(KEY_K,true)
	update_game(1.0/60)
	test_key(KEY_K,false)
	for f in range(8): update_game(1.0/60)
	if saber_time<=0 or charge<0.8: errors.append("charge during saber")
	test_key(KEY_X,false)
	update_game(1.0/60)
	if not bullets.filter(func(b): return not b.enemy).is_empty(): errors.append("no shot mid-swing")
	for f in range(30): update_game(1.0/60)
	if bullets.filter(func(b): return not b.enemy and b.damage>=7).is_empty(): errors.append("charge fires after swing")
	# A just reflection curves toward an enemy that is not straight ahead.
	bullets.clear()
	enemies.clear()
	spawn_enemy(player+Vector2(320,-230),1,0)
	saber_time=0.26
	saber_facing=1
	enemy_shot(player+Vector2(70,-60),Vector2.ZERO)
	update_bullets(0)
	saber_time=0
	for f in range(10): update_bullets(1.0/60)
	if bullets.is_empty() or bullets[0].v.y>-100: errors.append("reflection homes")
	bullets.clear()
	enemies.clear()
	# Rebinding moves a key to the new action and takes it from the old one.
	bind_key("jump",KEY_X)
	if KEY_X in key_binds.fire or key_binds.jump!=[KEY_X]: errors.append("rebind key")
	reset_bindings()
	# The final boss keeps attacking while Lumina hugs the arena's left wall.
	start_game()
	invincible=999
	player=Vector2(BOSS_X+200,610)
	update_game(1.0/60)
	player=Vector2(BOSS_X+35,610)
	for f in range(360):
		invincible=999
		player.x=BOSS_X+35
		update_game(1.0/60)
	if boss_cycle<1: errors.append("boss acts at left wall")
	if absf(camera_x-(END_X-W))>2: errors.append("boss arena camera")
	# A just dodge loads a full charge into the next tap.
	start_game()
	player=Vector2(180,610)
	grounded=true
	invincible=999
	dash_timer=0.1
	saber_cooldown=0.5
	enemy_shot(player+Vector2(0,-40),Vector2.LEFT)
	update_bullets(0)
	dash_timer=0
	bullets.clear()
	if dodge_charge<=0 or saber_cooldown>0 or dash_cooldown>0: errors.append("just dodge reward")
	prev_fire=false
	test_key(KEY_X,true)
	update_game(1.0/60)
	test_key(KEY_X,false)
	update_game(1.0/60)
	if bullets.filter(func(b): return not b.enemy and b.get("pierce",false)).is_empty(): errors.append("dodge charge shot")
	# Danmaku: triple fire, a fast saber that swings during a dash, weaker reflections.
	bullets.clear()
	danmaku=true
	enemy_shot(Vector2(600,400),Vector2.LEFT*200)
	if bullets.size()!=3: errors.append("danmaku triples fire")
	bullets.clear()
	saber_cooldown=0
	saber_time=0
	prev_saber=false
	dash_timer=0.1
	test_key(KEY_K,true)
	update_game(1.0/60)
	test_key(KEY_K,false)
	if saber_time<=0 or saber_cooldown>DANMAKU_SABER_COOLDOWN: errors.append("danmaku saber during dash")
	saber_time=0.21
	saber_facing=1
	enemy_shot(player+Vector2(70,-60),Vector2.ZERO)
	update_bullets(0)
	if bullets.is_empty() or bullets[0].enemy or bullets[0].damage!=1: errors.append("danmaku reflection")
	danmaku=false
	bullets.clear()
	# The sentinel keeps fighting even when Lumina stays at the room's left edge.
	start_game()
	invincible=999
	var mini_base=11*ROOM
	spawn_enemy(Vector2(mini_base+990,600),6,11)
	var sentinel=enemies[-1]
	player=Vector2(mini_base+30,610)
	camera_x=mini_base-390
	for f in range(360):
		invincible=999
		player.x=mini_base+30
		update_game(1.0/60)
	if sentinel.cycle<1 and sentinel.mode=="intro": errors.append("sentinel acts at left edge")
	if sentinel.p.x>camera_x+W-60: errors.append("sentinel stays on screen")
	print("MOTION TEST: ","PASS" if errors.is_empty() else "FAIL"," ",errors)
	get_tree().quit(0 if errors.is_empty() else 1)

func capture_motion():
	capture_mode = true
	set_process(false)
	set_physics_process(false)
	start_game()
	player=Vector2(480,610)
	camera_x=0
	grounded=true
	banner_time=0
	for action in ["walk","shoot","shootleft","charge","saber","left","air","airleft"]:
		for frame in range(8 if action in ["walk","shoot","shootleft","charge"] else 6):
			facing=-1 if action in ["left","shootleft","airleft"] else 1
			saber_facing=facing
			grounded=action not in ["air","airleft"]
			player.y=610 if grounded else 510
			saber_air=not grounded
			aim_time=0
			muzzle_time=0
			velocity=Vector2(156.75 if action=="charge" else 285,0)
			walk_phase=frame
			charge=1.0 if action=="charge" else 0.0
			saber_time=0.42-frame*0.07-0.001 if action in ["saber","left","air","airleft"] else 0.0
			bullets.clear()
			if action in ["shoot","shootleft","charge"]:
				shoot(action=="charge")
			queue_redraw()
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://test-output/motion-"+action+str(frame)+".png")
	for pose in ["idle","walk","jump","dash","hurt","charge","saber"]:
		player.y=610
		saber_air=false
		aim_time=0
		velocity=Vector2(285 if pose=="walk" else 0,0)
		grounded=pose!="jump"
		dash_timer=0.15 if pose=="dash" else 0.0
		hurt_pose=0.2 if pose=="hurt" else 0.0
		charge=1.0 if pose=="charge" else 0.0
		saber_time=0.21 if pose=="saber" else 0.0
		facing=1
		muzzle_time=0
		walk_phase=0
		bullets.clear()
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-output/size-"+pose+".png")
	grounded=true
	dash_timer=0
	hurt_pose=0
	charge=0
	saber_time=0
	saber_air=false
	muzzle_time=0
	velocity=Vector2(285,0)
	for mode in ["stride","aimstride"]:
		aim_time=0.25 if mode=="aimstride" else 0.0
		for frame in range(32):
			walk_phase=frame/4.0
			queue_redraw()
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://test-output/"+mode+"-"+str(frame)+".png")
	print("MOTION CAPTURE: PASS 56 motion + 7 size + 64 interpolated frames")
	get_tree().quit()

func hero_visual() -> Dictionary:
	var name = ""
	var index = 0
	if hurt_pose<=0 and saber_time>0:
		name = "air_saber" if saber_air else "saber"
		index = mini(5,int((0.42-saber_time)/0.07))
	elif hurt_pose<=0 and dash_timer<=0 and grounded and absf(velocity.x)>15:
		return {"name":"walk","frame":int(walk_phase)%8}
	if name!="":
		var meta = motion_meta[name].frames[index]
		return {"texture":motions[name][index],"region":Rect2(0,0,256,256),"anchor":Vector2(meta.anchor[0],meta.anchor[1]),"muzzle":Vector2(meta.muzzle[0],meta.muzzle[1]),"scale":motion_meta[name].scale,"frame":index,"name":name}
	var tex = atlas
	var region = regions[0]
	var pose = "idle"
	if hurt_pose>0: pose="hurt"; tex=art.poses.texture; region=art.poses.regions[1]
	elif dash_timer>0: pose="dash"; tex=art.poses.texture; region=art.poses.regions[0]
	elif not grounded: pose="jump"; region=regions[3]
	elif charge>0.3: pose="charge"; tex=art.poses.texture; region=art.poses.regions[2]
	var socket = motion_meta.legacy[pose]
	var calibrated = motion_meta.legacy_pose[pose]
	return {"texture":tex,"region":region,"anchor":Vector2(calibrated.anchor[0],calibrated.anchor[1]),"muzzle":Vector2(socket[0],socket[1])-region.position,"scale":calibrated.scale,"name":pose,"frame":0}

func muzzle_position() -> Vector2:
	var visual = hero_visual()
	if visual.name=="walk":
		var gun = walk_arm(walk_phase,true)
		return player+Vector2(gun.muzzle.x*facing,gun.muzzle.y)
	var point = (visual.muzzle-visual.anchor)*visual.scale
	return player+Vector2(point.x*facing,point.y)

func draw_hero(at: Vector2, tint = Color.WHITE):
	var visual = hero_visual()
	if visual.name=="walk":
		draw_walk_rig(at,walk_phase)
		return
	draw_set_transform(at,0,Vector2(facing,1))
	draw_texture_rect_region(visual.texture,Rect2(-visual.anchor*visual.scale,visual.region.size*visual.scale),visual.region,tint)
	draw_set_transform(Vector2.ZERO)

# Feet stay fixed in world space during stance; the other leg swings forward.
# The same near/far artwork keeps its identity for the entire two-step cycle.
func gait_foot(phase: float) -> Vector2:
	# Swing kicks the heel up behind and stays low in front, instead of a high knee march.
	var keys = [Vector2(26,-10),Vector2(13,-10),Vector2(0,-10),Vector2(-13,-10),Vector2(-26,-10),Vector2(-30,-22),Vector2(-6,-22),Vector2(18,-15)]
	var index = int(floor(phase))%8
	return keys[index].lerp(keys[(index+1)%8],fposmod(phase,1.0))

func walk_hip(phase: float) -> Vector2:
	# Hips sink at mid-stance and rise toward each contact for a weighted stride.
	return Vector2(0,-51-cos(phase*PI/2)*1.5)

func gait_knee(hip: Vector2, ankle: Vector2) -> Vector2:
	var delta = ankle-hip
	var distance = clampf(delta.length(),1.0,52.99)
	var direction = delta.normalized()
	var along = (24.0*24.0-29.0*29.0+distance*distance)/(2*distance)
	var bend = sqrt(maxf(0,24.0*24.0-along*along))
	return hip+direction*along+Vector2(direction.y,-direction.x)*bend

func draw_rig_bone(name: String, start: Vector2, end: Vector2, at: Vector2):
	var part = motion_meta.rig[name]
	var origin = Vector2(part.origin[0],part.origin[1])
	var tip = Vector2(part.end[0],part.end[1])
	var scale = (end-start).length()/origin.distance_to(tip)
	var angle = (end-start).angle()-(tip-origin).angle()
	var texture = rig_textures[name]
	var height = float(part.foot_cut+45) if name.ends_with("boot") else float(texture.get_height())
	var a = -origin*scale
	var b = (Vector2(texture.get_width(),0)-origin)*scale
	var c = (Vector2(texture.get_width(),height)-origin)*scale
	var d = (Vector2(0,height)-origin)*scale
	var points = PackedVector2Array()
	for point in [a,b,c,d]:
		var along = (tip-origin).normalized()
		var across = Vector2(along.y,-along.x)
		var widened = along*point.dot(along)+across*point.dot(across)*(1.25 if name.ends_with("thigh") else 1.0)
		var position = start+widened.rotated(angle)
		points.append(at+Vector2(position.x*facing,position.y))
	var bottom_uv = height/texture.get_height()
	draw_polygon(points,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2(1,bottom_uv),Vector2(0,bottom_uv)]),texture)

func draw_walk_rig(at: Vector2, phase: float):
	var hip = walk_hip(phase)
	# The left cannon arm is behind both legs and the torso.
	draw_walk_arm(at,phase,true)
	for side in ["far","near"]:
		var leg = gait_leg(phase,side)
		var ankle = leg.ankle
		var knee = leg.knee
		draw_rig_bone(side+"_thigh",hip,knee,at)
		draw_rig_bone(side+"_boot",knee,ankle,at)
		draw_rig_foot(side,ankle,leg.pitch,at)
	var body = motion_meta.rig.body
	draw_rig_piece("body",hip,walk_lean(),body.scale,at)
	draw_walk_arm(at,phase,false)
	draw_set_transform(Vector2.ZERO)

func walk_lean() -> float:
	return deg_to_rad(20)*clampf(absf(velocity.x)/180.0,0,1)

func walk_aiming() -> bool:
	return aim_time>0 or charge>0 or act("fire")

func walk_arm(phase: float, gun: bool) -> Dictionary:
	var body = motion_meta.rig.body
	var body_origin = Vector2(body.origin[0],body.origin[1])
	var shoulder = body.gun_shoulder if gun else body.free_shoulder
	var root = walk_hip(phase)+((Vector2(shoulder[0],shoulder[1])-body_origin)*body.scale).rotated(walk_lean())
	var name = "gun_arm" if gun else "free_arm"
	var part = motion_meta.rig[name]
	var origin = Vector2(part.origin[0],part.origin[1])
	var tip = Vector2(part.end[0],part.end[1])
	# Positive swings the arm back; a running swing reaches further forward than back.
	var swing = cos(phase*TAU/8)*(-1.0 if gun else 1.0)
	var angle = walk_lean()+(swing*0.6 if swing>0 else swing*1.1)
	# The elbow folds the forearm up, most when the arm drives forward. The heavy cannon folds less.
	var bend = (1.25+0.7*clampf(-swing,0,1)-0.15*clampf(swing,0,1))*(0.6 if gun else 1.0)
	if gun and walk_aiming():
		angle = part.aim_angle
		bend = 0.0
	var elbow_tex = Vector2(ARM_ELBOW[name][0],ARM_ELBOW[name][1])
	var elbow = root+((elbow_tex-origin)*part.scale).rotated(angle)
	var socket = elbow+((tip-elbow_tex)*part.scale).rotated(angle-bend)
	return {"root":root,"angle":angle,"bend":bend,"elbow":elbow,"muzzle":socket,"name":name,"scale":part.scale}

func draw_walk_arm(at: Vector2, phase: float, gun: bool):
	var arm = walk_arm(phase,gun)
	var texture = rig_textures[arm.name]
	var part = motion_meta.rig[arm.name]
	var origin = Vector2(part.origin[0],part.origin[1])
	var elbow_tex = Vector2(ARM_ELBOW[arm.name][0],ARM_ELBOW[arm.name][1])
	# Forearm first, upper arm on top; the slices overlap so the elbow has no gap.
	draw_rig_slice(texture,elbow_tex,arm.elbow,arm.angle-arm.bend,arm.scale,elbow_tex.y-ARM_OVERLAP,texture.get_height(),at)
	draw_rig_slice(texture,origin,arm.root,arm.angle,arm.scale,0,elbow_tex.y+ARM_OVERLAP,at)

func draw_rig_slice(texture: Texture2D, pivot: Vector2, root: Vector2, angle: float, scale: float, top: float, bottom: float, at: Vector2):
	var w = float(texture.get_width())
	var h = float(texture.get_height())
	var points = PackedVector2Array()
	for p in [Vector2(0,top),Vector2(w,top),Vector2(w,bottom),Vector2(0,bottom)]:
		var position = root+((p-pivot)*scale).rotated(angle)
		points.append(at+Vector2(position.x*facing,position.y))
	draw_polygon(points,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0,top/h),Vector2(1,top/h),Vector2(1,bottom/h),Vector2(0,bottom/h)]),texture)

func draw_rig_piece(name: String, root: Vector2, angle: float, scale: float, at: Vector2):
	var texture = rig_textures[name]
	var part = motion_meta.rig[name]
	var origin = Vector2(part.origin[0],part.origin[1])
	var points = PackedVector2Array()
	for p in [Vector2.ZERO,Vector2(texture.get_width(),0),texture.get_size(),Vector2(0,texture.get_height())]:
		var position = root+((p-origin)*scale).rotated(angle)
		points.append(at+Vector2(position.x*facing,position.y))
	draw_polygon(points,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]),texture)

func boot_floor(side: String, knee: Vector2, ankle: Vector2, pitch = 0.0) -> float:
	var part = motion_meta.rig[side+"_boot"]
	var origin = Vector2(part.origin[0],part.origin[1])
	var tip = Vector2(part.end[0],part.end[1])
	var scale = knee.distance_to(ankle)/origin.distance_to(tip)
	var bottom = -1000.0
	for p in part.outline:
		bottom = maxf(bottom,ankle.y+((Vector2(p[0],p[1])-tip)*scale).rotated(pitch).y)
	return bottom

func gait_leg(phase: float, side: String) -> Dictionary:
	var hip = walk_hip(phase)
	var foot = gait_foot(fposmod(phase+(4 if side=="far" else 0),8.0))
	var ankle = foot
	var sole = foot.y+10
	var local_phase = fposmod(phase+(4 if side=="far" else 0),8.0)
	var pitches = [-0.12,0.0,0.0,0.18,0.35,0.45,0.15,-0.1]
	var index = int(local_phase)%8
	var pitch = lerpf(pitches[index],pitches[(index+1)%8],fposmod(local_phase,1.0))
	var part = motion_meta.rig[side+"_boot"]
	var origin = Vector2(part.origin[0],part.origin[1])
	var tip = Vector2(part.end[0],part.end[1])
	var scale = 29.0/origin.distance_to(tip)
	var extent = -1000.0
	for p in part.outline: extent=maxf(extent,((Vector2(p[0],p[1])-tip)*scale).rotated(pitch).y)
	ankle.y=sole-extent
	var knee = gait_knee(hip,ankle)
	return {"knee":knee,"ankle":ankle,"sole":sole,"pitch":pitch}

func draw_rig_foot(side: String, ankle: Vector2, pitch: float, at: Vector2):
	var name = side+"_boot"
	var texture = rig_textures[name]
	var part = motion_meta.rig[name]
	var origin = Vector2(part.origin[0],part.origin[1])
	var tip = Vector2(part.end[0],part.end[1])
	var scale = 29.0/origin.distance_to(tip)
	var points = PackedVector2Array()
	for p in [Vector2(0,part.foot_cut),Vector2(texture.get_width(),part.foot_cut),texture.get_size(),Vector2(0,texture.get_height())]:
		var position = ankle+((p-tip)*scale).rotated(pitch)
		points.append(at+Vector2(position.x*facing,position.y))
	var top_uv = float(part.foot_cut)/texture.get_height()
	draw_polygon(points,PackedColorArray([Color.WHITE]),PackedVector2Array([Vector2(0,top_uv),Vector2(1,top_uv),Vector2.ONE,Vector2(0,1)]),texture)

func enemy_rect(enemy: Dictionary) -> Rect2:
	if enemy.kind==6: return Rect2(enemy.p-Vector2(63,132),Vector2(126,142))
	return Rect2(enemy.p-Vector2(35,72),Vector2(70,82))

func saber_active() -> bool:
	return state=="play" and saber_time>0.07 and saber_time<=0.28 and hurt_pose<=0

func saber_rect() -> Rect2:
	return Rect2(player+Vector2(0 if saber_facing>0 else -100,-112),Vector2(100,122))

func update_saber():
	if not saber_active(): return
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy.hp<=0 or i in saber_hits or door_between(player.x,enemy.p.x) or not saber_rect().intersects(enemy_rect(enemy)): continue
		saber_hits.append(i)
		if enemy.get("shield",false):
			burst(enemy.p,CYAN,5)
			continue
		enemy.hp -= 6
		enemy.flash = 0.15
		burst(enemy.p,CYAN,12)
		hitstop = 0.045
		if enemy.hp<=0:
			register_enemy_defeat(enemy)
	if boss_active and boss_hp>0 and boss_intro<=0 and not saber_boss_hit and saber_rect().intersects(Rect2(boss_pos-Vector2(70,160),Vector2(140,180))):
		saber_boss_hit = true
		boss_hp -= 8
		boss_flash = 0.15
		hitstop = 0.045
		if boss_hp<=0:
			state="defeat"
			ending_time=0
			boss_rays.clear()
			music.stop()
			shake=15

func combo_multiplier() -> float:
	return 1.0+minf(10,maxi(0,combo-1))*0.1

func register_enemy_defeat(enemy: Dictionary):
	if enemy.get("scored",false): return
	enemy.scored=true
	kills+=1
	combo=combo+1 if combo_timer>0 else 1
	max_combo=maxi(max_combo,combo)
	combo_timer=3.0
	var points=int([100,150,200,200,150,200,2000][enemy.kind]*combo_multiplier())
	score+=points
	popup(enemy.p-Vector2(0,80),"+%d"%points,Color("ffe28a"))
	hitstop=0.07 if enemy.kind==6 else 0.045
	fx.append({"p":enemy.p-Vector2(0,40),"age":0.0,"size":170.0 if enemy.kind==6 else 100.0})
	burst(enemy.p,Color("ffc578"),30 if enemy.kind==6 else 18)
	if kills%4==0 or enemy.kind==6:
		var drop=enemy.p-Vector2(0,25)
		var floor_y=610.0
		for platform in platforms:
			if drop.x>=platform.position.x and drop.x<=platform.end.x and platform.position.y>=drop.y: floor_y=minf(floor_y,platform.position.y)
		pickups.append(Vector2(drop.x,floor_y-30))
	if enemy.kind==6:
		banner="搬送路の番人を撃破！ 出口へ進もう"
		banner_time=3
		sound("win")

# Reflected shots curve toward the nearest visible enemy (or the boss) so a good parry pays off.
func reflection_target(from: Vector2) -> Vector2:
	var best = Vector2.INF
	var best_d = INF
	for e in enemies:
		if e.hp<=0 or e.p.x<camera_x or e.p.x>camera_x+W or door_between(from.x,e.p.x): continue
		var aim = enemy_rect(e).get_center()
		var d = from.distance_to(aim)
		if d<best_d:
			best_d = d
			best = aim
	if boss_active and boss_hp>0 and boss_intro<=0:
		var core = boss_pos-Vector2(0,70)
		if from.distance_to(core)<best_d: best = core
	return best

func steer_reflection(b: Dictionary, dt: float):
	var target = reflection_target(b.p)
	if target==Vector2.INF: return
	var speed = b.v.length()
	b.v = b.v.lerp((target-b.p).normalized()*speed,minf(1,dt*9)).normalized()*speed

func cycle_difficulty(step: int):
	var mode = (1 if easy else (2 if danmaku else 0))
	mode = (mode+step+3)%3
	easy = mode==1
	danmaku = mode==2

# Dodging through fire pays back: saber and dash ready, the next shot fully charged, and a brief slow-down.
func just_dodge_reward():
	saber_cooldown = 0
	dash_cooldown = 0
	dodge_charge = 3.0
	score += 60
	just_dodges += 1
	if slow_cool<=0:
		slow_time = 0.35
		slow_cool = 1.5
	popup(player-Vector2(0,95),"JUST DODGE  次弾MAX",CYAN)

func reflection_reward(at: Vector2):
	score+=150
	parry_marks.append({"p":at,"age":0.0})
	popup(at-Vector2(30,40),"反射ダメージ ×2",Color("ffe28a"))
	shake=maxf(shake,4)
	hitstop=maxf(hitstop,0.065)

func clear_rank() -> String:
	if deaths==0 and damage_taken<=6 and elapsed<=600 and max_combo>=3: return "S"
	if deaths<=1 and damage_taken<=18 and elapsed<=780 and max_combo>=2: return "A"
	if deaths<=3 and damage_taken<=40 and elapsed<=960: return "B"
	return "C"

func reward_clear():
	if clear_rewarded: return
	clear_rewarded=true
	score+=2000
	if damage_taken==0: score+=1500
	if score>best_score:
		best_score=score
		if not fixed_seed and not capture_mode:
			var records=ConfigFile.new()
			records.load(record_path)
			records.set_value("records","score",best_score)
			records.set_value("records","rank",clear_rank())
			records.save(record_path)

# Boss fights hold the camera on the whole arena so the fighter never leaves the screen.
func camera_goal() -> float:
	if boss_active and boss_hp>0: return END_X-W
	var room = int(player.x/ROOM)
	for enemy in enemies:
		if enemy.kind==6 and enemy.hp>0 and enemy.room==room: return room*ROOM-80
	return player.x-390

func update_miniboss(enemy: Dictionary, dt: float):
	if door_between(enemy.p.x,player.x): return
	enemy.fire_pose=maxf(0,enemy.get("fire_pose",0.0)-dt)
	var base=enemy.room*ROOM
	# While the camera is still sliding over, walk back into view instead of freezing.
	if enemy.p.x<camera_x+60 or enemy.p.x>camera_x+W-60:
		enemy.p.x=clampf(move_toward(enemy.p.x,clampf(enemy.p.x,camera_x+120,camera_x+W-120),220*dt),base+310,base+990)
		if enemy.mode=="rush": enemy.mode="recover"; enemy.mt=0.5
		return
	enemy.mt-=dt
	match enemy.mode:
		"intro":
			if enemy.mt<=0: enemy.mode="tell"; enemy.mt=0.8
		"tell":
			enemy.dir=1.0 if player.x>enemy.p.x else -1.0
			if enemy.mt<=0:
				if enemy.cycle==1:
					enemy.mode="rush"; enemy.mt=0.75
				else:
					if enemy.cycle==0:
						var from=enemy.p-Vector2(0,80)
						var aim=(player-Vector2(0,45)-from).normalized()
						for angle in [-0.23,0.0,0.23]: enemy_shot(from,aim.rotated(angle)*(210 if easy else 260),10)
					else:
						for direction in [-1,1]: enemy_shot(Vector2(enemy.p.x+direction*35,596),Vector2(direction*(210 if easy else 270),0),11,"solid")
					enemy.fire_pose=0.22
					enemy.mode="recover"; enemy.mt=0.9
					sound("shot")
		"rush":
			enemy.p.x=clampf(enemy.p.x+enemy.dir*(300 if easy else 390)*dt,base+310,base+990)
			if enemy.mt<=0: enemy.mode="recover"; enemy.mt=0.9
		"recover":
			if enemy.mt<=0:
				enemy.cycle=(enemy.cycle+1)%3
				enemy.mode="tell"; enemy.mt=0.8
	if (player-Vector2(0,40)).distance_to(enemy.p-Vector2(0,50))<80: hurt(1 if easy else 2)

func env_sprite(name: String, frame: int, target: Rect2, flip=false, tint=Color.WHITE, coverage=Vector2.ONE):
	if not environment_art.has(name): return
	var entry=environment_art[name]
	var region=entry.regions[frame]
	region.size*=coverage
	draw_set_transform(target.position+Vector2(target.size.x if flip else 0,0),0,Vector2(-1 if flip else 1,1))
	draw_texture_rect_region(entry.texture,Rect2(Vector2.ZERO,target.size),region,tint)
	draw_set_transform(Vector2.ZERO)

func env_strip(name: String, frame: int, target: Rect2, tile_width: float):
	var x=0.0
	while x<target.size.x:
		var width=minf(tile_width,target.size.x-x)
		env_sprite(name,frame,Rect2(target.position+Vector2(x,0),Vector2(width,target.size.y)),false,Color.WHITE,Vector2(width/tile_width,1))
		x+=width

func draw_miniboss(enemy: Dictionary, offset: Vector2):
	if not environment_art.has("miniboss"): return
	var entry=environment_art.miniboss
	var frame=2 if enemy.mode=="rush" or enemy.get("fire_pose",0.0)>0 else (1 if enemy.mode=="tell" else 0)
	var region=entry.regions[frame]
	var anchor=Vector2(entry.anchors[frame][0],entry.anchors[frame][1])
	var flip=enemy.dir>0
	var feet=enemy.p+offset+Vector2(0,10)
	var tint=Color(2,2,2) if enemy.flash>0 else Color.WHITE
	draw_set_transform(feet,0,Vector2(-1 if flip else 1,1))
	draw_texture_rect_region(entry.texture,Rect2(-anchor*entry.scale,region.size*entry.scale),region,tint)
	draw_set_transform(Vector2.ZERO)
	if enemy.mode=="tell":
		var center=enemy.p+offset-Vector2(0,80)
		draw_arc(center,66+sin(clock*18)*4,0,TAU,32,Color("ffb35a"),3)
		var label=["3方向射撃","突進に注意","床衝撃波！ ジャンプ"][enemy.cycle]
		txt(Vector2(500,630),"予告："+label,17,Color("ffb35a"))

func set_bgm(track: String, restart=false):
	if music_track==track and not restart: return
	if music_fade and music_fade.is_valid(): music_fade.kill()
	music_track=track
	music.stop()
	music.stream=bgm[track]
	music.volume_db=-30
	if not muted and bgm_level>0: music.play()
	music_fade=create_tween()
	music_fade.tween_property(music,"volume_db",level_db(bgm_level,-18.0),0.4)

func update_music_state():
	if state!="play": return
	var battle=boss_active and boss_hp>0
	for enemy in enemies:
		if enemy.kind==6 and enemy.hp>0 and absf(enemy.p.x-player.x)<1300 and not door_between(enemy.p.x,player.x): battle=true
	set_bgm("boss" if battle else "stage")
