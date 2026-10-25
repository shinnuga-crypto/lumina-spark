extends RefCounted

# Additional stages share Lumina's movement/combat, but use full 2D world coordinates.
var g
var data: Dictionary
var camera = Vector2.ZERO
var width = 11280.0
var height = 720.0
var arena = Rect2()
var checkpoint_pos = Vector2(130,610)
var checkpoint_section = 0
var shelters: Array = []
var strikes: Array = []
var crumbles: Array = []
var plugs: Array = []
var seals: Array = []
var rays: Array = []
# Big beams: thin guide lines converge (warning) -> a huge column fires -> it narrows away.
var beams: Array = []
var raid_timer = 1.5
var zone_index = 0
const BEAM_FIRE = 0.45
const BEAM_FADE = 0.3
var boss_clock = 0.0
var boss_attack = 0
var actor_texture: Texture2D
var actor_regions: Array = []
var backgrounds: Dictionary = {}
var props: Dictionary = {}

func _init(game):
	g=game
	if ResourceLoader.exists("res://assets/campaign/actors-v2.png"):
		actor_texture=load("res://assets/campaign/actors-v2.png")
		actor_regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/regions.json")).actors
	for name in ["surface","underground"]:
		if ResourceLoader.exists("res://assets/campaign/"+name+".png"): backgrounds[name]=load("res://assets/campaign/"+name+".png")
	if FileAccess.file_exists("res://assets/campaign/props-regions.json"):
		var measured=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/props-regions.json"))
		for name in measured:
			props[name]={"texture":load("res://assets/campaign/"+name+".png"),"regions":measured[name]}

func start(number: int):
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/stage%d.json"%number))
	width=data.width
	height=data.height
	arena=Rect2(data.arena[0],data.arena[1],data.arena[2],data.arena[3])
	g.platforms.clear(); g.enemies.clear(); g.gates.clear(); g.cores.clear(); g.moving.clear(); g.lasers.clear(); g.pickups.clear()
	g.core_count=0
	for p in data.platforms: g.platforms.append(Rect2(p[0],p[1],p[2],p[3]))
	for item in data.enemies:
		var p=Vector2(item[1],item[2])
		if not g.fixed_seed: p+=Vector2(g.rng.randf_range(-55,55),g.rng.randf_range(-20,20) if item[0]!=10 else 0)
		g.enemies.append({"kind":int(item[0]),"p":p,"origin":p,"hp":18 if item[0]==10 else (12 if item[0]==8 else 8),"room":0,"t":0.0,"shot":1.0+g.rng.randf(),"flash":0.0,"shield":false,"cycle":0})
	shelters=[]; strikes=[]; crumbles=[]; plugs=[]; seals=[]; rays=[]; beams=[]; raid_timer=1.5; zone_index=0
	for p in data.shelters: shelters.append(Rect2(p[0],p[1],p[2],p[3]))
	# Strike zones: [centre, half range, seconds between beams] rain beams on Lumina while she is inside.
	for p in data.strikes: strikes.append({"x":float(p[0]),"range":float(p[1]),"interval":float(p[2]) if p.size()>2 else 5.5,"timer":1.2})
	for index in data.crumble: crumbles.append({"index":int(index),"rect":g.platforms[int(index)],"timer":-1.0})
	for p in data.plugs:
		plugs.append({"rect":Rect2(p[0],p[1],p[2],p[3]),"hp":12,"index":g.platforms.size()})
		g.platforms.append(Rect2(p[0],p[1],p[2],p[3]))
	g.player=Vector2(130,500); g.safe_pos=Vector2(130,610)
	checkpoint_pos=g.safe_pos; checkpoint_section=0
	camera=Vector2.ZERO
	g.camera_x=0
	g.boss_max_hp=300 if number==2 else 420
	g.boss_hp=g.boss_max_hp
	g.boss_pos=Vector2(arena.position.x+900,370) if number==2 else Vector2(1050,6190)
	g.boss_active=false; g.boss_intro=0; g.boss_cycle=0
	boss_clock=0; boss_attack=0
	if number==3: reset_seals()

func reset_seals():
	seals=[{"p":Vector2(740,5950),"hp":12},{"p":Vector2(860,5910),"hp":12}]

func left_limit() -> float:
	return arena.position.x+35 if g.boss_active else 25.0

func right_limit() -> float:
	return minf(width-25,850.0) if g.stage==3 and g.boss_active else width-25

func fall_limit() -> float:
	return 850.0 if g.stage==2 else height+200

func can_drop() -> bool:
	for p in g.platforms:
		if p.size.y<35 and absf(g.player.y-p.position.y)<2 and g.player.x>=p.position.x and g.player.x<=p.end.x:
			for plug in plugs:
				if plug.hp>0 and plug.rect==p: return false
			return true
	return false

