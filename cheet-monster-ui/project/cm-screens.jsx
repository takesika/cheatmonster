// cm-screens.jsx — Cheat Monsters: Arcane Codex (Western fantasy TCG / 日本語UI)

function ScreenFrame({ children, theme, dark = true }) {
  return (
    <div className="cm-screen cm-night-bg cm-eb" style={{
      ...themeStyle(theme),
      width: PHONE_W, height: PHONE_H,
      fontFamily: "'EB Garamond', 'Hiragino Mincho ProN', 'Yu Mincho', 'Noto Serif JP', serif",
    }}>
      <IOSStatusBar dark={dark} time="9:41" />
      {children}
    </div>
  );
}

function NavBar({ title, onBack }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '6px 16px 14px', position: 'relative',
    }}>
      <div onClick={onBack} className="cm-nav-back" style={{ visibility: onBack ? 'visible' : 'hidden' }}>
        <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
          <path d="M14 4 L7 11 L14 18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
      <div style={{
        fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
        fontWeight: 600, fontSize: 14, letterSpacing: '0.25em',
        color: 'var(--gold-light)',
        position: 'absolute', left: '50%', top: 12, transform: 'translateX(-50%)',
      }}>{title}</div>
      <div style={{ width: 36 }} />
    </div>
  );
}

function FleurDivider({ small = false }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}>
      <span style={{ width: small ? 30 : 60, height: 1, background: 'linear-gradient(90deg, transparent, var(--gold), transparent)' }} />
      <span className="cm-cinzel" style={{ color: 'var(--gold)', fontSize: small ? 9 : 11, letterSpacing: '0.3em' }}>✦</span>
      <span style={{ width: small ? 30 : 60, height: 1, background: 'linear-gradient(90deg, transparent, var(--gold), transparent)' }} />
    </div>
  );
}

// Animated arcane circle background element
function ArcaneCircle({ size = 280, opacity = 0.18 }) {
  return (
    <div style={{
      position: 'absolute', left: '50%', top: '50%',
      transform: 'translate(-50%,-50%)',
      width: size, height: size,
      pointerEvents: 'none', opacity,
    }}>
      <svg viewBox="0 0 200 200" style={{ width: '100%', height: '100%', animation: 'cm-rotate 80s linear infinite', transformOrigin: 'center' }}>
        <circle cx="100" cy="100" r="95" fill="none" stroke="#e2b864" strokeWidth="0.5" />
        <circle cx="100" cy="100" r="85" fill="none" stroke="#e2b864" strokeWidth="0.3" strokeDasharray="2 4" />
        <circle cx="100" cy="100" r="70" fill="none" stroke="#e2b864" strokeWidth="0.5" />
        <circle cx="100" cy="100" r="55" fill="none" stroke="#e2b864" strokeWidth="0.3" />
        {/* pentagram */}
        <polygon points="100,30 118,82 172,82 128,114 144,166 100,134 56,166 72,114 28,82 82,82"
          fill="none" stroke="#e2b864" strokeWidth="0.6" />
        {/* runes around */}
        {Array.from({ length: 12 }).map((_, i) => {
          const a = (i / 12) * Math.PI * 2;
          const x = 100 + Math.cos(a) * 90;
          const y = 100 + Math.sin(a) * 90;
          return <text key={i} x={x} y={y} fontSize="4" fill="#e2b864" textAnchor="middle">{['ᚠ','ᚱ','ᚦ','ᛟ','ᛉ','ᛊ','ᚷ','ᚺ','ᛏ','ᛁ','ᛒ','ᛗ'][i]}</text>;
        })}
      </svg>
    </div>
  );
}

