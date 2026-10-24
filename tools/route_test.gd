extends SceneTree
var game
var held = {}
var ticks = 0
var jump_age = -1
var charging = false
var aim_dir = 1
var dropping = false
func _initialize():
	call_deferred("run")
func press(code:int, down:bool):
	if held.get(code,false)==down: return
	held[code]=down
	var e=InputEventKey.new()
	e.physical_keycode=code
	e.keycode=code
	e.pressed=down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func step(target:float, jump:bool):
	var error=target-game.player.x
	if game.field_area()==5 and not game.grounded: error-=game.velocity.x*absf(game.velocity.x)/(2*650.0)
	press(KEY_RIGHT,error>25 or (absf(error)<=25 and game.facing!=aim_dir and aim_dir>0))
	press(KEY_LEFT,error< -25 or (absf(error)<=25 and game.facing!=aim_dir and aim_dir<0))
	press(KEY_X,ticks%8<4 and not charging) # tap fire; holding now charges
	press(KEY_V,charging)
	var fastfall=game.field_area()==5 and not game.grounded and not jump and game.velocity.y>=0 and absf(target-game.player.x)<90 and game.on_ground(game.player.x,610)
	press(KEY_DOWN,dropping or fastfall)
	press(KEY_SPACE,jump or (dropping and ticks%2==0))
	game.invincible=999 # isolate route/combat reachability from damage balancing
	game.update_game(1.0/60)
	ticks+=1
func run():
	game=load("res://game.gd").new()
	root.add_child(game)
	game.muted=true
	game.set_process(false)
	game.set_physics_process(false)
	game.fixed_seed=true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="): game.run_seed=arg.trim_prefix("--seed=").to_int()
		if arg=="--danmaku": game.danmaku=true
	game.start_game()
	var failures=[]
	for room in range(24):
		var complete=false
		var waypoint=0
		var crossing=false
		for t in range(4200):
			var target=room*1120.0+1090
			var jump=false
			dropping=false
			var enemy=null
			for e in game.enemies:
				if e.room==room and e.hp>0:
					enemy=e
					break
			if enemy!=null:
				target=enemy.p.x-150
				aim_dir=1
				if not game.on_ground(target-35,610) or not game.on_ground(target+35,610):
					var alternate=enemy.p.x+150
					if game.on_ground(alternate-35,610) and game.on_ground(alternate+35,610):
						target=alternate
						aim_dir=-1
				jump=enemy.p.y<game.player.y-65
				dropping=enemy.p.y>game.player.y+65 and game.grounded
				charging=enemy.get("shield",false) and t%75<58
			else:
				charging=false
				for c in game.cores:
					if c.room==room and not c.got:
						var path=game.layout[room].core_path
						if waypoint<path.size():
							var point=path[waypoint]
							target=room*1120.0+point[0]
							if absf(game.player.x-target)<55 and absf(game.player.y-point[1])<12 and game.grounded: waypoint+=1
						else: target=c.p.x
						jump=true
				# Doors that open by switch or by charged shots.
				var door=game.gate_of(room)
				var core_done=true
				for c in game.cores:
					if c.room==room and not c.got: core_done=false
				if door.has("x") and not door.open and core_done:
					if door.kind=="switch":
						target=door.x-170
						aim_dir=1
						jump=true
					elif door.kind=="break":
						target=door.x-260
						aim_dir=1
						charging=t%75<58
			var floors=game.layout[room].floor
			if floors.size()>1:
				var left_edge=room*1120+floors[0][0]+floors[0][1]
				var right_edge=room*1120+floors[1][0]
				if target>left_edge-20 and target<right_edge+20:
					target=right_edge+45 if enemy!=null and enemy.p.x>=right_edge else left_edge-60
			var local=game.player.x-room*1120
			for span in game.layout[room].jump_ranges:
				if local>span[0] and local<span[1]: jump=true
			if floors.size()>1:
				var edge=room*1120+floors[0][0]+floors[0][1]
				var exit_x=room*1120+floors[1][0]
				if target>edge and game.player.x<exit_x+25:
					if not crossing and game.player.x>edge-170:
						if not game.grounded:
							target=edge-95
							jump=false
							jump_age=-1
						elif game.player.x>=edge-60:
							crossing=true
							jump_age=0
						else: jump=false
					if crossing: target=exit_x+65
				elif game.player.x>=exit_x+25: crossing=false
			if jump and game.grounded and jump_age<0: jump_age=0
			var pulse=false
			if jump_age>=0:
				pulse=(jump_age<22 or (jump_age>=25 and jump_age<47))
				jump_age+=1
				if jump_age>=55: jump_age=-1
			step(target,pulse)
			if game.state=="dead" or game.falls>0:
				failures.append("fall room %d at %s"%[room,game.player])
				break
			if game.player.x>=room*1120+1060:
				complete=true
				break
		if not complete:
			var left=[]
			for e in game.enemies:
				if e.room==room and e.hp>0: left.append([e.kind,e.p,e.hp])
			failures.append("room %d blocked at %s enemies=%s"%[room,game.player,left])
			break
		print("ROOM ",room+1," PASS / t=",int(ticks/60)," cores=",game.core_count)
	if failures.is_empty():
		charging=false
		press(KEY_V,false)
		for t in range(12000):
			if game.player.x<game.BOSS_X+150:
				step(game.BOSS_X+350,false)
			else:
				var direction=1 if game.boss_pos.x>game.player.x else -1
				press(KEY_LEFT,direction<0 and game.facing!=direction)
				press(KEY_RIGHT,direction>0 and game.facing!=direction)
				press(KEY_SPACE,false)
				press(KEY_X,ticks%8<4)
				game.invincible=999
				game.update_game(1.0/60)
				ticks+=1
			if game.state=="clear": break
		if game.state!="clear": failures.append("boss not cleared")
		for door in game.gates:
			if not door.passed or door.open: failures.append("door %d was not sealed after crossing"%door.room)
		var minibosses=0
		for enemy in game.enemies:
			if enemy.kind==6:
				minibosses+=1
				if enemy.hp>0: failures.append("miniboss alive after clear")
		if minibosses!=1: failures.append("expected one mandatory miniboss")
	for code in held.keys(): press(code,false)
	print("ROUTE TEST: ","PASS" if failures.is_empty() else "FAIL"," ",failures," seed=",game.run_seed," ticks=",ticks," seconds=",ticks/60," kills=",game.kills," cores=",game.core_count," score=",game.score," max_combo=",game.max_combo)
	await process_frame
	quit(0 if failures.is_empty() else 1)
