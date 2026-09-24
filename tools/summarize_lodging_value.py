"""Validate neutrality of standard prices and compare value-policy outcomes."""
import json
import statistics
import sys
from pathlib import Path


def summarize(current, baseline):
    rows = current["reports"]
    key = lambda r: (r["expanded"], r["seed"], r["percent"])
    indexed = {key(r): r for r in rows}
    expected = {(e, s, p) for e in (False, True) for s in (1, 17, 123) for p in (75, 100, 125)}
    if current["failures"] or current["days"] != 30 or len(rows) != 18 or set(indexed) != expected:
        raise ValueError("Incomplete value experiment")
    if any(r["service_percent"] != 100 or r["ticks"] != 36000 or r["save_checkpoints"] != 5 for r in rows):
        raise ValueError("Wrong policy or incomplete continuation")
    old = {key(r): r for r in baseline["reports"] if r["service_percent"] == 100}
    neutral = 0
    for k, r in indexed.items():
        if r["percent"] == 100:
            if r != old[k]:
                raise ValueError(f"Standard price changed baseline: {k}")
            neutral += 1
    groups = []
    pairs = []
    for expanded in (False, True):
        for percent in (75, 100, 125):
            group = [indexed[expanded, s, percent] for s in (1, 17, 123)]
            groups.append({"expanded": expanded, "percent": percent,
                           "mean": {m: statistics.mean(r[m] for r in group) for m in
                                    ("profit", "reputation", "bookings", "meals", "occupancy")}})
        for seed in (1, 17, 123):
            base = indexed[expanded, seed, 100]
            for percent in (75, 125):
                r = indexed[expanded, seed, percent]
                pairs.append({"expanded": expanded, "seed": seed, "percent": percent,
                              "profit_delta": r["profit"] - base["profit"],
                              "reputation_delta": r["reputation"] - base["reputation"]})
    return {"scenarios": len(rows), "standard_exactly_unchanged": neutral,
            "save_checkpoints": sum(r["save_checkpoints"] for r in rows), "groups": groups, "pairs": pairs}


if __name__ == "__main__":
    result = summarize(*(json.loads(Path(p).read_text(encoding="utf-8")) for p in sys.argv[1:3]))
    Path(sys.argv[3]).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