// ───────────────────────────────
// 1. HOME
// ───────────────────────────────
function HomeScreen({ theme, remaining = 4, total = 5, wins = 1, plays = 1 }) {
  return (
    <ScreenFrame theme={theme}>
      <div style={{ position: 'absolute', top: 80, left: 0, right: 0, height: 320, overflow: 'hidden', pointerEvents: 'none' }}>
        <ArcaneCircle size={420} opacity={0.13} />
      </div>

      {/* logo lockup */}
      <div style={{ padding: '20px 24px 8px', textAlign: 'center', position: 'relative', zIndex: 1 }}>
        <FleurDivider />
        <div style={{
          fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
          fontSize: 10, color: 'var(--gold)', letterSpacing: '0.5em',
          marginTop: 14,
        }}>叡 智 ノ 写 本</div>
        <div className="cm-cinzel cm-engraved" style={{
          fontSize: 38, fontWeight: 800, lineHeight: 1.0,
          margin: '8px 0 4px',
          textTransform: 'uppercase',
        }}>Cheat<br />Monsters</div>
        <div style={{
          fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
          fontSize: 11, color: 'var(--ink-soft)', letterSpacing: '0.35em',
          marginTop: 10,
        }}>叡智ハ伝説ヲ鍛ウ</div>
      </div>

      {/* hero card preview */}
      <div style={{ display: 'flex', justifyContent: 'center', margin: '14px 0 14px', position: 'relative', zIndex: 1 }}>
        <div style={{
          position: 'absolute', top: -4, left: '50%', transform: 'translateX(-50%) rotate(-2deg)',
          background: 'var(--panel)', padding: '3px 14px',
          fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif", fontSize: 10, color: 'var(--gold-light)',
          letterSpacing: '0.3em', border: '0.5px solid var(--gold)',
          zIndex: 2,
        }}>直近の召喚</div>
        <div style={{ transform: 'rotate(-3deg)' }}>
          <MonsterCard scale={0.62} name="フレイムドラゴン" ability="全てを焼き尽くす炎" atk={71} def={52} art="flame" />
        </div>
        <div style={{ marginLeft: -32, transform: 'rotate(4deg) translateY(8px)', opacity: .85 }}>
          <MonsterCardBack scale={0.62} />
        </div>
      </div>

      {/* daily sigils */}
      <div style={{
        margin: '0 24px 14px', padding: '12px 16px',
        background: 'rgba(255,255,255,.03)',
        border: '1px solid var(--gold-deep)',
        borderRadius: 4,
        boxShadow: 'inset 0 0 0 1px rgba(0,0,0,.3)',
        textAlign: 'center', position: 'relative', zIndex: 1,
      }}>
        <div style={{
          fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
          fontSize: 11, color: 'var(--gold)', letterSpacing: '0.4em',
          marginBottom: 8,
        }}>本日の召喚権</div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 8 }}>
          {Array.from({ length: total }).map((_, i) => (
            <div key={i} className={`cm-sigil ${i < remaining ? 'cm-sigil-on' : 'cm-sigil-off'}`}>
              {i < remaining ? '✦' : ''}
            </div>
          ))}
        </div>
      </div>

      {/* mode buttons */}
      <div style={{ padding: '0 24px', display: 'flex', flexDirection: 'column', gap: 10, position: 'relative', zIndex: 1 }}>
        <div style={{
          background: 'linear-gradient(180deg, #a04848 0%, var(--seal) 60%, var(--seal-deep) 100%)',
          color: 'var(--gold-light)', padding: '14px 18px', borderRadius: 4,
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,.18), inset 0 -1px 0 rgba(0,0,0,.22), 0 2px 0 var(--seal-deep)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div>
            <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 10, opacity: .85, letterSpacing: '0.3em' }}>一人で挑む</div>
            <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 20, fontWeight: 700, letterSpacing: '0.18em', marginTop: 2 }}>三層の塔</div>
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            {[1,2,3].map(s => (
              <div key={s} className="cm-cinzel" style={{
                width: 22, height: 26,
                background: s === 1 ? 'var(--gold-light)' : 'rgba(255,255,255,.10)',
                color: s === 1 ? 'var(--seal-deep)' : 'var(--gold-light)',
                fontSize: 11, fontWeight: 800,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                clipPath: 'polygon(50% 0, 100% 25%, 100% 100%, 0 100%, 0 25%)',
              }}>{s}</div>
            ))}
          </div>
        </div>

        <div style={{
          background: 'rgba(255,255,255,.03)', color: 'var(--gold-light)',
          padding: '14px 18px', borderRadius: 4, border: '1px solid var(--gold)',
          boxShadow: 'inset 0 0 0 1px rgba(0,0,0,.25)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div>
            <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 10, color: 'var(--gold)', letterSpacing: '0.3em' }}>友と挑む</div>
            <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 20, fontWeight: 700, letterSpacing: '0.18em', marginTop: 2 }}>決闘の間</div>
          </div>
          <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 11, color: 'var(--ink-soft)' }}>合言葉で参加</div>
        </div>

        {/* PvP record */}
        <div style={{
          marginTop: 4, border: '0.5px dashed var(--gold-deep)',
          padding: '10px 12px', borderRadius: 2,
          display: 'flex', justifyContent: 'space-around', alignItems: 'center',
          background: 'rgba(0,0,0,.2)',
        }}>
          <Stat label="勝利" value={`${wins}`} />
          <span style={{ width: 1, height: 22, background: 'var(--gold-deep)', opacity: .4 }} />
          <Stat label="対戦" value={`${plays}`} />
          <span style={{ width: 1, height: 22, background: 'var(--gold-deep)', opacity: .4 }} />
          <Stat label="勝率" value={plays > 0 ? `${Math.round(wins/plays*100)}%` : '—'} />
        </div>
      </div>

      {/* footer */}
      <div style={{ position: 'absolute', bottom: 50, left: 0, right: 0, textAlign: 'center', zIndex: 1 }}>
        <FleurDivider small />
        <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 10, color: 'var(--ink-soft)', letterSpacing: '0.4em', marginTop: 6, opacity: .6 }}>
          審判 ・ 神託の予言者
        </div>
      </div>
    </ScreenFrame>
  );
}

