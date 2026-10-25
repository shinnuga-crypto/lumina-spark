extends RefCounted

# New atlases share anatomical head scale; old motion metadata/source pixels stay intact.
var g
var sets: Dictionary
var textures: Dictionary={}

func _init(game):
	g=game
	sets=JSON.parse_string(FileAccess.get_file_as_string("res://assets/motion/v3-regions.json")).sets
	for key in sets: textures[key]=load("res://"+sets[key].file)

func visual(set_name: String, index: int, action: String) -> Dictionary:
	var f=sets[set_name].frames[index]
	return {"texture":textures[set_name],"region":Rect2(f.region[0],f.region[1],f.region[2],f.region[3]),
		"anchor":Vector2(f.anchor[0],f.anchor[1]),"muzzle":Vector2(f.muzzle[0],f.muzzle[1]),
		"scale":f.scale,"frame":index,"name":action,"v3":set_name}

func hero_visual() -> Dictionary:
	if g.hurt_pose>0: return {}
	if g.saber_time>0:
		if g.saber_kind=="dash": return visual("dash",3,"saber")
		var airborne=g.saber_kind=="air" or g.saber_air
		var action="air_saber" if airborne else "saber"
		if not g.saber_seq.is_empty():
			var frame={0:0,3:1,4:2,5:3,2:4}.get(g.saber_segment()[0],5)
			if g.saber_time<0.04: frame=5
			return visual("air" if airborne else "ground",frame,action)
		var elapsed=g.saber_total-g.saber_time
		var frame=0 if elapsed<g.saber_startup*0.55 else (1 if elapsed<g.saber_startup else (2 if elapsed<g.saber_startup+0.015 else 3))
		return visual("heavy-air" if airborne else "heavy",frame,action)
	# During aim the rig keeps arbitrary-angle cannon control. A stationary charge can use art.
	if g.saber_charge>0 and not g.walk_aiming() and (not g.grounded or absf(g.velocity.x)<15):
		return visual("heavy" if g.grounded else "heavy-air",0,"saber_charge")
	if g.dash_timer>0:
		if g.walk_aiming():
			# Horizontal fire uses its own drawn pose, other angles keep the shoulder/elbow rig.
			if absf(g.aim_direction.y)>0.03 or g.aim_direction.x*g.facing<0.9: return {}
			return visual("dash",2,"dash")
		return visual("dash",0 if g.dash_timer>0.11 else 1,"dash")
	return {}

func draw_effects(offset: Vector2) -> bool:
	var v=hero_visual()
	if v.is_empty(): return false
	if g.saber_charge>0:
		var hand=g.player+offset+Vector2(-28*g.facing,-50)
		var tier=2 if g.saber_charge>=g.FULL_CHARGE-0.001 else (1 if g.saber_charge>=0.8 else 0)
		var col=Color("ffe291") if tier==2 else (g.CYAN if tier==1 else g.PINK)
		g.draw_arc(hand,14+g.saber_charge*6,g.clock*4,g.clock*4+TAU*g.saber_charge/g.FULL_CHARGE,32,col,2+tier)
	# The independent charged smear covers the actual reach without scaling up the heroine.
	if g.saber_time>0: draw_reach_rim(g.player+offset)
	return g.saber_time>0 or g.saber_charge>0

func draw_reach_rim(at: Vector2):
	if g.saber_kind=="dash":
		if g.saber_active(): g.draw_line(at+Vector2(g.facing*55,-57),at+Vector2(g.facing*g.saber_reach(),-57),Color(g.CYAN,0.65),3)
		return
	if g.saber_tier<2 or not g.saber_active(): return
	var elapsed=g.saber_total-g.saber_time-g.saber_startup
	var fade=1-clampf(elapsed/maxf(0.01,g.saber_total-g.saber_startup-g.saber_recovery),0,1)
	var r=region("slash",0)
	var point=sets.slash.pivot[0]
	var pivot=Vector2(point[0],point[1])
	var scale=g.saber_reach()/sets.slash.radius[0]
	if g.saber_kind=="air":
		# The existing airborne MAX hit covers both sides. Show the returning arc too.
		g.draw_set_transform(at-Vector2(0,55),0,Vector2(-g.facing,1))
		g.draw_texture_rect_region(textures.slash,Rect2(-pivot*scale,r.size*scale),r,Color(1,1,1,fade*0.72))
	g.draw_set_transform(at-Vector2(0,55),0,Vector2(g.facing,1))
	g.draw_texture_rect_region(textures.slash,Rect2(-pivot*scale,r.size*scale),r,Color(1,1,1,fade))
	g.draw_set_transform(Vector2.ZERO)

