extends SceneTree
var g
var errors: Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok: bool, note: String):
	if not ok: errors.append(note)
func button(code: int, down: bool):
	var event=InputEventJoypadButton.new(); event.device=0; event.button_index=code; event.pressed=down
	Input.parse_input_event(event); Input.flush_buffered_events()
func trigger(value: float):
	var event=InputEventJoypadMotion.new(); event.device=0; event.axis=JOY_AXIS_TRIGGER_RIGHT; event.axis_value=value
	Input.parse_input_event(event); Input.flush_buffered_events()
func run():
	g=load("res://game.gd").new(); root.add_child(g); g.muted=true; g.set_process(false); g.set_physics_process(false)
	g.state="play"; g.reset_bindings()
	g.bind_pad("jump",JOY_BUTTON_RIGHT_STICK,1)
	for code in [JOY_BUTTON_A,JOY_BUTTON_RIGHT_STICK]:
		button(code,true); check(g.act("jump"),"multiple jump buttons work "+str(code)); button(code,false)
	g.bind_pad("fire",JOY_BUTTON_LEFT_SHOULDER,3)
	check(g.pad_binds.fire==[JOY_BUTTON_X,JOY_BUTTON_Y,g.PAD_RT,JOY_BUTTON_LEFT_SHOULDER],"adding fourth slot preserves first three")
	for code in [JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_LEFT_SHOULDER]:
		button(code,true); check(g.act("fire"),"each mapped button fires "+str(code)); button(code,false)
	trigger(0.9); check(g.act("fire"),"mapped RT fires"); trigger(0)
	g.clear_pad_slot("fire",1)
	check(g.pad_binds.fire==[JOY_BUTTON_X,-1,g.PAD_RT,JOY_BUTTON_LEFT_SHOULDER],"clearing middle slot preserves slot positions")
	button(JOY_BUTTON_Y,true); check(not g.act("fire"),"removed button does not fire"); button(JOY_BUTTON_Y,false)
	g.clear_pad_slot("fire",2); trigger(0.9); check(not g.act("fire"),"removed RT does not fire implicitly"); trigger(0)
	g.bind_pad("saber",JOY_BUTTON_LEFT_SHOULDER,1)
	check(g.pad_slot("fire",3)==-1 and g.pad_slot("saber",0)==JOY_BUTTON_RIGHT_SHOULDER and g.pad_slot("saber",1)==JOY_BUTTON_LEFT_SHOULDER,"moving button to another function preserves unrelated slots")
	g.bind_pad("saber",JOY_BUTTON_RIGHT_SHOULDER,2)
	check(g.pad_slot("saber",0)==-1 and g.pad_slot("saber",2)==JOY_BUTTON_RIGHT_SHOULDER,"same button occupies only one slot")
	var path="user://pad-slot-test-%d.cfg"%Time.get_ticks_usec()
	var snapshot=g.settings_config(); check(snapshot.save(path)==OK,"write settings fixture")
	var loaded=ConfigFile.new(); check(loaded.load(path)==OK,"load settings fixture")
	g.reset_bindings(); g.apply_settings_config(loaded)
	check(g.pad_binds.fire==[JOY_BUTTON_X] and g.pad_binds.saber==[-1,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER],"save/load preserves holes and deliberate RT removal")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var legacy=ConfigFile.new(); legacy.set_value("pad","fire",[JOY_BUTTON_Y]); legacy.set_value("audio","bgm",3)
	g.apply_settings_config(legacy)
	check(g.pad_binds.fire==[JOY_BUTTON_Y,g.PAD_RT] and g.bgm_level==3,"legacy settings preserve configured buttons plus old RT default")
	legacy.set_value("pad","dash",[g.PAD_RT]); g.apply_settings_config(legacy)
	check(not g.PAD_RT in g.pad_binds.fire and g.PAD_RT in g.pad_binds.dash,"legacy RT assigned elsewhere does not also fire")
	g.reset_bindings(); g.state="title"; g.using_pad=true; g.open_settings()
	g.settings_index=g.settings_rows().find("fire"); g.settings_column=1
	for i in range(3): g.settings_activate(1)
	check(g.settings_column==4,"controller navigation reaches fourth slot")
	g.settings_activate()
	var axis=InputEventJoypadMotion.new(); axis.axis=JOY_AXIS_TRIGGER_LEFT; axis.axis_value=0.9
	g.settings_input(axis)
	check(g.pad_slot("fire",3)==g.PAD_LT and g.rebinding=="","trigger event binds selected slot")
	var clear=InputEventJoypadButton.new(); clear.button_index=JOY_BUTTON_X; clear.pressed=true; g.settings_input(clear)
	check(g.pad_slot("fire",3)==-1,"X clears focused slot")
	g.settings_column=0; g.settings_activate(); var key=InputEventKey.new(); key.physical_keycode=KEY_H; key.pressed=true; g.settings_input(key)
	check(g.key_binds.fire==[KEY_H],"keyboard mapping remains separate")
	print("CONTROL SLOTS TEST: ","PASS" if errors.is_empty() else "FAIL"," ",errors)
	quit(0 if errors.is_empty() else 1)
