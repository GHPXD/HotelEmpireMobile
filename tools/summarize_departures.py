"""Reconcile observed historical cohorts and verify observer neutrality."""
import json
import math
import statistics
import sys
from pathlib import Path


def summarize(current, reference):
    rows = current["reports"]
    key = lambda r: (r["expanded"], r["seed"], r["percent"])
    old = {key(r): r for r in reference["reports"]}
    expected = {(e, s, p) for e in (False, True) for s in (1, 17, 123) for p in (75, 100, 125)}
    if current["failures"] or current["days"] != 30 or len(rows) != 18 or {key(r) for r in rows} != expected:
        raise ValueError("Incomplete departure experiment")
    for row in rows:
        previous = {k: v for k, v in row.items() if k != "departure_cohorts"}
        if previous != old[key(row)]:
            raise ValueError(f"Observer changed reference outcomes: {key(row)}")
        groups = row["departure_cohorts"]
        if sum(g["count"] for g in groups.values()) != row["departures"]:
            raise ValueError("Counts do not reconcile")
        for g in groups.values():
            if g["count"] <= 0 or not math.isclose(g["score_total"] / g["count"], g["mean"], abs_tol=1e-8):
                raise ValueError("Missing population or inconsistent mean")
    result = []
    for expanded in (False, True):
        for percent in (75, 100, 125):
            selected = [r for r in rows if r["expanded"] == expanded and r["percent"] == percent]
            cohorts = {}
            for group in ("stayed", "no_stay"):
                count = sum(r["departure_cohorts"][group]["count"] for r in selected)
                total = sum(r["departure_cohorts"][group]["score_total"] for r in selected)
                cohorts[group] = {"count": count, "pooled_mean": total / count,
                                  "seed_mean_range": [min(r["departure_cohorts"][group]["mean"] for r in selected),
                                                      max(r["departure_cohorts"][group]["mean"] for r in selected)]}
            result.append({"expanded": expanded, "percent": percent, "cohorts": cohorts,
                           "profit_mean": statistics.mean(r["profit"] for r in selected)})
    return {"scenarios": 18, "reference_outcomes_unchanged": 18, "groups": result}


if __name__ == "__main__":
    result = summarize(*(json.loads(Path(p).read_text(encoding="utf-8")) for p in sys.argv[1:3]))
    Path(sys.argv[3]).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