func boss_rect() -> Rect2:
	return Rect2(g.boss_pos-Vector2(95,90),Vector2(190,135)) if g.stage==2 else Rect2(g.boss_pos-Vector2(63,355),Vector2(126,115))

func boss_vulnerable() -> bool:
	if g.stage==2: return true
	for seal in seals:
		if seal.hp>0: return false
	return fmod(boss_clock,7.0)<4.6

func hit_device(b: Dictionary) -> bool:
	for plug in plugs:
		if plug.hp>0 and plug.rect.grow(b.r).has_point(b.p):
			plug.hp-=b.damage
			g.burst(b.p,Color("ffd27f"),5)
			if plug.hp<=0:
				g.platforms[plug.index]=Rect2(-9999,-9999,0,0)
				g.burst(plug.rect.get_center(),Color("ffa865"),28)
				g.popup(plug.rect.get_center(),"隔壁破壊",Color("ffe28a"))
			return true
	if g.boss_active:
		for seal in seals:
			if seal.hp>0 and seal.p.distance_to(b.p)<30+b.r:
				seal.hp-=b.damage
				g.burst(seal.p,Color("ff6eae"),8)
				if seal.hp<=0:
					g.score+=400
					g.popup(seal.p,"封印解除",Color("ffe28a"))
				return true
	return false

# The saber can cut bulkheads (also the one under Lumina's feet) and the boss seals.
func saber_devices():
	if not g.saber_active(): return
	var damage=g.SABER_DAMAGE[g.saber_tier]
	for i in range(plugs.size()):
		var plug=plugs[i]
		var tag="plug%d"%i
		if plug.hp<=0 or tag in g.saber_hits: continue
		var underfoot=absf(g.player.y-plug.rect.position.y)<4 and g.player.x>plug.rect.position.x-20 and g.player.x<plug.rect.end.x+20
		if underfoot or g.saber_contacts(plug.rect):
			g.saber_hits.append(tag)
			hit_device({"p":plug.rect.get_center(),"r":plug.rect.size.x,"damage":damage})
	if not g.boss_active: return
	for i in range(seals.size()):
		var tag="seal%d"%i
		if seals[i].hp<=0 or tag in g.saber_hits: continue
		if g.saber_contacts(Rect2(seals[i].p-Vector2(30,30),Vector2(60,60))):
			g.saber_hits.append(tag)
			hit_device({"p":seals[i].p,"r":5,"damage":damage})

func update(dt: float):
	var section=int(g.player.x/2400) if g.stage==2 else int(maxf(0,g.player.y-500)/1200)
	if section>checkpoint_section and g.grounded:
		checkpoint_section=section; checkpoint_pos=g.player
		g.hp=g.max_hp; g.banner="CHECKPOINT  /  全回復"; g.banner_time=2
	if g.stage==2:
		for vent in data.vents:
			# Only standing on the pad launches, not standing on a ledge above it.
			if g.grounded and absf(g.player.y-vent[1])<4 and absf(g.player.x-(vent[0]+vent[2]/2))<vent[2]/2:
				g.velocity.y=-820; g.grounded=false; g.jumps=1; g.sound("jump")
		for belt in data.belts:
			if g.grounded and absf(g.player.y-belt[1])<2 and g.player.x>belt[0] and g.player.x<belt[0]+belt[2]: g.player.x+=belt[3]*dt
		# Announce each themed stretch of the surface as Lumina enters it.
		var zones=data.get("zones",[])
		if zone_index<zones.size() and g.player.x>=zones[zone_index][0]:
			g.banner=zones[zone_index][1]; g.banner_time=3
			zone_index+=1
		for strike in strikes:
			if g.boss_active or absf(g.player.x-strike.x)>strike.range: continue
			strike.timer-=dt
			if strike.timer<=0:
				strike.timer=strike.interval*(1.4 if g.easy else 1.0)
				# Lead a running target a little so standing still and running straight both get caught.
				add_beam(g.player.x+g.velocity.x*0.8+g.rng.randf_range(-70,70))
		for raid in data.get("raids",[]):
			if g.boss_active or g.player.x<raid[0] or g.player.x>raid[1]: continue
			raid_timer-=dt
			if raid_timer<=0:
				raid_timer=float(raid[2])*(1.4 if g.easy else 1.0)
				spawn_raid()
	else:
		for crumble in crumbles:
			if crumble.timer<0 and g.grounded and absf(g.player.y-crumble.rect.position.y)<2 and absf(g.player.x-crumble.rect.get_center().x)<crumble.rect.size.x/2+12: crumble.timer=0.65
			if crumble.timer>=0:
				crumble.timer=maxf(0,crumble.timer-dt)
				if crumble.timer==0: g.platforms[crumble.index]=Rect2(-9999,-9999,0,0)
		for crusher in data.crushers:
			if crusher_phase(crusher)>1.2 and crusher_phase(crusher)<2.1 and crusher_rect(crusher).intersects(Rect2(g.player-Vector2(18,85),Vector2(36,85))): g.hurt(1 if g.easy else 3)
	update_enemies(dt)
	update_beams(dt)
	if not g.boss_active and ((g.stage==2 and g.player.x>arena.position.x+70) or (g.stage==3 and g.player.y>arena.position.y+170)):
		g.boss_active=true; g.boss_intro=1.3; checkpoint_pos=Vector2(arena.position.x+150,610 if g.stage==2 else 6300)
		g.hp=g.max_hp; g.bullets.clear(); beams.clear()
		g.banner="空の覇者・ヴァルチャー" if g.stage==2 else "深層固定要塞・アビス・マザー"
		g.banner_time=3
	if g.boss_active: update_boss(dt)
	var target=Vector2(clampf(g.player.x-420,0,width-1280),0) if g.stage==2 else Vector2(0,clampf(g.player.y-360,0,height-720))
	if g.boss_active: target=Vector2(arena.position.x,maxf(0,height-720) if g.stage==3 else 0)
	camera=camera.lerp(target,1-exp(-dt*8))
	g.camera_x=camera.x

