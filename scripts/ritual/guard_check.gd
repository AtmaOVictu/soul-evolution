# guard_check.gd — The Guard evaluates the player's distinctions
#
# CL-036: Guard is the organism's immune system. It does NOT judge
# "correct" or "wrong". It checks: stability, scope, witness, responsibility.
#
# Checks:
#   1. Has distinction? (at least one distinction exists)
#   2. Has context? (at least one is scoped)
#   3. Has evidence? (at least one is witnessed)
#   4. Residual named? (if SEAL attempted, was ℜ named?)
#
# Results:
#   PASS             — all checks pass, SEAL available
#   MISSING_CONTEXT  — distinctions exist but none scoped
#   MISSING_EVIDENCE — distinctions exist but none witnessed
#   RESIDUAL_UNNAMED — SEAL attempted but no ℜ named
#   SEAL_BLOCKED     — cannot SEAL, residual must be named first
#
# The Guard is protective. It prevents the player from sealing incomplete work.
# It feels like the body refusing to close a wound that hasn't been cleaned.

extends Node

enum Result {
  PASS,
  MISSING_CONTEXT,
  MISSING_EVIDENCE,
  RESIDUAL_UNNAMED,
  SEAL_BLOCKED,
}

const RESULT_TEXT := {
  Result.PASS: "stable",
  Result.MISSING_CONTEXT: "unscoped",
  Result.MISSING_EVIDENCE: "unwitnessed",
  Result.RESIDUAL_UNNAMED: "residual unnamed",
  Result.SEALED_BLOCKED: "seal blocked",
}

static func evaluate() -> Dictionary:
  var distinctions := Events.get_all_distinctions()
  var has_distinction := distinctions.size() > 0
  var has_scoped := false
  var has_witnessed := false
  
  for d in distinctions:
    if is_instance_valid(d):
      if d.is_scoped:
        has_scoped = true
      if d.is_witnessed:
        has_witnessed = true
  
  var result: Result
  
  if not has_distinction:
    result = Result.MISSING_CONTEXT  # nothing to guard
  elif not has_scoped:
    result = Result.MISSING_CONTEXT
  elif not has_witnessed:
    result = Result.MISSING_EVIDENCE
  else:
    result = Result.PASS
  
  return {
    "result": result,
    "pass": result == Result.PASS,
    "has_distinction": has_distinction,
    "has_scoped": has_scoped,
    "has_witnessed": has_witnessed,
    "text": RESULT_TEXT.get(result, "unknown"),
    "distinction_count": distinctions.size(),
  }

static func check_seal_eligibility(has_residual: bool) -> Dictionary:
  var base := evaluate()
  if not base["pass"]:
    return {
      "can_seal": false,
      "reason": base["text"],
      "result": base["result"],
    }
  
  if not has_residual:
    return {
      "can_seal": false,
      "reason": "residual unnamed",
      "result": Result.RESIDUAL_UNNAMED,
    }
  
  return {
    "can_seal": true,
    "reason": "stable",
    "result": Result.PASS,
  }
