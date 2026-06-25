import { motion } from 'framer-motion'
import { SectionHeading } from './HowItWorks'

const FEATURES = [
  {
    icon: '✦',
    title: 'AI Chat Astrologer',
    body: 'A GPT-powered astrologer that has actually read your chart — ask it anything, anytime.',
  },
  {
    icon: '◎',
    title: 'Real Vedic Birth Charts',
    body: 'Computed with proper astronomical positions (Swiss Ephemeris), not a generic lookup table.',
  },
  {
    icon: '🟢',
    title: 'Daily Horoscope on WhatsApp',
    body: 'Wake up to your personalised reading delivered straight to WhatsApp, on your schedule.',
  },
  {
    icon: '🧭',
    title: 'Personalised Guidance',
    body: 'Career, love, health, travel — pick a life area and get insight grounded in your dasha and transits.',
  },
  {
    icon: '♡',
    title: 'Compatibility Matching',
    body: 'Check synastry with a partner using both birth charts, not just sun-sign guesswork.',
  },
  {
    icon: '🔒',
    title: 'Private & Secure',
    body: 'Your birth data and conversations stay yours — encrypted, never sold, never shared.',
  },
]

export default function Features() {
  return (
    <section id="features" className="relative py-28">
      <div
        className="absolute inset-0 -z-10"
        style={{
          background: 'radial-gradient(ellipse 70% 50% at 50% 50%, rgba(31,61,51,0.4), transparent 70%)',
        }}
      />
      <div className="mx-auto max-w-6xl px-6">
        <SectionHeading
          eyebrow="What makes us different"
          title="Astrology that knows your actual chart"
          subtitle="Not horoscope-of-the-day filler. Every answer is grounded in your real planetary positions."
        />

        <div className="mt-16 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f, i) => (
            <motion.div
              key={f.title}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-60px' }}
              transition={{ duration: 0.5, delay: (i % 3) * 0.08 }}
              className="glass-card rounded-2xl p-7 transition hover:border-cosmic-gold/40"
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-cosmic-gold/10 text-xl text-cosmic-gold-light">
                {f.icon}
              </div>
              <h3 className="font-serif-display mt-5 text-xl text-cosmic-cream">{f.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-cosmic-cream-dim">{f.body}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
