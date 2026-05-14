import {
  AbsoluteFill,
  Sequence,
  interpolate,
  spring,
  useCurrentFrame,
  Easing,
} from 'remotion'

export const AD_FPS = 30
export const AD_WIDTH = 1280
export const AD_HEIGHT = 720
export const AD_FRAMES = 450 // 15s

const SCENE = 90 // 3s per scene

// ─ Colours
const NAVY = '#1B2A4A'
const NAVY2 = '#243558'
const GOLD = '#C9A84C'
const WHITE = '#FFFFFF'
const BG = '#EEF1F8'
const RED = '#D63031'
const GREEN = '#00B894'
const SKIN = '#FDBCB4'
const SKIN2 = '#E8976A'
const HAIR = '#3D2B1F'
const SHIRT_STRESS = '#2D5BE3'
const SHIRT_HAPPY = '#2D7D46'
const DESK = '#8B6240'
const DESK2 = '#6B4A2A'

function clamp(v: number, lo = 0, hi = 1) {
  return Math.max(lo, Math.min(hi, v))
}
function fi(frame: number, start: number, dur = 20) {
  return clamp(interpolate(frame, [start, start + dur], [0, 1]))
}
function easedY(frame: number, start: number, dur = 20, dist = 35) {
  const p = fi(frame, start, dur)
  const e = Easing.out(Easing.cubic)(p)
  return { opacity: p, transform: `translateY(${(1 - e) * dist}px)` }
}

// ────── SCENE 1: STRESSED PERSON ──────

