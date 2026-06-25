import { useState } from 'react'
import { motion } from 'framer-motion'
import Starfield from './Starfield'

export default function Waitlist() {
  const [email, setEmail] = useState('')
  const [submitted, setSubmitted] = useState(false)

  function handleSubmit(e) {
    e.preventDefault()
    if (!email.trim()) return
    setSubmitted(true)
  }

  return (
    <section id="waitlist" className="relative overflow-hidden py-28">
      <Starfield />
      <div
        className="absolute inset-0 -z-10"
        style={{
          background:
            'radial-gradient(ellipse 60% 60% at 50% 50%, rgba(217,173,98,0.14), transparent 70%)',
        }}
      />

      <motion.div
        initial={{ opacity: 0, y: 24 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.6 }}
        className="glass-card mx-auto max-w-2xl rounded-3xl px-8 py-14 text-center md:px-14"
      >
        <span className="text-xs font-semibold uppercase tracking-[0.2em] text-cosmic-gold">
          Coming soon
        </span>
        <h2 className="font-serif-display mt-4 text-4xl text-cosmic-cream md:text-5xl">
          Be among the first to align your stars
        </h2>
        <p className="mt-4 text-cosmic-cream-dim">
          Join the waitlist for first access, a founding-member badge in-app, and
          early-bird pricing when Kundali AI launches.
        </p>

        {submitted ? (
          <div className="mt-8 rounded-full bg-cosmic-green/60 px-6 py-4 text-cosmic-gold-light">
            ✦ You're on the list — we'll let you know the moment we launch.
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-3 sm:flex-row">
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@email.com"
              className="w-full rounded-full border border-cosmic-gold/25 bg-cosmic-bg-deep/60 px-5 py-3.5 text-cosmic-cream placeholder:text-cosmic-cream-dim/50 outline-none focus:border-cosmic-gold"
            />
            <button
              type="submit"
              className="shrink-0 rounded-full bg-cosmic-cream px-7 py-3.5 text-sm font-semibold text-cosmic-bg-deep transition hover:bg-cosmic-gold-light"
            >
              Get early access
            </button>
          </form>
        )}

        <div className="mt-10 flex items-center justify-center gap-4 border-t border-cosmic-gold/10 pt-8">
          <span className="text-xs uppercase tracking-wider text-cosmic-cream-dim">
            Coming to
          </span>
          <StoreBadge label="App Store" icon="apple" />
          <StoreBadge label="Google Play" icon="play" />
        </div>
      </motion.div>
    </section>
  )
}

function StoreBadge({ label, icon }) {
  return (
    <span className="flex items-center gap-2 rounded-xl border border-cosmic-gold/20 px-4 py-2 text-sm text-cosmic-cream-dim">
      {icon === 'apple' ? <AppleIcon /> : <PlayIcon />}
      {label}
    </span>
  )
}

function AppleIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M16.365 1.43c0 1.14-.493 2.27-1.177 3.08-.744.9-1.99 1.57-3.014 1.57-.12 0-.23-.02-.3-.03-.01-.05-.04-.2-.04-.36 0-1.13.55-2.27 1.23-3.06.74-.85 2.01-1.49 3.04-1.53.05.07.06.18.06.33zM20.5 17.5c-.55 1.27-.82 1.84-1.54 2.95-1 1.55-2.42 3.48-4.18 3.5-1.55.02-1.96-1.02-4.07-1.01-2.1.01-2.55 1.03-4.1 1-1.76-.02-3.1-1.78-4.1-3.32C-.55 17 0 10.6 4.1 8.8c1.13-.5 2.18-.7 3.1-.7 1.2 0 2.2.5 2.95.5.7 0 1.96-.6 3.36-.5.9.06 2.7.4 3.85 2.1-.1.07-2.3 1.34-2.27 3.94.03 3.1 2.7 4.13 2.41 4.36z" />
    </svg>
  )
}

function PlayIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M3.6 2.3c-.35.34-.55.86-.55 1.46v16.5c0 .6.2 1.12.55 1.46l9.9-9.7-9.9-9.72z" />
      <path d="M16.8 8.6 5.3 2.05 14.4 11l2.4-2.4z" />
      <path d="M14.4 13l-9.1 8.95L16.8 15.4l-2.4-2.4z" />
      <path d="M17.7 9.4l-2 2 2 2 3.3-1.95c.7-.4.7-1.7 0-2.1l-3.3-1.95z" />
    </svg>
  )
}
