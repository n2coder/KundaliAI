const STATS = [
  { value: '9', label: 'Planets tracked' },
  { value: '12', label: 'Houses analysed' },
  { value: '27', label: 'Nakshatras mapped' },
  { value: '24/7', label: 'AI astrologer on call' },
]

export default function Stats() {
  return (
    <section className="relative border-y border-cosmic-gold/10 bg-cosmic-night/40 py-14">
      <div className="mx-auto grid max-w-5xl grid-cols-2 gap-8 px-6 text-center md:grid-cols-4">
        {STATS.map((s) => (
          <div key={s.label}>
            <div className="font-serif-display text-gradient-gold text-4xl md:text-5xl">
              {s.value}
            </div>
            <div className="mt-2 text-xs uppercase tracking-wider text-cosmic-cream-dim">
              {s.label}
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
