extends SceneTree
var game
var held = {}
var ticks = 0
var jump_age = -1
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
	press(KEY_RIGHT,game.player.x<target-8)
	press(KEY_LEFT,game.player.x>target+8)
	press(KEY_X,true)
	press(KEY_SPACE,jump)
	game.invincible=999 # isolate route/combat reachability from damage balancing
	game.update_game(1.0/60)
	ticks+=1
func run():
	game=load("res://game.gd").new()
	root.add_child(game)
	game.muted=true
	game.set_process(false)
	game.set_physics_process(false)
	game.start_game()
	var failures=[]
	for room in range(24):
		var complete=false
		for t in range(2400):
			var target=room*1120.0+1090
			var jump=false
			var enemy=null
			for e in game.enemies:
				if e.room==room and e.hp>0:
					enemy=e
					break
			if enemy!=null:
				target=enemy.p.x-150
				jump=enemy.kind==1
			else:
				for c in game.cores:
					if c.room==room and not c.got:
						target=c.p.x
						jump=true
			var local=game.player.x-room*1120
			if local>660 and local<930 and room>1 and room%4!=0: jump=true
			if jump and game.grounded and jump_age<0: jump_age=0
			var pulse=false
			if jump_age>=0:
				pulse=(jump_age<22 or (jump_age>=25 and jump_age<47))
				jump_age+=1
				if jump_age>=55: jump_age=-1
			step(target,pulse)
			if game.state=="dead":
				failures.append("fall room %d at %s"%[room,game.player])
				break
			if game.player.x>=room*1120+1060:
				complete=true
				break
		if not complete:
			failures.append("room %d blocked at %s"%[room,game.player])
			break
		print("ROOM ",room+1," PASS / t=",int(ticks/60)," cores=",game.core_count)
	if failures.is_empty():
		for t in range(7200):
			if game.player.x < game.BOSS_X+325:
				step(game.BOSS_X+350,false)
			else:
				press(KEY_LEFT,false)
				press(KEY_RIGHT,t%120==0)
				press(KEY_SPACE,false)
				press(KEY_X,true)
				game.invincible=999
				game.update_game(1.0/60)
				ticks+=1
			if game.state=="clear": break
		if game.state!="clear": failures.append("boss not cleared")
	for code in held.keys(): press(code,false)
	print("ROUTE TEST: ","PASS" if failures.is_empty() else "FAIL"," ",failures," ticks=",ticks," seconds=",ticks/60," kills=",game.kills," cores=",game.core_count)
	await process_frame
	quit(0 if failures.is_empty() else 1)



