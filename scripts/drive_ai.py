#!/usr/bin/env python3
"""Drive-resident AI: memory (SQLite FTS5 on the external drive) + ask (final answer only).

  drive_ai.py ask "question"            retrieve memory -> model -> store -> print ONLY the final answer
  drive_ai.py remember "fact"           store a fact
  drive_ai.py recall "query"            show what memory would retrieve
  drive_ai.py stats

Everything persistent (memory.db, KV slot saves, logs) lives under $MOE_WORK on the drive.
Stdlib only — no extra RAM-hungry deps on an 8 GB host.
"""
import json, os, sqlite3, subprocess, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))

def env():
    out = subprocess.check_output(["bash", "-c", f'. "{HERE}/env.sh"; echo "$WORK|$MEMORY|$PORT"'], text=True).strip()
    w, m, p = out.split("|"); return w, m, int(p)

WORK, MEMORY, PORT = env()
DB = os.path.join(MEMORY, "memory.db")

def db():
    c = sqlite3.connect(DB)
    c.executescript("""
    CREATE TABLE IF NOT EXISTS mem(id INTEGER PRIMARY KEY, ts REAL, kind TEXT, text TEXT);
    CREATE VIRTUAL TABLE IF NOT EXISTS mem_fts USING fts5(text, content='mem', content_rowid='id');
    CREATE TRIGGER IF NOT EXISTS mem_ai AFTER INSERT ON mem BEGIN INSERT INTO mem_fts(rowid,text) VALUES(new.id,new.text); END;
    """)
    return c

def remember(kind, text):
    c = db(); c.execute("INSERT INTO mem(ts,kind,text) VALUES(?,?,?)", (time.time(), kind, text)); c.commit(); c.close()

def recall(query, k=8):
    c = db()
    toks = [t for t in "".join(ch if ch.isalnum() else " " for ch in query).split() if len(t) > 2]
    rows = []
    if toks:
        q = " OR ".join(f'"{t}"' for t in toks)
        rows = c.execute("SELECT m.kind,m.text FROM mem_fts f JOIN mem m ON m.id=f.rowid WHERE mem_fts MATCH ? ORDER BY bm25(mem_fts) LIMIT ?", (q, k)).fetchall()
    recent = c.execute("SELECT kind,text FROM mem ORDER BY id DESC LIMIT 4").fetchall()
    c.close()
    seen, out = set(), []
    for r in rows + recent[::-1]:
        if r[1] not in seen: seen.add(r[1]); out.append(r)
    return out

def ensure_server():
    try: urllib.request.urlopen(f"http://127.0.0.1:{PORT}/health", timeout=2); return
    except Exception: pass
    subprocess.check_call(["bash", os.path.join(HERE, "serve.sh")])

def ask(question, show_context=False):
    ensure_server()
    ctx = recall(question)
    mem_block = "\n".join(f"- ({k}) {t}" for k, t in ctx) or "- (none)"
    if show_context: print("[memory]\n" + mem_block + "\n", file=sys.stderr)
    msgs = [
        {"role": "system", "content": "You are a helpful assistant that runs entirely from an external drive. "
         "Use the MEMORY below when relevant; it is the user's own prior statements. Answer concisely.\n\nMEMORY:\n" + mem_block},
        {"role": "user", "content": question},
    ]
    body = json.dumps({"messages": msgs, "temperature": 0.3, "max_tokens": 1536, "cache_prompt": True}).encode()
    req = urllib.request.Request(f"http://127.0.0.1:{PORT}/v1/chat/completions", body, {"Content-Type": "application/json"})
    t0 = time.time(); r = json.load(urllib.request.urlopen(req, timeout=900)); dt = time.time() - t0
    m = r["choices"][0]["message"]; ans = (m.get("content") or "").strip()
    if "</think>" in ans: ans = ans.split("</think>")[-1].strip()   # final answer only
    if not ans and m.get("reasoning_content"):
        ans = "(model ran out of tokens while thinking; last thought: " + m["reasoning_content"].strip()[-300:] + ")"
    u = r.get("usage", {})
    remember("user", question); remember("assistant", ans)
    print(ans)
    print(f"[{u.get('completion_tokens','?')} tok in {dt:.1f}s]", file=sys.stderr)

if __name__ == "__main__":
    a = sys.argv[1:]
    if not a or a[0] not in ("ask", "remember", "recall", "stats"): print(__doc__); sys.exit(1)
    if a[0] == "ask": ask(" ".join(a[1:]), show_context="-v" in os.environ.get("DRIVE_AI_FLAGS", ""))
    elif a[0] == "remember": remember("fact", " ".join(a[1:])); print("ok")
    elif a[0] == "recall": [print(f"({k}) {t}") for k, t in recall(" ".join(a[1:]))]
    else:
        c = db(); n = c.execute("SELECT count(*) FROM mem").fetchone()[0]; print(f"{n} memories in {DB} ({os.path.getsize(DB)//1024} KB)")
