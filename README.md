# Sanadome HRMS · Inlogpagina

Split-screen inlogpagina voor het HRMS medewerkersportaal van Sanadome Hotel & Spa. Inloggen gaat via **Supabase Auth**; na inloggen kom je op een eenvoudig dashboard.

## Supabase

- Inloggen gebruikt **Supabase Authentication** (e-mail/wachtwoord).
- Maak in het [Supabase-dashboard](https://supabase.com/dashboard) onder **Authentication** → **Users** een gebruiker aan (e-mail + wachtwoord), of gebruik **Sign up** als je dat later in de app toevoegt.
- Lokaal: kopieer `config.example.js` naar `config.js` en vul je **Project URL** en **anon / publishable key** in (Project Settings → API). Het bestand `config.js` staat in `.gitignore` en wordt niet gecommit.

## Lokaal bekijken

1. Zorg dat `config.js` bestaat (zie hierboven).
2. Gebruik een lokale server (bijv. Live Server of `npx serve .`) en open de site via `http://localhost:...`. Rechtstreeks `index.html` openen via `file://` kan problemen geven door CORS.

## Live zetten via Vercel

Stel in je Vercel-project **Environment Variables** in:

- `SUPABASE_URL` = je Supabase Project URL  
- `SUPABASE_ANON_KEY` = je Supabase anon / publishable key  

Bij deploy wordt `npm run build` uitgevoerd; daarmee wordt `config.js` gegenereerd uit deze variabelen.

### Optie 1: Vercel CLI

1. Installeer de Vercel CLI (eenmalig):
   ```bash
   npm i -g vercel
   ```

2. Log in (eenmalig):
   ```bash
   vercel login
   ```

3. Deploy vanuit deze map:
   ```bash
   cd sanadome-hrms-login
   vercel
   ```
   Volg de prompts; kies dezelfde map als project root. Je krijgt een live URL (bijv. `https://sanadome-hrms-login-xxx.vercel.app`).

4. Productie-deploy:
   ```bash
   vercel --prod
   ```

### Optie 2: GitHub + Vercel

1. Zet de code in een GitHub-repository.
2. Ga naar [vercel.com](https://vercel.com) en log in.
3. **Add New** → **Project** → importeer je repo.
4. **Framework Preset:** Other. **Build Command:** `npm run build`. **Output Directory:** `dist`.
5. Voeg Environment Variables toe: `SUPABASE_URL` en `SUPABASE_ANON_KEY` (zie hierboven).
6. Klik **Deploy**. Elke push naar `main` wordt automatisch live gezet.

### Optie 3: Vercel-dashboard (drag & drop)

1. Ga naar [vercel.com/new](https://vercel.com/new).
2. Upload de map `sanadome-hrms-login` (of een zip ervan) of kies “Import Git Repository” als de code al op GitHub staat.

---

Na een geslaagde deploy is je inlogpagina bereikbaar op de gegenereerde Vercel-URL.
