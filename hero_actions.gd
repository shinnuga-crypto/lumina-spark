extends RefCounted

# One skeleton keeps the same head/limb scale through aim, jumps and all saber styles.
var g
var weapon: Texture2D
var weapon_region=Rect2()
var grip=Vector2.ZERO
var guard_y=0.0
var blade_scale=0.1
# Set while drawing the slash trail to pose the sword at an earlier moment of the swing.
var progress_override=-1.0
# Charging holds the blade drawn back and low behind the body.
const CHARGE_HAND=2.35
const CHARGE_FOLD=0.4
const CHARGE_SWORD=2.75

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
	if progress_override>=0: return progress_override
	return clampf((swing_elapsed()-g.saber_startup)/maxf(0.01,g.saber_total-g.saber_startup-g.saber_recovery),0,1)

func swing_weight() -> float:
	if g.saber_time<=0: return 0.0
	return smoothstep(0,0.055,swing_elapsed())*smoothstep(0,g.saber_recovery,g.saber_time)

func charge_weight() -> float:
	return smoothstep(0,0.16,g.saber_charge)

# The blade snaps through the front of the arc and eases into the follow-through.
func strike_curve() -> float:
	return 1-pow(1-swing_progress(),5)

func run_factor() -> float:
	return clampf(absf(g.velocity.x)/285.0,0,1) if g.grounded else 0.0

# 0..1: how far a ground slash has stepped into its low lunge. Running keeps half of it.
func lunge() -> float:
	if g.saber_time<=0 or g.saber_kind!="ground" or not g.grounded: return 0.0
	return smoothstep(0,0.45,swing_progress())*swing_weight()*(1-run_factor()*0.5)

func prepared_entry() -> float:
	return g.saber_prepare_weight*(1-smoothstep(0,0.08,swing_elapsed())) if g.saber_time>0 else 0.0

func hip(phase: float) -> Vector2:
	var value=g.walk_hip(phase)
	if not g.grounded: value=Vector2(0,-51+clampf(-g.velocity.y/550.0,0,1)*2)
	if g.landing_time>0: value.y+=sin((1-g.landing_time/0.12)*PI)*4
	if g.grounded:
		# A ready stance: knees soft, a slow breath, lower again while charging and in the lunge.
		var still=1-run_factor()
		value.y+=(1.5+sin(g.clock*2.2)*0.8)*still+5*maxf(charge_weight(),prepared_entry())*still+9*lunge()
		value.x+=-2*still+6*lunge()
	# Dash: hips low and thrown forward over the front foot.
	if g.dash_timer>0: value=Vector2(6,-43)
	return value

func torso_angle() -> float:
	var base=g.walk_lean()
	if not g.grounded: base*=0.6
	# Dash: an extreme forward lean, chest leading.
	if g.dash_timer>0: base=0.72
	var twist=0.0
	if g.saber_kind=="dash": twist=0.22
	elif g.saber_kind=="air": twist=sin(swing_progress()*TAU)*0.16
	else: twist=lerpf(-0.2,0.4,strike_curve())
	var ready=0.05*(1-run_factor()) if g.grounded else 0.0
	return base+ready+twist*swing_weight()-maxf(charge_weight(),prepared_entry())*0.14

func leg(phase: float, side: String) -> Dictionary:
	var value=g.gait_leg(phase,side)
	var resting=absf(g.velocity.x)<15
	if not g.grounded:
		var rising=clampf(-g.velocity.y/550.0,0,1)
		var falling=clampf(g.velocity.y/700.0,0,1)
		# Knees pulled up like the drawn jump pose; the legs open toward the ground only when falling.
		var apex=Vector2(6,-31) if side=="near" else Vector2(-6,-27)
		var ascend=Vector2(9,-36) if side=="near" else Vector2(-2,-33)
		var descend=Vector2(14,-20) if side=="near" else Vector2(-13,-17)
		value.ankle=apex.lerp(ascend,rising).lerp(descend,falling)
		value.pitch=-0.1+rising*0.14-falling*0.04 if side=="near" else 0.08-rising*0.15
	elif resting:
		# Feet apart, front foot ahead: a fighter's stance instead of standing at attention.
		var wide=charge_weight()
		value.ankle=Vector2(16+6*wide,-10) if side=="near" else Vector2(-27-3*wide,-10)
		value.pitch=0.0
	var step=lunge()
	if step>0:
		# Ground slash: plant the front foot far forward and stretch the back leg, heel lifted.
		var target=Vector2(31,-10) if side=="near" else Vector2(-31,-13)
		value.ankle=value.ankle.lerp(target,step)
		value.pitch=lerpf(value.pitch,0.0 if side=="near" else 0.3,step)
	if g.dash_timer>0:
		# Back leg stretched out behind, toe driving off the ground; front knee driven up and forward.
		value.ankle=Vector2(-36,-12) if side=="far" else Vector2(20,-30)
		value.pitch=0.55 if side=="far" else -0.2
	value.knee=g.gait_knee(hip(phase),value.ankle)
	return value

