export default function Footer() {
  return (
    <footer className="border-t border-cosmic-gold/10 py-10">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 text-sm text-cosmic-cream-dim md:flex-row">
        <div className="flex items-center gap-2">
          <img src="/zodiac_wheel.png" alt="" className="h-6 w-6 rounded-full object-cover" />
          <span>Kundali AI — Your Cosmic AI Companion</span>
        </div>

        <div className="flex items-center gap-6">
          <a
            href="https://github.com/n2coder/KundaliAI"
            target="_blank"
            rel="noreferrer"
            className="transition hover:text-cosmic-gold-light"
          >
            GitHub
          </a>
          <a href="#" className="transition hover:text-cosmic-gold-light">
            Privacy Policy
          </a>
          <a href="#" className="transition hover:text-cosmic-gold-light">
            Terms of Service
          </a>
        </div>
      </div>
    </footer>
  )
}
