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
export const AD_FRAMES = 450

const SCENE = 90
const NAVY = '#1B2A4A'
const NAVY2 = '#243558'
const GOLD  = '#C9A84C'
const WHITE = '#FFFFFF'
const BG    = '#F5F2ED'
const RED   = '#D63031'
const GREEN = '#00B894'

function clamp(v: number, lo = 0, hi = 1) { return Math.max(lo, Math.min(hi, v)) }
function fi(f: number, s: number, d = 20) { return clamp(interpolate(f, [s, s+d], [0, 1])) }
function ey(f: number, s: number, d = 20, dist = 36) {
  const p = fi(f,s,d), e = Easing.out(Easing.cubic)(p)
  return { opacity: p, transform: `translateY(${(1-e)*dist}px)` }
}

// CSS keyframe animations for the character
// Using CSS (not Remotion frames) = GPU-smooth, no choppiness
const CHAR_CSS = `
  @keyframes tug {
    0%,100% { transform: translateY(0); }
    50%      { transform: translateY(-13px); }
  }
  @keyframes shake {
    0%,100% { transform: translateX(0) rotate(0deg); }
    20%     { transform: translateX(-9px) rotate(-2.5deg); }
    40%     { transform: translateX(9px)  rotate(2.5deg); }
    60%     { transform: translateX(-6px) rotate(-1.5deg); }
    80%     { transform: translateX(6px)  rotate(1.5deg); }
  }
  @keyframes sweat {
    0%,50%  { opacity:0; transform:translateY(0); }
    62%     { opacity:0.95; }
    88%     { opacity:0.05; transform:translateY(26px); }
    100%    { opacity:0; transform:translateY(26px); }
  }
  @keyframes stress {
    0%,100% { opacity:0; transform:scale(0.3); }
    35%,65% { opacity:1; transform:scale(1); }
  }
  @keyframes csec { from{transform:rotate(0deg)} to{transform:rotate(360deg)} }
  @keyframes cmin { from{transform:rotate(0deg)} to{transform:rotate(360deg)} }
  @keyframes p1 {
    0%,100%{transform:translate(48px,82px) rotate(-22deg);}
    50%    {transform:translate(42px,70px) rotate(-27deg);}
  }
  @keyframes p2 {
    0%,100%{transform:translate(502px,68px) rotate(19deg);}
    50%    {transform:translate(510px,57px) rotate(14deg);}
  }
  @keyframes p3 {
    0%,100%{transform:translate(34px,215px) rotate(-38deg);}
    50%    {transform:translate(28px,203px) rotate(-44deg);}
  }
  @keyframes p4 {
    0%,100%{transform:translate(524px,198px) rotate(30deg);}
    50%    {transform:translate(532px,186px) rotate(24deg);}
  }
  .ac-arms  { animation:tug 0.78s ease-in-out infinite; }
  .ac-head  { animation:shake 0.62s ease-in-out infinite; transform-box:fill-box; transform-origin:center; }
  .ac-sw1   { animation:sweat 1.9s ease-in-out 0s infinite; }
  .ac-sw2   { animation:sweat 1.9s ease-in-out 0.65s infinite; }
  .ac-sw3   { animation:sweat 1.9s ease-in-out 1.3s infinite; }
  .ac-st1   { animation:stress 1.1s ease-in-out 0s infinite; transform-box:fill-box; transform-origin:center; }
  .ac-st2   { animation:stress 1.1s ease-in-out 0.37s infinite; transform-box:fill-box; transform-origin:center; }
  .ac-st3   { animation:stress 1.1s ease-in-out 0.74s infinite; transform-box:fill-box; transform-origin:center; }
  .ac-csec  { animation:csec 1s linear infinite; transform-box:fill-box; transform-origin:50% 100%; }
  .ac-cmin  { animation:cmin 10s linear infinite; transform-box:fill-box; transform-origin:50% 100%; }
  .ac-p1    { animation:p1 3.2s ease-in-out infinite; }
  .ac-p2    { animation:p2 2.8s ease-in-out 0.4s infinite; }
  .ac-p3    { animation:p3 3.6s ease-in-out 0.9s infinite; }
  .ac-p4    { animation:p4 2.5s ease-in-out 1.4s infinite; }
`

