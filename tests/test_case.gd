class_name TestCase
extends RefCounted
## Base for unit tests. Methods named test_* are run by tests/test_runner.gd.

var failures: Array[String] = []


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [message, str(expected), str(actual)])


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append("%s expected true" % message)


func assert_near(actual: float, expected: float, epsilon: float, message: String = "") -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s expected %s +/- %s, got %s" % [message, expected, epsilon, actual])