function Stat({ label, value }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 10, color: 'var(--gold)', letterSpacing: '0.25em' }}>{label}</div>
      <div className="cm-cinzel" style={{ fontSize: 18, fontWeight: 800, color: 'var(--gold-light)', marginTop: 2 }}>{value}</div>
    </div>
  );
}

// ───────────────────────────────
// 2. SUMMON
// ───────────────────────────────
function SummonScreen({ theme, monsterName = 'フレイムドラゴン', ability = '全てを焼き尽くす炎' }) {
  return (
    <ScreenFrame theme={theme}>
      <NavBar title="召 喚" onBack={() => {}} />

      <div style={{ padding: '8px 24px 0', textAlign: 'center' }}>
        <FleurDivider small />
        <div className="cm-cinzel cm-engraved" style={{ fontSize: 24, fontWeight: 800, marginTop: 14, letterSpacing: '0.12em' }}>
          召喚の儀
        </div>
        <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 12, color: 'var(--ink-soft)', letterSpacing: '0.1em', marginTop: 6 }}>
          真名と異能を、汝の手で記せ
        </div>
      </div>

      <div style={{ padding: '20px 24px 0', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <FormField label="壱 ・ 真名" counter={`${monsterName.length}/20`} required>
          <div className="cm-cinzel" style={{
            fontSize: 19, fontWeight: 700, color: 'var(--ink-dark)',
            letterSpacing: '0.06em',
          }}>{monsterName}<span style={{
            display: 'inline-block', width: 1.5, height: 18, background: 'var(--seal)',
            marginLeft: 2, verticalAlign: 'middle',
          }} /></div>
        </FormField>

        <FormField label="弐 ・ 異能" counter={`${ability.length}/20`} accent>
          <div style={{
            fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
            fontSize: 16, fontWeight: 600, color: 'var(--ink-dark)',
            letterSpacing: '0.04em', lineHeight: 1.5,
          }}>{ability}</div>
          <div style={{
            fontFamily: "'Hiragino Mincho ProN', serif",
            marginTop: 6, fontSize: 10, color: 'var(--seal-deep)',
            letterSpacing: '0.05em',
          }}>※ 神託の予言者がこの言葉を解釈し、勝敗を裁く</div>
        </FormField>

        <div style={{
          display: 'flex', gap: 8, alignItems: 'stretch',
          background: 'rgba(244,232,200,.05)', border: '0.5px dashed var(--gold-deep)',
          borderRadius: 4, padding: '10px 12px',
        }}>
          <div style={{
            fontFamily: "'Hiragino Mincho ProN', serif",
            fontSize: 11, color: 'var(--gold)', letterSpacing: '0.25em',
            alignSelf: 'center', flex: '0 0 70px',
          }}>参 ・ 戦力</div>
          <div style={{ flex: 1, display: 'flex', justifyContent: 'space-around', alignItems: 'center' }}>
            <BlindStat label="攻" />
            <span style={{ color: 'var(--gold-deep)', fontFamily: "'Cinzel', serif", fontSize: 14, opacity: .5 }}>×</span>
            <BlindStat label="守" />
          </div>
        </div>

        <div style={{
          fontFamily: "'Hiragino Mincho ProN', serif",
          fontSize: 11, color: 'var(--ink-soft)', textAlign: 'center',
          letterSpacing: '0.06em', marginTop: -4,
        }}>戦力は召喚の刹那に運命が定める（1—100）</div>
      </div>

      <div style={{ position: 'absolute', bottom: 38, left: 24, right: 24 }}>
        <button className="cm-btn-gold" style={{ width: '100%', fontSize: 16, padding: '16px 0', fontFamily: "'Hiragino Mincho ProN', serif", fontWeight: 700, letterSpacing: '0.5em' }}>
          召 喚 す る
        </button>
      </div>
    </ScreenFrame>
  );
}