function Paper({ label, colour = '#CCC' }: { label: string; colour?: string }) {
  return (
    <>
      <rect x="-24" y="-30" width="48" height="60" rx="3" fill="white" stroke="#E0E0E0" strokeWidth="1"/>
      <rect x="-17" y="-22" width="34" height="3" rx="1.5" fill="#D8D8D8"/>
      <rect x="-17" y="-16" width="26" height="3" rx="1.5" fill="#D8D8D8"/>
      <rect x="-17" y="-10" width="30" height="3" rx="1.5" fill="#D8D8D8"/>
      <text x="0" y="14" textAnchor="middle" fontSize="9" fontWeight="800" fill={colour} fontFamily="Inter,sans-serif">{label}</text>
    </>
  )
}

function StressedPerson() {
  return (
    <svg width="600" height="460" viewBox="0 0 600 460" overflow="visible" style={{ filter:'drop-shadow(0 12px 40px rgba(27,42,74,0.18))' }}>
      <defs>
        <style>{CHAR_CSS}</style>
        <linearGradient id="sV" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FDBCB4"/>
          <stop offset="100%" stopColor="#D4896A"/>
        </linearGradient>
        <linearGradient id="sH" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#E8976A"/>
          <stop offset="50%" stopColor="#FDBCB4"/>
          <stop offset="100%" stopColor="#E8976A"/>
        </linearGradient>
        <linearGradient id="sh" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#3A6EA5"/>
          <stop offset="100%" stopColor="#1E4A78"/>
        </linearGradient>
        <linearGradient id="dk" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#9A7040"/>
          <stop offset="100%" stopColor="#7A5230"/>
        </linearGradient>
        <linearGradient id="hr" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#3D2B1F"/>
          <stop offset="100%" stopColor="#2C1810"/>
        </linearGradient>
      </defs>

      {/* Floating papers */}
      <g className="ac-p1"><Paper label="DENIED" colour={RED}/></g>
      <g className="ac-p2"><Paper label="FORM 45-B" colour="#888"/></g>
      <g className="ac-p3"><Paper label="PENDING" colour="#E67E22"/></g>
      <g className="ac-p4"><Paper label="OVERDUE" colour={RED}/></g>

      {/* Wall clock */}
      <g transform="translate(515,55)">
        <circle r="36" fill="white" stroke="#E0E0E0" strokeWidth="2.5"/>
        {[0,30,60,90,120,150,180,210,240,270,300,330].map((deg, i) => {
          const big = i%3===0, r1=big?23:27, r2=30, rad=deg*Math.PI/180
          return <line key={deg}
            x1={Math.sin(rad)*r1} y1={-Math.cos(rad)*r1}
            x2={Math.sin(rad)*r2} y2={-Math.cos(rad)*r2}
            stroke={big?'#888':'#CCC'} strokeWidth={big?2:1}/>
        })}
        <g className="ac-cmin"><rect x="-1.5" y="-22" width="3" height="22" rx="1.5" fill="#555"/></g>
        <g className="ac-csec"><rect x="-1" y="-28" width="2" height="28" rx="1" fill={RED}/></g>
        <circle r="3.5" fill="#333"/>
      </g>

      {/* Desk */}
      <rect x="30" y="385" width="540" height="18" rx="6" fill="url(#dk)"/>
      <rect x="30" y="399" width="540" height="6" fill="#6B4A2A" opacity="0.3"/>
      <rect x="58"  y="403" width="16" height="50" rx="4" fill="#7A5230"/>
      <rect x="526" y="403" width="16" height="50" rx="4" fill="#7A5230"/>

      {/* Laptop on desk */}
      <g transform="translate(268,308)">
        <rect x="-62" y="-78" width="124" height="84" rx="6" fill="#222"/>
        <rect x="-57" y="-73" width="114" height="74" rx="3" fill="#071120"/>
        <rect x="-51" y="-67" width="102" height="4" rx="2" fill={`${RED}44`}/>
        <text x="0" y="-50" textAnchor="middle" fontSize="12" fontWeight="700" fill={RED} fontFamily="monospace">ERROR 403</text>
        <text x="0" y="-34" textAnchor="middle" fontSize="9" fill="rgba(255,255,255,0.38)" fontFamily="monospace">ACCESS DENIED</text>
        <text x="0" y="-20" textAnchor="middle" fontSize="8" fill="rgba(255,255,255,0.2)" fontFamily="monospace">contact security@...</text>
        <rect x="-22" y="-8" width="44" height="3" rx="1.5" fill="rgba(255,255,255,0.1)"/>
        <rect x="-20" y="6" width="40" height="6" rx="3" fill="#333"/>
        <rect x="-34" y="10" width="68" height="4" rx="2" fill="#333"/>
      </g>

      {/* Chair */}
      <rect x="196" y="326" width="168" height="16" rx="9" fill="#3A3A4A"/>
      <rect x="240" y="342" width="80" height="50" fill="#444"/>
      <rect x="232" y="342" width="96" height="8" fill="#3A3A4A" opacity="0.5"/>

      {/* Torso */}
      <path d="M 198,384 C 194,352 198,322 214,308 C 232,294 256,288 300,288 C 344,288 368,294 386,308 C 402,322 406,352 402,384 Z"
        fill="url(#sh)"/>
      {/* Collar */}
      <path d="M 280,288 L 300,312 L 320,288" stroke="rgba(255,255,255,0.2)" strokeWidth="3" fill="none"/>
      <line x1="300" y1="312" x2="300" y2="382" stroke="rgba(255,255,255,0.08)" strokeWidth="2"/>

      {/* Neck */}
      <ellipse cx="300" cy="280" rx="25" ry="14" fill="url(#sH)"/>

      {/* ARMS — animated as one group for sync */}
      <g className="ac-arms">
        {/* Left upper arm (shirt sleeve) */}
        <path d="M 212,320 C 170,308 142,284 135,262"
          stroke="url(#sh)" strokeWidth="38" fill="none" strokeLinecap="round"/>
        {/* Left forearm (skin) */}
        <path d="M 135,262 C 128,243 152,190 204,145"
          stroke="url(#sV)" strokeWidth="30" fill="none" strokeLinecap="round"/>
        {/* Left hand */}
        <ellipse cx="201" cy="143" rx="30" ry="25" fill="url(#sH)"/>
        {/* Left fingers gripping hair */}
        <path d="M 184,128 C 179,106 181,91 185,82" stroke="#D4896A" strokeWidth="11" fill="none" strokeLinecap="round"/>
        <path d="M 197,124 C 194,100 196,85 200,76" stroke="#D4896A" strokeWidth="11" fill="none" strokeLinecap="round"/>
        <path d="M 211,126 C 211,102 215,88 219,79" stroke="#D4896A" strokeWidth="10" fill="none" strokeLinecap="round"/>

        {/* Right upper arm */}
        <path d="M 388,320 C 430,308 458,284 465,262"
          stroke="url(#sh)" strokeWidth="38" fill="none" strokeLinecap="round"/>
        {/* Right forearm */}
        <path d="M 465,262 C 472,243 448,190 396,145"
          stroke="url(#sV)" strokeWidth="30" fill="none" strokeLinecap="round"/>
        {/* Right hand */}
        <ellipse cx="399" cy="143" rx="30" ry="25" fill="url(#sH)"/>
        {/* Right fingers */}
        <path d="M 381,126 C 377,102 373,88 369,79" stroke="#D4896A" strokeWidth="10" fill="none" strokeLinecap="round"/>
        <path d="M 395,124 C 392,100 390,85 386,76" stroke="#D4896A" strokeWidth="11" fill="none" strokeLinecap="round"/>
        <path d="M 410,128 C 407,106 405,91 401,82" stroke="#D4896A" strokeWidth="11" fill="none" strokeLinecap="round"/>
      </g>

      {/* HEAD — separate from arms so head shake is independent */}
      <g className="ac-head">
        {/* Head */}
        <ellipse cx="300" cy="196" rx="80" ry="82" fill="url(#sH)"/>
        {/* Hair covering top 55% of head */}
        <path d="M 220,182 C 220,128 246,104 300,101 C 354,104 380,128 380,182 C 366,160 340,150 300,149 C 260,150 234,160 220,182 Z"
          fill="url(#hr)"/>
        {/* Hair strands being pulled — LEFT side */}
        <path d="M 213,126 C 207,100 205,82 199,66"   stroke="#2C1810" strokeWidth="6"   fill="none" strokeLinecap="round"/>
        <path d="M 226,119 C 223,91  224,72  222,56"  stroke="#2C1810" strokeWidth="5.5" fill="none" strokeLinecap="round"/>
        <path d="M 240,114 C 240,87  244,68  246,54"  stroke="#3D2B1F" strokeWidth="5"   fill="none" strokeLinecap="round"/>
        {/* Hair strands — RIGHT side */}
        <path d="M 360,119 C 363,91  364,72  366,56"  stroke="#2C1810" strokeWidth="5.5" fill="none" strokeLinecap="round"/>
        <path d="M 374,126 C 380,100 382,82  388,66"  stroke="#2C1810" strokeWidth="6"   fill="none" strokeLinecap="round"/>
        <path d="M 352,114 C 352,87  350,68  348,54"  stroke="#3D2B1F" strokeWidth="5"   fill="none" strokeLinecap="round"/>

        {/* Stressed eyebrows — sharply angled inward */}
        <path d="M 247,167 Q 264,155 277,163" stroke="#2C1810" strokeWidth="6" fill="none" strokeLinecap="round"/>
        <path d="M 323,163 Q 336,155 353,167" stroke="#2C1810" strokeWidth="6" fill="none" strokeLinecap="round"/>

        {/* Eyes — wide open */}
        <ellipse cx="270" cy="184" rx="17" ry="19" fill="white"/>
        <ellipse cx="270" cy="186" rx="12" ry="13" fill="#2C3E50"/>
        <ellipse cx="270" cy="186" rx="7.5" ry="8.5" fill="#161D26"/>
        <circle  cx="275" cy="181" r="4.5" fill="white"/>

        <ellipse cx="330" cy="184" rx="17" ry="19" fill="white"/>
        <ellipse cx="330" cy="186" rx="12" ry="13" fill="#2C3E50"/>
        <ellipse cx="330" cy="186" rx="7.5" ry="8.5" fill="#161D26"/>
        <circle  cx="335" cy="181" r="4.5" fill="white"/>

        {/* Nose */}
        <path d="M 296,188 Q 285,212 295,220 Q 305,222 315,220 Q 305,212 300,188 Z" fill="#D4896A" opacity="0.5"/>

        {/* Mouth — stressed grimace/frown */}
        <path d="M 272,232 Q 300,221 328,232" stroke="#555" strokeWidth="4.5" fill="none" strokeLinecap="round"/>
        <path d="M 277,231 Q 300,225 323,231 L 323,236 Q 300,230 277,236 Z" fill="white" opacity="0.45"/>

        {/* Cheek blush */}
        <ellipse cx="240" cy="202" rx="22" ry="12" fill="#FFB3A7" opacity="0.3"/>
        <ellipse cx="360" cy="202" rx="22" ry="12" fill="#FFB3A7" opacity="0.3"/>

        {/* Sweat drops */}
        <g className="ac-sw1">
          <path d="M 206,185 Q 201,200 206,210 Q 214,210 215,200 Z" fill="#74B9FF"/>
        </g>
        <g className="ac-sw2">
          <path d="M 396,190 Q 391,206 396,217 Q 404,217 405,206 Z" fill="#74B9FF"/>
        </g>
        <g className="ac-sw3">
          <path d="M 218,228 Q 214,240 218,248 Q 224,248 225,240 Z" fill="#74B9FF"/>
        </g>
      </g>

      {/* Stress markers */}
      <g className="ac-st1"><text x="408" y="152" fontSize="36" fontWeight="900" fill={RED} fontFamily="Inter,sans-serif">!</text></g>
      <g className="ac-st2"><text x="164" y="144" fontSize="28" fontWeight="900" fill={RED} fontFamily="Inter,sans-serif">?</text></g>
      <g className="ac-st3">
        <line x1="408" y1="192" x2="434" y2="218" stroke={RED} strokeWidth="5" strokeLinecap="round"/>
        <line x1="434" y1="192" x2="408" y2="218" stroke={RED} strokeWidth="5" strokeLinecap="round"/>
      </g>
    </svg>
  )
}

