"""Compare lodging and service tariffs within each expansion/seed context."""
import json
import statistics
import sys
from pathlib import Path


def summarize(data):
    expected = {(e, s, l, p) for e in (False, True) for s in (1, 17, 123)
                for l in (75, 100, 125) for p in (75, 100, 125)}
    rows = data["reports"]
    indexed = {(r["expanded"], r["seed"], r["percent"], r["service_percent"]): r for r in rows}
    if data["failures"] or data["days"] != 30 or len(rows) != 54 or set(indexed) != expected:
        raise ValueError("Incomplete 54-case matrix")
    if any(r["ticks"] != 36000 or r["save_checkpoints"] != 5 or r["bedrooms"] != 8 for r in rows):
        raise ValueError("Incomplete simulation or continuity check")
    if any(r["expanded"] and not {"cafe", "lounge"} <= r["income_by_type"].keys() for r in rows):
        raise ValueError("Expansion missing")
    metrics = ("profit", "bookings", "meals", "service_uses", "reputation", "occupancy")
    groups = []
    for expanded in (False, True):
        for lodging in (75, 100, 125):
            for service in (75, 100, 125):
                group = [indexed[expanded, seed, lodging, service] for seed in (1, 17, 123)]
                groups.append({"expanded": expanded, "lodging": lodging, "service": service,
                               "mean": {k: statistics.mean(r[k] for r in group) for k in metrics},
                               "range": {k: [min(r[k] for r in group), max(r[k] for r in group)] for k in metrics},
                               "mean_income_by_type": {kind: statistics.mean(r["income_by_type"].get(kind, 0) for r in group)
                                                       for kind in ("bedroom", "restaurant", "cafe", "lounge")}})
    pairs = []
    for expanded in (False, True):
        for seed in (1, 17, 123):
            for other in (75, 100, 125):
                for category in ("lodging", "service"):
                    base_key = (expanded, seed, 100, other) if category == "lodging" else (expanded, seed, other, 100)
                    premium_key = (expanded, seed, 125, other) if category == "lodging" else (expanded, seed, other, 125)
                    base, premium = indexed[base_key], indexed[premium_key]
                    delta = {k: premium[k] - base[k] for k in metrics}
                    pairs.append({"expanded": expanded, "seed": seed, "category": category, "other_tariff": other,
                                  "premium_minus_standard": delta,
                                  "unchanged_experience": all(abs(delta[k]) < 1e-9 for k in metrics if k != "profit")})
    return {"scenarios": 54, "save_checkpoints": 270, "groups": groups, "pairs": pairs}


if __name__ == "__main__":
    result = summarize(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")))
    Path(sys.argv[2]).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    for category in ("lodging", "service"):
        pairs = [p for p in result["pairs"] if p["category"] == category]
        print(json.dumps({"category": category, "pairs": len(pairs),
                          "premium_more_profit": sum(p["premium_minus_standard"]["profit"] > 0 for p in pairs),
                          "unchanged_experience": sum(p["unchanged_experience"] for p in pairs)}))
