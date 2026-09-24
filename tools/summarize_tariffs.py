"""Summarize a complete fixed-policy tariff experiment without tuning game data."""
import argparse
import json
import statistics
from pathlib import Path


def summarize(data):
    rows = data["reports"]
    expected = {(rooms, seed, tariff) for rooms in (2, 8)
                for seed in (1, 17, 123) for tariff in (75, 100, 125)}
    indexed = {(r["bedrooms"], r["seed"], r["percent"]): r for r in rows}
    if data["failures"] != 0 or data["days"] != 30 or len(rows) != 18 or set(indexed) != expected:
        raise ValueError("Expected all 18 successful scenarios over 30 days")
    if any(r["ticks"] != 36000 or r["save_checkpoints"] != 5 for r in rows):
        raise ValueError("Incomplete simulation or save continuity")
    metrics = ("profit", "ending_cash", "bookings", "meals", "reputation", "occupancy")
    groups = []
    for bedrooms in (2, 8):
        for percent in (75, 100, 125):
            group = [indexed[bedrooms, seed, percent] for seed in (1, 17, 123)]
            groups.append({"bedrooms": bedrooms, "percent": percent,
                           "metrics": {key: {"mean": statistics.mean(r[key] for r in group),
                                              "min": min(r[key] for r in group),
                                              "max": max(r[key] for r in group)} for key in metrics}})
    pairs = []
    for bedrooms in (2, 8):
        for seed in (1, 17, 123):
            base, premium = indexed[bedrooms, seed, 100], indexed[bedrooms, seed, 125]
            delta = {key: premium[key] - base[key] for key in metrics}
            pairs.append({"bedrooms": bedrooms, "seed": seed, "premium_minus_standard": delta,
                          "same_service_and_reputation": all(abs(delta[k]) < 1e-9 for k in
                                                             ("bookings", "meals", "reputation", "occupancy"))})
    return {"scenario_count": len(rows), "save_checkpoints": sum(r["save_checkpoints"] for r in rows),
            "groups": groups, "paired_comparisons": pairs,
            "premium_more_profit_cases": sum(p["premium_minus_standard"]["profit"] > 0 for p in pairs),
            "premium_unchanged_service_cases": sum(p["same_service_and_reputation"] for p in pairs),
            "reference_eight_room_solvent": all(indexed[8, s, 100]["minimum_cash"] >= 0 for s in (1, 17, 123)),
            "limitations": ["Three seeds, fixed hotel and policy", "No human playtest", "No causal isolation of room versus service tariffs"]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    result = summarize(json.loads(args.input.read_text(encoding="utf-8")))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items() if k not in ("groups", "paired_comparisons")}))
