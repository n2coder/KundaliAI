import Navbar from './components/Navbar'
import Hero from './components/Hero'
import HowItWorks from './components/HowItWorks'
import Features from './components/Features'
import Stats from './components/Stats'
import Showcase from './components/Showcase'
import Waitlist from './components/Waitlist'
import Footer from './components/Footer'

function App() {
  return (
    <div className="min-h-screen bg-cosmic-bg font-sans text-cosmic-cream">
      <Navbar />
      <main>
        <Hero />
        <HowItWorks />
        <Features />
        <Stats />
        <Showcase />
        <Waitlist />
      </main>
      <Footer />
    </div>
  )
}

export default App