// ─── SCENE 1: THE PROBLEM ──────────────────────────────────────────────────

function Scene1() {
  const f = useCurrentFrame()
  const sc = spring({ frame:f, fps:AD_FPS, config:{damping:14,stiffness:65} })

  return (
    <AbsoluteFill style={{
      background: BG,
      display: 'flex',
      flexDirection: 'row',
      alignItems: 'center',
      padding: '0 80px',
      gap: 40,
    }}>
      {/* Left: copy */}
      <div style={{ flex:'0 0 480px' }}>
        <div style={{
          display: 'inline-flex', alignItems:'center', gap:8,
          background:`${RED}12`, border:`1.5px solid ${RED}35`,
          borderRadius:24, padding:'6px 18px',
          fontSize:13, fontWeight:700, color:RED, letterSpacing:2, textTransform:'uppercase',
          marginBottom:24, ...ey(f,0,16,20),
        }}>
          <span style={{width:7,height:7,borderRadius:'50%',background:RED,display:'inline-block'}}/>
          Sound familiar?
        </div>

        <div style={{
          fontSize: 54, fontWeight:900, color:NAVY, letterSpacing:'-2.5px', lineHeight:1.08,
          marginBottom:26, ...ey(f,6,22),
        }}>
          Security<br/>clearances<br/><span style={{color:RED}}>shouldn't</span><br/>be this hard.
        </div>

        <div style={{ fontSize:19, color:'#6B7C93', lineHeight:1.75, ...ey(f,26,20) }}>
          Endless forms. No guidance.<br/>Months of silence.
        </div>
      </div>

      {/* Right: character */}
      <div style={{
        flex: 1,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transform: `scale(${sc})`,
        transformOrigin: 'center',
      }}>
        <StressedPerson/>
      </div>
    </AbsoluteFill>
  )
}

