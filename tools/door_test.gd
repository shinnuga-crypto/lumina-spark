extends SceneTree

var game
var failures: Array[String] = []

func _initialize():
	call_deferred("run")

func check(ok: bool, message: String):
	if not ok: failures.append(message)

func open_fixture() -> Dictionary:
	game.start_game()
	var door = game.gates[0]
	for core in game.cores:
		if core.room==door.room: core.got=true; core.sync=0
	for enemy in game.enemies:
		if enemy.room==door.room: enemy.hp=0
	game.player=Vector2(door.x-100,610)
	game.velocity=Vector2.ZERO
	game.grounded=true
	for i in range(60): game.update_doors(1.0/60,game.player)
	return door

func run():
	game=load("res://game.gd").new()
	root.add_child(game)
	game.muted=true
	game.fixed_seed=true
	game.set_process(false)
	game.set_physics_process(false)
	game.start_game()
	var door=game.gates[0]
	game.player=Vector2(door.x+80,610)
	game.update_doors(0.016,Vector2(door.x-80,610))
	check(not door.open and game.player.x<=door.x-44,"closed wall stops a swept crossing")

	door=open_fixture()
	check(door.open and door.lift==1 and not door.passed,"unlock opens the passage")
	check(game.door_between(door.x-80,door.x+80,200),"upper wall remains solid")
	check(not game.door_between(door.x-80,door.x+80,550),"open lower passage is clear")
	game.player=Vector2(door.x+80,400)
	game.update_doors(0,Vector2(door.x-80,400))
	check(game.player.x<=door.x-44 and not door.passed,"jumping above the passage cannot bypass wall")
	game.player=Vector2(door.x+10,610)
	game.update_doors(0,Vector2(door.x-60,610))
	check(not door.passed and game.player.x==door.x+10,"partial crossing does not close on player")
	game.player=Vector2(door.x-60,610)
	game.update_doors(0,Vector2(door.x+10,610))
	check(door.open and not door.passed,"backing out before clearing is allowed")
	game.player=Vector2(door.x+60,610)
	game.update_doors(0,Vector2(door.x-60,610))
	check(door.passed and not door.open and game.player.x==door.x+60,"full swept crossing latches behind player")
	check(game.safe_pos.x>door.x+44,"fall recovery stays on destination side")
	game.player=Vector2(door.x-100,610)
	game.velocity=Vector2(-720,0)
	game.update_doors(0.1,Vector2(door.x+60,610))
	check(game.player.x>=door.x+44 and game.velocity.x==0,"return blocked from right")
	for i in range(60): game.update_doors(1.0/60,game.player)
	check(door.lift==0 and not game.door_ready(door),"closed passed door never reopens")
	check(game.door_between(door.x-80,door.x+80,550),"locked doorway also blocks bullets")

	# Actual left + dash + jump input must not cross a latched wall.
	game.player=Vector2(door.x+80,610)
	game.grounded=true
	game.invincible=999
	game.test_key(KEY_LEFT,true)
	game.test_key(KEY_SHIFT,true)
	game.test_key(KEY_SPACE,true)
	for i in range(60):
		game.update_game(1.0/60)
		check(game.player.x>=door.x+44,"dash/jump cannot return through lock")
	for key in [KEY_LEFT,KEY_SHIFT,KEY_SPACE]: game.test_key(key,false)
	game.invincible=0
	game.hurt(99)
	game.checkpoint=0 # Even a stale checkpoint must not send Lumina behind a sealed door.
	game.respawn()
	check(game.player.x>=game.backtrack_limit() and door.passed,"death/respawn retains one-way progress")

	# A muzzle extending through a closed wall cannot create shots behind it.
	game.start_game()
	door=game.gates[0]
	game.player=Vector2(door.x-44,610)
	game.camera_x=door.x-400
	game.grounded=true
	game.facing=1
	game.shoot(false)
	check(game.bullets[0].p.x<door.x,"close-range muzzle stays on near side")
	game.update_bullets(0.15)
	check(game.bullets.is_empty(),"close-range shot cannot bypass closed wall")

	door=open_fixture()
	game.camera_x=door.x-400
	game.enemy_shot(Vector2(door.x-80,200),Vector2(860,0))
	game.update_bullets(0.2)
	check(game.bullets.is_empty(),"header blocks projectile above opening")
	game.enemy_shot(Vector2(door.x-80,550),Vector2(860,0))
	game.update_bullets(0.2)
	check(game.bullets.size()==1,"projectile fits through open passage")
	game.start_game()
	check(not game.gates[0].passed and not game.gates[0].entered,"new run resets doorway latches")
	door=game.gates[0]
	door.passed=true
	game.player=Vector2(door.x+80,610)
	game.camera_x=door.x-400
	game.enemies.clear()
	game.spawn_enemy(Vector2(door.x-60,600),0,door.room)
	game.enemies[0].t=PI/(2*1.4)-0.016
	game.update_enemies(0.016)
	check(game.enemies[0].p.x<=door.x-54,"patrolling enemies cannot slip through closed door")
	game.enemies.clear()
	game.spawn_enemy(Vector2(door.x-100,400),1,door.room)
	game.enemies[0].burst=2
	game.enemies[0].bt=0
	game.update_enemies(0.016)
	check(game.bullets.is_empty(),"queued enemy volley stops behind closed door")
	game.enemies.clear()
	game.spawn_enemy(Vector2(door.x-30,600),0,door.room)
	game.enemies[0].hp=20
	game.player=Vector2(door.x+44,610)
	game.saber_time=0.21
	game.saber_facing=-1
	game.saber_hits.clear()
	game.update_saber()
	check(game.enemies[0].hp==20,"saber cannot damage through a sealed wall")
	print("DOOR TEST: ","PASS" if failures.is_empty() else "FAIL"," ",failures)
	await process_frame
	quit(0 if failures.is_empty() else 1)
