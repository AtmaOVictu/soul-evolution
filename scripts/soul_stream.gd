extends RefCounted
class_name SoulStream

## The player's persistent consciousness — a field that excites into particles (souls).
## "In particle physics, particles are excitations of a field."
## The stream persists; the bodies die.

var stream_id: int = 0
var incarnations: int = 0
var memory_fragments: Array[Dictionary] = []  # [{body_id, genome_summary, story_line, cause_of_death}]
var current_body: RefCounted = null  # the active SoulGenome


## Called when the stream incarnates into a new body.
func incarnate(new_body: RefCounted) -> void:
	if current_body and current_body.capacity_current <= 0:
		_write_memory(current_body)
	current_body = new_body
	incarnations += 1
	# Influence the new body with the stream's accumulated memory
	_apply_stream_memory(new_body)


## Write a memory fragment from a dying body.
func _write_memory(body: RefCounted) -> void:
	var cause_text := "unknown"
	if body.story_lines.size() > 0:
		cause_text = body.story_lines[body.story_lines.size() - 1]
	var fragment := {
		"body_id": body.soul_id,
		"incarnation": incarnations,
		"cause": cause_text,
		"psi": body.psi,
		"skulls": body.skulls,
		"story_line": "incarnation #%d — body #%d fell." % [incarnations, body.soul_id],
	}
	memory_fragments.append(fragment)


## Apply the stream's accumulated memory to a new body.
func _apply_stream_memory(body: RefCounted) -> void:
	# Each past incarnation slightly boosts the genome (the field remembers)
	var boost: float = clampf(float(incarnations) * 0.005, 0.0, 0.15)
	body.divergence = minf(body.divergence + boost, 1.0)
	body.negation = minf(body.negation + boost, 1.0)
	body.delta = minf(body.delta + boost, 1.0)
	body.trace = minf(body.trace + boost, 1.0)
	body._compute_abilities()
	body._compute_psi()
	body._compute_pools()
	body.capacity_current = body.capacity_max
	body.add_story("the stream incarnates — incarnation #%d" % incarnations)


func get_total_skulls() -> int:
	var total := 0
	for f in memory_fragments:
		total += f["skulls"]
	return total


func get_stream_status() -> String:
	return "incarnation #%d — %d souls fallen" % [incarnations, memory_fragments.size()]
