// cm-tokens.jsx — Cheat Monsters: Arcane Codex (Western fantasy TCG)
// Midnight blue × gold × crimson seal × parchment

const CM_THEMES = {
  arcane: {
    name: 'Arcane Codex',
    bg: '#0c1228',          // ややくすんだ深藍
    bgDeep: '#06091a',
    panel: '#141b3a',
    panelLight: '#1d2750',
    parchment: '#ede0c0',   // 落ち着いた羊皮紙
    parchmentDeep: '#cfb98c',
    ink: '#e8dcb8',         // text on dark
    inkDark: '#1c1a2c',     // text on parchment
    inkSoft: '#9aa4c6',
    inkSoftDark: '#5a4f3c',
    seal: '#8a3a3a',        // 落ち着いた朱（カジノ赤からトーン落とし）
    sealDeep: '#5a2424',
    gold: '#b89752',        // くすみゴールド（ピカピカ感を抑える）
    goldLight: '#d4b97a',
    goldDeep: '#7e6228',
    goldGlow: '#d4b97a',
    line: '#2e3760',
    win: '#b89752',
    lose: '#5d5470',
    starlight: '#7a87b0',
  },
  parchment: {  // alt: lighter daytime variant
    name: 'Cathedral Light',
    bg: '#f6efde',
    bgDeep: '#e6d8b6',
    panel: '#fcf7e6',
    panelLight: '#fffcf2',
    parchment: '#fdf7e4',
    parchmentDeep: '#e6d2a8',
    ink: '#241f3a',
    inkDark: '#241f3a',
    inkSoft: '#6a5d4a',
    inkSoftDark: '#6a5d4a',
    seal: '#b22c3a',
    sealDeep: '#7a1820',
    gold: '#b8893a',
    goldLight: '#d9b063',
    goldDeep: '#7d5b21',
    goldGlow: '#e8c87a',
    line: '#c9b48c',
    win: '#9a7a2a',
    lose: '#7a6450',
    starlight: '#c9b48c',
  },
};

const PHONE_W = 393;
const PHONE_H = 852;

function themeStyle(theme) {
  const out = { color: theme.ink };
  Object.entries(theme).forEach(([k, v]) => {
    out[`--${k.replace(/[A-Z]/g, m => '-' + m.toLowerCase())}`] = v;
  });
  return out;
}

