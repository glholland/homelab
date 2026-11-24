"""Renders a WoW: Forever character report (one self-contained HTML page) from
Blizzard profile API responses. Shared by the web service (app.py)."""
import datetime, html

# Profile sections fetched for a report: key -> path suffix after /profile/wow/character/<slug>.
SECTIONS = {"summary": "", "equipment": "/equipment", "stats": "/statistics", "specs": "/specializations",
            "professions": "/professions", "reps": "/reputations", "quests": "/quests",
            "completed": "/quests/completed", "achievements": "/achievements", "mounts": "/collections/mounts",
            "pets": "/collections/pets", "pvp": "/pvp-summary", "titles": "/titles", "media": "/character-media",
            "dungeons": "/encounters/dungeons", "raids": "/encounters/raids"}


def render(D):
    """D maps each SECTIONS key to its decoded JSON response ({} if missing)."""
    e = html.escape
    def g(d, *path, default=None):
        for p in path:
            if isinstance(d, dict): d = d.get(p)
            elif isinstance(d, list) and isinstance(p, int) and p < len(d): d = d[p]
            else: return default
            if d is None: return default
        return d

    def money(c):
        c = int(c or 0)
        parts = [(c // 10000, "g", "gold"), (c // 100 % 100, "s", "silver"), (c % 100, "c", "copper")]
        return " ".join(f'<span class="{cls}">{n}{u}</span>' for n, u, cls in parts if n) or '<span class="copper">0c</span>'

    def ts(ms):
        return datetime.datetime.fromtimestamp(ms / 1000).strftime("%b %d, %Y %H:%M") if ms else "-"

    def q(item):  # quality class
        return "q-" + (g(item, "quality", "type", default="COMMON") or "COMMON").lower()

    def bar(value, maximum, label=""):
        pct = 0 if not maximum else max(0, min(100, 100 * value / maximum))
        return f'<div class="bar"><div class="fill" style="width:{pct:.1f}%"></div><span>{e(label)}</span></div>'

    def section(id_, title, body, count=None):
        c = f' <span class="count">{count}</span>' if count is not None else ""
        return f'<section id="{id_}"><h2>{e(title)}{c}</h2>{body}</section>'

    S = D["summary"]
    avatar = next((a["value"] for a in g(D, "media", "assets", default=[]) if a["key"] == "avatar"), "")
    main = next((a["value"] for a in g(D, "media", "assets", default=[]) if a["key"] == "main-raw"), "")
    groups_ = sorted(g(D, "specs", "specialization_groups", default=[]), key=lambda grp: not grp.get("is_active"))
    def trees(grp):  # a talent setup's trees, most points first
        return sorted(grp.get("specializations", []), key=lambda s: -s.get("spent_points", 0))
    def split(grp):  # "Combat 35 / Assassination 12"
        return " / ".join(f'{s.get("specialization_name")} {s.get("spent_points", 0)}' for s in trees(grp))
    active = groups_[0] if groups_ else {}

    # ---- header
    facts = [("Level", S.get("level")), ("Race", g(S, "race", "name")), ("Class", g(S, "character_class", "name")),
             ("Talents", split(active) or "-"),
             ("Faction", g(S, "faction", "name")), ("Guild", g(S, "guild", "name", default="-")),
             ("Item level", f'{S.get("equipped_item_level")} equipped / {S.get("average_item_level")} average'),
             ("Gender", g(S, "gender", "name")), ("Ruleset", g(S, "ruleset", "name")),
             ("Experience", f'{S.get("experience", 0):,}'), ("Last logout", ts(S.get("last_login_timestamp"))),
             ("Honorable kills", g(D, "pvp", "honorable_kills", default=0))]
    header = f'''<header class="hero">
      {f'<img class="avatar" src="{e(avatar)}" alt="" onerror="this.remove()">' if avatar else ""}
      <div><h1>{e(S.get("name",""))} <span class="surname">{e(S.get("surname",""))}</span></h1>
      <p class="sub">Level {S.get("level")} {e(g(S,"race","name",default=""))} {e(g(S,"character_class","name",default=""))} &middot; {e(g(S,"guild","name",default="no guild"))} &middot; World of Warcraft: Forever</p>
      <dl class="facts">{"".join(f"<div><dt>{e(k)}</dt><dd>{e(str(v))}</dd></div>" for k, v in facts)}</dl></div>
    </header>'''

    # ---- equipment
    SLOT_ORDER = ["HEAD", "NECK", "SHOULDER", "BACK", "CHEST", "SHIRT", "TABARD", "WRIST", "HANDS", "WAIST", "LEGS",
                  "FEET", "FINGER_1", "FINGER_2", "TRINKET_1", "TRINKET_2", "MAIN_HAND", "OFF_HAND", "RANGED"]
    items = sorted(g(D, "equipment", "equipped_items", default=[]),
                   key=lambda i: SLOT_ORDER.index(g(i, "slot", "type")) if g(i, "slot", "type") in SLOT_ORDER else 99)
    rows, totals = [], {}
    for it in items:
        stats = []
        for st in it.get("stats", []):
            name, v = g(st, "type", "name"), st.get("value", 0)
            totals[name] = totals.get(name, 0) + v
            stats.append(f'<span class="{"bonus" if st.get("is_equip_bonus") else ""}">+{v} {e(name)}</span>')
        extras = [f'<span class="ench">{e(en.get("display_string",""))}</span>' for en in it.get("enchantments", [])]
        extras += [f'<span class="spell">{e(sp.get("description",""))}</span>' for sp in it.get("spells", [])]
        if g(it, "weapon"):
            extras.insert(0, f'<span>{e(g(it,"weapon","damage","display_string",default=""))}, {e(g(it,"weapon","attack_speed","display_string",default=""))} {e(g(it,"weapon","dps","display_string",default=""))}</span>')
        if g(it, "armor", "value"):
            stats.insert(0, f'<span>{g(it,"armor","value")} Armor</span>')
        dur = g(it, "durability")
        durcell = bar(dur["value"], int(dur["display_string"].split("/")[-1]), dur["display_string"].replace("Durability ", "")) if dur else "-"
        rows.append(f'''<tr><td class="slot">{e(g(it,"slot","name",default=""))}</td>
          <td><a class="{q(it)}" href="https://www.wowhead.com/classic/item={g(it,"item","id")}" target="_blank" rel="noopener">{e(it.get("name",""))}</a>
          <div class="meta">{e(g(it,"item_subclass","name",default=""))} &middot; {e(g(it,"binding","name",default=""))}{(" &middot; " + e(g(it,"set","display_string"))) if g(it,"set") else ""}</div></td>
          <td class="num">{g(it,"level","value",default="")}</td><td class="stats">{" ".join(stats)}<div>{" ".join(extras)}</div></td>
          <td class="dur">{durcell}</td><td class="num">{money(g(it,"sell_price","value"))}</td></tr>''')
    sets = "".join(f'<li><b>{e(s.get("display_string",""))}</b><ul>' + "".join(
        f'<li class="{"on" if ef.get("is_active") else "off"}">{e(ef.get("display_string",""))}</li>' for ef in s.get("effects", []))
        + "</ul></li>" for s in g(D, "equipment", "equipped_item_sets", default=[]))
    gear_sum = " ".join(f'<span class="chip">+{v} {e(k)}</span>' for k, v in sorted(totals.items(), key=lambda kv: -kv[1]))
    vendor_total = sum(g(i, "sell_price", "value", default=0) for i in items)
    equipment = f'''<p class="lead">Totals from gear: {gear_sum}</p>
    <table class="grid"><thead><tr><th>Slot</th><th>Item</th><th>iLvl</th><th>Stats</th><th>Durability</th><th>Vendor</th></tr></thead>
    <tbody>{"".join(rows)}</tbody></table>
    <p class="note">Everything equipped vendors for {money(vendor_total)}.</p>{f"<h3>Item sets</h3><ul class='sets'>{sets}</ul>" if sets else ""}'''

    # ---- stats
    st = D["stats"]
    def sv(k):
        v = st.get(k)
        if isinstance(v, dict):
            if "effective" in v: return f'{v["effective"]}' + (f' <small>(base {v["base"]})</small>' if v.get("base") != v["effective"] else "")
            if "value" in v: return f'{v["value"]:.2f}%'
        if isinstance(v, float): return f"{v:.1f}"
        return e(str(v)) if v is not None else "-"
    groups = {
        "Core": [("Health", "health"), ("Mana", "power"), ("Stamina", "stamina"), ("Intellect", "intellect"),
                 ("Spirit", "spirit"), ("Strength", "strength"), ("Agility", "agility"), ("Armor", "armor")],
        "Spell": [("Spell power", "spell_power"), ("Healing", "spell_healing"), ("Spell crit", "spell_crit"),
                  ("Spell hit", "spell_hit"), ("Spell penetration", "spell_penetration"), ("Mana regen", "mana_regen"),
                  ("Mana regen in combat", "mana_regen_combat")],
        "Physical": [("Attack power", "attack_power"), ("Melee crit", "melee_crit"), ("Ranged crit", "ranged_crit"),
                     ("Dodge", "dodge"), ("Defense", "defense"), ("Main hand DPS", "main_hand_dps")],
        "Resistances": [(n.title(), n + "_resistance") for n in ("arcane", "fire", "frost", "nature", "shadow")],
    }
    stats = '<div class="cards">' + "".join(
        f'<div class="card"><h3>{e(gname)}</h3><dl class="kv">' + "".join(f"<dt>{e(lbl)}</dt><dd>{sv(k)}</dd>" for lbl, k in rows_) + "</dl></div>"
        for gname, rows_ in groups.items()) + "</div>"

    # ---- talents
    def talent_cards(spec): return "".join(f'''<div class="talent"><div class="tname">{e(g(t,"talent","name",default=""))} <span class="rank">{t.get("talent_rank",1)}</span></div>
      <div class="meta">{e(g(t,"spell_tooltip","cast_time",default=""))}{(" &middot; " + e(g(t,"spell_tooltip","cooldown"))) if g(t,"spell_tooltip","cooldown") else ""}{(" &middot; " + e(g(t,"spell_tooltip","power_cost"))) if g(t,"spell_tooltip","power_cost") else ""}</div>
      <p>{e(g(t,"spell_tooltip","description",default=""))}</p></div>''' for t in spec.get("talents", []))
    talent_parts = []
    for n, grp in enumerate(groups_):
        label = "Active talents" if grp.get("is_active") else f"Other talent setup {n}"
        total = sum(s.get("spent_points", 0) for s in grp.get("specializations", []))
        body_ = "".join(f'<h4>{e(s.get("specialization_name",""))} <span class="count">{s.get("spent_points",0)}</span></h4><div class="talents">{talent_cards(s)}</div>' for s in trees(grp))
        talent_parts.append(f'<details{" open" if grp.get("is_active") else ""}><summary><b>{label}</b>: {e(split(grp))} ({total} points)</summary>{body_}</details>')
    talents = "".join(talent_parts) or "<p>No talents.</p>"

    # ---- professions
    prof = []
    for group in ("primaries", "secondaries"):
        for p in g(D, "professions", group, default=[]):
            for t in p.get("tiers", []):
                recipes = sorted(r["name"] for r in t.get("known_recipes", []))
                prof.append(f'''<div class="card prof"><h3>{e(g(p,"profession","name",default=""))} <small>{"primary" if group=="primaries" else "secondary"}</small></h3>
      {bar(t.get("skill_points",0), t.get("max_skill_points",0), f'{t.get("skill_points",0)} / {t.get("max_skill_points",0)}')}
      <details><summary>{len(recipes)} known recipes</summary><ul class="cols">{"".join(f"<li>{e(r)}</li>" for r in recipes)}</ul></details></div>''')
    professions = f'<div class="cards">{"".join(prof)}</div>'

    # ---- reputations
    TIER_CLASS = {0: "hated", 1: "hostile", 2: "unfriendly", 3: "neutral", 4: "friendly", 5: "honored", 6: "revered", 7: "exalted"}
    reps = sorted(g(D, "reps", "reputations", default=[]), key=lambda r: (-g(r, "standing", "raw", default=0)))
    reputations = '<div class="reps">' + "".join(
        f'''<div class="rep"><span class="rname">{e(g(r,"faction","name",default=""))}</span>
      <span class="standing {TIER_CLASS.get(g(r,"standing","tier"),"neutral")}">{e(g(r,"standing","name",default=""))}</span>
      {bar(g(r,"standing","value",default=0), g(r,"standing","max",default=1), f'{g(r,"standing","value",default=0):,} / {g(r,"standing","max",default=0):,}')}</div>'''
        for r in reps) + "</div>"

    # ---- achievements
    ach_rows, done = [], 0
    for a in g(D, "achievements", "achievements", default=[]):
        crit = g(a, "criteria", default={})
        kids = crit.get("child_criteria") or []
        complete = bool(a.get("completed_timestamp"))
        done += complete
        if kids:
            got = sum(1 for k in kids if k.get("is_completed"))
            prog = bar(got, len(kids), f"{got} / {len(kids)}") if len(kids) > 1 else (
                bar(1 if complete else 0, 1, "done" if complete else f'{kids[0].get("amount",0)}'))
        else:
            prog = bar(1 if complete else 0, 1, "done" if complete else "not yet")
        ach_rows.append(f'<tr class="{"done" if complete else ""}" data-text="{e(g(a,"achievement","name",default="").lower())}"><td>{e(g(a,"achievement","name",default=""))}</td><td>{prog}</td><td>{ts(a.get("completed_timestamp")) if complete else ""}</td></tr>')
    ach_list = g(D, "achievements", "achievements", default=[])
    achievements = f'''<p class="lead">{done} of {len(ach_list)} tracked achievements complete. Forever awards no achievement points.</p>
    <input class="filter" data-target="ach" placeholder="Filter achievements">
    <table class="grid" id="ach"><thead><tr><th>Achievement</th><th>Progress</th><th>Completed</th></tr></thead><tbody>{"".join(ach_rows)}</tbody></table>'''

    # ---- quests
    inprog = g(D, "quests", "in_progress", default=[])
    completed = sorted(g(D, "completed", "quests", default=[]), key=lambda x: x["name"].lower())
    quests = f'''<div class="two"><div><h3>In progress <span class="count">{len(inprog)}</span></h3>
    <ul class="plain">{"".join(f'<li><a href="https://www.wowhead.com/classic/quest={x["id"]}" target="_blank" rel="noopener">{e(x["name"])}</a></li>' for x in sorted(inprog, key=lambda x: x["name"]))}</ul></div>
    <div><h3>Completed <span class="count">{len(completed)}</span></h3><input class="filter" data-target="done-quests" placeholder="Filter completed quests">
    <ul class="plain cols" id="done-quests">{"".join(f'<li data-text="{e(x["name"].lower())}">{e(x["name"])}</li>' for x in completed)}</ul></div></div>'''

    # ---- collections & pvp
    mounts = g(D, "mounts", "mounts", default=[])
    pets = g(D, "pets", "pets", default=[])
    coll = f'''<div class="two"><div><h3>Mounts <span class="count">{len(mounts)}</span></h3><ul class="plain">{"".join(f'<li>{e(g(m,"mount","name",default=""))}</li>' for m in mounts)}</ul></div>
    <div><h3>Pets <span class="count">{len(pets)}</span></h3><ul class="plain">{"".join(f'<li class="{q(p)}">{e(g(p,"species","name",default=""))}{(" &ldquo;" + e(p["name"]) + "&rdquo;") if p.get("name") else ""} <small>level {p.get("level",1)}</small></li>' for p in pets)}</ul></div></div>'''
    pvpmaps = g(D, "pvp", "pvp_map_statistics", default=[])
    pvp = f'''<p class="lead">{g(D,"pvp","honorable_kills",default=0)} honorable kills, PvP rank {g(D,"pvp","pvp_rank",default=0)}.</p>
    <table class="grid narrow"><thead><tr><th>Battleground</th><th>Played</th><th>Won</th><th>Lost</th></tr></thead><tbody>{"".join(
        f'<tr><td>{e(g(m,"world_map","name",default=""))}</td><td class="num">{g(m,"match_statistics","played",default=0)}</td><td class="num">{g(m,"match_statistics","won",default=0)}</td><td class="num">{g(m,"match_statistics","lost",default=0)}</td></tr>' for m in pvpmaps)}</tbody></table>
    <p class="note">Titles: {", ".join(e(t["name"]) for t in g(D,"titles","titles",default=[])) or "none yet"}. Dungeon and raid kills: {"none recorded by the API yet" if not g(D,"dungeons","expansions") else "see armory"}.</p>'''

    NAV = [("gear", "Gear"), ("stats", "Stats"), ("talents", "Talents"), ("professions", "Professions"),
           ("reputation", "Reputation"), ("quests", "Quests"), ("achievements", "Achievements"),
           ("collections", "Collections"), ("pvp", "PvP")]
    body = "".join([
        section("gear", "Gear", equipment, len(items)), section("stats", "Stats", stats),
        section("talents", "Talents", talents), section("professions", "Professions", professions),
        section("reputation", "Reputation", reputations, len(reps)), section("quests", "Quests", quests),
        section("achievements", "Achievements", achievements, len(ach_list)),
        section("collections", "Collections", coll), section("pvp", "PvP and the rest", pvp)])

    CSS = """
    :root{--bg:#f6f4ef;--panel:#fffdf8;--ink:#221d16;--muted:#6f675b;--line:#e2dccf;--accent:#8a5a12;--fill:#c9973c;--track:#ece5d6;
    --q-poor:#8b8b8b;--q-common:#3a3a3a;--q-uncommon:#178a00;--q-rare:#0062c4;--q-epic:#8a2fc9;--q-legendary:#d46a00;--bonus:#178a00;
    --gold:#a77d00;--silver:#7c8288;--copper:#a3592a}
    @media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#14120f;--panel:#1d1a16;--ink:#ece6da;--muted:#a59c8c;--line:#352f27;
    --accent:#e0b25c;--fill:#c9973c;--track:#2c2720;--q-poor:#9d9d9d;--q-common:#e8e4dc;--q-uncommon:#1eff00;--q-rare:#0070dd;--q-epic:#a335ee;
    --q-legendary:#ff8000;--bonus:#3ddc3d;--gold:#ffd24a;--silver:#c7ccd1;--copper:#e08b54}}
    :root[data-theme="dark"]{--bg:#14120f;--panel:#1d1a16;--ink:#ece6da;--muted:#a59c8c;--line:#352f27;--accent:#e0b25c;--fill:#c9973c;--track:#2c2720;
    --q-poor:#9d9d9d;--q-common:#e8e4dc;--q-uncommon:#1eff00;--q-rare:#0070dd;--q-epic:#a335ee;--q-legendary:#ff8000;--bonus:#3ddc3d;--gold:#ffd24a;--silver:#c7ccd1;--copper:#e08b54}
    *{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
    a{color:inherit}main{max-width:1180px;margin:0 auto;padding:0 16px 64px}
    nav{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);display:flex;gap:4px;overflow-x:auto;padding:8px 16px}
    nav a{white-space:nowrap;text-decoration:none;padding:4px 10px;border-radius:999px;color:var(--muted)}nav a:hover{background:var(--track);color:var(--ink)}
    .hero{display:flex;gap:20px;align-items:flex-start;padding:28px 0 8px}.avatar{width:96px;height:96px;border-radius:12px;border:1px solid var(--line);object-fit:cover}
    h1{font-family:Georgia,"Times New Roman",serif;font-size:2.2rem;margin:0;line-height:1.1}.surname{color:var(--accent)}.sub{color:var(--muted);margin:4px 0 14px}
    .facts{display:grid;grid-template-columns:repeat(auto-fill,minmax(170px,1fr));gap:8px 18px;margin:0}.facts dt{font-size:12px;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}.facts dd{margin:0;font-weight:600}
    section{margin-top:36px}h2{font-family:Georgia,serif;font-size:1.5rem;border-bottom:2px solid var(--accent);padding-bottom:4px;margin:0 0 14px}
    h3{margin:0 0 8px;font-size:1rem}.count{font:600 12px system-ui;background:var(--track);color:var(--muted);border-radius:999px;padding:1px 8px;vertical-align:middle}
    .lead{margin:0 0 12px}.note{color:var(--muted);font-size:14px}small{color:var(--muted);font-weight:400}
    .grid{width:100%;border-collapse:collapse;background:var(--panel);border:1px solid var(--line);border-radius:10px;overflow:hidden}
    .grid th,.grid td{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top}.grid th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}
    .grid.narrow{width:auto;min-width:360px}.num{text-align:right;white-space:nowrap}.slot{color:var(--muted);white-space:nowrap}.meta{font-size:12px;color:var(--muted)}
    .stats span{display:inline-block;margin-right:8px;font-size:13px}.stats .bonus{color:var(--bonus)}.ench{color:var(--bonus)}.spell{color:var(--bonus);font-size:12px}
    .dur{min-width:110px}.chip{display:inline-block;background:var(--track);border-radius:6px;padding:1px 7px;margin:2px 3px 2px 0;font-size:13px}
    .q-poor{color:var(--q-poor)}.q-common{color:var(--q-common)}.q-uncommon{color:var(--q-uncommon)}.q-rare{color:var(--q-rare)}.q-epic{color:var(--q-epic)}.q-legendary{color:var(--q-legendary)}
    a[class^="q-"]{font-weight:600;text-decoration:none}a[class^="q-"]:hover{text-decoration:underline}
    .gold{color:var(--gold)}.silver{color:var(--silver)}.copper{color:var(--copper)}
    .bar{position:relative;height:18px;background:var(--track);border-radius:5px;overflow:hidden;min-width:90px}.bar .fill{position:absolute;inset:0 auto 0 0;background:var(--fill);opacity:.75}
    .bar span{position:relative;font-size:11px;padding:0 6px;line-height:18px;font-weight:600}
    .cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:14px}.card{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:14px}
    .kv{display:grid;grid-template-columns:1fr auto;gap:3px 12px;margin:0}.kv dt{color:var(--muted)}.kv dd{margin:0;text-align:right;font-weight:600}
    .prof .bar{margin:6px 0 8px}details summary{cursor:pointer;color:var(--accent)}.cols{columns:2 200px;padding-left:18px;margin:8px 0 0}
    .talents{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:12px}.talent{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:12px}
    h4{margin:14px 0 8px}#talents details{margin-bottom:14px}.talent p{margin:6px 0 0;font-size:14px}.tname{font-weight:700}.rank{background:var(--accent);color:var(--bg);border-radius:5px;padding:0 6px;font-size:12px;margin-left:4px}
    .reps{display:grid;grid-template-columns:repeat(auto-fill,minmax(330px,1fr));gap:8px 18px}.rep{display:grid;grid-template-columns:1fr auto;gap:2px 10px;align-items:center}.rep .bar{grid-column:1/-1}
    .standing{font-size:12px;font-weight:700}.hated,.hostile{color:#d04040}.unfriendly{color:#e07020}.neutral{color:var(--gold)}.friendly,.honored,.revered,.exalted{color:var(--bonus)}
    .two{display:grid;grid-template-columns:1fr 2fr;gap:24px}.plain{list-style:none;padding:0;margin:0}.plain li{padding:2px 0}.plain.cols{columns:2 220px}
    .filter{width:100%;max-width:340px;padding:7px 10px;border:1px solid var(--line);border-radius:8px;background:var(--panel);color:var(--ink);margin:0 0 10px;font:inherit}
    tr.done td:first-child{font-weight:600}.sets{padding-left:18px}.sets .off{color:var(--muted)}.sets .on{color:var(--bonus)}
    footer{color:var(--muted);font-size:13px;margin-top:48px;border-top:1px solid var(--line);padding-top:12px}
    @media (max-width:720px){.hero{flex-direction:column}.two{grid-template-columns:1fr}.grid{display:block;overflow-x:auto}}
    """
    JS = """document.querySelectorAll('.filter').forEach(f=>f.addEventListener('input',()=>{const t=f.value.toLowerCase();
    document.querySelectorAll('#'+f.dataset.target+' [data-text]').forEach(el=>{el.style.display=el.dataset.text.includes(t)?'':'none'})}));"""

    page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>{e(S.get("name",""))} {e(S.get("surname",""))}</title><style>{CSS}</style></head><body>
    <nav>{"".join(f'<a href="#{i}">{t}</a>' for i, t in NAV)}</nav><main>{header}{body}
    <footer><a href="/">Look up another character</a> &middot; From Blizzard's World of Warcraft: Forever API (profile-forever-us), as of the character's last logout. Built {datetime.datetime.now():%b %d, %Y %H:%M}.
    Item and quest links go to Wowhead Classic, whose IDs match for original items; Forever's new items may not be listed there.</footer></main>
    <script>{JS}</script></body></html>"""
    return page