func arm_adjust(gun: bool, angle: float, bend: float) -> Vector2:
	if g.dash_timer>0 and g.saber_time<=0 and g.saber_charge<=0:
		# Dash: arms flung back behind the lean unless the cannon is aiming.
		if not gun: return Vector2(1.35,0.45)
		if not g.walk_aiming(): return Vector2(0.75,0.35)
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
		# From behind the head, over the top, to a low forward finish.
		# After a charge the arc starts from the drawn-back pose and sweeps up over the shoulder.
		var drawn=g.saber_prepare_weight
		hand=lerpf(lerpf(-2.7,CHARGE_HAND-TAU,drawn),0.95,strike_curve()); fold=lerpf(lerpf(0.7,CHARGE_FOLD,drawn),0.2,smoothstep(0,0.6,p))
	var part=g.motion_meta.rig.free_arm
	var axis=(Vector2(part.end[0],part.end[1])-Vector2(part.origin[0],part.origin[1])).angle()
	var target=hand-axis+fold*0.5
	weight=maxf(weight,prepared_entry())
	if g.saber_charge>0 and g.saber_time<=0:
		# Charging draws the blade back and low behind the body.
		target=CHARGE_HAND-axis+CHARGE_FOLD*0.5
		weight=charge_weight()
		fold=CHARGE_FOLD
	return Vector2(lerp_angle(angle,target,weight),lerpf(bend,fold,weight))

func sword_angle() -> float:
	if g.saber_time<=0: return CHARGE_SWORD
	var p=swing_progress()
	if g.saber_kind=="dash": return lerpf(-0.2,0.04,smoothstep(0,0.4,p))
	if g.saber_kind=="air": return -2.4+TAU*p
	return lerpf(lerpf(-2.75,CHARGE_SWORD-TAU,g.saber_prepare_weight),1.2,strike_curve())

func sword_pose(at: Vector2, phase: float) -> Dictionary:
	var arm=g.walk_arm(phase,false)
	var hand=at+Vector2(arm.muzzle.x*g.facing,arm.muzzle.y)
	var local=Vector2.RIGHT.rotated(sword_angle())
	var direction=Vector2(local.x*g.facing,local.y)
	# The blade keeps its size; a full charge shows its reach through the afterimage instead.
	var length=g.saber_blade_length()
	if g.saber_time>0 and progress_override<0:
		# The beam ignites as the swing starts instead of hanging out at full length in the wind-up.
		length*=lerpf(0.35,1.0,smoothstep(0,g.saber_startup+0.02,swing_elapsed()))
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
	if g.action_art.draw_effects(offset): return
	var col=Color("ffe291") if g.saber_tier==2 else (Color("b8ffeb") if g.saber_tier==1 else g.CYAN)
	if g.saber_charge>0:
		var pose=sword_pose(g.player+offset,g.walk_phase)
		var tier=g.saber_charge_level()
		var charge_col=Color("ffe291") if tier==2 else (g.CYAN if tier==1 else g.PINK)
		g.draw_arc(pose.hand,14+g.saber_charge*6,g.clock*4,g.clock*4+TAU*g.saber_charge/g.FULL_CHARGE,32,charge_col,2+tier)
		if tier>0: g.draw_circle(pose.hand,22+sin(g.clock*14)*3,Color(charge_col,0.16))
	if not g.saber_seq.is_empty():
		draw_sweep(g.player+offset)
		return
	if g.saber_kind!="dash" and g.saber_time>0:
		draw_trail(g.player+offset,col)
		return
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

