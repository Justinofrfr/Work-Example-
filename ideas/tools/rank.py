import json, glob, re, sys, difflib, csv, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEIGHTS = {"O": 1.6, "D": 1.2, "P": 1.0, "A": 1.0, "B": 1.2}

def load():
    ideas, bad = [], 0
    for path in sorted(glob.glob(os.path.join(ROOT, "raw", "*.jsonl"))):
        for line in open(path, encoding="utf-8"):
            line = line.strip().rstrip(",")
            if not line:
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                bad += 1
                continue
            try:
                for k in WEIGHTS:
                    d[k] = max(1, min(5, int(d.get(k, 1))))
            except (TypeError, ValueError):
                bad += 1
                continue
            ideas.append(d)
    return ideas, bad

def norm(t):
    t = t.lower()
    t = re.sub(r"[^a-z0-9 ]", " ", t)
    t = re.sub(r"\b(a|an|the|your|my|of|and|to|simulator|sim|tycoon|rng)\b", " ", t)
    return " ".join(t.split())

def score(d):
    s = sum(d[k] * w for k, w in WEIGHTS.items())
    if d["O"] <= 2:
        s -= 4
    if d["B"] <= 2:
        s -= 3
    ev = str(d.get("evidence", "")).lower()
    if ev and ev != "none":
        s += 1
    return round(s, 2)

def dedupe(ideas):
    ideas.sort(key=lambda d: -d["score"])
    kept, keys = [], []
    for d in ideas:
        k = norm(d.get("title", ""))
        dup = next((i for i, kk in enumerate(keys) if kk == k or difflib.SequenceMatcher(None, k, kk).ratio() > 0.86), None)
        if dup is None:
            kept.append(d)
            keys.append(k)
        else:
            kept[dup].setdefault("dupes", []).append(d.get("id"))
    return kept

def main():
    top_n = int(sys.argv[1]) if len(sys.argv) > 1 else 200
    ideas, bad = load()
    for d in ideas:
        d["score"] = score(d)
    uniq = dedupe(ideas)
    with open(os.path.join(ROOT, "all-ideas-ranked.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["rank", "id", "title", "category", "score", "O", "D", "P", "A", "B", "loop", "twist", "source", "evidence", "roblox_occupancy", "money", "dupes"])
        for i, d in enumerate(uniq, 1):
            w.writerow([i, d.get("id"), d.get("title"), d.get("category"), d["score"], d["O"], d["D"], d["P"], d["A"], d["B"], d.get("loop"), d.get("twist"), d.get("source"), d.get("evidence"), d.get("roblox_occupancy"), d.get("money"), " ".join(d.get("dupes", []))])
    with open(os.path.join(ROOT, "shortlist.jsonl"), "w", encoding="utf-8") as f:
        for d in uniq[:top_n]:
            f.write(json.dumps({k: d.get(k) for k in ["id", "title", "category", "loop", "twist", "source", "evidence", "roblox_occupancy", "score"]}, ensure_ascii=False) + "\n")
    print(f"raw={len(ideas)} malformed={bad} unique={len(uniq)} shortlisted={min(top_n, len(uniq))}")

if __name__ == "__main__":
    main()
