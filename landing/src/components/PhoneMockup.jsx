export default function PhoneMockup({ src, alt, className = '', tilt = 0, glow = true }) {
  return (
    <div
      className={`relative ${className}`}
      style={{ transform: tilt ? `rotate(${tilt}deg)` : undefined }}
    >
      {glow && (
        <div className="absolute -inset-6 rounded-[3rem] bg-cosmic-gold/20 blur-3xl" />
      )}
      <div className="relative rounded-[2.2rem] border-[3px] border-cosmic-gold/40 bg-black p-2 shadow-2xl shadow-black/60">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 z-10 h-5 w-24 rounded-b-2xl bg-black" />
        <div className="overflow-hidden rounded-[1.7rem]">
          <img
            src={src}
            alt={alt}
            className="block h-auto w-full select-none"
            draggable={false}
          />
        </div>
      </div>
    </div>
  )
}
