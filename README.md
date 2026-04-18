# Valcrium — Portfolio Intelligence

> PE value creation monitoring platform. Track objectives, initiatives, and KPIs across your entire portfolio.

---

## Live Site

**[valcrium.vercel.app](https://valcrium.vercel.app)**

---

## Pages

| Page | File | Description |
|------|------|-------------|
| Landing | `index.html` | Marketing page with pricing & sign up |
| App | `app.html` | Main dashboard (auth required) |
| Founder | `founder.html` | Admin view across all accounts |

---

## Tech Stack

- **Frontend** — Vanilla HTML/CSS/JS (no framework)
- **Auth & Database** — [Supabase](https://supabase.com)
- **Hosting** — [Vercel](https://vercel.com)

---

## Setup

### 1. Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run `schema.sql`
3. Copy your **Project URL** and **Anon Key** from Project Settings → API

### 2. Environment Variables on Vercel

In your Vercel project → Settings → Environment Variables, add:

```
SUPABASE_URL   = https://your-project.supabase.co
SUPABASE_ANON  = your-anon-key
```

### 3. Update supabase.js

Replace the placeholders in `supabase.js`:
```js
const SUPABASE_URL  = 'https://your-project.supabase.co';
const SUPABASE_ANON = 'your-anon-key';
```

---

## Features

- ✅ Multi-tenant — each user has their own isolated data
- ✅ Portfolio company management
- ✅ Value Creation Plans (VCP)
- ✅ Objectives & Initiatives tracking
- ✅ Quantitative KPI monitoring
- ✅ Initiative completion tracking with audit trail
- ✅ Reports & Gantt charts
- ✅ Dark mode
- ✅ Multi-language (EN / FR / ES)

---

## Folder Structure

```
/
├── index.html      # Landing page
├── app.html        # Main application
├── founder.html    # Founder dashboard
├── supabase.js     # Supabase client & helpers
├── schema.sql      # Database schema
├── vercel.json     # Vercel routing
└── README.md
```

---

## Roadmap

- [ ] Connect app.html to Supabase (replace localStorage)
- [ ] Email notifications
- [ ] PDF report export
- [ ] Mobile app (React Native)
- [ ] AI-powered initiative suggestions

---

## License

Private — © Valcrium