func add_beam(pos: float, horizontal=false, width=150.0, charge=1.0):
	beams.append({"pos":pos,"h":horizontal,"w":width,"charge":charge,"t":0.0,"fired":false})

# Current width: zero while charging, snaps open, holds, then narrows back to a line.
func beam_width(b: Dictionary) -> float:
	var f=b.t-b.charge
	if f<0: return 0.0
	if f<BEAM_FIRE: return b.w*(1-pow(1-minf(1,f/0.07),3))
	return b.w*(1-smoothstep(0,1,(f-BEAM_FIRE)/BEAM_FADE))

func update_beams(dt: float):
	for i in range(beams.size()-1,-1,-1):
		var b=beams[i]
		b.t+=dt
		if b.t>=b.charge and not b.fired:
			b.fired=true
			g.shake=maxf(g.shake,6)
			g.sound("hit")
		var width=beam_width(b)
		if width>b.w*0.45:
			# The hit area stays inside the bright part of the column.
			var inside=absf(g.player.y-45-b.pos)<width*0.4 if b.h else absf(g.player.x-b.pos)<width*0.38
			if inside and (b.h or not sheltered(g.player)): g.hurt(1 if g.easy else 3)
		if b.t>b.charge+BEAM_FIRE+BEAM_FADE: beams.remove_at(i)

# A bomber squadron sweeps in from the right, carpets the ground with bombs and leaves to the left.
func spawn_raid():
	for k in range(3):
		var p=Vector2(camera.x+1380+k*120,150+k*40)
		g.enemies.append({"kind":8,"p":p,"origin":p,"hp":4,"room":0,"t":0.0,"shot":0.25+k*0.15,"flash":0.0,"shield":false,"cycle":0,"raider":true})
	g.banner="爆撃編隊、接近！  屋根の下へ"
	g.banner_time=1.6

func sheltered(feet: Vector2) -> bool:
	for roof in shelters:
		if feet.x>roof.position.x+12 and feet.x<roof.end.x-12 and feet.y>roof.end.y+85: return true
	return false

func crusher_phase(item: Array) -> float:
	return fmod(g.elapsed+item[1]/200, float(item[2]))

func crusher_rect(item: Array) -> Rect2:
	return Rect2(0 if item[0]==0 else 840,item[1],440,130)

