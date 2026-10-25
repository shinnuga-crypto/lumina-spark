extends RefCounted

# One skeleton keeps the same head/limb scale through aim, jumps and all saber styles.
var g
var weapon: Texture2D
var weapon_region=Rect2()
var grip=Vector2.ZERO
var guard_y=0.0
var blade_scale=0.1

func _init(game):
	g=game
	if ResourceLoader.exists("res://assets/motion/saber-weapon.png"):
		weapon=load("res://assets/motion/saber-weapon.png")
		var info=JSON.parse_string(FileAccess.get_file_as_string("res://assets/motion/saber-weapon.json"))
		var r=info.region; weapon_region=Rect2(r[0],r[1],r[2],r[3])
		grip=Vector2(info.grip[0],info.grip[1]); guard_y=info.guard_y
		blade_scale=76.0/(grip.y-weapon_region.position.y)

func swing_elapsed() -> float:
	return clampf(g.saber_total-g.saber_time,0,g.saber_total)

func swing_progress() -> float:
	return clampf((swing_elapsed()-g.saber_startup)/maxf(0.01,g.saber_total-g.saber_startup-g.saber_recovery),0,1)

func swing_weight() -> float:
	if g.saber_time<=0: return 0.0
	return smoothstep(0,0.055,swing_elapsed())*smoothstep(0,g.saber_recovery,g.saber_time)

func charge_weight() -> float:
	return smoothstep(0,0.16,g.saber_charge)

func prepared_entry() -> float:
	return g.saber_prepare_weight*(1-smoothstep(0,0.08,swing_elapsed())) if g.saber_time>0 else 0.0

func hip(phase: float) -> Vector2:
	var value=g.walk_hip(phase)
	if not g.grounded: value=Vector2(0,-51+clampf(-g.velocity.y/550.0,0,1)*2)
	if g.landing_time>0: value.y+=sin((1-g.landing_time/0.12)*PI)*4
	return value

func torso_angle() -> float:
	var base=g.walk_lean()
	if not g.grounded: base*=0.6
	var twist=0.0
	if g.saber_kind=="dash": twist=0.22
	elif g.saber_kind=="air": twist=sin(swing_progress()*TAU)*0.16
	else: twist=lerpf(-0.16,0.22,smoothstep(0,1,swing_progress()))
	return base+twist*swing_weight()-maxf(charge_weight(),prepared_entry())*0.10

func leg(phase: float, side: String) -> Dictionary:
	var value=g.gait_leg(phase,side)
	var resting=absf(g.velocity.x)<15
	if not g.grounded:
		var rising=clampf(-g.velocity.y/550.0,0,1)
		var falling=clampf(g.velocity.y/700.0,0,1)
		var apex=Vector2(15,-22) if side=="near" else Vector2(-16,-18)
		var ascend=Vector2(18,-29) if side=="near" else Vector2(-18,-22)
		var descend=Vector2(12,-10) if side=="near" else Vector2(-13,-15)
		value.ankle=apex.lerp(ascend,rising).lerp(descend,falling)
		value.pitch=-0.1+rising*0.14-falling*0.04 if side=="near" else 0.08-rising*0.15
	elif resting:
		value.ankle=Vector2(10,-10) if side=="near" else Vector2(-10,-10)
		value.pitch=0.0
	if g.dash_timer>0:
		value.ankle=Vector2(-25,-10) if side=="far" else Vector2(15,-23)
		value.pitch=-0.18 if side=="far" else 0.12
	value.knee=g.gait_knee(hip(phase),value.ankle)
	return value

func arm_adjust(gun: bool, angle: float, bend: float) -> Vector2:
	var weight=swing_weight()
	if gun:
		# The cannon lowers during the swing; a shot never originates from an unrelated pose.
		return Vector2(lerp_angle(angle,-0.35,weight),lerpf(bend,0.45,weight))
	var p=swing_progress()
	var hand=-1.9
	var fold=0.8
	if g.saber_kind=="dash":
		hand=lerpf(-0.75,-0.03,smoothstep(0,0.4,p)); fold=0.12
	elif g.saber_kind=="air":
		hand=-2.1+TAU*p; fold=0.26
	else:
		hand=lerpf(-2.0,0.7,smoothstep(0,1,p)); fold=lerpf(0.75,0.15,sin(p*PI))
	var part=g.motion_meta.rig.free_arm
	var axis=(Vector2(part.end[0],part.end[1])-Vector2(part.origin[0],part.origin[1])).angle()
	var target=hand-axis+fold*0.5
	weight=maxf(weight,prepared_entry())
	if g.saber_charge>0 and g.saber_time<=0:
		target=-2.0-axis+0.5
		weight=charge_weight()
		fold=0.95
	return Vector2(lerp_angle(angle,target,weight),lerpf(bend,fold,weight))

