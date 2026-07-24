// cm-app.jsx — top-level canvas wrapping all six screens

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "arcane",
  "showLabels": true
}/*EDITMODE-END*/;

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const theme = CM_THEMES[t.theme] || CM_THEMES.arcane;

  const screens = [
    { id: 'home',    label: '01 ─ ホーム',         comp: <HomeScreen theme={theme} /> },
    { id: 'summon',  label: '02 ─ 召喚（記入）',    comp: <SummonScreen theme={theme} /> },
    { id: 'result',  label: '03 ─ 召喚成功',        comp: <SummonResultScreen theme={theme} /> },
    { id: 'vs',      label: '04 ─ バトル準備',      comp: <BattleReadyScreen theme={theme} /> },
    { id: 'verdict', label: '05 ─ 判決（結果）',     comp: <ResultScreen theme={theme} win={false} /> },
    { id: 'room',    label: '06 ─ 対人ロビー',       comp: <RoomScreen theme={theme} /> },
  ];

  return (
    <div data-screen-label="cheatmonster-redesign">
      <DesignCanvas>
        <DCSection
          id="cheatmonster"
          title="チートモンスターズ ─ UIリデザイン"
          subtitle="魔導書の審判 ／ 羊皮紙×朱印×墨×金箔。Tweaksでテーマ切替可"
        >
          {screens.map(s => (
            <DCArtboard
              key={s.id}
              id={s.id}
              label={s.label}
              width={PHONE_W}
              height={PHONE_H}
            >
              <div data-screen-label={s.label} style={{ width: '100%', height: '100%' }}>
                {s.comp}
              </div>
            </DCArtboard>
          ))}
        </DCSection>
      </DesignCanvas>

      <TweaksPanel>
        <TweakSection label="Theme" />
        <TweakRadio
          label="Palette"
          value={t.theme}
          options={['arcane', 'parchment']}
          onChange={(v) => setTweak('theme', v)}
        />
        <div style={{ fontSize: 10, color: 'rgba(41,38,27,.55)', lineHeight: 1.5, padding: '0 0 4px' }}>
          <b>arcane</b>: Midnight + Gold（推奨）<br />
          <b>parchment</b>: Cathedral Light（昼）
        </div>
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