func update_enemies(dt: float):
	for e in g.enemies:
		# Squadrons spawn beyond the right edge and must keep flying until they leave.
		if e.hp<=0 or (not e.get("raider",false) and not Rect2(camera-Vector2(200,220),Vector2(1680,1160)).has_point(e.p)): continue
		e.t+=dt; e.shot-=dt; e.flash=maxf(0,e.flash-dt)
		if e.get("raider",false):
			e.p=Vector2(e.p.x-430*dt,e.origin.y+sin(e.t*3)*10)
			if e.shot<=0 and e.p.x<camera.x+1260:
				e.shot=0.3
				g.enemy_shot(e.p+Vector2(0,25),Vector2(-150,40),11,"bomb")
			if e.p.x<camera.x-160: e.hp=0; e.gone=true
			continue
		var offset=Vector2(sin(e.t*1.5+e.origin.x)*100,cos(e.t*2)*38)
		if e.kind==7:
			e.p=e.origin+offset
			if fmod(e.t,5.0)>3.8: e.p.y+=sin((fmod(e.t,5.0)-3.8)/1.2*PI)*210
		elif e.kind==8: e.p=e.origin+Vector2(sin(e.t)*75,cos(e.t*1.2)*25)
		elif e.kind==9: e.p=e.origin+Vector2(sin(e.t*2.1)*150,sin(e.t*3.2)*65)
		else: e.p=e.origin+Vector2(sin(e.t*1.3)*75,0)
		var view=Rect2(camera+Vector2(20,20),Vector2(1240,680))
		if e.shot<=0 and (not view.has_point(e.p) or (g.boss_active and not arena.has_point(e.p))): e.shot=0.4
		if e.shot<=0:
			e.cycle+=1
			e.shot=2.5 if e.kind!=10 else 3.3
			var direction=(g.player-Vector2(0,45)-e.p).normalized()
			if e.kind==8: g.enemy_shot(e.p,Vector2(0,80),10,"bomb")
			elif e.kind==10:
				for angle in [-0.24,0,0.24]: g.enemy_shot(e.p,direction.rotated(angle)*210,8,"solid" if e.cycle%3==0 else "")
			else: g.enemy_shot(e.p,direction*(250 if e.kind==7 else 220),7)
		if g.enemy_rect(e).intersects(Rect2(g.player-Vector2(18,80),Vector2(36,80))): g.hurt(1 if g.easy else 2)

func update_boss(dt: float):
	g.boss_intro=maxf(0,g.boss_intro-dt)
	if g.boss_intro>0 or g.boss_hp<=0: return
	boss_clock+=dt; g.boss_timer-=dt
	g.boss_phase=2 if g.boss_hp<g.boss_max_hp/2 else 1
	if g.stage==2:
		var phase=fmod(boss_clock,8.0)
		g.boss_pos=Vector2(arena.position.x+800+sin(boss_clock*0.65)*270,310+sin(boss_clock)*90)
		if phase>6.2: g.boss_pos.y+=sin((phase-6.2)/1.8*PI)*220
		if g.boss_timer<=0:
			g.boss_timer=0.8 if g.boss_phase==2 else 1.15
			var toward=(g.player-Vector2(0,45)-(g.boss_pos-Vector2(0,20))).normalized()
			boss_attack+=1
			if boss_attack%4==0:
				# Beam curtain around Lumina: the gaps between columns are where to stand.
				var spread=[-240,0,240] if g.boss_phase==1 else [-360,-180,0,180,360]
				for dx in spread: add_beam(clampf(g.player.x+dx,arena.position.x+60,arena.end.x-60),false,120,0.9)
				g.boss_timer=1.9
			else:
				for angle in [-0.25,0,0.25]: g.enemy_shot(g.boss_pos-Vector2(0,20),toward.rotated(angle)*250,9)
				if g.boss_phase==2: g.enemy_shot(g.boss_pos+Vector2(-120,20),Vector2(0,100),11,"bomb")
		if g.boss_pos.distance_to(g.player-Vector2(0,40))<115: g.hurt(3)
	else:
		# The final boss NEVER leaves its wall mount. Telegraph aimed horizontal beams.
		if g.boss_timer<=0:
			g.boss_timer=2.6 if g.boss_phase==2 else 3.3
			boss_attack+=1
			if boss_attack%3==0:
				# Horizontal cannon at Lumina's height: jump over it or drop below it.
				add_beam(clampf(g.player.y-45,5700,6250),true,70,1.0)
			elif boss_attack%3==1:
				# Pillars from the ceiling on Lumina and beside her: keep moving.
				for dx in [-260,0,260]: add_beam(clampf(g.player.x+dx,60,820),false,110,1.0)
			else:
				var from=g.boss_pos-Vector2(40,150)
				var direction=(g.player-Vector2(0,45)-from).normalized()
				for angle in [-0.45,-0.22,0,0.22,0.45]: g.enemy_shot(from,direction.rotated(angle)*230,9,"solid" if boss_attack%2==0 and angle==0 else "")
			# Phase 2 sweeps the floor too, so the ledges are needed.
			if g.boss_phase==2 and boss_attack%2==0: add_beam(6255.0,true,70,1.2)

func respawn():
	g.player=checkpoint_pos; g.safe_pos=checkpoint_pos; g.velocity=Vector2.ZERO
	g.hp=g.max_hp; g.invincible=2; g.bullets.clear(); g.reset_saber_action(); g.saber_cooldown=0; g.saber_spam=0
	g.charge=0; g.charge_release=-1; g.hurt_pose=0; g.dash_timer=0; g.dash_cooldown=0
	g.jumps=0; g.prev_jump=false; g.prev_fire=false; g.prev_dash=false; g.prev_saber=false
	g.fire_buffer=0; g.drop_buffer=0; g.walk_phase=0; g.aim_time=0; g.saber_air=false
	for crumble in crumbles: crumble.timer=-1.0; g.platforms[crumble.index]=crumble.rect
	beams=[]
	if g.boss_active:
		g.boss_hp=g.boss_max_hp; g.boss_intro=1.3; g.boss_timer=0; boss_clock=0; rays=[]; beams=[]; boss_attack=0
		if g.stage==3: reset_seals()
	g.state="play"

