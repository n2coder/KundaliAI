import { SectionHeading } from './HowItWorks'

const SCREENS = [
  { src: '/screenshots/home.jpeg', label: 'Home' },
  { src: '/screenshots/insights-love.jpeg', label: 'Love Insights' },
  { src: '/screenshots/insights-career.jpeg', label: 'Career Insights' },
  { src: '/screenshots/compatibility.jpeg', label: 'Compatibility' },
  { src: '/screenshots/houses.jpeg', label: 'Birth Chart Houses' },
  { src: '/screenshots/guidance.jpeg', label: 'Personalised Guidance' },
  { src: '/screenshots/profile.jpeg', label: 'Profile' },
]

export default function Showcase() {
  const track = [...SCREENS, ...SCREENS]

  return (
    <section id="showcase" className="relative overflow-hidden py-28">
      <div className="mx-auto max-w-6xl px-6">
        <SectionHeading
          eyebrow="Inside the app"
          title="Every screen, built for clarity"
          subtitle="A glimpse at the experience — from your daily cosmic weather to a full Vedic chart breakdown."
        />
      </div>

      <div className="group relative mt-16">
        <div className="pointer-events-none absolute inset-y-0 left-0 z-10 w-24 bg-gradient-to-r from-cosmic-bg to-transparent" />
        <div className="pointer-events-none absolute inset-y-0 right-0 z-10 w-24 bg-gradient-to-l from-cosmic-bg to-transparent" />

        <div className="scrollbar-none flex w-max gap-6 px-6 [animation:marquee_42s_linear_infinite] group-hover:[animation-play-state:paused]">
          {track.map((s, i) => (
            <figure key={i} className="w-[200px] shrink-0 md:w-[230px]">
              <div className="overflow-hidden rounded-[1.6rem] border border-cosmic-gold/25 shadow-xl shadow-black/40">
                <img src={s.src} alt={s.label} className="block h-auto w-full" draggable={false} />
              </div>
              <figcaption className="mt-3 text-center text-sm text-cosmic-cream-dim">
                {s.label}
              </figcaption>
            </figure>
          ))}
        </div>
      </div>

      <style>{`
        @keyframes marquee {
          from { transform: translateX(0); }
          to { transform: translateX(-50%); }
        }
      `}</style>
    </section>
  )
}