function FormField({ label, counter, children, required, accent }) {
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 5 }}>
        <span style={{
          fontFamily: "'Hiragino Mincho ProN', serif",
          fontSize: 11, fontWeight: 700,
          color: accent ? 'var(--seal)' : 'var(--gold)',
          letterSpacing: '0.3em',
        }}>{label}{required && <span style={{ color: 'var(--seal)', marginLeft: 4 }}>*</span>}</span>
        <span className="cm-cinzel" style={{ fontSize: 9, color: 'var(--ink-soft)', opacity: .8, letterSpacing: '0.1em' }}>{counter}</span>
      </div>
      <div style={{
        background: 'linear-gradient(180deg, #f0e2c0, #d8c298)',
        border: accent ? '1.5px solid var(--seal)' : '1px solid var(--gold-deep)',
        boxShadow: accent
          ? '0 0 0 2px rgba(138,58,58,.12), inset 0 0 0 1px #efe0bb'
          : 'inset 0 0 0 1px #efe0bb, 0 1px 4px rgba(0,0,0,.25)',
        borderRadius: 3, padding: '12px 14px',
        backgroundImage: 'repeating-linear-gradient(0deg, transparent 0 22px, rgba(140,110,60,.06) 22px 23px), linear-gradient(180deg, #f0e2c0, #d8c298)',
      }}>{children}</div>
    </div>
  );
}

function BlindStat({ label }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
      <span style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 11, color: 'var(--gold)', letterSpacing: '0.15em' }}>{label}</span>
      <span className="cm-cinzel" style={{ fontSize: 22, color: 'var(--gold-deep)', fontWeight: 800 }}>??</span>
    </div>
  );
}