function StressedPerson({ f }: { f: number }) {
  const cx = 160
  const swing = Math.sin(f * 0.28) * 24
  const shakeX = Math.sin(f * 0.75) * Math.min(f * 0.12, 7)
  const bob = Math.sin(f * 0.18) * 3

  const papers: { x: number; y: number; dr: number; phase: number }[] = [
    { x: 22,  y: 55,  dr:  3, phase: 0  },
    { x: 270, y: 42,  dr: -2, phase: 7  },
    { x: 8,   y: 145, dr:  2.5, phase: 14 },
    { x: 285, y: 125, dr: -4, phase: 3  },
    { x: 60,  y: 20,  dr:  1.5, phase: 20 },
  ]

  return (
    <svg width={320} height={270} viewBox="0 0 320 270">
      {/* clock */}
      <g transform="translate(290,38)">
        <circle r="26" fill="white" stroke="#ddd" strokeWidth="2"/>
        <g transform={`rotate(${f * 9})`}>
          <line x1="0" y1="0" x2="0" y2="-14" stroke="#333" strokeWidth="2.5" strokeLinecap="round"/>
        </g>
        <g transform={`rotate(${f * 1.8})`}>
          <line x1="0" y1="0" x2="0" y2="-19" stroke="#666" strokeWidth="1.5" strokeLinecap="round"/>
        </g>
        <circle r="3" fill="#333"/>
        {['12','3','6','9'].map((n, i) => {
          const a = i * 90 * Math.PI / 180
          return <text key={n} x={Math.sin(a)*19} y={-Math.cos(a)*19+3} textAnchor="middle" fontSize="6" fill="#aaa">{n}</text>
        })}
      </g>

      {/* flying papers */}
      {papers.map((p, i) => (
        <g key={i} transform={`translate(${p.x + Math.sin((f + p.phase) * 0.12) * 14},${p.y + Math.cos((f + p.phase) * 0.1) * 11}) rotate(${p.dr * f + p.phase * 5})`}>
          <rect x="-15" y="-19" width="30" height="38" rx="2" fill="white" stroke="#ddd" strokeWidth="0.8"/>
          <rect x="-10" y="-13" width="20" height="2.5" rx="1.2" fill="#ccc"/>
          <rect x="-10" y="-8"  width="14" height="2.5" rx="1.2" fill="#ccc"/>
          <rect x="-10" y="-3"  width="18" height="2.5" rx="1.2" fill="#ccc"/>
          {i % 2 === 0
            ? <text x="0" y="13" textAnchor="middle" fontSize="6" fontWeight="700" fill={RED}>DENIED</text>
            : <text x="0" y="13" textAnchor="middle" fontSize="5.5" fill="#999">FORM 45-B</text>
          }
        </g>
      ))}

      {/* desk */}
      <rect x="40" y={202 + bob} width="240" height="12" rx="5" fill={DESK}/>
      <rect x="40" y={210 + bob} width="240" height="5" fill={DESK2} opacity="0.45"/>
      <rect x="58" y={214 + bob} width="10" height="42" fill={DESK2}/>
      <rect x="252" y={214 + bob} width="10" height="42" fill={DESK2}/>

      {/* monitor */}
      <rect x="116" y={148 + bob} width="88" height="58" rx="4" fill="#222"/>
      <rect x="120" y={152 + bob} width="80" height="48" rx="2" fill="#0A1628"/>
      {[[48,3,'rgba(255,255,255,0.35)'],[58,3,'rgba(255,255,255,0.2)'],[38,3,'rgba(255,255,255,0.28)'],[64,3,'rgba(255,255,255,0.15)']].map(([w,h,c],i)=>(
        <rect key={i} x="125" y={157 + bob + i * 8} width={w as number} height={h as number} rx="1.5" fill={c as string}/>
      ))}
      <rect x="152" y={202 + bob} width="16" height="7" rx="2" fill="#333"/>
      <rect x="142" y={207 + bob} width="36" height="4" rx="2" fill="#333"/>

      {/* chair back */}
      <rect x={cx - 36} y="185" width="72" height="10" rx="5" fill="#444"/>
      <rect x={cx - 9}  y="185" width="18" height="52" fill="#555"/>

      {/* body */}
      <g transform={`translate(0,${bob})`}>
        <rect x={cx - 30} y="142" width="60" height="64" rx="12" fill={SHIRT_STRESS}/>
        <rect x={cx - 9}  y="142" width="18" height="18" rx="0" fill="#1A3FC4" opacity="0.5"/>

        {/* LEFT arm — swings up to grab hair */}
        <g transform={`translate(${cx - 28},162) rotate(${-112 + swing})`}>
          <rect x="-8" y="0" width="16" height="48" rx="8" fill={SHIRT_STRESS}/>
          <ellipse cx="0" cy="52" rx="11" ry="12" fill={SKIN}/>
          <rect x="-9"  cy="55" width="6" height="13" rx="3" fill={SKIN2}/>
          <rect x="-3.5" cy="59" width="6" height="14" rx="3" fill={SKIN2}/>
          <rect x="3"   cy="59" width="6" height="14" rx="3" fill={SKIN2}/>
        </g>

        {/* RIGHT arm — mirror */}
        <g transform={`translate(${cx + 28},162) rotate(${112 - swing})`}>
          <rect x="-8" y="0" width="16" height="48" rx="8" fill={SHIRT_STRESS}/>
          <ellipse cx="0" cy="52" rx="11" ry="12" fill={SKIN}/>
          <rect x="-9"  cy="55" width="6" height="13" rx="3" fill={SKIN2}/>
          <rect x="-3.5" cy="59" width="6" height="14" rx="3" fill={SKIN2}/>
          <rect x="3"   cy="59" width="6" height="14" rx="3" fill={SKIN2}/>
        </g>

        {/* neck */}
        <rect x={cx - 10} y="126" width="20" height="20" rx="5" fill={SKIN}/>

        {/* head */}
        <g transform={`translate(${shakeX},0)`}>
          <ellipse cx={cx} cy="110" rx="33" ry="35" fill={SKIN}/>

          {/* hair */}
          <ellipse cx={cx} cy="80" rx="31" ry="14" fill={HAIR}/>
          <rect x={cx - 31} y="80" width="62" height="16" fill={HAIR}/>
          {/* strands being yanked up */}
          {[-16, 0, 16].map((dx, i) => (
            <path key={i} d={`M${cx + dx},80 C${cx + dx - 3},${62 - i * 3} ${cx + dx + 2},${50 - i * 2} ${cx + dx - 4},${42 - i * 3}`}
              stroke={HAIR} strokeWidth="3.5" fill="none" strokeLinecap="round"/>
          ))}

          {/* stressed brows — angled inward */}
          <path d={`M${cx-22},103 Q${cx-14},97 ${cx-7},101`} stroke={HAIR} strokeWidth="3" fill="none" strokeLinecap="round"/>
          <path d={`M${cx+7},101 Q${cx+14},97 ${cx+22},103`} stroke={HAIR} strokeWidth="3" fill="none" strokeLinecap="round"/>

          {/* wide eyes */}
          <ellipse cx={cx - 13} cy="113" rx="7.5" ry="8.5" fill="white"/>
          <ellipse cx={cx + 13} cy="113" rx="7.5" ry="8.5" fill="white"/>
          <circle  cx={cx - 13} cy="114" r="5" fill="#2C3E50"/>
          <circle  cx={cx + 13} cy="114" r="5" fill="#2C3E50"/>
          <circle  cx={cx - 11} cy="112" r="1.8" fill="white"/>
          <circle  cx={cx + 15} cy="112" r="1.8" fill="white"/>

          {/* frown */}
          <path d={`M${cx-13},129 Q${cx},123 ${cx+13},129`} stroke="#555" strokeWidth="2.5" fill="none" strokeLinecap="round"/>

          {/* sweat */}
          {[
            { x: cx - 38, y: 108, phase: 0   },
            { x: cx + 40, y: 116, phase: 1.5 },
            { x: cx - 32, y: 127, phase: 0.8 },
          ].map((s, i) => (
            <ellipse key={i} cx={s.x} cy={s.y} rx={i === 2 ? 3 : 4} ry={i === 2 ? 4 : 6}
              fill="#74B9FF" opacity={Math.max(0, Math.sin(f * 0.42 + s.phase)) * 0.9}/>
          ))}
        </g>

        {/* stress marks */}
        {[{x:cx+42,y:88,a:18},{x:cx+54,y:78,a:32},{x:cx+46,y:104,a:6}].map((m,i)=>(
          <g key={i} transform={`translate(${m.x},${m.y}) rotate(${m.a})`}>
            <line x1="0" y1="-12" x2="0" y2="12" stroke={RED} strokeWidth="3.5" strokeLinecap="round"
              opacity={Math.abs(Math.sin(f * 0.52 + i * 1.3)) * 0.95}/>
            <line x1="-12" y1="0" x2="12" y2="0" stroke={RED} strokeWidth="3.5" strokeLinecap="round"
              opacity={Math.abs(Math.sin(f * 0.52 + i * 1.3)) * 0.95}/>
          </g>
        ))}
      </g>

      {/* ! bubble */}
      <g transform={`translate(${cx + 50},${58 + Math.sin(f * 0.4) * 6})`}
        opacity={0.5 + Math.abs(Math.sin(f * 0.35)) * 0.5}>
        <circle r="20" fill={RED} opacity="0.95"/>
        <text x="0" y="8" textAnchor="middle" fontSize="24" fontWeight="900" fill="white">!</text>
      </g>
    </svg>
  )
}