// ─── SCENE 2: AUSCLEAR SOLUTION ────────────────────────────────────────────

function Scene2() {
  const f = useCurrentFrame()
  const lSp = spring({ frame:f, fps:AD_FPS, config:{damping:12,stiffness:55} })

  return (
    <AbsoluteFill style={{
      background: `linear-gradient(145deg, ${NAVY} 0%, #0D1929 100%)`,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '0 100px',
    }}>
      {/* Large logo reveal */}
      <div style={{
        transform: `scale(${lSp}) translateY(${(1-lSp)*-30}px)`,
        display: 'flex', flexDirection:'column', alignItems:'center',
        marginBottom: 40,
      }}>
        {/* Logo mark */}
        <div style={{
          width:100, height:100, borderRadius:28,
          background: `linear-gradient(135deg, ${GOLD}22, ${GOLD}08)`,
          border: `2px solid ${GOLD}50`,
          display:'flex', alignItems:'center', justifyContent:'center',
          marginBottom:24,
          boxShadow: `0 0 60px ${GOLD}25`,
        }}>
          <div style={{
            fontSize:42, fontWeight:900, color:GOLD,
            fontFamily:'Inter,sans-serif', letterSpacing:'-2px',
          }}>AC</div>
        </div>
        <div style={{
          fontSize:80, fontWeight:900, letterSpacing:'-4px',
          background:`linear-gradient(90deg,${WHITE},${GOLD})`,
          WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent',
          lineHeight:1,
        }}>AusClear</div>
        <div style={{ fontSize:16, color:'rgba(255,255,255,0.45)', letterSpacing:5, textTransform:'uppercase', marginTop:10 }}>
          Security Clearance Specialists
        </div>
      </div>

      {/* Tagline */}
      <div style={{
        fontSize:26, color:'rgba(255,255,255,0.78)', textAlign:'center', lineHeight:1.5,
        marginBottom:50, ...ey(f,22,22),
      }}>
        We handle the complexity so <span style={{color:GOLD,fontWeight:700}}>you</span> can focus on what matters.
      </div>

      {/* Service chips */}
      <div style={{ display:'flex', gap:16, ...ey(f,36,22) }}>
        {[
          { icon:'🏛️', name:'Baseline', tag:'Direct Sponsor',  color:'#4A90D9' },
          { icon:'🔐', name:'NV1',      tag:'Referral Partner', color:GOLD      },
          { icon:'⭐',   name:'NV2',      tag:'Referral Partner', color:'#E84393'  },
        ].map((s,i) => (
          <div key={i} style={{
            background:'rgba(255,255,255,0.05)',
            border:`1px solid ${s.color}40`,
            borderRadius:18, padding:'20px 28px',
            textAlign:'center', minWidth:160,
            boxShadow:`0 0 30px ${s.color}10`,
          }}>
            <div style={{fontSize:34,marginBottom:10}}>{s.icon}</div>
            <div style={{fontSize:20,fontWeight:800,color:WHITE,letterSpacing:'-0.5px',marginBottom:4}}>{s.name}</div>
            <div style={{fontSize:13,color:s.color,fontWeight:600}}>{s.tag}</div>
          </div>
        ))}
      </div>
    </AbsoluteFill>
  )
}

