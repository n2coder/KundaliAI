import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'

const LINKS = [
  { label: 'How it works', href: '#how-it-works' },
  { label: 'Features', href: '#features' },
  { label: 'Inside the app', href: '#showcase' },
]

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20)
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <motion.header
      initial={{ y: -40, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ duration: 0.6 }}
      className={`fixed top-0 z-50 w-full transition-all duration-300 ${
        scrolled ? 'glass-card border-b border-cosmic-gold/10' : 'bg-transparent'
      }`}
    >
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <a href="#top" className="flex items-center gap-2">
          <img src="/zodiac_wheel.png" alt="" className="h-8 w-8 rounded-full object-cover" />
          <span className="font-serif-display text-xl text-cosmic-cream">Kundali AI</span>
        </a>

        <nav className="hidden items-center gap-8 md:flex">
          {LINKS.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="text-sm text-cosmic-cream-dim transition hover:text-cosmic-gold-light"
            >
              {l.label}
            </a>
          ))}
        </nav>

        <a
          href="#waitlist"
          className="hidden rounded-full bg-cosmic-cream px-5 py-2 text-sm font-medium text-cosmic-bg-deep transition hover:bg-cosmic-gold-light md:inline-block"
        >
          Join the waitlist
        </a>

        <button
          className="text-cosmic-cream md:hidden"
          onClick={() => setMenuOpen((v) => !v)}
          aria-label="Toggle menu"
        >
          <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
            <path d="M4 6h16M4 12h16M4 18h16" strokeLinecap="round" />
          </svg>
        </button>
      </div>

      {menuOpen && (
        <div className="glass-card flex flex-col gap-4 px-6 py-6 md:hidden">
          {LINKS.map((l) => (
            <a
              key={l.href}
              href={l.href}
              onClick={() => setMenuOpen(false)}
              className="text-cosmic-cream-dim"
            >
              {l.label}
            </a>
          ))}
          <a
            href="#waitlist"
            onClick={() => setMenuOpen(false)}
            className="rounded-full bg-cosmic-cream px-5 py-2 text-center text-sm font-medium text-cosmic-bg-deep"
          >
            Join the waitlist
          </a>
        </div>
      )}
    </motion.header>
  )
}
