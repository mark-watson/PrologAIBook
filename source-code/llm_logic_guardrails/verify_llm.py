import json
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

def test_recommendation(name, recommendation_dict):
    print(f"\nTesting recommendation: {name}")
    print("LLM Output JSON:")
    json_str = json.dumps(recommendation_dict, indent=2)
    print(json_str)
    
    # Query Prolog guardrails
    query_str = "validate_portfolio_json(Json, Errors)"
    res = janus.query_once(query_str, {"Json": json_str})
    
    errors = res["Errors"]
    if not errors:
        print("✅ Guardrail Check Passed: Recommendation is SAFE.")
    else:
        print("❌ Guardrail Check Failed! Violations found:")
        for err in errors:
            # Decode bytes to string if returned as bytes
            err_str = err.decode('utf-8') if isinstance(err, bytes) else str(err)
            print(f"  - {err_str}")

def main():
    print("Consulting Prolog guardrail rules...")
    janus.consult("prolog/guardrails.pl")
    
    # Test valid case
    test_recommendation("Valid Senior Low-Risk Portfolio", VALID_RECOMMENDATION)
    
    # Test invalid case
    test_recommendation("Invalid Senior Low-Risk Portfolio", INVALID_RECOMMENDATION)

if __name__ == '__main__':
    main()