# A filled crescent swept by the blade: thick and bright at the leading edge, fading behind it,
# and lingering a moment into the follow-through.
func draw_trail(at: Vector2, col: Color):
	var p=swing_progress()
	if p<=0: return
	var fade=smoothstep(0,g.saber_recovery+0.04,g.saber_time)
	var span=(0.7 if g.saber_kind=="air" else 0.55)+g.saber_tier*0.08
	# No smear during the wind-up: the afterimage starts once the blade comes over the top.
	var start=maxf(1-pow(0.7,0.2),p-span)
	if p<=start: return
	var samples=14
	var inner: Array[Vector2]=[]
	var outer: Array[Vector2]=[]
	for i in range(samples+1):
		progress_override=lerpf(start,p,float(i)/samples)
		var pose=sword_pose(at,g.walk_phase)
		# Thickest in the middle of the arc, tapering to points at both ends: a crescent.
		var t=float(i)/samples
		# The afterimage reaches as far as the hit does, well past the blade on a full charge.
		var reach=maxf(pose.length+6,g.saber_reach()-14)
		var edge=pose.hand+pose.direction*reach
		inner.append(edge-pose.direction*reach*(0.06+0.55*sin(t*PI)*smoothstep(0,0.35,t)))
		outer.append(edge)
	progress_override=-1.0
	var white=Color(1,1,1)
	# Saturated body colour so the crescent reads as a solid slash, not a pale sheet.
	col=[Color("2ee6d6"),Color("46f5b4"),Color("ffcf3a")][g.saber_tier]
	for i in range(samples):
		var a0=pow(float(i)/samples,0.8)*fade
		var a1=pow(float(i+1)/samples,0.8)*fade
		g.draw_polygon(PackedVector2Array([inner[i],inner[i+1],outer[i+1],outer[i]]),PackedColorArray([Color(col,0.5*a0),Color(col,0.5*a1),Color(col,0.95*a1),Color(col,0.95*a0)]))
		# Bright rim along the path of the tip.
		var rim0=outer[i]+(inner[i]-outer[i])*0.35
		var rim1=outer[i+1]+(inner[i+1]-outer[i+1])*0.35
		g.draw_polygon(PackedVector2Array([rim0,rim1,outer[i+1],outer[i]]),PackedColorArray([Color(white,0.0),Color(white,0.0),Color(white,0.95*a1),Color(white,0.95*a0)]))

# The big front slash over the drawn frames: a crescent that grows along the swept arc,
# brightest at the leading edge, matching exactly the area that hits.
func draw_sweep(at: Vector2):
	var sweep=g.slash_sweep()
	if sweep.is_empty(): return
	var center=at-Vector2(0,55)
	var radius=g.saber_reach()
	var col=[Color("2ee6d6"),Color("46f5b4"),Color("ffcf3a")][g.saber_tier]
	var white=Color(1,1,1)
	var samples=16
	var points_in: Array[Vector2]=[]
	var points_out: Array[Vector2]=[]
	for i in range(samples+1):
		var t=float(i)/samples
		var angle=lerpf(sweep.from,sweep.to,t)
		var dir=Vector2(cos(angle)*g.saber_facing,sin(angle))
		# Thick in the middle of the stroke, tapering to a point at the tail.
		var thickness=radius*(0.1+0.55*sin(t*PI*0.5)*smoothstep(0,0.5,t))
		points_out.append(center+dir*radius)
		points_in.append(center+dir*(radius-thickness))
	for i in range(samples):
		var a0=pow(float(i)/samples,0.7)*sweep.fade
		var a1=pow(float(i+1)/samples,0.7)*sweep.fade
		g.draw_polygon(PackedVector2Array([points_in[i],points_in[i+1],points_out[i+1],points_out[i]]),PackedColorArray([Color(col,0.4*a0),Color(col,0.4*a1),Color(col,0.95*a1),Color(col,0.95*a0)]))
		var rim0=points_out[i].lerp(points_in[i],0.3)
		var rim1=points_out[i+1].lerp(points_in[i+1],0.3)
		g.draw_polygon(PackedVector2Array([rim0,rim1,points_out[i+1],points_out[i]]),PackedColorArray([Color(white,0.0),Color(white,0.0),Color(white,a1),Color(white,a0)]))
