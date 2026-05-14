import { Player } from '@remotion/player'
import { AusClearAd, AD_FPS, AD_WIDTH, AD_HEIGHT, AD_FRAMES } from './AusClearAd'

export default function App() {
  return (
    <div style={{
      width: '100vw',
      height: '100vh',
      background: '#080D1A',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 14,
    }}>
      <Player
        component={AusClearAd}
        durationInFrames={AD_FRAMES}
        fps={AD_FPS}
        compositionWidth={AD_WIDTH}
        compositionHeight={AD_HEIGHT}
        style={{
          width: '95vw',
          maxWidth: 1280,
          aspectRatio: `${AD_WIDTH}/${AD_HEIGHT}`,
          borderRadius: 16,
          overflow: 'hidden',
          boxShadow: '0 40px 100px rgba(0,0,0,0.7)',
        }}
        autoPlay
        loop
        controls
      />
      <div style={{ color: 'rgba(255,255,255,0.2)', fontSize: 11, letterSpacing: 3, textTransform: 'uppercase' }}>
        AusClear · Security Clearance Specialists · ausclear.com.au
      </div>
    </div>
  )
}