// ───────────────────────────────
// 3. SUMMON RESULT
// ───────────────────────────────
function SummonResultScreen({ theme }) {
  return (
    <ScreenFrame theme={theme}>
      <div style={{ position: 'absolute', top: 200, left: 0, right: 0, height: 400, pointerEvents: 'none' }}>
        <ArcaneCircle size={500} opacity={0.22} />
      </div>
      <div style={{
        position: 'absolute', top: 300, left: '50%', transform: 'translateX(-50%)',
        width: 600, height: 600,
        background: `conic-gradient(from 0deg, transparent 0deg, rgba(226,184,100,.18) 8deg, transparent 16deg, transparent 30deg, rgba(226,184,100,.12) 38deg, transparent 46deg)`,
        animation: 'cm-rotate-cw 60s linear infinite',
        zIndex: 0, opacity: .55,
      }} />
      <style>{`@keyframes cm-rotate-cw { to { transform: translateX(-50%) rotate(360deg); } }`}</style>

      <div style={{ padding: '40px 24px 0', textAlign: 'center', position: 'relative', zIndex: 1 }}>
        <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 11, color: 'var(--gold)', letterSpacing: '0.5em' }}>魔獣 ・ 顕現</div>
        <div className="cm-cinzel cm-engraved" style={{
          fontSize: 38, fontWeight: 800, marginTop: 8,
          fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
          letterSpacing: '0.3em',
        }}>召 喚 成 功</div>
        <div style={{ marginTop: 10 }}><FleurDivider small /></div>
      </div>

      <div style={{ display: 'flex', justifyContent: 'center', marginTop: 30, position: 'relative', zIndex: 1 }}>
        <div style={{ filter: 'drop-shadow(0 12px 30px rgba(0,0,0,.5)) drop-shadow(0 0 18px rgba(184,151,82,.18))' }}>
          <MonsterCard scale={1.05} name="フレイムドラゴン" ability="全てを焼き尽くす炎" atk={71} def={52} art="flame" />
        </div>
        <div className="cm-wax-seal" style={{
          position: 'absolute', top: -8, right: 28,
          width: 54, height: 54, fontSize: 18, fontWeight: 900,
          fontFamily: "'Hiragino Mincho ProN', serif",
          transform: 'rotate(-6deg)',
        }}>封</div>
      </div>

      <div style={{ padding: '24px 32px 0', textAlign: 'center', position: 'relative', zIndex: 1 }}>
        <div style={{
          fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
          fontSize: 13, color: 'var(--ink-soft)', letterSpacing: '0.08em',
          lineHeight: 1.9,
        }}>戦力は定まり、異能は刻まれた。<br />汝の魔獣、審判の場にて待つ。</div>
      </div>

      <div style={{ position: 'absolute', bottom: 38, left: 24, right: 24 }}>
        <button className="cm-btn-crimson" style={{ width: '100%', fontSize: 16, padding: '16px 0', fontFamily: "'Hiragino Mincho ProN', serif", fontWeight: 700, letterSpacing: '0.4em' }}>
          審判の場へ
        </button>
      </div>
    </ScreenFrame>
  );
}