func actor(index: int, center: Vector2, size: Vector2, tint=Color.WHITE, flip=false):
	if not actor_texture or index>=actor_regions.size(): return
	var r=actor_regions[index]
	var region=Rect2(r[0],r[1],r[2],r[3])
	var scale=minf(size.x/region.size.x,size.y/region.size.y)
	var rect=Rect2(center-region.size*scale/2,region.size*scale)
	if flip: rect.position.x+=rect.size.x; rect.size.x=-rect.size.x
	g.draw_texture_rect_region(actor_texture,rect,region,tint)

func prop(name: String, index: int, target: Rect2, flip=false):
	if not props.has(name): return
	var r=props[name].regions[index]
	var source=Rect2(r[0],r[1],r[2],r[3])
	if flip:
		g.draw_set_transform(target.position+Vector2(target.size.x,0),0,Vector2(-1,1))
		g.draw_texture_rect_region(props[name].texture,Rect2(Vector2.ZERO,target.size),source)
		g.draw_set_transform(Vector2.ZERO)
	else: g.draw_texture_rect_region(props[name].texture,target,source)

func prop_strip(name: String, index: int, target: Rect2, tile_width: float):
	if not props.has(name): return
	var r=props[name].regions[index]
	for x in range(0,int(target.size.x),int(tile_width)):
		var width=minf(tile_width,target.size.x-x)
		g.draw_texture_rect_region(props[name].texture,Rect2(target.position+Vector2(x,0),Vector2(width,target.size.y)),Rect2(r[0],r[1],r[2]*width/tile_width,r[3]))

func piston(target: Rect2, extended: bool, flip: bool):
	if not props.has("props-shaft"): return
	var r=props["props-shaft"].regions[6 if extended else 7]
	var scale=target.size.y/r[3]
	# Stretch only the central shaft, preserving the housing/head size between states.
	var left=minf(200,r[2]*0.45); var right=minf(132,r[2]*0.4)
	var widths=[left*scale,maxf(1,target.size.x-(left+right)*scale),right*scale]
	var cuts=[0.0,left,r[2]-right,r[2]]
	if flip: g.draw_set_transform(target.position+Vector2(target.size.x,0),0,Vector2(-1,1))
	else: g.draw_set_transform(target.position)
	var x=0.0
	for i in range(3):
		g.draw_texture_rect_region(props["props-shaft"].texture,Rect2(x,0,widths[i],target.size.y),Rect2(r[0]+cuts[i],r[1],cuts[i+1]-cuts[i],r[3]))
		x+=widths[i]
	g.draw_set_transform(Vector2.ZERO)

func draw():
	var bg="surface" if g.stage==2 else "underground"
	if backgrounds.has(bg): g.draw_texture_rect(backgrounds[bg],Rect2(-24-fmod(camera.x*0.035,24),-fmod(camera.y*0.04,18),1330,760),false)
	g.draw_rect(Rect2(0,0,1280,720),Color(0.01,0.025,0.05,0.12 if g.stage==2 else 0.36))
	var o=-camera+Vector2(sin(g.clock*81)*g.shake,0)
	for p in g.platforms:
		if not p.intersects(Rect2(camera,Vector2(1280,720))): continue
		var r=Rect2(p.position+o,p.size)
		g.draw_rect(r,Color("192c38") if g.stage==2 else Color("292438"))
		var heavy=p.size.y>40
		prop_strip("props-surface" if g.stage==2 else "props-shaft",0 if heavy else 1,Rect2(r.position,Vector2(r.size.x,minf(r.size.y,96) if heavy else maxf(r.size.y,38))),320 if heavy else 256)
	if g.stage==2: draw_surface(o)
	else: draw_shaft(o)
	for e in g.enemies:
		if e.hp<=0 or not Rect2(camera-Vector2(100,100),Vector2(1480,920)).has_point(e.p): continue
		actor(e.kind-7,e.p+o,Vector2(112,85),Color(2,2,2) if e.flash>0 else Color.WHITE,e.kind!=9 and e.p.x<g.player.x)
		if e.shot<0.45: g.draw_arc(e.p+o,45,0,TAU,24,Color("ffb55f"),2)
	for pickup in g.pickups: g.sprite(6,pickup+o,30)
	if g.boss_active and (g.boss_hp>0 or g.state=="defeat"):
		if g.stage==2:
			actor(4,g.boss_pos+o,Vector2(420,300),Color(2,1.3,1.3) if g.boss_flash>0 else Color.WHITE)
			if fmod(boss_clock,8)>5.2: g.txt(Vector2(450,180),"急降下の予告 — 真下から離れよう",20,Color("ffbc68"))
		else: draw_final_boss(o)
	for b in beams: draw_beam(b,o)
	draw_combat(o)
	draw_hud()
	if g.state=="pause": g.panel("一時停止",g.confirm_label()+" / ESCで再開","O：設定・音量    R：タイトルへ")
	if g.state=="dead": g.panel("もう一度、飛び出そう。",g.confirm_label()+" / クリックでチェックポイントへ","残機制限なし。直前の区間から再開します。")
	if g.state=="clear":
		g.panel("STAGE CLEAR" if g.stage==2 else "ALL STAGES CLEAR", "迎撃線を突破。地下の星炉へ。" if g.stage==2 else "星炉の夜明けは、ルミナの手に。", "SCORE %07d   RANK %s   時間 %s"%[g.score,g.clear_rank(),g.time_text()])
		g.txt(Vector2(370,520),g.confirm_label()+(" / クリックでステージ3へ" if g.stage==2 else " / クリックでタイトルの選択へ"),22,g.CYAN)
	if g.state=="settings": g.draw_settings()

