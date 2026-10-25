extends RefCounted
var g
var overdrive=0.0
var add_timer=7.0
var pressure_camp=0.0
var pressure_time=-1.0
var pressure_cool=0.0
var launcher_flash=0.0
const PRESSURE_WARN=0.9
const PRESSURE_PUSH=0.85

func _init(game):
	g=game

func reset():
	overdrive=0; add_timer=7; pressure_camp=0; pressure_time=-1; pressure_cool=0; launcher_flash=0
	for e in g.enemies:
		if e.get("boss_add",false): e.hp=0

func enrage():
	overdrive=1.1; add_timer=8; pressure_cool=0
	g.boss_timer=0.7; g.shake=maxf(g.shake,7)
	g.banner="OVERDRIVE / 攻撃激化！ 回復を持つ援軍が出現"; g.banner_time=3
	g.sound("charge"); spawn_helpers()

func spawn_helpers():
	var living=0
	for e in g.enemies:
		if e.hp>0 and e.get("boss_add",false): living+=1
	for i in range(maxi(0,2-living)):
		var x=clampf(g.player.x+(-180 if i==0 else 250),g.campaign.arena.position.x+110,810 if g.stage==3 else g.campaign.arena.end.x-100)
		var y=clampf(g.player.y-155,5800,6120) if g.stage==3 else 230+i*70
		var pos=Vector2(x,y)
		g.enemies.append({"kind":9 if g.stage==3 else 7,"p":pos,"origin":pos,"hp":8,"room":0,"t":0.0,"shot":1.8+i*0.4,"flash":0.0,"shield":false,"cycle":0,"boss_add":true,"heal_drop":true})

func update(dt: float):
	overdrive=maxf(0,overdrive-dt); launcher_flash=maxf(0,launcher_flash-dt)
	pressure_cool=maxf(0,pressure_cool-dt)
	if g.boss_intro>0 or overdrive>0: return
	if g.boss_phase==2:
		add_timer-=dt
		if add_timer<=0: spawn_helpers(); add_timer=9.0
	if g.stage!=3: return
	if pressure_time>=0:
		pressure_time+=dt
		if pressure_time>=PRESSURE_WARN and pressure_time<PRESSURE_WARN+PRESSURE_PUSH and g.player.y<6250:
			g.drop_timer=maxf(g.drop_timer,0.14); g.grounded=false; g.coyote=0; g.jumps=2
			g.velocity.y=maxf(g.velocity.y,480.0)
		if pressure_time>=PRESSURE_WARN+PRESSURE_PUSH:
			pressure_time=-1; pressure_camp=0; pressure_cool=5 if g.boss_phase==2 else 7
	elif pressure_cool<=0:
		pressure_camp=pressure_camp+dt if g.player.y<6110 else maxf(0,pressure_camp-dt*2)
		if pressure_camp>=(1.8 if g.boss_phase==2 else 2.7):
			pressure_time=0; g.sound("charge")

func launch_missiles():
	launcher_flash=0.8
	var origin=g.boss_pos-Vector2(250,160)
	var aim=(g.player-Vector2(0,45)-origin).normalized()
	var angles=[-0.24,0,0.24] if g.boss_phase==1 else [-0.4,-0.2,0,0.2,0.4]
	for angle in angles:
		var first=g.bullets.size()
		g.enemy_shot(origin,aim.rotated(angle)*(190 if g.boss_phase==1 else 235),10,"home")
		for i in range(first,g.bullets.size()): g.bullets[i].boss_missile=true

func core_index() -> int:
	if not g.campaign.boss_vulnerable(): return 0
	return 2 if g.boss_phase==2 else 1

func draw(o: Vector2):
	var core=g.campaign.boss_rect().get_center()+o
	g.action_art.sprite("boss",core_index(),core,Vector2(155,165))
	if launcher_flash>0:
		g.action_art.sprite("boss",4,g.boss_pos+o-Vector2(150,160),Vector2(180,155))
	if pressure_time>=0:
		g.action_art.sprite("boss",3,Vector2(1050,6090)+o,Vector2(180,155))
		var active=pressure_time>=PRESSURE_WARN
		var col=Color("ff4fa8") if active else Color("ffe291")
		g.txt(Vector2(40,150),"重力パルス！ ↓ 下段へ" if active else "重力収束 / 上段から降りろ ↓",20,col)
		for x in [180,420,680]:
			var y=5900+fmod(g.clock*(520 if active else 170)+x,350)
			g.draw_line(Vector2(x,y-65)+o,Vector2(x,y)+o,Color(col,0.7),4 if active else 2)
			g.draw_colored_polygon(PackedVector2Array([Vector2(x-14,y-10)+o,Vector2(x+14,y-10)+o,Vector2(x,y+12)+o]),Color(col,0.8))
	if overdrive>0: g.draw_rect(Rect2(0,104,1280,616),Color(1,0.15,0.45,0.13*overdrive))
