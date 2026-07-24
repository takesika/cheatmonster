// cm-card.jsx — Cheat Monsters card (Western TCG: arcane parchment scroll)

const PLACEHOLDER_BEAST_SVGS = {
  flame: (
    <svg viewBox="0 0 100 100" preserveAspectRatio="xMidYMid slice" style={{ width: '100%', height: '100%' }}>
      <defs>
        <radialGradient id="f-grad" cx="50%" cy="65%" r="60%">
          <stop offset="0%" stopColor="#ffd06b" />
          <stop offset="40%" stopColor="#e8541a" />
          <stop offset="100%" stopColor="#3b1208" />
        </radialGradient>
      </defs>
      <rect width="100" height="100" fill="url(#f-grad)" />
      <path d="M50 18 C 30 36, 24 50, 32 66 C 38 76, 46 80, 50 88 C 54 80, 62 76, 68 66 C 76 50, 70 36, 50 18 Z" fill="#ffd06b" opacity="0.85" />
      <path d="M50 32 C 40 44, 38 56, 44 66 C 48 72, 50 76, 50 82 C 50 76, 52 72, 56 66 C 62 56, 60 44, 50 32 Z" fill="#fff7d4" opacity="0.7" />
    </svg>
  ),
  thunder: (
    <svg viewBox="0 0 100 100" preserveAspectRatio="xMidYMid slice" style={{ width: '100%', height: '100%' }}>
      <defs>
        <linearGradient id="t-grad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#3a2a6a" />
          <stop offset="100%" stopColor="#0a0612" />
        </linearGradient>
      </defs>
      <rect width="100" height="100" fill="url(#t-grad)" />
      <path d="M55 12 L 30 52 L 46 54 L 38 88 L 70 42 L 54 40 L 62 12 Z" fill="#ffd84a" stroke="#fff8c8" strokeWidth="0.8" />
    </svg>
  ),
};

function StatBadge({ label, value, accent }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '3px 7px',
      background: accent ? 'linear-gradient(180deg,#d8485a,#8b1c2c)' : 'linear-gradient(180deg,#1d2a52,#0d1530)',
      color: '#f5d68f',
      border: `1px solid ${accent ? '#5a0e1a' : '#2a3866'}`,
      borderRadius: 3,
      fontFamily: "'Cinzel', serif",
      fontWeight: 800,
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,.18), 0 1px 0 rgba(0,0,0,.3)',
    }}>
      <span style={{ fontSize: 8, letterSpacing: '0.15em', opacity: .9 }}>{label}</span>
      <span style={{ fontSize: 14, fontVariantNumeric: 'tabular-nums', lineHeight: 1 }}>{value}</span>
    </div>
  );
}