func draw_surface(o: Vector2):
	for roof in shelters:
		var p=roof.position+o
		prop("props-surface",3,Rect2(p+Vector2(8,58),Vector2(32,610-roof.position.y-58)))
		prop("props-surface",3,Rect2(p+Vector2(roof.size.x-40,58),Vector2(32,610-roof.position.y-58)))
		prop("props-surface",2,Rect2(p,Vector2(roof.size.x,64)))
		g.txt(p+Vector2(20,90),"防空シェルター",20,g.CYAN)
	for vent in data.vents:
		var p=Vector2(vent[0],vent[1])+o
		prop("props-surface",4,Rect2(p,Vector2(vent[2],50)))
		for k in range(3): g.draw_arc(p+Vector2(vent[2]/2,-20-k*24-fmod(g.clock*30,24)),23,PI,TAU,16,Color(0.3,1,0.9,0.5),3)
	for belt in data.belts:
		var p=Vector2(belt[0],belt[1])+o
		prop_strip("props-surface",5,Rect2(p,Vector2(belt[2],42)),210)
		for x in range(15,int(belt[2])-15,45): g.txt(p+Vector2(x,-8),"›" if belt[3]>0 else "‹",27,Color("ffd27f"))
	if camera.x<950:
		g.txt(Vector2(100,220),"STAGE 02 / 地上・夜明けの迎撃線",25,g.CYAN)
		g.txt(Vector2(100,255),"↑↓＋左右 / マウス / 右スティックで上空を狙おう",19,Color.WHITE)
		g.txt(Vector2(100,285),"青い跳躍台で上昇。空爆の予告が出たら屋根の下へ。",18,Color("c1d4df"))

func draw_shaft(o: Vector2):
	for y in range(int(camera.y/160)*160,int(camera.y+900),160):
		for x in [18,1245]:
			g.draw_rect(Rect2(Vector2(x,y)+o,Vector2(16,115)),Color("4e384d"))
			g.draw_circle(Vector2(x+8,y+20)+o,5,Color("ffb55f"))
	for crumble in crumbles:
		if crumble.timer==0: continue
		var r=Rect2(crumble.rect.position+o,crumble.rect.size)
		prop("props-shaft",3 if crumble.timer<0 else 4,Rect2(r.position,Vector2(r.size.x,55)))
	for plug in plugs:
		if plug.hp>0:
			var r=Rect2(plug.rect.position+o,plug.rect.size)
			prop("props-shaft",2 if plug.hp>6 else 5,Rect2(r.position,Vector2(r.size.x,62)))
			g.txt(r.position+Vector2(15,-15),"下へ撃って隔壁を破壊 ↓",20,Color("ffe28a"))
	for item in data.crushers:
		var r=crusher_rect(item); r.position+=o
		var t=crusher_phase(item)
		if t<1.2:
			piston(Rect2(Vector2(0 if item[0]==0 else 1080,item[1])+o,Vector2(200,130)),false,item[0]!=0)
			g.draw_rect(r,Color(1,0.4,0.25,0.15)); g.draw_rect(r,Color("ffb85c"),false,2)
			g.txt(r.position+Vector2(15,60),"圧搾機 / 退避",20,Color("ffb85c"))
		elif t<2.1:
			piston(r,true,item[0]!=0)
		else:
			piston(Rect2(Vector2(0 if item[0]==0 else 1080,item[1])+o,Vector2(200,130)),false,item[0]!=0)
	if camera.y<200:
		g.txt(Vector2(100,215),"STAGE 03 / 地下・星骸の深淵",25,g.CYAN)
		g.txt(Vector2(100,250),"隔壁は下へ射撃。ヒビの足場は着地から0.65秒で崩れる。",19,Color.WHITE)
		g.txt(Vector2(100,280),"床の切れ目は左右交互。走って下へ。圧搾機の予告に注意。",18,Color("c1d4df"))