// ─── SCENE 3: HOW IT WORKS ─────────────────────────────────────────────────

function Scene3() {
  const f = useCurrentFrame()

  const steps = [
    { n:'01', icon:'📋', title:'You apply',       desc:'Short online form. No confusing AGSVA jargon — we ask only what we need to get you started.',        col:'#4A90D9' },
    { n:'02', icon:'🤝', title:'We sponsor you',  desc:'AusClear sponsors your Baseline clearance. Need NV1 or NV2? We refer you to our vetted partners.',      col:GOLD      },
    { n:'03', icon:'✅',  title:'You get cleared',  desc:'We track your progress, answer your questions and support you until your clearance is confirmed.',        col:GREEN     },
  ]

  return (
    <AbsoluteFill style={{ background:BG, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:'0 72px' }}>
      <div style={{ fontSize:14, fontWeight:700, letterSpacing:5, color:NAVY, textTransform:'uppercase', marginBottom:12, ...ey(f,0,16,20) }}>How It Works</div>
      <div style={{ fontSize:56, fontWeight:900, color:NAVY, letterSpacing:'-2.5px', textAlign:'center', marginBottom:10, ...ey(f,6,20) }}>
        Simple. <span style={{color:GOLD,fontStyle:'italic'}}>Supported.</span> Sorted.
      </div>
      <div style={{ fontSize:18, color:'#6B7C93', marginBottom:48, ...ey(f,18,18) }}>Three steps from application to clearance.</div>

      <div style={{ display:'flex', gap:24, width:'100%' }}>
        {steps.map((s,i)=>{
          const d=24+i*14, op=fi(f,d,18), yo=(1-clamp(interpolate(f,[d,d+18],[0,1])))*34
          return (
            <div key={i} style={{
              flex:1, background:WHITE, borderRadius:22, padding:'32px 28px',
              boxShadow:'0 8px 32px rgba(27,42,74,0.1)',
              borderTop:`5px solid ${s.col}`,
              opacity:op, transform:`translateY(${yo}px)`,
            }}>
              <div style={{fontSize:13,fontWeight:700,color:s.col,letterSpacing:2,marginBottom:14}}>STEP {s.n}</div>
              <div style={{fontSize:38,marginBottom:16}}>{s.icon}</div>
              <div style={{fontSize:22,fontWeight:800,color:NAVY,marginBottom:12}}>{s.title}</div>
              <div style={{fontSize:15,color:'#6B7C93',lineHeight:1.7}}>{s.desc}</div>
            </div>
          )
        })}
      </div>
    </AbsoluteFill>
  )
}

