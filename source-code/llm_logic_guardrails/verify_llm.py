import json
import sys
import janus_swi as janus

# Define simulated LLM portfolio recommendations
VALID_RECOMMENDATION = {
    "client_age": 70,
    "risk_tolerance": "low",
    "allocations": {
        "stocks": 10,
        "bonds": 60,
        "crypto": 0,
        "cash": 30
    }
}

INVALID_RECOMMENDATION = {
    "client_age": 72,
    "risk_tolerance": "low",
    "allocations": {
        "stocks": 40,      # Violates: High-risk stocks + crypto (50%) > 30% for age > 65
        "bonds": 30,
        "crypto": 10,      # Violates: Low risk tolerance cannot have crypto
        "cash": 10         # Violates: Bonds + Cash (40%) < 50% for low risk
    }                      # Violates: Sum is 40 + 30 + 10 + 10 = 90% (not 100%)
}

FAILURES = []

def check(condition, message):
    if condition:
        print(f"  [PASS] {message}")
    else:
        print(f"  [FAIL] {message}")
        FAILURES.append(message)

def test_recommendation(name, recommendation_dict):
    print(f"\nTesting recommendation: {name}")
    print("LLM Output JSON:")
    json_str = json.dumps(recommendation_dict, indent=2)
    print(json_str)

    # Query Prolog guardrails
    query_str = "validate_portfolio_json(Json, Errors)"
    res = janus.query_once(query_str, {"Json": json_str})

    errors = res["Errors"]
    err_strs = [e.decode('utf-8') if isinstance(e, bytes) else str(e) for e in errors]

    if not err_strs:
        print("Guardrail Check Passed: Recommendation is SAFE.")
    else:
        print("Guardrail Check Failed! Violations found:")
        for err_str in err_strs:
            print(f"  - {err_str}")
    return err_strs

def main():
    print("Consulting Prolog guardrail rules...")
    janus.consult("prolog/guardrails.pl")

    # Test valid case: all five rules must be silent
    valid_errors = test_recommendation(
        "Valid Senior Low-Risk Portfolio", VALID_RECOMMENDATION)
    check(valid_errors == [],
          "valid recommendation produces no violations")

    # Test invalid case: all four expected violations must appear
    invalid_errors = test_recommendation(
        "Invalid Senior Low-Risk Portfolio", INVALID_RECOMMENDATION)
    joined = "\n".join(invalid_errors)
    check("Total allocation must sum to exactly 100%" in joined,
          "violation: total allocation sum")
    check("high-risk assets" in joined,
          "violation: senior high-risk allocation")
    check("speculative crypto assets" in joined,
          "violation: crypto with low risk tolerance")
    check("at least 50% in conservative assets" in joined,
          "violation: low-risk conservative minimum")
    check(len(invalid_errors) == 4,
          "exactly four violations reported (asset negativity not triggered)")

    if FAILURES:
        print(f"\n{len(FAILURES)} assertion(s) FAILED")
        sys.exit(1)
    print("\nAll assertions passed.")
    sys.exit(0)

if __name__ == '__main__':
    main()