func draw_final_boss(o: Vector2):
	# Static backplate, anchored pipes and sprite never translate or bob.
	var center=g.boss_pos+o-Vector2(0,195)
	for side in [-1,1]: g.draw_line(center+Vector2(side*110,-200),center+Vector2(side*180,250),Color("4d354e"),30)
	actor(5,center,Vector2(490,610),Color(1.5,1.0,1.2) if g.boss_flash>0 else Color.WHITE)
	var core=boss_rect().get_center()+o
	g.draw_circle(core,27,Color(1,0.2,0.65,0.5) if boss_vulnerable() else Color("4b6882"))
	g.draw_arc(core,48,0,TAU,48,Color("ff82c6") if boss_vulnerable() else Color("79dfe0"),4)
	for seal in seals:
		if seal.hp>0:
			g.draw_line(seal.p+o,core,Color(0.4,1,1,0.35),3)
			prop("props-shaft",8,Rect2(seal.p+o-Vector2(32,32),Vector2(64,64)))
			g.draw_arc(seal.p+o,32,g.clock,g.clock+TAU,32,g.CYAN,2)
			g.txt(seal.p+o+Vector2(-34,-40),"封印装置",15,g.CYAN)
	g.txt(Vector2(330,210),"封印装置を破壊 → 光るコアを狙え" if not boss_vulnerable() else "コア開放！ 上へ狙って撃ち込め",21,Color("ffe28a"))

func draw_combat(o: Vector2):
	for b in g.bullets:
		var col=Color("ff9a3c") if b.get("solid",false) else (g.PINK if b.enemy else g.CYAN)
		if b.get("reflected",false): col=Color("ffe28a")
		g.draw_line(b.p+o,b.p+o-b.v.normalized()*22,col,3)
		g.draw_circle(b.p+o,b.r+4,Color(col,0.2)); g.draw_circle(b.p+o,b.r,col)
		if b.get("solid",false): g.draw_arc(b.p+o,b.r+5,0,TAU,8,Color("ffcd91"),2)
	for effect in g.fx: g.art_sprite("explosion",mini(5,int(effect.age*12)),effect.p+o+Vector2(0,effect.size/2),effect.size)
	for p in g.particles: g.draw_circle(p.p+o,3,Color(p.c,clampf(p.life*2,0,1)))
	for p in g.popups: g.txt(p.p+o+Vector2(-35,-p.age*50),p.text,18,Color(p.c,clampf(2-p.age*2.5,0,1)))
	if g.invincible<=0 or int(g.clock*18)%2==0: g.draw_hero(g.player+o)
	var muzzle=g.muzzle_position()+o
	if g.muzzle_time>0:
		g.draw_circle(muzzle,13,Color(0.6,1,1,0.6)); g.draw_line(muzzle,muzzle+g.aim_direction*28,Color.WHITE,5)
	if g.charge>0.2: g.draw_arc(muzzle,10+g.charge*6,g.clock*5,g.clock*5+TAU*g.charge/g.FULL_CHARGE,32,Color("ffe28a"),3)
	g.hero_actions.draw_effects(o)
	if g.mouse_aim:
		var aim=g.get_global_mouse_position()
		g.draw_arc(aim,12,0,TAU,24,g.CYAN,1.5)
		g.draw_line(aim-Vector2(18,0),aim+Vector2(18,0),g.CYAN,1)
	if g.state=="defeat": g.draw_rect(Rect2(0,0,1280,720),Color(1,0.75,0.9,maxf(0,1-absf(g.ending_time-2.0)*5)))

