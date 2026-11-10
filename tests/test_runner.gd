extends Node
## Headless test runner. Runs as a scene so autoloads exist (scripts run with
## --script compile before autoloads are registered).
##
##   godot --headless --path . res://tests/test_runner.tscn                  # everything
##   godot --headless --path . res://tests/test_runner.tscn -- unit m2_combat # some
##
## Exits 0 when all pass, 1 otherwise. Each integration test has a time limit, so a
## broken test fails instead of hanging.

const INTEGRATION: Array[String] = ["m0_smoke", "m1_movement", "m2_combat"]
const UNIT_DIR: String = "res://tests/unit/"
const TIME_LIMIT_SEC: float = 60.0

var _failed: int = 0


func _ready() -> void:
	var wanted := OS.get_cmdline_user_args()
	if wanted.is_empty():
		wanted = PackedStringArray(["unit"] + INTEGRATION)
	for name in wanted:
		if name == "unit":
			_run_unit_tests()
		else:
			await _run_integration(name)
	print("\n%s" % ("ALL TESTS PASSED" if _failed == 0 else "%d TEST(S) FAILED" % _failed))
	get_tree().quit(0 if _failed == 0 else 1)


func _run_unit_tests() -> void:
	var dir := DirAccess.open(UNIT_DIR)
	for file in dir.get_files():
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var test: TestCase = load(UNIT_DIR + file).new()
		for method in test.get_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			test.failures.clear()
			test.call(method_name)
			_report("%s.%s" % [file.get_basename(), method_name], test.failures)


func _run_integration(name: String) -> void:
	var path := "res://tests/%s.gd" % name
	if not ResourceLoader.exists(path):
		_report(name, ["no such test: " + path])
		return
	var test: IntegrationTest = load(path).new()
	add_child(test)
	var timer := get_tree().create_timer(TIME_LIMIT_SEC, true, false, true)
	timer.timeout.connect(func() -> void: test.fail("timed out after %ds" % TIME_LIMIT_SEC); test.finish())
	await test.finished
	_report(name, test.failures)
	test.queue_free()
	Engine.time_scale = 1.0
	await get_tree().process_frame


func _report(label: String, failures: Array[String]) -> void:
	if failures.is_empty():
		print("  ok    ", label)
		return
	_failed += 1
	print("  FAIL  ", label)
	for f in failures:
		print("          - ", f)