// ─── SCENE 4: CLEARANCE LEVELS ─────────────────────────────────────────────

function Scene4() {
  const f = useCurrentFrame()

  const levels = [
    { name:'Baseline', tag:'PROTECTED',  desc:'Entry-level clearance. AusClear sponsors you directly — fast, clear, no confusion.', icon:'🏛️', col:'#4A90D9', how:'Direct Sponsorship' },
    { name:'NV1',      tag:'SECRET',     desc:'Higher clearance for sensitive roles. We connect you with our trusted, verified partners.',  icon:'🔐', col:GOLD,      how:'Referral Partner'  },
    { name:'NV2',      tag:'TOP SECRET', desc:'Top-tier clearance. Expert referral with full guidance and support throughout.',              icon:'⭐',   col:'#E84393',  how:'Referral Partner'  },
  ]

  return (
    <AbsoluteFill style={{ background:`linear-gradient(145deg,#0D1929,${NAVY} 55%,${NAVY2})`, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:'0 72px' }}>
      <div style={{fontSize:14,fontWeight:700,letterSpacing:5,color:GOLD,textTransform:'uppercase',marginBottom:12,...ey(f,0,16,20)}}>Clearance Levels</div>
      <div style={{fontSize:56,fontWeight:900,color:WHITE,letterSpacing:'-2.5px',textAlign:'center',marginBottom:10,...ey(f,6,20)}}>
        We cover <span style={{color:GOLD}}>all levels.</span>
      </div>
      <div style={{fontSize:18,color:'rgba(255,255,255,0.45)',marginBottom:48,...ey(f,18,18)}}>Baseline to NV2 — AusClear has you covered.</div>

      <div style={{ display:'flex', gap:22, width:'100%' }}>
        {levels.map((l,i)=>{
          const d=24+i*12, op=fi(f,d,18), yo=(1-clamp(interpolate(f,[d,d+18],[0,1])))*42
          return (
            <div key={i} style={{
              flex:1, background:'rgba(255,255,255,0.04)',
              border:`1px solid ${l.col}40`, borderRadius:22,
              padding:'28px 24px', opacity:op, transform:`translateY(${yo}px)`,
            }}>
              <div style={{display:'flex',alignItems:'center',gap:12,marginBottom:16}}>
                <div style={{fontSize:32}}>{l.icon}</div>
                <div>
                  <div style={{fontSize:24,fontWeight:900,color:WHITE,letterSpacing:'-0.5px'}}>{l.name}</div>
                  <span style={{display:'inline-block',fontSize:10,fontWeight:700,letterSpacing:2,color:l.col,background:`${l.col}18`,border:`1px solid ${l.col}38`,borderRadius:20,padding:'2px 10px',marginTop:3}}>{l.tag}</span>
                </div>
              </div>
              <div style={{fontSize:14,color:'rgba(255,255,255,0.58)',lineHeight:1.7,marginBottom:20}}>{l.desc}</div>
              <div style={{display:'flex',alignItems:'center',gap:8,padding:'10px 14px',background:`${l.col}10`,borderRadius:10,border:`1px solid ${l.col}28`}}>
                <div style={{width:8,height:8,borderRadius:'50%',background:l.col,flexShrink:0}}/>
                <div style={{fontSize:13,fontWeight:600,color:l.col}}>{l.how}</div>
              </div>
            </div>
          )
        })}
      </div>
    </AbsoluteFill>
  )
}