// ───────────────────────────────
// 4. BATTLE READY
// ───────────────────────────────
function BattleReadyScreen({ theme }) {
  return (
    <ScreenFrame theme={theme}>
      <div style={{ padding: '12px 24px 0', textAlign: 'center' }}>
        <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 11, color: 'var(--gold)', letterSpacing: '0.4em' }}>第一層 ・ 三層の塔</div>
        <div className="cm-cinzel cm-engraved" style={{
          fontSize: 26, fontWeight: 800, marginTop: 6,
          fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
          letterSpacing: '0.4em',
        }}>審 判 の 場</div>
      </div>

      <div style={{
        position: 'relative', height: 470, margin: '14px 0 0',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <ArcaneCircle size={340} opacity={0.18} />
        <div style={{
          position: 'absolute', inset: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 1, pointerEvents: 'none',
        }}>
          <div className="cm-cinzel" style={{
            fontSize: 130, fontWeight: 900, lineHeight: 1,
            color: 'transparent',
            background: 'linear-gradient(180deg, #d4b97a 0%, #8a3a3a 60%, #4a1c1c 100%)',
            WebkitBackgroundClip: 'text', backgroundClip: 'text',
            filter: 'drop-shadow(0 4px 0 rgba(0,0,0,.5))',
            letterSpacing: '0.02em',
          }}>對</div>
        </div>

        {/* player card */}
        <div style={{ position: 'absolute', left: 12, top: 30, transform: 'rotate(-5deg)', zIndex: 2 }}>
          <div style={{
            position: 'absolute', top: -18, left: 12, zIndex: 3,
            background: 'rgba(20,30,80,.9)', padding: '3px 14px',
            color: 'var(--gold-light)', fontSize: 11,
            letterSpacing: '0.4em',
            border: '0.5px solid var(--gold)',
            fontFamily: "'Hiragino Mincho ProN', serif",
          }}>汝</div>
          <MonsterCard scale={0.78} name="フレイムドラゴン" ability="全てを焼き尽くす炎" atk={71} def={52} art="flame" selected />
        </div>

        {/* enemy card */}
        <div style={{ position: 'absolute', right: 12, bottom: 30, transform: 'rotate(5deg)', zIndex: 2 }}>
          <div style={{
            position: 'absolute', top: -18, right: 12, zIndex: 3,
            background: 'var(--seal)', padding: '3px 14px',
            color: 'var(--gold-light)', fontSize: 11,
            letterSpacing: '0.4em',
            border: '0.5px solid var(--seal-deep)',
            fontFamily: "'Hiragino Mincho ProN', serif",
          }}>敵</div>
          <MonsterCard scale={0.78} name="ヴォルテックス" ability="召喚時、相手のライフを0にする" atk={33} def={99} art="thunder" />
        </div>
      </div>

      <div style={{
        margin: '14px 32px 0', padding: '8px 12px', textAlign: 'center',
        border: '0.5px solid var(--gold)', background: 'rgba(0,0,0,.25)', borderRadius: 4,
      }}>
        <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 10, color: 'var(--gold)', letterSpacing: '0.4em' }}>審判 ・ 神託の予言者</div>
        <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 12, color: 'var(--gold-light)', letterSpacing: '0.25em', marginTop: 3, fontWeight: 600 }}>
          <span style={{ color: 'var(--seal)' }}>◉</span> 神託の予言者 ・ ジェミニ
        </div>
      </div>

      <div style={{ position: 'absolute', bottom: 38, left: 24, right: 24 }}>
        <button className="cm-btn-crimson" style={{ width: '100%', fontSize: 18, padding: '16px 0', fontFamily: "'Hiragino Mincho ProN', serif", fontWeight: 700, letterSpacing: '0.6em' }}>
          開 戦
        </button>
      </div>
    </ScreenFrame>
  );
}

