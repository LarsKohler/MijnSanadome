# Sanadome HRMS · Inlogpagina

Split-screen inlogpagina voor het HRMS medewerkersportaal van Sanadome Hotel & Spa.

## Lokaal bekijken

Open `index.html` in je browser of gebruik Live Server / Live Preview.

## Live zetten via Vercel

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
4. Laat **Framework Preset** op “Other” en **Build Command** leeg.
5. Klik **Deploy**. Elke push naar `main` wordt automatisch live gezet.

### Optie 3: Vercel-dashboard (drag & drop)

1. Ga naar [vercel.com/new](https://vercel.com/new).
2. Upload de map `sanadome-hrms-login` (of een zip ervan) of kies “Import Git Repository” als de code al op GitHub staat.

---

Na een geslaagde deploy is je inlogpagina bereikbaar op de gegenereerde Vercel-URL.
