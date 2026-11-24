# forever-armory

A lookup page for World of Warcraft: Forever characters. Type `First Surname`,
get one page with everything Blizzard's API has on the character: gear and
stats, every talent tree, professions and recipes, reputations, quests,
achievements, collections and PvP. Data is as of the character's last logout.

- `app.py`: standard-library HTTP server. `GET /` is the form, `GET /c/first-surname`
  is the report, `GET /healthz` is the probe. Blizzard is called server-side, so the
  client secret never reaches a browser. Reports are cached in memory for
  `CACHE_SECONDS` (300). An unknown name costs one API request, a report 16.
- `report.py`: turns the profile responses into the HTML page.

Deployed by `kubernetes/forever-armory` (Argo CD application `forever-armory`) at
https://armory.garrettholland.com, LAN only. The image is built into Harbor by
`.tekton/build-forever-armory.yaml` on pushes to `images/forever-armory/**`.

Credentials: a Blizzard API client from https://develop.battle.net, stored in
Secret Manager as `blizzard-client-id` and `blizzard-client-secret` and injected by
argocd-vault-plugin. To rotate:

```bash
gcloud secrets versions add blizzard-client-secret --project home-26300 --data-file=-
```

then hard-refresh the Argo CD application and restart the deployment.

Run locally:

```bash
BLIZZARD_CLIENT_ID=... BLIZZARD_CLIENT_SECRET=... PORT=8099 python app.py
```