if (typeof document !== 'undefined' && !document.getElementById('cm-styles')) {
  const s = document.createElement('style');
  s.id = 'cm-styles';
  s.textContent = `
    .cm-cinzel { font-family: 'Cinzel', 'Trajan Pro', serif; font-feature-settings: 'liga'; }
    .cm-cormorant { font-family: 'Cormorant Garamond', 'EB Garamond', serif; }
    .cm-uncial { font-family: 'UnifrakturCook', 'Cinzel', serif; }
    .cm-eb { font-family: 'EB Garamond', 'Cormorant Garamond', serif; }

    /* night sky w/ subtle starfield (calmer, less casino) */
    .cm-night-bg {
      background-color: var(--bg);
      background-image:
        radial-gradient(ellipse at 50% 0%, rgba(122,135,176,.10) 0%, transparent 60%),
        radial-gradient(ellipse at 80% 100%, rgba(184,151,82,.06) 0%, transparent 50%),
        radial-gradient(circle at 15% 25%, rgba(255,255,255,.35) 0.5px, transparent 1.2px),
        radial-gradient(circle at 75% 18%, rgba(255,255,255,.22) 0.5px, transparent 1.2px),
        radial-gradient(circle at 35% 65%, rgba(255,255,255,.28) 0.5px, transparent 1.2px),
        radial-gradient(circle at 88% 70%, rgba(255,255,255,.30) 0.5px, transparent 1.2px),
        radial-gradient(circle at 22% 88%, rgba(255,255,255,.22) 0.5px, transparent 1.2px),
        radial-gradient(circle at 60% 40%, rgba(255,255,255,.18) 0.5px, transparent 1.2px),
        linear-gradient(180deg, var(--bg) 0%, var(--bg-deep) 100%);
    }
    /* parchment page surface */
    .cm-parchment-bg {
      background-color: var(--parchment);
      background-image:
        radial-gradient(ellipse at 30% 20%, rgba(255,253,240,.85) 0%, transparent 70%),
        radial-gradient(ellipse at 80% 90%, rgba(180,140,80,.18) 0%, transparent 60%),
        repeating-linear-gradient(0deg, transparent 0 2px, rgba(140,110,60,.025) 2px 3px);
    }

    /* engraved title — muted gold, less metallic shine */
    .cm-engraved {
      background: linear-gradient(180deg, var(--gold-light) 0%, var(--gold) 55%, var(--gold-deep) 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      filter: drop-shadow(0 1px 0 rgba(0,0,0,.4));
      letter-spacing: 0.14em;
    }
    .cm-engraved-dark {
      background: linear-gradient(180deg, #6a5028 0%, #3d2c14 100%);
      -webkit-background-clip: text;
      background-clip: text;
      -webkit-text-fill-color: transparent;
      letter-spacing: 0.15em;
    }

    /* wax seal — circular pressed-wax look (toned down) */
    .cm-wax-seal {
      display: inline-flex; align-items: center; justify-content: center;
      background: radial-gradient(circle at 35% 30%, #a25050 0%, var(--seal) 55%, var(--seal-deep) 100%);
      color: var(--gold-light);
      border-radius: 50%;
      font-family: 'Cinzel', 'Hiragino Mincho ProN', 'Yu Mincho', serif;
      font-weight: 800;
      box-shadow:
        inset 1px 1px 2px rgba(255,255,255,.18),
        inset -1px -2px 4px rgba(0,0,0,.35),
        0 2px 5px rgba(60,20,20,.45),
        0 0 0 1px rgba(0,0,0,.18);
      position: relative;
    }
    .cm-wax-seal::after {
      content: '';
      position: absolute; inset: 4px;
      border: 1px dashed rgba(255,220,180,.5);
      border-radius: 50%;
      pointer-events: none;
    }

    /* gold filigree border helper */
    .cm-gold-frame {
      border: 1px solid var(--gold);
      box-shadow:
        inset 0 0 0 3px var(--panel),
        inset 0 0 0 4px var(--gold-deep),
        0 4px 18px rgba(0,0,0,.35);
    }

    /* CTA — muted gold, no glow halo (tones down casino feel) */
    .cm-btn-gold {
      background: linear-gradient(180deg, var(--gold-light) 0%, var(--gold) 60%, var(--gold-deep) 100%);
      color: #1a1428;
      border: 1px solid var(--gold-deep);
      font-family: 'Cinzel', 'Hiragino Mincho ProN', 'Yu Mincho', serif;
      font-weight: 700;
      letter-spacing: 0.18em;
      padding: 14px 28px;
      border-radius: 4px;
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,.35),
        inset 0 -1px 0 rgba(0,0,0,.18),
        0 2px 0 var(--gold-deep);
      cursor: pointer;
    }
    .cm-btn-gold-outline {
      background: rgba(255,255,255,0.03);
      color: var(--gold-light);
      border: 1px solid var(--gold);
      font-family: 'Cinzel', 'Hiragino Mincho ProN', 'Yu Mincho', serif;
      font-weight: 600;
      letter-spacing: 0.18em;
      padding: 12px 22px;
      border-radius: 4px;
      box-shadow: inset 0 0 0 1px rgba(0,0,0,.25);
      cursor: pointer;
    }
    .cm-btn-crimson {
      background: linear-gradient(180deg, #a04848 0%, var(--seal) 60%, var(--seal-deep) 100%);
      color: var(--gold-light);
      border: 1px solid var(--seal-deep);
      font-family: 'Cinzel', 'Hiragino Mincho ProN', 'Yu Mincho', serif;
      font-weight: 700;
      letter-spacing: 0.18em;
      padding: 14px 28px;
      border-radius: 4px;
      box-shadow:
        inset 0 1px 0 rgba(255,255,255,.18),
        inset 0 -1px 0 rgba(0,0,0,.22),
        0 2px 0 var(--seal-deep);
      cursor: pointer;
    }

    .cm-cta-pulse { /* glow removed — calm, premium */ }

    /* daily charm — wax sigil pip */
    .cm-sigil {
      width: 28px; height: 28px; border-radius: 50%;
      display: inline-flex; align-items: center; justify-content: center;
      font-family: 'Cinzel', serif;
      font-size: 11px; font-weight: 900;
      flex-shrink: 0;
    }
    .cm-sigil-on {
      background: radial-gradient(circle at 35% 30%, #b86060 0%, var(--seal) 60%, var(--seal-deep) 100%);
      color: var(--gold-light);
      box-shadow: inset 1px 1px 1px rgba(255,255,255,.18), inset -1px -1px 2px rgba(0,0,0,.30), 0 1px 3px rgba(60,20,20,.35);
    }
    .cm-sigil-off {
      background: rgba(255,255,255,.04);
      color: var(--gold-deep);
      border: 1px dashed var(--gold-deep);
      opacity: .6;
    }

    /* nav back */
    .cm-nav-back { width: 36px; height: 36px; display: inline-flex; align-items: center; justify-content: center; color: var(--gold-light); cursor: pointer; }

    .cm-screen { position: relative; width: 100%; height: 100%; overflow: hidden; }

    /* arcane circle — animated */
    @keyframes cm-rotate { to { transform: translate(-50%,-50%) rotate(360deg); } }
    @keyframes cm-rotate-rev { to { transform: translate(-50%,-50%) rotate(-360deg); } }
  `;
  document.head.appendChild(s);
}

Object.assign(window, { CM_THEMES, PHONE_W, PHONE_H, themeStyle });