function Scene1() {
  const f = useCurrentFrame()
  const sc = spring({ frame: f, fps: AD_FPS, config: { damping: 14, stiffness: 70 } })

  return (
    <AbsoluteFill style={{ background: BG, display: 'flex', flexDirection: 'row', alignItems: 'center', justifyContent: 'space-around', padding: '48px 80px' }}>
      <div style={{ flex: 1, maxWidth: 520 }}>
        <div style={{ display:'inline-block', background:`${RED}14`, border:`1.5px solid ${RED}38`, borderRadius:24, padding:'6px 18px', fontSize:13, fontWeight:700, color:RED, letterSpacing:2, textTransform:'uppercase', marginBottom:22, ...easedY(f,0,18) }}>
          Sound familiar?
        </div>
        <div style={{ fontSize:56, fontWeight:900, color:NAVY, letterSpacing:'-2.5px', lineHeight:1.05, marginBottom:24, ...easedY(f,5,22) }}>
          Security<br/>clearances<br/><span style={{color:RED}}>shouldn't</span><br/>be this hard.
        </div>
        <div style={{ fontSize:18, color:'#6B7C93', lineHeight:1.7, ...easedY(f,28,20) }}>
          Endless forms. Confusing requirements.<br/>Months of waiting with no answers.
        </div>
      </div>
      <div style={{ transform:`scale(${sc})`, transformOrigin:'center', filter:'drop-shadow(0 20px 50px rgba(27,42,74,0.2))' }}>
        <StressedPerson f={f}/>
      </div>
    </AbsoluteFill>
  )
}