// ───────────────────────────────
// 5. RESULT
// ───────────────────────────────
function ResultScreen({ theme, win = false }) {
  return (
    <ScreenFrame theme={theme}>
      <div style={{ padding: '14px 24px 0', textAlign: 'center' }}>
        <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 11, color: 'var(--gold)', letterSpacing: '0.5em' }}>判 ・ 決</div>
        <div className="cm-cinzel cm-engraved" style={{ fontSize: 26, fontWeight: 800, marginTop: 6,
          fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
          letterSpacing: '0.4em',
        }}>
          神 託 の 裁 定
        </div>
      </div>

      <div style={{
        margin: '14px 16px 0', padding: '20px 22px 18px', position: 'relative',
        background: 'linear-gradient(180deg, #f0e2c0 0%, #d8c298 100%)',
        backgroundImage:
          'radial-gradient(ellipse at 30% 20%, rgba(255,250,230,.7) 0%, transparent 70%),' +
          'radial-gradient(ellipse at 80% 90%, rgba(140,110,60,.14) 0%, transparent 60%),' +
          'repeating-linear-gradient(0deg, transparent 0 26px, rgba(140,110,60,.06) 26px 27px),' +
          'linear-gradient(180deg, #f0e2c0 0%, #d8c298 100%)',
        border: '1px solid var(--gold-deep)',
        boxShadow: 'inset 0 0 0 3px #f0e2c0, inset 0 0 0 4px var(--gold), 0 6px 22px rgba(0,0,0,.45)',
        borderRadius: 4,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 18, marginBottom: 14 }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 13, color: 'var(--seal-deep)', letterSpacing: '0.4em', fontWeight: 700 }}>
              {win ? '勝 利' : '敗 北'}
            </div>
            <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 12, color: 'var(--ink-soft-dark)', letterSpacing: '0.05em', marginTop: 4 }}>
              神託は下された
            </div>
          </div>
          <div className="cm-wax-seal" style={{
            width: 84, height: 84, fontSize: 26, fontWeight: 800,
            fontFamily: "'Hiragino Mincho ProN', serif",
            transform: 'rotate(-8deg)',
          }}>{win ? '勝' : '敗'}</div>
        </div>

        <div style={{ display: 'flex', gap: 10, justifyContent: 'center', marginBottom: 14 }}>
          <MonsterCard scale={0.42} name="フレイムドラゴン" ability="全てを焼き尽くす炎" atk={71} def={52} art="flame" faded={!win} />
          <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", color: 'var(--seal-deep)', fontSize: 26, alignSelf: 'center', opacity: .55, fontWeight: 800 }}>對</div>
          <MonsterCard scale={0.42} name="ヴォルテックス" ability="召喚時、相手のライフを0にする" atk={33} def={99} art="thunder" faded={win} />
        </div>

        <div style={{ borderTop: '0.5px solid var(--gold-deep)', paddingTop: 12 }}>
          <div style={{
            fontFamily: "'Hiragino Mincho ProN', serif",
            fontSize: 10, color: 'var(--seal-deep)', letterSpacing: '0.3em', marginBottom: 8,
          }}>― 神託の予言者による裁定 ―</div>
          <div style={{
            fontFamily: "'Hiragino Mincho ProN', 'Yu Mincho', serif",
            fontSize: 13, color: 'var(--ink-dark)', lineHeight: 1.9,
            letterSpacing: '0.04em', textAlign: 'justify',
          }}>
            「ヴォルテックス」が場に召喚されたその瞬間、時空を超えた絶対の力が発動した。「フレイムドラゴン」の全てを焼き尽くす炎が荒ぶる前に、その生命の灯は本源より消し去られた。
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 8, marginTop: 14 }}>
          <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 10, color: 'var(--ink-soft-dark)', letterSpacing: '0.15em' }}>
            予言者 ・ 印
          </div>
          <div className="cm-wax-seal" style={{ width: 24, height: 24, fontSize: 11, fontFamily: "'Hiragino Mincho ProN', serif", transform: 'rotate(-8deg)' }}>印</div>
        </div>
      </div>

      <div style={{ position: 'absolute', bottom: 38, left: 24, right: 24, display: 'flex', gap: 10 }}>
        <button className="cm-btn-gold-outline" style={{ flex: 1, fontSize: 12, padding: '12px 0', fontFamily: "'Hiragino Mincho ProN', serif", letterSpacing: '0.3em' }}>戻る</button>
        <button className="cm-btn-crimson" style={{ flex: 1.4, fontSize: 13, padding: '12px 0', fontFamily: "'Hiragino Mincho ProN', serif", letterSpacing: '0.3em' }}>再 戦</button>
      </div>
    </ScreenFrame>
  );
}

