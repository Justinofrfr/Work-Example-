import json, glob, os, csv, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W = {"O": 1.6, "D": 1.2, "P": 1.0, "A": 1.0, "B": 1.2}
LANE = {"OPEN": 2, "CROWDED": -3, "TAKEN": -12, "UNCHECKED": -2}
MONEY = {"HIGH": 2, "MID": 0, "LOW": -2}
VERDICT = {"KEEP": 2, "PIVOT": 0, "KILL": -10}

def num(v, default=1):
    try:
        return max(1, min(5, int(v)))
    except (TypeError, ValueError):
        return default

def main():
    top_n = int(sys.argv[1]) if len(sys.argv) > 1 else 40
    src = {}
    for p in glob.glob(os.path.join(ROOT, "raw", "*.jsonl")):
        for l in open(p, encoding="utf-8"):
            if l.strip():
                d = json.loads(l)
                src[d["id"]] = d
    rows, bad = [], 0
    for p in sorted(glob.glob(os.path.join(ROOT, "factcheck", "result_*.jsonl"))):
        for l in open(p, encoding="utf-8"):
            l = l.strip().rstrip(",")
            if not l:
                continue
            try:
                d = json.loads(l)
            except json.JSONDecodeError:
                bad += 1
                continue
            for k in W:
                d[k] = num(d.get(k))
            lane = str(d.get("lane", "UNCHECKED")).upper().split()[0].strip(".,")
            money = str(d.get("money", "MID")).upper().split()[0].strip(".,")
            verdict = str(d.get("verdict", "PIVOT")).upper().split()[0].strip(".,")
            d["lane"], d["money"], d["verdict"] = lane, money, verdict
            d["vscore"] = round(sum(d[k] * w for k, w in W.items()) + LANE.get(lane, -2) + MONEY.get(money, 0) + VERDICT.get(verdict, 0), 2)
            s = src.get(d.get("id"), {})
            d["loop"], d["twist"], d["source"], d["category"] = s.get("loop"), s.get("twist"), s.get("source"), s.get("category")
            rows.append(d)
    best = {}
    for d in rows:
        if d["id"] not in best or d["vscore"] > best[d["id"]]["vscore"]:
            best[d["id"]] = d
    rows = sorted(best.values(), key=lambda d: -d["vscore"])
    cols = ["rank", "id", "title", "vscore", "lane", "money", "verdict", "O", "D", "P", "A", "B", "competitors", "demand_check", "red_flags", "why", "pivot", "loop", "twist", "source", "category"]
    with open(os.path.join(ROOT, "factcheck", "verified-ranked.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for i, d in enumerate(rows, 1):
            w.writerow([i] + [d.get(c) for c in cols[1:]])
    finalists = [d for d in rows if d["verdict"] != "KILL" and d["lane"] != "TAKEN"][:top_n]
    with open(os.path.join(ROOT, "factcheck", "finalists.jsonl"), "w", encoding="utf-8") as f:
        for d in finalists:
            f.write(json.dumps({c: d.get(c) for c in cols[1:]}, ensure_ascii=False) + "\n")
    from collections import Counter
    print(f"checked={len(rows)} malformed={bad} lanes={dict(Counter(d['lane'] for d in rows))} verdicts={dict(Counter(d['verdict'] for d in rows))} finalists={len(finalists)}")

if __name__ == "__main__":
    main()