// ────── SCENE 2: AUSCLEAR INTRO ──────

function HappyPerson({ f }: { f: number }) {
  const cx = 130
  const bob = Math.sin(f * 0.15) * 3

  return (
    <svg width={260} height={230} viewBox="0 0 260 230">
      {/* desk */}
      <rect x="20" y={178 + bob} width="220" height="11" rx="4" fill={DESK}/>
      <rect x="38" y={187 + bob} width="10" height="32" fill={DESK2}/>
      <rect x="212" y={187 + bob} width="10" height="32" fill={DESK2}/>

      {/* laptop */}
      <rect x="90" y={130 + bob} width="90" height="52" rx="4" fill="#222"/>
      <rect x="94" y={134 + bob} width="82" height="44" rx="2" fill="#061220"/>
      <circle cx="135" cy={156 + bob} r="13" fill={GREEN} opacity="0.9"/>
      <path d={`M128,${156+bob} l5,6 l9,-11`} stroke="white" strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      <rect x="112" y={183 + bob} width="46" height="5" rx="2.5" fill="#333"/>

      {/* chair */}
      <rect x={cx-36} y="170" width="72" height="10" rx="5" fill="#444"/>
      <rect x={cx-9}  y="170" width="18" height="46" fill="#555"/>

      {/* body */}
      <rect x={cx-28} y="122" width="56" height="60" rx="12" fill={SHIRT_HAPPY}/>
      <rect x={cx-9}  y="122" width="18" height="16" rx="0" fill="#246039" opacity="0.6"/>

      {/* left arm — relaxed on desk */}
      <g transform={`translate(${cx-26},150) rotate(58)`}>
        <rect x="-7" y="0" width="14" height="38" rx="7" fill={SHIRT_HAPPY}/>
        <ellipse cx="0" cy="43" rx="11" ry="12" fill={SKIN}/>
      </g>

      {/* right arm — thumbs up */}
      <g transform={`translate(${cx+26},140) rotate(-72)`}>
        <rect x="-7" y="0" width="14" height="36" rx="7" fill={SHIRT_HAPPY}/>
        <ellipse cx="0" cy="41" rx="11" ry="13" fill={SKIN}/>
        <rect x="-3" y="28" width="6" height="15" rx="3" fill={SKIN2}/>
        <path d={`M4,36 Q13,30 11,21`} stroke={SKIN} strokeWidth="7" fill="none" strokeLinecap="round"/>
      </g>

      {/* neck */}
      <rect x={cx-9} y="108" width="18" height="18" rx="5" fill={SKIN}/>

      {/* head */}
      <ellipse cx={cx} cy="92" rx="31" ry="33" fill={SKIN}/>
      {/* neat hair */}
      <ellipse cx={cx} cy="64" rx="29" ry="13" fill={HAIR}/>
      <rect x={cx-29} y="64" width="58" height="15" fill={HAIR}/>
      <path d={`M${cx-4},62 L${cx-4},78`} stroke="#2A1D14" strokeWidth="2" opacity="0.4"/>

      {/* happy brows */}
      <path d={`M${cx-19},79 Q${cx-12},75 ${cx-6},78`} stroke={HAIR} strokeWidth="2.5" fill="none" strokeLinecap="round"/>
      <path d={`M${cx+6},78 Q${cx+12},75 ${cx+19},79`} stroke={HAIR} strokeWidth="2.5" fill="none" strokeLinecap="round"/>

      {/* happy squinting eyes */}
      <path d={`M${cx-18},89 Q${cx-12},84 ${cx-6},89`} stroke="#2C3E50" strokeWidth="3" fill="none" strokeLinecap="round"/>
      <path d={`M${cx+6},89 Q${cx+12},84 ${cx+18},89`} stroke="#2C3E50" strokeWidth="3" fill="none" strokeLinecap="round"/>

      {/* big smile */}
      <path d={`M${cx-14},106 Q${cx},118 ${cx+14},106`} stroke="#555" strokeWidth="2.5" fill="none" strokeLinecap="round"/>

      {/* rosy cheeks */}
      <ellipse cx={cx-22} cy="99" rx="9" ry="5" fill="#FFB3A7" opacity="0.5"/>
      <ellipse cx={cx+22} cy="99" rx="9" ry="5" fill="#FFB3A7" opacity="0.5"/>

      {/* floating stars */}
      {[0,1,2].map(i=>{
        const a=(i*120+f*1.8)*Math.PI/180
        return <text key={i} x={cx+Math.cos(a)*110} y={90+Math.sin(a)*55} textAnchor="middle"
          fontSize="22" opacity={0.65+Math.sin(f*0.3+i)*0.35}>{'⭐'}</text>
      })}
    </svg>
  )
}

