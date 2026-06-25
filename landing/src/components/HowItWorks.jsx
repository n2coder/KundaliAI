import { motion } from 'framer-motion'
import PhoneMockup from './PhoneMockup'

const STEPS = [
  {
    n: '01',
    title: 'Sign up in seconds',
    body: 'Verify your number with a one-time OTP — no passwords, no friction.',
    img: '/screenshots/otp.jpeg',
  },
  {
    n: '02',
    title: 'Get your Vedic chart',
    body: 'Enter your birth date, time, and place. Our engine computes your real planetary positions — not a template.',
    img: '/screenshots/birth-chart.jpeg',
  },
  {
    n: '03',
    title: 'Chat with your AI astrologer',
    body: 'Ask anything — career, love, timing — and get answers grounded in your actual chart.',
    img: '/screenshots/ai-chat.jpeg',
  },
  {
    n: '04',
    title: 'Receive daily guidance',
    body: 'Wake up to your horoscope on WhatsApp, plus life scores for love, career, health and money.',
    img: '/screenshots/home.jpeg',
  },
]

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="relative py-28">
      <div className="mx-auto max-w-6xl px-6">
        <SectionHeading
          eyebrow="How it works"
          title="From birth details to daily guidance"
          subtitle="Four steps between you and a personal AI astrologer who actually knows your chart."
        />

        <div className="mt-16 space-y-24">
          {STEPS.map((step, i) => (
            <motion.div
              key={step.n}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-80px' }}
              transition={{ duration: 0.6 }}
              className={`flex flex-col items-center gap-10 md:flex-row md:gap-16 ${
                i % 2 === 1 ? 'md:flex-row-reverse' : ''
              }`}
            >
              <div className="w-full max-w-[220px] shrink-0">
                <PhoneMockup src={step.img} alt={step.title} glow={false} />
              </div>

              <div className="max-w-md text-center md:text-left">
                <span className="font-serif-display text-5xl text-cosmic-gold/40">{step.n}</span>
                <h3 className="font-serif-display mt-2 text-2xl text-cosmic-cream md:text-3xl">
                  {step.title}
                </h3>
                <p className="mt-3 text-cosmic-cream-dim">{step.body}</p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

export function SectionHeading({ eyebrow, title, subtitle, light = false }) {
  return (
    <div className="mx-auto max-w-2xl text-center">
      <span className="text-xs font-semibold uppercase tracking-[0.2em] text-cosmic-gold">
        {eyebrow}
      </span>
      <h2
        className={`font-serif-display mt-4 text-4xl md:text-5xl ${
          light ? 'text-cosmic-bg-deep' : 'text-cosmic-cream'
        }`}
      >
        {title}
      </h2>
      {subtitle && (
        <p className={`mt-4 text-base ${light ? 'text-cosmic-bg-deep/70' : 'text-cosmic-cream-dim'}`}>
          {subtitle}
        </p>
      )}
    </div>
  )
}