func region(set_name: String, index: int) -> Rect2:
	var r=sets[set_name].regions[index]
	return Rect2(r[0],r[1],r[2],r[3])

func sprite(set_name: String, index: int, center: Vector2, size: Vector2, tint=Color.WHITE):
	g.draw_texture_rect_region(textures[set_name],Rect2(center-size/2,size),region(set_name,index),tint)

func draw_raider(e: Dictionary, at: Vector2):
	var index=int(e.t*12)%3
	var r=region("airraid",index)
	var size=Vector2(126,126*r.size.y/r.size.x)
	sprite("airraid",index,at,size,Color(2,2,2) if e.flash>0 else Color.WHITE)

func projectile_frame(b: Dictionary) -> int:
	if not b.enemy: return -1
	# Bombs are intentionally solid too; their own artwork must take priority over spikes.
	if b.get("bomb",false): return 3
	if b.get("solid",false): return -1
	if b.get("floor_fire",false): return 4 if b.v.x<0 else 5
	return -1

func draw_projectile(b: Dictionary, offset: Vector2) -> bool:
	var index=projectile_frame(b)
	if index<0: return false
	if index==3:
		var r=region("airraid",3)
		var size=Vector2(b.r*2.8*r.size.x/r.size.y,b.r*2.8)
		sprite("airraid",3,b.p+offset,size)
		return true
	if index in [4,5]:
		var size=Vector2(b.r*5.2,b.r*2.6)
		# Keep the white leading core centered on the existing collision circle.
		var center=b.p+offset+Vector2((1 if b.v.x<0 else -1)*size.x*0.32,0)
		sprite("airraid",index,center,size)
		return true
	return false

func draw_beam(line: float, horizontal: bool, from: float, to: float, k: float, width: float, charging: bool, col: Color) -> bool:
	var origin=Vector2(from,line) if horizontal else Vector2(line,from)
	var length=maxf(0,to-from)
	var phase=int(g.clock*17)%4
	g.draw_set_transform(origin,-PI/2 if horizontal else 0.0)
	if charging:
		var spread=lerpf(150,10,pow(k,1.6))
		var r=region("beam",clampi(int(k*4),0,3))
		g.draw_texture_rect_region(textures.beam,Rect2(-spread,0,spread*2,length),r,Color(col,0.20+0.2*k))
		g.draw_set_transform(Vector2.ZERO)
		return false # Keep the existing precise central warning line visible over the art.
	if width<=0.5:
		g.draw_set_transform(Vector2.ZERO)
		return true
	var r=region("beam",4+phase)
	# Stretch a cap-free interior once: repeating generated glows exposed hard tile joins.
	g.draw_texture_rect_region(textures.beam,Rect2(-width,0,width*2,length),r,Color(col,0.85))
	g.draw_line(Vector2.ZERO,Vector2(0,length),Color(1,0.98,0.94,0.95),maxf(1,width*0.38))
	# Emitter and impact are independent, so the end can still stop on a shelter roof.
	var flare=region("beam",8+phase)
	g.draw_texture_rect_region(textures.beam,Rect2(-width*1.25,-width*0.7,width*2.5,width*1.4),flare,Color(col,0.8))
	var impact=region("beam",12+phase)
	g.draw_texture_rect_region(textures.beam,Rect2(-width*1.8,length-width*0.45,width*3.6,width*0.9),impact,Color(col,0.95))
	g.draw_set_transform(Vector2.ZERO)
	return true