func sword_angle() -> float:
	if g.saber_time<=0: return -1.85
	var p=swing_progress()
	if g.saber_kind=="dash": return lerpf(-0.2,0.04,smoothstep(0,0.4,p))
	if g.saber_kind=="air": return -2.4+TAU*p
	return lerpf(-2.0,1.1,smoothstep(0,1,p))

func sword_pose(at: Vector2, phase: float) -> Dictionary:
	var arm=g.walk_arm(phase,false)
	var hand=at+Vector2(arm.muzzle.x*g.facing,arm.muzzle.y)
	var local=Vector2.RIGHT.rotated(sword_angle())
	var direction=Vector2(local.x*g.facing,local.y)
	var length=76.0+g.saber_tier*55.0
	if g.saber_time<=0: length=76.0
	return {"hand":hand,"direction":direction,"length":length,"tip":hand+direction*length}

func draw_weapon(at: Vector2, phase: float):
	if g.saber_time<=0 and g.saber_charge<=0: return
	var pose=sword_pose(at,phase)
	var scale=blade_scale
	var region=weapon_region
	if weapon:
		var tint=Color(g.rig_tint,g.rig_tint.a*maxf(maxf(swing_weight(),charge_weight()),prepared_entry()))
		g.draw_set_transform(pose.hand,pose.direction.angle()+PI/2)
		# The hilt keeps its size; only the energy blade grows with charge.
		var upper=(guard_y-grip.y)*scale
		g.draw_texture_rect_region(weapon,Rect2((region.position.x-grip.x)*scale,upper,region.size.x*scale,(region.end.y-guard_y)*scale),Rect2(region.position.x,guard_y,region.size.x,region.end.y-guard_y),tint)
		g.draw_texture_rect_region(weapon,Rect2((region.position.x-grip.x)*scale,-pose.length,region.size.x*scale,pose.length+upper),Rect2(region.position,Vector2(region.size.x,guard_y-region.position.y)),tint)
		g.draw_set_transform(Vector2.ZERO)
	else: g.draw_line(pose.hand,pose.tip,g.CYAN,4)

func draw_effects(offset: Vector2):
	var col=Color("ffe291") if g.saber_tier==2 else (Color("b8ffeb") if g.saber_tier==1 else g.CYAN)
	if g.saber_charge>0:
		var pose=sword_pose(g.player+offset,g.walk_phase)
		var tier=2 if g.saber_charge>=g.FULL_CHARGE-0.001 else (1 if g.saber_charge>=0.8 else 0)
		var charge_col=Color("ffe291") if tier==2 else (g.CYAN if tier==1 else g.PINK)
		g.draw_arc(pose.hand,14+g.saber_charge*6,g.clock*4,g.clock*4+TAU*g.saber_charge/g.FULL_CHARGE,32,charge_col,2+tier)
		if tier>0: g.draw_circle(pose.hand,22+sin(g.clock*14)*3,Color(charge_col,0.16))
	if not g.saber_active(): return
	var center=g.player+offset-Vector2(0,55)
	var r=g.saber_reach()-10
	if g.saber_kind=="dash":
		var start=center+Vector2(g.saber_facing*26,-16)
		g.draw_line(start,start+Vector2(g.saber_facing*(r-20),0),Color(col,0.28),15+g.saber_tier*5)
		g.draw_line(start,start+Vector2(g.saber_facing*(r-20),0),Color(col,0.8),3)
	else:
		var angle=sword_angle()
		if g.saber_facing<0: angle=PI-angle
		var span=0.75+g.saber_tier*0.15
		g.draw_arc(center,r,angle-span if g.saber_facing>0 else angle,angle if g.saber_facing>0 else angle+span,32,Color(col,0.23),14+g.saber_tier*4)
		g.draw_arc(center,r,angle-span if g.saber_facing>0 else angle,angle if g.saber_facing>0 else angle+span,32,Color(col,0.85),3)
