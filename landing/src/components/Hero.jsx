import { motion } from 'framer-motion'
import PhoneMockup from './PhoneMockup'
import Starfield from './Starfield'

export default function Hero() {
  return (
    <section id="top" className="relative overflow-hidden pt-36 pb-24 md:pt-44 md:pb-32">
      <Starfield />
      <div
        className="absolute inset-0 -z-10"
        style={{
          background:
            'radial-gradient(ellipse 60% 50% at 50% 0%, rgba(217,173,98,0.16), transparent 70%), radial-gradient(ellipse 50% 40% at 85% 30%, rgba(31,61,51,0.35), transparent 70%)',
        }}
      />

      <div className="mx-auto grid max-w-6xl items-center gap-16 px-6 md:grid-cols-2">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7 }}
        >
          <span className="inline-flex items-center gap-2 rounded-full border border-cosmic-gold/30 bg-cosmic-gold/10 px-4 py-1.5 text-xs font-medium uppercase tracking-wider text-cosmic-gold-light">
            <span className="h-1.5 w-1.5 rounded-full bg-cosmic-gold-light" />
            AI-Powered Vedic Astrologer
          </span>

          <h1 className="font-serif-display mt-6 text-5xl leading-[1.08] text-cosmic-cream md:text-6xl">
            Ancient wisdom.
            <br />
            <span className="text-gradient-gold italic">Modern AI.</span>
          </h1>

          <p className="mt-6 max-w-md text-base text-cosmic-cream-dim md:text-lg">
            Kundali AI reads your birth chart the way a master astrologer would —
            then talks to you like one. Daily horoscopes, instant Vedic charts,
            and an AI astrologer in your pocket, on call 24&times;7.
          </p>

          <div className="mt-9 flex flex-wrap items-center gap-4">
            <a
              href="#waitlist"
              className="rounded-full bg-cosmic-cream px-7 py-3.5 text-sm font-semibold text-cosmic-bg-deep shadow-lg shadow-black/30 transition hover:bg-cosmic-gold-light"
            >
              Join the waitlist
            </a>
            <a
              href="#how-it-works"
              className="flex items-center gap-2 text-sm font-medium text-cosmic-cream-dim transition hover:text-cosmic-gold-light"
            >
              See how it works
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M9 5l7 7-7 7" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </a>
          </div>

          <div className="mt-12 flex flex-wrap gap-x-10 gap-y-4 text-cosmic-cream-dim">
            <Stat icon="♄" label="Personalized Predictions" />
            <Stat icon="✦" label="AI Powered Insights" />
            <Stat icon="🪷" label="Ancient Wisdom, Modern AI" />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.92 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.8, delay: 0.15 }}
          className="relative mx-auto w-full max-w-[300px]"
        >
          <img
            src="/zodiac_wheel.png"
            alt=""
            className="spin-slow absolute -top-16 left-1/2 w-56 -translate-x-1/2 opacity-50 md:-top-20 md:w-64"
          />
          <PhoneMockup src="/screenshots/splash.jpeg" alt="Kundali AI app splash screen" className="float-slow" />
        </motion.div>
      </div>
    </section>
  )
}

function Stat({ icon, label }) {
  return (
    <div className="flex items-center gap-2 text-sm">
      <span className="text-cosmic-gold">{icon}</span>
      <span>{label}</span>
    </div>
  )
}