func draw_hud():
	g.draw_rect(Rect2(24,20,1232,82),Color(0.025,0.04,0.1,0.94))
	g.txt(Vector2(42,49),"LUMINA %d / %d"%[g.hp,g.max_hp],17,g.PINK)
	g.draw_rect(Rect2(42,64,220,17),Color("29344b")); g.draw_rect(Rect2(42,64,220*float(g.hp)/g.max_hp,17),g.CYAN)
	g.txt(Vector2(300,50),data.name,23)
	g.txt(Vector2(300,80),"DASH %s   SABER %s   CHARGE %s"%["READY" if g.dash_cooldown<=0 else "…",g.saber_status(),"MAX（ジャスト）" if g.dodge_charge>0 else ("MAX" if g.charge>=g.FULL_CHARGE else ("READY" if g.charge>=0.8 else "長押し"))],14,g.CYAN)
	g.txt(Vector2(870,49),"%07d pt"%g.score,21,Color("ffe28a")); g.txt(Vector2(1090,49),g.time_text(),24)
	g.txt(Vector2(870,80),"COMBO %d   撃破 %d"%[g.combo,g.kills],14,Color("c1d4df"))
	var progress=g.player.x/width if g.stage==2 else g.player.y/height
	g.draw_rect(Rect2(24,104,1232*clampf(progress,0,1),3),g.PINK)
	if g.banner_time>0:
		g.draw_rect(Rect2(270,125,740,48),Color(0.02,0.06,0.13,0.85)); g.txt(Vector2(300,157),g.banner,21,g.CYAN)
	if g.boss_active and g.boss_hp>0:
		# A dark plate keeps the name and bar readable over the floor art.
		g.draw_rect(Rect2(355,636,570,64),Color(0.02,0.03,0.08,0.82))
		g.draw_rect(Rect2(370,672,540,20),Color("30233f")); g.draw_rect(Rect2(370,672,540*float(g.boss_hp)/g.boss_max_hp,20),g.PINK)
		g.txt(Vector2(430,660),"SKY VULTURE" if g.stage==2 else "ABYSS MOTHER / 壁面固定要塞",19)

func draw_beam(b: Dictionary, o: Vector2):
	var col=Color("ff5a3c") if g.stage==2 else Color("ff4fa8")
	var k=clampf(b.t/b.charge,0,1)
	if b.h:
		draw_beam_shape(b.pos+o.y,true,30.0,1030.0,k,beam_width(b),b.t<b.charge,col)
		if b.t<b.charge: g.txt(Vector2(70,b.pos+o.y-16),"水平砲撃  /  ジャンプか下へ",17,Color("ff9eae"))
		return
	var bottom=610.0 if g.stage==2 else 6300.0
	if g.stage==2:
		for roof in shelters:
			if b.pos>roof.position.x+12 and b.pos<roof.end.x-12: bottom=roof.position.y
	draw_beam_shape(b.pos+o.x,false,camera.y+104+o.y,bottom+o.y,k,beam_width(b),b.t<b.charge,col)
	if b.t<b.charge and g.stage==2 and not g.boss_active: g.txt(Vector2(b.pos+o.x-40,150),"光線予告",17,Color("ffb55f"))

# Screen-space drawing shared with stage 1: thin guide lines that close in on the line while
# charging, then a huge layered column (glow, body, white core) with a flare where it lands.
func draw_beam_shape(line: float, horizontal: bool, from: float, to: float, k: float, width: float, charging: bool, col: Color):
	var axis=func(along: float, across: float) -> Vector2: return Vector2(along,across) if horizontal else Vector2(across,along)
	if charging:
		var spread=lerpf(150,0,pow(k,1.6))
		for i in range(-3,4):
			var offset=line+spread*i/3.0
			var a=0.18+0.5*k*(1.0-absf(i)/4.0)
			g.draw_line(axis.call(from,offset),axis.call(to,offset),Color(col,a),1.5)
		g.draw_line(axis.call(from,line),axis.call(to,line),Color(1,1,1,0.25+0.6*k),1.5+2*k)
		g.draw_circle(axis.call(to,line),6+22*k,Color(col,0.25+0.4*k))
		return
	if width<=0.5: return
	var jitter=sin(g.clock*70)*width*0.04
	# Soft layers: each fades from its centre line to transparent edges, so the column glows.
	for layer in [[1.0,0.5,col],[0.6,0.95,col.lightened(0.25)],[0.42,0.9,col.lightened(0.5)],[0.24,1.0,Color(1,0.98,0.92)]]:
		var half=(width*layer[0]+jitter)
		var centre=Color(layer[2],layer[1])
		var edge=Color(layer[2],0.0)
		for side in [-1,1]:
			var a=axis.call(from,line); var b=axis.call(to,line)
			var c=axis.call(to,line+side*half); var d=axis.call(from,line+side*half)
			g.draw_polygon(PackedVector2Array([a,b,c,d]),PackedColorArray([centre,centre,edge,edge]))
	# Impact flare: a flattened bloom where the column hits the floor or roof.
	var hit=axis.call(to,line)
	g.draw_set_transform(hit,0,Vector2(1,0.28) if not horizontal else Vector2(0.28,1))
	for ring in range(6):
		var r=width*(1.3-ring*0.18)
		g.draw_circle(Vector2.ZERO,r,Color(col.lerp(Color(1,0.97,0.9),ring/5.0),0.12+ring*0.08))
	g.draw_set_transform(Vector2.ZERO)