function Scene2() {
  const f = useCurrentFrame()
  const logoSp = spring({ frame:f, fps:AD_FPS, config:{damping:13,stiffness:58} })
  const pSp    = spring({ frame:f, fps:AD_FPS, config:{damping:16,stiffness:52}, delay:8 })

  const services = [
    { icon:'🏛️', label:'Baseline', sub:'Direct sponsor' },
    { icon:'🔐', label:'NV1', sub:'Referral partner' },
    { icon:'⭐',   label:'NV2', sub:'Referral partner' },
  ]

  return (
    <AbsoluteFill style={{ background:`linear-gradient(135deg,${NAVY},${NAVY2})`, display:'flex', flexDirection:'row', alignItems:'center', justifyContent:'space-around', padding:'48px 80px' }}>
      <div style={{flex:1}}>
        <div style={{ transform:`scale(${logoSp}) translateY(${(1-logoSp)*-28}px)`, display:'inline-block', marginBottom:22 }}>
          <div style={{ fontSize:14, fontWeight:700, letterSpacing:4, color:GOLD, textTransform:'uppercase', marginBottom:6 }}>Introducing</div>
          <div style={{ fontSize:76, fontWeight:900, letterSpacing:'-3px', background:`linear-gradient(90deg,${WHITE},${GOLD})`, WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent', lineHeight:1 }}>AusClear</div>
          <div style={{ fontSize:16, color:'rgba(255,255,255,0.5)', letterSpacing:3, textTransform:'uppercase', marginTop:6 }}>Security Clearance Specialists</div>
        </div>
        <div style={{ fontSize:20, color:'rgba(255,255,255,0.75)', lineHeight:1.6, marginBottom:36, ...easedY(f,18,20) }}>
          We handle the complexity<br/>so you can focus on what matters.
        </div>
        <div style={{ display:'flex', gap:14, ...easedY(f,32,20) }}>
          {services.map((s,i)=>(
            <div key={i} style={{ background:'rgba(255,255,255,0.05)', border:`1px solid ${GOLD}38`, borderRadius:14, padding:'14px 18px', textAlign:'center', minWidth:108 }}>
              <div style={{fontSize:28,marginBottom:6}}>{s.icon}</div>
              <div style={{fontSize:15,fontWeight:700,color:WHITE,marginBottom:3}}>{s.label}</div>
              <div style={{fontSize:12,color:GOLD,fontWeight:500}}>{s.sub}</div>
            </div>
          ))}
        </div>
      </div>
      <div style={{ transform:`scale(${pSp})`, transformOrigin:'center' }}>
        <HappyPerson f={f}/>
      </div>
    </AbsoluteFill>
  )
}

// ────── SCENE 3: HOW IT WORKS ──────

function Scene3() {
  const f = useCurrentFrame()

  const steps = [
    { num:'01', icon:'📋', title:'You apply',       desc:'Fill out a short online form. No confusing AGSVA jargon — we ask only what we need.',    color:'#2D5BE3' },
    { num:'02', icon:'🤝', title:'We sponsor you',  desc:'AusClear sponsors your Baseline clearance. NV1 or NV2? We refer you to our vetted partners.', color:GOLD    },
    { num:'03', icon:'✅',  title:'You get cleared',  desc:'We track your progress, answer questions, and guide you until your clearance is confirmed.',    color:GREEN   },
  ]

  return (
    <AbsoluteFill style={{ background:BG, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:'48px 72px' }}>
      <div style={{ fontSize:14, fontWeight:700, letterSpacing:4, color:NAVY, textTransform:'uppercase', marginBottom:10, ...easedY(f,0,16,20) }}>How It Works</div>
      <div style={{ fontSize:54, fontWeight:900, color:NAVY, letterSpacing:'-2px', textAlign:'center', marginBottom:8, ...easedY(f,5,20) }}>
        Simple. <span style={{color:GOLD}}>Supported.</span> Sorted.
      </div>
      <div style={{ fontSize:18, color:'#6B7C93', marginBottom:44, ...easedY(f,18,18) }}>Three steps from application to clearance.</div>

      <div style={{ display:'flex', gap:22, width:'100%' }}>
        {steps.map((s,i)=>{
          const delay=24+i*14
          const op=fi(f,delay,18)
          const yO=(1-clamp(interpolate(f,[delay,delay+18],[0,1])))*32
          return (
            <div key={i} style={{ flex:1, background:'white', borderRadius:20, padding:'30px 26px', boxShadow:'0 8px 30px rgba(27,42,74,0.09)', borderTop:`4px solid ${s.color}`, opacity:op, transform:`translateY(${yO}px)` }}>
              <div style={{ fontSize:13, fontWeight:700, color:s.color, letterSpacing:2, marginBottom:12 }}>STEP {s.num}</div>
              <div style={{ fontSize:36, marginBottom:14 }}>{s.icon}</div>
              <div style={{ fontSize:22, fontWeight:800, color:NAVY, marginBottom:10 }}>{s.title}</div>
              <div style={{ fontSize:15, color:'#6B7C93', lineHeight:1.65 }}>{s.desc}</div>
            </div>
          )
        })}
      </div>
    </AbsoluteFill>
  )
}

// ────── SCENE 4: CLEARANCE LEVELS ──────

function Scene4() {
  const f = useCurrentFrame()

  const levels = [
    { level:'Baseline', tag:'PROTECTED',  desc:'Entry-level government clearance. AusClear sponsors you directly — fast, clear, and straightforward.', badge:'🏛️', color:'#2D5BE3', how:'Direct Sponsorship' },
    { level:'NV1',      tag:'SECRET',     desc:'Higher clearance for sensitive roles. We connect you with our trusted, verified referral partners.',        badge:'🔐', color:GOLD,      how:'Referral Partner'  },
    { level:'NV2',      tag:'TOP SECRET', desc:'Top-tier clearance. Expert referral to specialist partners with full support throughout your application.',  badge:'⭐',   color:'#E84393',  how:'Referral Partner'  },
  ]

  return (
    <AbsoluteFill style={{ background:`linear-gradient(135deg,#0D1929,${NAVY} 60%,${NAVY2})`, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:'48px 72px' }}>
      <div style={{ fontSize:14, fontWeight:700, letterSpacing:4, color:GOLD, textTransform:'uppercase', marginBottom:10, ...easedY(f,0,16,20) }}>Clearance Levels</div>
      <div style={{ fontSize:54, fontWeight:900, color:WHITE, letterSpacing:'-2px', textAlign:'center', marginBottom:8, ...easedY(f,5,20) }}>
        We cover <span style={{color:GOLD}}>all levels.</span>
      </div>
      <div style={{ fontSize:18, color:'rgba(255,255,255,0.45)', marginBottom:44, ...easedY(f,18,18) }}>Baseline to NV2 — AusClear has you covered.</div>

      <div style={{ display:'flex', gap:20, width:'100%' }}>
        {levels.map((l,i)=>{
          const delay=24+i*12
          const op=fi(f,delay,18)
          const yO=(1-clamp(interpolate(f,[delay,delay+18],[0,1])))*40
          return (
            <div key={i} style={{ flex:1, background:'rgba(255,255,255,0.04)', border:`1px solid ${l.color}40`, borderRadius:20, padding:'26px 22px', opacity:op, transform:`translateY(${yO}px)`, backdropFilter:'blur(8px)' }}>
              <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:14 }}>
                <div style={{fontSize:28}}>{l.badge}</div>
                <div>
                  <div style={{fontSize:22,fontWeight:900,color:WHITE}}>{l.level}</div>
                  <span style={{ display:'inline-block', fontSize:10, fontWeight:700, letterSpacing:2, color:l.color, background:`${l.color}18`, border:`1px solid ${l.color}38`, borderRadius:20, padding:'2px 8px', marginTop:3 }}>{l.tag}</span>
                </div>
              </div>
              <div style={{ fontSize:14, color:'rgba(255,255,255,0.58)', lineHeight:1.65, marginBottom:18 }}>{l.desc}</div>
              <div style={{ display:'flex', alignItems:'center', gap:8, padding:'10px 14px', background:`${l.color}10`, borderRadius:10, border:`1px solid ${l.color}28` }}>
                <div style={{ width:8, height:8, borderRadius:'50%', background:l.color, flexShrink:0 }}/>
                <div style={{ fontSize:13, fontWeight:600, color:l.color }}>{l.how}</div>
              </div>
            </div>
          )
        })}
      </div>
    </AbsoluteFill>
  )
}