function MonsterCard({
  name = 'Flame Dragon',
  ability = '全てを焼き尽くす炎',
  atk = 71,
  def = 52,
  art = 'flame',
  scale = 1,
  faded = false,
  selected = false,
}) {
  const w = 200 * scale;
  const h = 300 * scale;
  return (
    <div style={{
      width: w, height: h,
      position: 'relative',
      background: 'linear-gradient(180deg, #f8eed0 0%, #e8d5a0 100%)',
      backgroundImage:
        'radial-gradient(ellipse at 25% 20%, rgba(255,253,240,.9) 0%, transparent 70%),' +
        'radial-gradient(ellipse at 80% 90%, rgba(180,140,80,.18) 0%, transparent 60%),' +
        'linear-gradient(180deg, #faecc8 0%, #e6cf95 100%)',
      borderRadius: 5,
      padding: 7 * scale,
      boxShadow:
        `inset 0 0 0 1.5px var(--gold-deep),` +
        `inset 0 0 0 3px #f8eed0,` +
        `inset 0 0 0 4.5px var(--gold),` +
        `0 ${10 * scale}px ${24 * scale}px rgba(0,0,0,.45),` +
        `0 0 0 1px rgba(0,0,0,.3)`,
      filter: faded ? 'grayscale(.5) brightness(.85)' : 'none',
      transform: selected ? `scale(1.02)` : 'none',
      transition: 'transform .25s, filter .25s',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* corner fleur ornaments */}
      {[
        { top: 5, left: 5, rot: 0 },
        { top: 5, right: 5, rot: 90 },
        { bottom: 5, left: 5, rot: 270 },
        { bottom: 5, right: 5, rot: 180 },
      ].map((p, i) => (
        <svg key={i} width={10 * scale} height={10 * scale} viewBox="0 0 10 10"
             style={{ position: 'absolute', top: p.top, left: p.left, right: p.right, bottom: p.bottom, transform: `rotate(${p.rot}deg)` }}>
          <path d="M0 0 L10 0 L10 1.5 L1.5 1.5 L1.5 10 L0 10 Z M2.5 2.5 L4 2.5 L4 4 L2.5 4 Z" fill="#7a5520" />
        </svg>
      ))}

      {/* name plaque */}
      <div className="cm-cinzel" style={{
        textAlign: 'center',
        fontWeight: 800,
        fontSize: 12 * scale,
        color: '#1a1428',
        letterSpacing: '0.12em',
        padding: `${2 * scale}px 0 ${4 * scale}px`,
        borderBottom: `0.5px solid var(--gold-deep)`,
        marginBottom: 5 * scale,
        textTransform: 'uppercase',
      }}>{name}</div>

      {/* art window */}
      <div style={{
        flex: '1 1 auto',
        position: 'relative',
        border: '1.5px solid #5a3e18',
        borderRadius: 2,
        overflow: 'hidden',
        boxShadow: 'inset 0 0 0 1px #f8eed0, inset 0 0 12px rgba(60,40,20,.3)',
      }}>
        {PLACEHOLDER_BEAST_SVGS[art] || PLACEHOLDER_BEAST_SVGS.flame}
        {/* watermark sigil */}
        <div style={{
          position: 'absolute', bottom: 4, right: 4,
          width: 16 * scale, height: 16 * scale,
          borderRadius: '50%',
          border: '1px solid #c8364a',
          color: '#c8364a',
          background: 'rgba(248,238,208,.7)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: "'Cinzel', serif",
          fontSize: 8 * scale, fontWeight: 900,
        }}>✦</div>
      </div>

      {/* stats */}
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: `${5 * scale}px 2px ${4 * scale}px` }}>
        <StatBadge label="ATK" value={atk} accent />
        <StatBadge label="DEF" value={def} />
      </div>

      {/* ability strip */}
      <div className="cm-eb" style={{
        background: 'rgba(248,238,208,.6)',
        border: '0.5px solid var(--gold-deep)',
        borderRadius: 2,
        padding: `${5 * scale}px ${6 * scale}px`,
        textAlign: 'center',
        fontSize: 10 * scale,
        fontWeight: 600,
        color: '#3a2c14',
        letterSpacing: '0.02em',
        whiteSpace: 'nowrap',
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        fontStyle: 'italic',
      }}>
        ❦ {ability} ❦
      </div>
    </div>
  );
}

function MonsterCardBack({ scale = 1 }) {
  const w = 200 * scale;
  const h = 300 * scale;
  return (
    <div style={{
      width: w, height: h,
      position: 'relative',
      background: 'linear-gradient(135deg, #1a1840 0%, #0a0820 100%)',
      borderRadius: 5,
      boxShadow:
        `inset 0 0 0 1.5px var(--gold-deep),` +
        `inset 0 0 0 3px #0a0820,` +
        `inset 0 0 0 4.5px var(--gold),` +
        `0 ${10 * scale}px ${24 * scale}px rgba(0,0,0,.5)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <div style={{
        width: 70 * scale, height: 70 * scale,
        borderRadius: '50%',
        border: `1.5px solid var(--gold)`,
        boxShadow: `inset 0 0 0 4px #0a0820, inset 0 0 0 5px var(--gold), 0 0 20px rgba(226,184,100,.4)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--gold-light)',
        fontFamily: "'Cinzel', serif",
        fontSize: 30 * scale,
        fontWeight: 900,
        background: 'radial-gradient(circle, #2a2060 0%, #0a0820 100%)',
      }}>✦</div>
    </div>
  );
}

Object.assign(window, { MonsterCard, MonsterCardBack, StatBadge, PLACEHOLDER_BEAST_SVGS });