// ─── SCENE 5: CTA ──────────────────────────────────────────────────────────

function Scene5() {
  const f = useCurrentFrame()
  const mSp = spring({ frame:f, fps:AD_FPS, config:{damping:12,stiffness:52} })
  const pulse = 0.5 + Math.sin(f * 0.13) * 0.5
  const btnSc = 1 + Math.sin(f * 0.09) * 0.02

  return (
    <AbsoluteFill style={{ background:`linear-gradient(145deg,${NAVY},#0D1929)`, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', padding:80 }}>
      {/* Pulsing rings */}
      {[640,420,240].map((sz,i) => (
        <div key={i} style={{
          position:'absolute', width:sz, height:sz, borderRadius:'50%',
          border:`1px solid ${GOLD}${['12','20','30'][i]}`,
          opacity:pulse*(0.3+i*0.2),
          transform:`scale(${1+f*0.0016*(i+1)})`,
          pointerEvents:'none',
        }}/>
      ))}

      <div style={{
        display:'inline-flex',alignItems:'center',gap:9,
        padding:'8px 20px',background:`${GREEN}16`,
        border:`1px solid ${GREEN}40`,borderRadius:24,
        fontSize:13,fontWeight:600,color:GREEN,
        marginBottom:30,...ey(f,5,20),
      }}>
        <div style={{width:7,height:7,borderRadius:'50%',background:GREEN,boxShadow:`0 0 10px ${GREEN}`}}/>
        Australian Security Clearance Specialists
      </div>

      <div style={{
        fontSize:80, fontWeight:900, letterSpacing:'-4px', textAlign:'center', lineHeight:1.05,
        background:`linear-gradient(135deg,${WHITE} 0%,${GOLD} 100%)`,
        WebkitBackgroundClip:'text', WebkitTextFillColor:'transparent',
        transform:`scale(${mSp}) translateY(${(1-mSp)*36}px)`,
        marginBottom:24,
      }}>
        Ready to get<br/>cleared?
      </div>

      <div style={{
        fontSize:20,color:'rgba(255,255,255,0.58)',textAlign:'center',
        maxWidth:500,lineHeight:1.7,marginBottom:52,...ey(f,20,20),
      }}>
        Baseline sponsorship. NV1 &amp; NV2 referrals.<br/>
        Expert guidance every step of the way.
      </div>

      <div style={{ transform:`scale(${btnSc})`,...ey(f,26,20),marginBottom:26 }}>
        <div style={{
          background:`linear-gradient(135deg,${GOLD},#E8A020)`,
          borderRadius:18,padding:'20px 64px',
          fontSize:26,fontWeight:900,color:NAVY,letterSpacing:'-0.5px',
          boxShadow:`0 20px 56px ${GOLD}40`,
        }}>www.ausclear.com.au</div>
      </div>

      <div style={{ fontSize:13,color:'rgba(255,255,255,0.2)',letterSpacing:4,textTransform:'uppercase',...ey(f,36,20) }}>
        Trusted &middot; Professional &middot; Australian
      </div>
    </AbsoluteFill>
  )
}

// ─── ROOT ──────────────────────────────────────────────────────────────────

export function AusClearAd() {
  return (
    <>
      <Sequence from={0}         durationInFrames={SCENE}><Scene1/></Sequence>
      <Sequence from={SCENE}     durationInFrames={SCENE}><Scene2/></Sequence>
      <Sequence from={SCENE*2}   durationInFrames={SCENE}><Scene3/></Sequence>
      <Sequence from={SCENE*3}   durationInFrames={SCENE}><Scene4/></Sequence>
      <Sequence from={SCENE*4}   durationInFrames={SCENE}><Scene5/></Sequence>
    </>
  )
}
