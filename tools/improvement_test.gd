extends SceneTree
var game
var failures: Array[String]=[]

func _initialize(): call_deferred("run")
func check(ok: bool, note: String):
	if not ok: failures.append(note)

func fresh():
	game.fixed_seed=true
	game.start_game()
	game.enemies.clear()
	game.bullets.clear()
	game.player=Vector2(180,610)
	game.grounded=true

func run():
	game=load("res://game.gd").new()
	root.add_child(game)
	game.muted=true
	game.set_process(false)
	game.set_physics_process(false)
	fresh()
	check(game.environment_art.size()==5,"all five GPTImage atlases loaded")
	check(game.environment_art.doors.regions.size()==4 and game.environment_art.devices.regions.size()==3,"door/device frames")
	check(game.bgm.stage.get_length()>30 and game.bgm.boss.get_length()>30,"provided MP3 tracks decode")
	check(game.bgm.stage.loop and game.bgm.boss.loop,"MP3 loops enabled")
	print("BGM lengths: Heroic Quest=",game.bgm.stage.get_length()," Untitled=",game.bgm.boss.get_length())
	game.spawn_enemy(Vector2(400,600),0,0)
	var first=game.enemies[-1]
	first.hp=0
	game.register_enemy_defeat(first)
	check(game.score==100 and game.combo==1,"first kill scoring")
	game.register_enemy_defeat(first)
	check(game.score==100 and game.kills==1,"kill cannot be scored twice")
	game.spawn_enemy(Vector2(450,400),1,0)
	game.enemies[-1].hp=0
	game.register_enemy_defeat(game.enemies[-1])
	check(game.score==265 and game.combo==2 and game.max_combo==2,"combo multiplier")
	game.combo_timer=0
	game.spawn_enemy(Vector2(500,600),2,0)
	game.enemies[-1].hp=0
	game.register_enemy_defeat(game.enemies[-1])
	check(game.combo==1 and game.score==465,"expired combo resets")
	game.hurt(2)
	game.hurt(2)
	check(game.combo==0 and game.damage_taken==2,"accepted damage resets combo once")

	fresh()
	game.saber_time=0.26
	game.saber_facing=1
	game.enemy_shot(game.player+Vector2(70,-60),Vector2.ZERO)
	game.update_bullets(0)
	check(game.bullets.size()==1 and game.bullets[0].get("reflected",false),"actual reflection tags projectile")
	check(game.score==100 and game.parry_marks.size()==1,"just reflection reward and effect")
	game.boss_active=true
	game.boss_intro=0
	game.boss_pos=Vector2(700,540)
	game.boss_hp=100
	game.bullets[0].p=game.boss_pos-Vector2(0,60)
	game.update_bullets(0)
	check(game.boss_hp==94 and game.score==250,"reflected final boss hit deals six and awards bonus")
	game.bullets.append({"p":game.boss_pos-Vector2(0,60),"v":Vector2.ZERO,"enemy":false,"damage":4,"r":5.0,"life":1.0})
	game.update_bullets(0)
	check(game.boss_hp==90,"ordinary four-damage shot is not doubled")

	fresh()
	var base=11*game.ROOM
	game.player=Vector2(base+400,610)
	game.camera_x=base+100
	game.invincible=999
	game.spawn_enemy(Vector2(base+820,600),6,11)
	var mini=game.enemies[-1]
	for core in game.cores:
		if core.room==11: core.got=true;core.sync=0
	check(not game.door_ready(game.gate_of(11)),"live miniboss holds exit closed")
	game.update_music_state()
	check(game.music_track=="boss","miniboss selects Untitled")
	mini.mode="tell";mini.mt=0.01;mini.cycle=0
	game.update_miniboss(mini,0.02)
	check(game.bullets.size()==3,"miniboss aimed spread")
	game.bullets.clear()
	mini.mode="tell";mini.mt=0.01;mini.cycle=1
	game.update_miniboss(mini,0.02)
	var old_x=mini.p.x
	game.update_miniboss(mini,0.1)
	check(mini.mode=="rush" and mini.p.x<old_x,"telegraphed miniboss rush")
	mini.mode="tell";mini.mt=0.01;mini.cycle=2
	game.update_miniboss(mini,0.02)
	check(game.bullets.size()==2 and game.bullets[0].solid and game.bullets[1].solid,"miniboss floor shockwaves")
	game.bullets.clear()
	game.bullets.append({"p":mini.p-Vector2(0,60),"v":Vector2.ZERO,"enemy":false,"reflected":true,"damage":4,"r":5.0,"life":1.0})
	game.update_bullets(0)
	check(mini.hp==104,"reflected miniboss damage doubled")
	mini.hp=0
	game.register_enemy_defeat(mini)
	game.spawn_enemy(Vector2(base+250,600),0,11)
	check(game.door_ready(game.gate_of(11)) and game.score>=2000,"miniboss defeat unlocks exit and scores")
	game.update_music_state()
	check(game.music_track=="stage","miniboss defeat returns Heroic Quest")
	game.boss_active=true
	game.update_music_state()
	check(game.music_track=="boss","final boss selects Untitled")
	check(not game.music.playing,"muted track switches do not start audio")

	fresh()
	game.player=Vector2(20*game.ROOM+100,400)
	game.grounded=false
	game.velocity=Vector2(285,0)
	game.invincible=999
	game.update_game(0.1)
	check(absf(game.velocity.x-220)<0.1,"low gravity preserves horizontal momentum")
	game.velocity=Vector2.ZERO
	game.test_key(KEY_DOWN,true)
	game.update_game(0.1)
	game.test_key(KEY_DOWN,false)
	check(game.velocity.y>=290,"down input accelerates descent")
	game.elapsed=0
	game.player.y=220
	game.velocity.y=-200
	game.update_field(0)
	check(game.player.y==244 and game.velocity.y==0,"ceiling contains low gravity jumps")
	game.elapsed=4.5
	game.player.y=220
	game.invincible=0
	game.hp=12
	game.update_field(0)
	check(game.hp==10 and game.velocity.y==260,"energized ceiling hurts and pushes downward")

	fresh()
	game.elapsed=500;game.max_combo=4
	check(game.clear_rank()=="S","S rank performance")
	game.damage_taken=12
	check(game.clear_rank()=="A","A rank performance")
	game.damage_taken=30
	check(game.clear_rank()=="B","B rank performance")
	game.deaths=4
	check(game.clear_rank()=="C","C rank performance")
	game.deaths=0;game.damage_taken=0;game.score=50000;game.best_score=0
	game.record_path="res://test-output/records-test.cfg"
	game.fixed_seed=false
	game.reward_clear()
	var clear_score=game.score
	game.reward_clear()
	check(clear_score==53500 and game.score==clear_score,"clear/no-damage rewards awarded once")
	var record=ConfigFile.new()
	check(record.load(game.record_path)==OK and record.get_value("records","score",0)==53500,"best score persists to file")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.record_path))
	print("IMPROVEMENT TEST: ","PASS" if failures.is_empty() else "FAIL"," ",failures)
	await process_frame
	quit(0 if failures.is_empty() else 1)