// ────── SCENE 5: CTA ──────

function Scene5() {
  const f = useCurrentFrame()
  const mainSp = spring({ frame:f, fps:AD_FPS, config:{damping:13,stiffness:55} })
  const pulse  = 0.5 + Math.sin(f * 0.14) * 0.5
  const btnSc  = 1 + Math.sin(f * 0.1) * 0.018

  return (
    <AbsoluteFill style={{ background:`linear-gradient(135deg,${NAVY},#0D1929)`, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:60 }}>
      {[600,380,220].map((sz,i)=>(
        <div key={i} style={{ position:'absolute', width:sz, height:sz, borderRadius:'50%', border:`1px solid ${GOLD}${['15','22','30'][i]}`, opacity: pulse*(0.4+i*0.2), transform:`scale(${1+f*0.0015*(i+1)})` }}/>
      ))}

      <div style={{ display:'inline-flex', alignItems:'center', gap:8, padding:'7px 18px', background:`${GREEN}18`, border:`1px solid ${GREEN}40`, borderRadius:24, fontSize:13, fontWeight:600, color:GREEN, marginBottom:28, ...easedY(f,5,20) }}>
        <div style={{ width:7, height:7, borderRadius:'50%', background:GREEN, boxShadow:`0 0 8px ${GREEN}` }}/>
        Australian Security Clearance Specialists
      </div>

      <div style={{ fontSize:76, fontWeight:900, letterSpacing:'-3.5px', textAlign:'center', lineHeight:1.05, background:`linear-gradient(135deg,${WHITE},${GOLD})`, WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent', transform:`scale(${mainSp}) translateY(${(1-mainSp)*32}px)`, marginBottom:22 }}>
        Ready to get<br/>cleared?
      </div>

      <div style={{ fontSize:20, color:'rgba(255,255,255,0.58)', textAlign:'center', maxWidth:480, lineHeight:1.65, marginBottom:50, ...easedY(f,20,20) }}>
        Baseline sponsorship. NV1 &amp; NV2 referrals.<br/>Expert guidance every step of the way.
      </div>

      <div style={{ transform:`scale(${btnSc})`, ...easedY(f,26,20), marginBottom:24 }}>
        <div style={{ background:`linear-gradient(135deg,${GOLD},#E8A020)`, borderRadius:16, padding:'18px 56px', fontSize:24, fontWeight:800, color:NAVY, letterSpacing:'-0.5px', boxShadow:`0 16px 50px ${GOLD}42` }}>
          www.ausclear.com.au
        </div>
      </div>

      <div style={{ fontSize:13, color:'rgba(255,255,255,0.22)', letterSpacing:3, textTransform:'uppercase', ...easedY(f,36,20) }}>
        Trusted &middot; Professional &middot; Australian
      </div>
    </AbsoluteFill>
  )
}

// ────── ROOT COMPOSITION ──────

export function AusClearAd() {
  return (
    <>
      <Sequence from={0}          durationInFrames={SCENE}><Scene1/></Sequence>
      <Sequence from={SCENE}      durationInFrames={SCENE}><Scene2/></Sequence>
      <Sequence from={SCENE * 2}  durationInFrames={SCENE}><Scene3/></Sequence>
      <Sequence from={SCENE * 3}  durationInFrames={SCENE}><Scene4/></Sequence>
      <Sequence from={SCENE * 4}  durationInFrames={SCENE}><Scene5/></Sequence>
    </>
  )
}
