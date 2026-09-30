"""Validate upgrade/tariff experiment and compare cash after real investments."""
import json
import math
import statistics
import sys
from pathlib import Path


def summarize(current, reference):
    rows = current["reports"]
    key = lambda r: (r["bedroom_level"], r["seed"], r["percent"])
    expected = {(level, seed, price) for level in (1, 2, 3)
                for seed in (1, 17, 123) for price in (75, 100, 125)}
    if current["failures"] or current["days"] != 30 or len(rows) != 27 or {key(r) for r in rows} != expected:
        raise ValueError("Incomplete upgrade experiment")
    by_key = {key(r): r for r in rows}
    old = {(r["seed"], r["percent"]): r for r in reference["reports"] if not r["expanded"]}
    added = {"bedroom_level", "upgrade_events", "before_upgrades", "post_day5_cohorts", "capital_spent"}
    for row in rows:
        level, seed, price = key(row)
        base = by_key[(1, seed, price)]
        if row["before_upgrades"] != base["before_upgrades"]:
            raise ValueError("Policies diverged before the scheduled investment")
        if level == 1 and {k: v for k, v in row.items() if k not in added} != old[(seed, price)]:
            raise ValueError("N1 reference outcomes changed")
        events = row["upgrade_events"]
        plan = [] if level == 1 else [(6001, 2, 2800)]
        if level == 3:
            plan.append((18001, 3, 4800))
        if len(events) != len(plan):
            raise ValueError("Missing upgrade purchase")
        for event, (tick, tier, spent) in zip(events, plan):
            if (event["tick"], event["level"], event["rooms"], event["spent"]) != (tick, tier, 8, spent):
                raise ValueError("Wrong upgrade schedule or cost")
            if event["cash_before"] - event["cash_after"] != spent or event["cash_after"] < 0:
                raise ValueError("Upgrade purchase did not conserve cash")
        if row["capital_spent"] != 9630 + sum(e[2] for e in plan):
            raise ValueError("Unexpected total investment")
        if row["ending_cash"] != row["starting_cash"] + row["profit"] - row["capital_spent"]:
            raise ValueError("Economy does not reconcile")
        if row["save_checkpoints"] != 5 or row["ticks"] != 36000 or row["bedrooms"] != 8 or row["service_percent"] != 100 or row["expanded"]:
            raise ValueError("Wrong comparison context")
        for name in ("departure_cohorts", "post_day5_cohorts"):
            groups = row[name]
            departures = row["departures"] - (row["before_upgrades"]["departures"] if name == "post_day5_cohorts" else 0)
            if sum(g["count"] for g in groups.values()) != departures:
                raise ValueError("Departure population does not reconcile")
            for group in groups.values():
                if group["count"] <= 0 or not math.isclose(group["mean"], group["score_total"] / group["count"], abs_tol=1e-8):
                    raise ValueError("Missing cohort or inconsistent satisfaction")
    groups = []
    for level in (1, 2, 3):
        for percent in (75, 100, 125):
            selected = [r for r in rows if r["bedroom_level"] == level and r["percent"] == percent]
            count = sum(r["post_day5_cohorts"]["stayed"]["count"] for r in selected)
            total = sum(r["post_day5_cohorts"]["stayed"]["score_total"] for r in selected)
            groups.append({"bedroom_level": level, "percent": percent,
                           "profit_mean": statistics.mean(r["profit"] for r in selected),
                           "ending_cash_mean": statistics.mean(r["ending_cash"] for r in selected),
                           "bookings_mean": statistics.mean(r["bookings"] for r in selected),
                           "stayed_post_day5_count": count, "stayed_post_day5_pooled_mean": total / count,
                           "cash_difference_vs_n1_by_seed": [r["ending_cash"] - by_key[(1, r["seed"], percent)]["ending_cash"] for r in selected],
                           "post_day5_satisfaction_difference_vs_standard_by_seed": [
                               r["post_day5_cohorts"]["stayed"]["mean"] - by_key[(level, r["seed"], 100)]["post_day5_cohorts"]["stayed"]["mean"] for r in selected]})
    return {"scenarios": 27, "save_checkpoints": 135, "unchanged_n1_references": 9, "groups": groups}


if __name__ == "__main__":
    result = summarize(*(json.loads(Path(p).read_text(encoding="utf-8")) for p in sys.argv[1:3]))
    Path(sys.argv[3]).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
