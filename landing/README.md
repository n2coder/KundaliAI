# Kundali AI — Landing Page

One-pager marketing site for Kundali AI, built with React + Vite + Tailwind CSS v4 + Framer Motion. Styled to match the in-app cosmic theme (navy/gold/emerald, Cormorant Garamond + Inter).

## Local development

```bash
npm install
npm run dev
```

## Build

```bash
npm run build   # outputs to dist/
npm run preview # serve the production build locally
```

## Structure

- `src/components/Hero.jsx` — headline, CTA, splash-screen phone mockup
- `src/components/HowItWorks.jsx` — 4-step alternating walkthrough with screenshots
- `src/components/Features.jsx` — 6-card feature grid
- `src/components/Stats.jsx` — quick stat strip
- `src/components/Showcase.jsx` — auto-scrolling screenshot marquee
- `src/components/Waitlist.jsx` — email capture (client-side only — see note below)
- `src/components/Footer.jsx`
- `public/screenshots/` — app screenshots used throughout
- `public/zodiac_wheel.png` — splash wheel asset, also used as favicon/logo

## Known limitation

The waitlist form in `Waitlist.jsx` only stores the email in local component state — it does **not** send anywhere yet. Wire it to an email service (Mailchimp, a Render backend endpoint, a Google Form, etc.) before relying on it to actually capture leads.

## Deploying to Render

This folder sits inside the `KundaliAI` repo alongside `mobile/` and `backend/`. A `render.yaml` blueprint is included at `landing/render.yaml` for a **Static Site** service with `rootDir: landing`.

To deploy:
1. Commit and push the `landing/` folder to GitHub.
2. In the Render dashboard: New → Static Site → connect the `KundaliAI` repo.
3. Set **Root Directory** to `landing`, **Build Command** to `npm install && npm run build`, **Publish Directory** to `dist`.
4. Add a rewrite rule `/*` → `/index.html` (already in `render.yaml` if using Blueprints).
