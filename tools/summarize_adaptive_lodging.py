"""Validate causal daily review decisions and compare against fixed N2 tariffs."""
import json
import math
import statistics
import sys
from pathlib import Path


def summarize(current, reference):
    rows = current["reports"]
    key = lambda r: (r["seed"], r["adaptive"], r["percent"])
    expected = {(s, False, p) for s in (1, 17, 123) for p in (75, 100, 125)} | {(s, True, 100) for s in (1, 17, 123)}
    if current["failures"] or current["days"] != 30 or len(rows) != 12 or {key(r) for r in rows} != expected:
        raise ValueError("Incomplete adaptive experiment")
    old = {(r["seed"], r["percent"]): r for r in reference["reports"] if r["bedroom_level"] == 2}
    by_key = {key(r): r for r in rows}
    for row in rows:
        if row["bedroom_level"] != 2 or row["expanded"] or row["service_percent"] != 100 or row["ticks"] != 36000 or row["save_checkpoints"] != 5:
            raise ValueError("Wrong comparison context")
        if row["capital_spent"] != 12430 or row["ending_cash"] != 12000 + row["profit"] - row["capital_spent"]:
            raise ValueError("Economy does not reconcile")
        if not row["adaptive"]:
            if row["decisions"] or {k: v for k, v in row.items() if k not in ("adaptive", "decisions")} != old[(row["seed"], row["percent"])]:
                raise ValueError("Fixed control differs from N2 reference")
            continue
        if row["before_upgrades"] != old[(row["seed"], 100)]["before_upgrades"]:
            raise ValueError("Adaptive policy altered its initial five days")
        if row["upgrade_events"] != old[(row["seed"], 100)]["upgrade_events"]:
            raise ValueError("Adaptive policy altered the common upgrade purchase")
        decisions = row["decisions"]
        if len(decisions) != 25 or [d["tick"] for d in decisions] != list(range(6001, 36001, 1200)):
            raise ValueError("Wrong daily decision schedule")
        price = 100
        for decision in decisions:
            observations = decision["observations"]
            if decision["current"] != price or decision["samples"] != len(observations) or len(observations) > 20:
                raise ValueError("Price or sample history is inconsistent")
            if len({r["guest_id"] for r in observations}) != len(observations):
                raise ValueError("Duplicate observed guest")
            last_time = -1
            for review in observations:
                if review["guest_id"] <= 0 or not 0 <= review["score"] <= 100 or not last_time <= review["time"] <= (decision["tick"] - 1) * 0.1 + 1e-8:
                    raise ValueError("Invalid or future observation")
                last_time = review["time"]
            total = sum(r["score"] for r in observations)
            if not math.isclose(total, decision["score_total"], abs_tol=1e-8):
                raise ValueError("Observation scores do not reconcile")
            mean = total / len(observations) if observations else None
            if (mean is None and decision["mean"] is not None) or (mean is not None and not math.isclose(mean, decision["mean"], abs_tol=1e-8)):
                raise ValueError("Observation mean is inconsistent")
            next_price = price
            if len(observations) >= 5:
                if mean < 75:
                    next_price = max(75, price - 25)
                elif mean > 80:
                    next_price = min(125, price + 25)
            if decision["next"] != next_price:
                raise ValueError("Decision violates declared policy")
            price = next_price
        for name in ("departure_cohorts", "post_day5_cohorts"):
            groups = row[name]
            departures = row["departures"] - (row["before_upgrades"]["departures"] if name == "post_day5_cohorts" else 0)
            if sum(g["count"] for g in groups.values()) != departures:
                raise ValueError("Cohort counts do not reconcile")
            for group in groups.values():
                if group["count"] <= 0 or not math.isclose(group["mean"], group["score_total"] / group["count"], abs_tol=1e-8):
                    raise ValueError("Missing cohort or invalid satisfaction")
    comparisons = []
    for seed in (1, 17, 123):
        adaptive = by_key[(seed, True, 100)]
        standard = by_key[(seed, False, 100)]
        economy = by_key[(seed, False, 75)]
        mean = adaptive["post_day5_cohorts"]["stayed"]["mean"]
        comparisons.append({"seed": seed, "ending_cash": adaptive["ending_cash"],
                            "cash_difference_vs_economy": adaptive["ending_cash"] - economy["ending_cash"],
                            "cash_difference_vs_standard": adaptive["ending_cash"] - standard["ending_cash"],
                            "post_day5_cash_gain_difference_vs_economy": (adaptive["ending_cash"] - adaptive["before_upgrades"]["cash"]) - (economy["ending_cash"] - economy["before_upgrades"]["cash"]),
                            "post_day5_cash_gain_difference_vs_standard": (adaptive["ending_cash"] - adaptive["before_upgrades"]["cash"]) - (standard["ending_cash"] - standard["before_upgrades"]["cash"]),
                            "stayed_post_day5_mean": mean,
                            "satisfaction_difference_vs_standard": mean - standard["post_day5_cohorts"]["stayed"]["mean"],
                            "target_met": mean >= 75 and adaptive["ending_cash"] >= economy["ending_cash"],
                            "price_changes": sum(d["current"] != d["next"] for d in adaptive["decisions"]),
                            "days_by_price": {str(p): sum(d["next"] == p for d in adaptive["decisions"]) for p in (75, 100, 125)}})
    policies = []
    for adaptive_flag, percent in ((False, 75), (False, 100), (False, 125), (True, 100)):
        selected = [by_key[(seed, adaptive_flag, percent)] for seed in (1, 17, 123)]
        count = sum(r["post_day5_cohorts"]["stayed"]["count"] for r in selected)
        total = sum(r["post_day5_cohorts"]["stayed"]["score_total"] for r in selected)
        policies.append({"policy": "adaptive" if adaptive_flag else str(percent),
                         "ending_cash_mean": statistics.mean(r["ending_cash"] for r in selected),
                         "post_day5_cash_gain_mean": statistics.mean(r["ending_cash"] - r["before_upgrades"]["cash"] for r in selected),
                         "bookings_mean": statistics.mean(r["bookings"] for r in selected),
                         "stayed_post_day5_count": count, "stayed_post_day5_pooled_mean": total / count})
    return {"scenarios": 12, "save_checkpoints": 60, "unchanged_fixed_controls": 9,
            "causal_daily_decisions": 75, "target_met_seeds": sum(r["target_met"] for r in comparisons),
            "policies": policies, "comparisons": comparisons}


if __name__ == "__main__":
    result = summarize(*(json.loads(Path(p).read_text(encoding="utf-8")) for p in sys.argv[1:3]))
    Path(sys.argv[3]).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