// ───────────────────────────────
// 6. ROOM
// ───────────────────────────────
function RoomScreen({ theme }) {
  return (
    <ScreenFrame theme={theme}>
      <NavBar title="決闘の間" onBack={() => {}} />

      <div style={{ padding: '8px 24px 0', textAlign: 'center' }}>
        <FleurDivider small />
        <div className="cm-cinzel cm-engraved" style={{ fontSize: 24, fontWeight: 800, marginTop: 14, letterSpacing: '0.12em' }}>
          合言葉で繋ぐ
        </div>
        <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 12, color: 'var(--ink-soft)', letterSpacing: '0.06em', marginTop: 8 }}>
          合言葉を共有し、友を召喚せよ
        </div>
      </div>

      {/* Create — primary */}
      <div style={{ padding: '24px 24px 0' }}>
        <div style={{
          background: 'rgba(255,255,255,.03)', borderRadius: 4,
          border: '1px solid var(--gold)',
          boxShadow: 'inset 0 0 0 1px rgba(0,0,0,.25), 0 2px 0 var(--gold-deep)',
          padding: '18px 20px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
            <div className="cm-wax-seal" style={{ width: 32, height: 32, fontSize: 13, fontFamily: "'Hiragino Mincho ProN', serif" }}>主</div>
            <div>
              <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 17, fontWeight: 700, letterSpacing: '0.18em', color: 'var(--gold-light)' }}>
                部屋を開く
              </div>
              <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 11, color: 'var(--ink-soft)', marginTop: 2 }}>
                合言葉を発行し、友を待つ
              </div>
            </div>
          </div>
          <div style={{
            background: 'rgba(0,0,0,.3)', border: '0.5px dashed var(--gold-deep)', borderRadius: 3,
            padding: '10px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 10,
          }}>
            <span style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 11, color: 'var(--gold)', letterSpacing: '0.3em' }}>合言葉</span>
            <span className="cm-cinzel" style={{ fontSize: 22, fontWeight: 800, letterSpacing: '0.2em', color: 'var(--gold-light)' }}>朱雀 ・ 玄武</span>
          </div>
          <button className="cm-btn-gold" style={{ width: '100%', marginTop: 12, fontSize: 14, padding: '12px 0', fontFamily: "'Hiragino Mincho ProN', serif", letterSpacing: '0.4em' }}>
            開 く
          </button>
        </div>
      </div>

      {/* divider */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '20px 32px 16px' }}>
        <span style={{ flex: 1, height: 0.5, background: 'var(--gold-deep)', opacity: .5 }} />
        <span style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 12, color: 'var(--gold)', letterSpacing: '0.4em' }}>又は</span>
        <span style={{ flex: 1, height: 0.5, background: 'var(--gold-deep)', opacity: .5 }} />
      </div>

      {/* Join — secondary */}
      <div style={{ padding: '0 24px' }}>
        <div style={{
          background: 'rgba(0,0,0,.2)', border: '1px solid var(--gold-deep)',
          borderRadius: 4, padding: '14px 20px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
            <div style={{
              width: 28, height: 28, background: 'rgba(255,255,255,.06)',
              color: 'var(--gold-light)', display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 13, fontWeight: 700, border: '1px solid var(--gold)', borderRadius: 14,
              fontFamily: "'Hiragino Mincho ProN', serif",
            }}>客</div>
            <div style={{ fontFamily: "'Hiragino Mincho ProN', serif", fontSize: 16, fontWeight: 700, letterSpacing: '0.18em', color: 'var(--gold-light)' }}>
              部屋に入る
            </div>
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 8, justifyContent: 'center' }}>
            {['朱','雀','玄','武','◯','◯'].map((c, i) => (
              <div key={i} className="cm-cinzel" style={{
                width: 38, height: 46,
                background: 'linear-gradient(180deg, #f0e2c0, #d8c298)',
                border: '1px solid var(--gold-deep)', borderRadius: 3,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 22, fontWeight: 800, color: '#1c1a2c',
                opacity: i < 4 ? 1 : .35,
                boxShadow: i === 4 ? '0 0 0 2px var(--seal), inset 0 0 0 1px #efe0bb' : 'inset 0 0 0 1px #efe0bb',
              }}>{i < 4 ? c : ''}</div>
            ))}
          </div>
          <button className="cm-btn-gold-outline" style={{ width: '100%', marginTop: 12, fontSize: 12, padding: '10px 0', fontFamily: "'Hiragino Mincho ProN', serif", letterSpacing: '0.3em' }}>
            繋 ぐ
          </button>
        </div>
      </div>

      {/* recent foes */}
      <div style={{ position: 'absolute', bottom: 50, left: 24, right: 24 }}>
        <div style={{
          fontFamily: "'Hiragino Mincho ProN', serif",
          fontSize: 11, color: 'var(--gold)', letterSpacing: '0.35em',
          textAlign: 'center', marginBottom: 8,
        }}>直近の対戦相手</div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 8 }}>
          {['友','蓮','凛'].map((n, i) => (
            <div key={i} style={{
              width: 36, height: 36, borderRadius: '50%',
              background: 'rgba(255,255,255,.04)', border: '1px solid var(--gold-deep)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 14, fontWeight: 700, color: 'var(--gold-light)',
              fontFamily: "'Hiragino Mincho ProN', serif",
            }}>{n}</div>
          ))}
        </div>
      </div>
    </ScreenFrame>
  );
}

Object.assign(window, {
  HomeScreen, SummonScreen, SummonResultScreen,
  BattleReadyScreen, ResultScreen, RoomScreen,
});
