// SmithMk Tapo Proxy v2 — LOCAL ONLY, no cloud login needed
// Uses direct local IP control. Device IPs found from HA.
// Runs on VM at 192.168.1.47:4500 or wherever.
const express = require('express');
const { loginDeviceByIp } = require('tp-link-tapo-connect');

const app = express();
app.use(express.json());
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

const EMAIL = 'smithmk@aussiebb.com.au';
const PASSWORD = 'MkS.9272103';

// Known devices — IPs will be discovered from HA or manually set
// These get populated on first discovery scan
let devices = {};

// Scan local network for Tapo devices by trying known HA entity IPs
// We get the IPs from HA's device registry
async function discoverFromHA() {
  try {
    console.log('[Tapo] Discovering from HA...');
    const resp = await fetch('http://192.168.1.101:8123/api/states', {
      headers: { 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIwOWI5OTlmY2JmMWY0OWQwYTFiYzBiMmM1M2NiZTgyMiIsImlhdCI6MTc3MzExOTk5OSwiZXhwIjoyMDg4NDc5OTk5fQ.0HfaVvG4_Ld5xuxzejS5sWxi5jRGREkNrPXN3s-uM0k' }
    });
    const states = await resp.json();
    
    // Find Tapo switch entities and try to get their IPs from device info
    const tapoEntities = states.filter(e => 
      ['switch.lounge_picture', 'switch.kitchen_ucl_1', 'switch.kitchen_ucl_2',
       'light.cerise_lightstrip', 'light.cerise_lightstrip_2'].includes(e.entity_id)
    );
    
    for (const ent of tapoEntities) {
      const name = ent.attributes.friendly_name || ent.entity_id;
      const isPlug = ent.entity_id.startsWith('switch.');
      devices[ent.entity_id] = {
        entityId: ent.entity_id,
        nickname: name,
        ip: null, // Will try to find
        type: isPlug ? 'SMART.TAPOPLUG' : 'SMART.TAPOBULB',
        model: isPlug ? 'P100' : 'L920',
        isPlug: isPlug,
        deviceOn: ent.state === 'on',
        brightness: ent.attributes.brightness ? Math.round(ent.attributes.brightness / 255 * 100) : 0,
        hue: ent.attributes.hs_color ? ent.attributes.hs_color[0] : 0,
        saturation: ent.attributes.hs_color ? ent.attributes.hs_color[1] : 0,
        reachable: ent.state !== 'unavailable',
        useHA: true // Flag: control via HA until local IP found
      };
    }
    console.log(`[Tapo] Found ${Object.keys(devices).length} Tapo entities from HA`);
  } catch (e) {
    console.error('[Tapo] HA discovery failed:', e.message);
  }
}

// Try to find local IPs by scanning common ranges
async function scanForLocalIPs() {
  console.log('[Tapo] Scanning for local Tapo devices...');
  // Try each device — if we can login locally, we have the IP
  const subnet = '192.168.1.';
  const candidates = [];
  
  // Build candidate list from DHCP range
  for (let i = 2; i <= 254; i++) {
    if (i === 47 || i === 101 || i === 203) continue; // Skip VM, QNAP, Hue
    candidates.push(subnet + i);
  }
  
  // Try in parallel batches of 20
  for (let batch = 0; batch < candidates.length; batch += 20) {
    const slice = candidates.slice(batch, batch + 20);
    const promises = slice.map(async (ip) => {
      try {
        const dev = await loginDeviceByIp(EMAIL, PASSWORD, ip);
        const info = await dev.getDeviceInfo();
        if (info.type && (info.type.includes('TAPOPLUG') || info.type.includes('TAPOBULB'))) {
          const nickname = info.nickname ? Buffer.from(info.nickname, 'base64').toString('utf8') : ip;
          console.log(`[Tapo] Found ${nickname} at ${ip}`);
          
          // Match to existing HA device by name
          let matched = false;
          for (const [key, d] of Object.entries(devices)) {
            if (d.nickname.toLowerCase().includes(nickname.toLowerCase()) || nickname.toLowerCase().includes(d.nickname.toLowerCase())) {
              d.ip = ip;
              d.useHA = false;
              d.deviceOn = info.device_on || false;
              d.brightness = info.brightness || 0;
              matched = true;
              console.log(`[Tapo] Matched ${nickname} → ${key}`);
              break;
            }
          }
          if (!matched) {
            // New device not in HA
            const id = 'tapo_' + ip.replace(/\./g, '_');
            devices[id] = {
              entityId: id, nickname, ip,
              type: info.type, model: info.model || '',
              isPlug: (info.type || '').includes('PLUG'),
              deviceOn: info.device_on || false,
              brightness: info.brightness || 0,
              hue: info.hue || 0, saturation: info.saturation || 0,
              reachable: true, useHA: false
            };
          }
        }
      } catch (_) {} // Not a Tapo device or unreachable
    });
    await Promise.allSettled(promises);
  }
  console.log('[Tapo] Scan complete');
}

// Poll known devices for state
async function pollAll() {
  for (const [key, dev] of Object.entries(devices)) {
    if (dev.ip && !dev.useHA) {
      try {
        const local = await loginDeviceByIp(EMAIL, PASSWORD, dev.ip);
        const info = await local.getDeviceInfo();
        dev.deviceOn = info.device_on || false;
        dev.brightness = info.brightness || 0;
        dev.hue = info.hue || 0;
        dev.saturation = info.saturation || 0;
        dev.reachable = true;
      } catch { dev.reachable = false; }
    } else if (dev.useHA) {
      // Poll from HA
      try {
        const resp = await fetch(`http://192.168.1.101:8123/api/states/${dev.entityId}`, {
          headers: { 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIwOWI5OTlmY2JmMWY0OWQwYTFiYzBiMmM1M2NiZTgyMiIsImlhdCI6MTc3MzExOTk5OSwiZXhwIjoyMDg4NDc5OTk5fQ.0HfaVvG4_Ld5xuxzejS5sWxi5jRGREkNrPXN3s-uM0k' }
        });
        const ent = await resp.json();
        dev.deviceOn = ent.state === 'on';
        dev.brightness = ent.attributes.brightness ? Math.round(ent.attributes.brightness / 255 * 100) : 0;
        dev.reachable = ent.state !== 'unavailable';
      } catch { dev.reachable = false; }
    }
  }
}

setInterval(pollAll, 10000);
setInterval(() => scanForLocalIPs(), 300000); // Re-scan every 5 mins

// ─── REST API ───
app.get('/api/tapo/devices', (req, res) => res.json(devices));
app.post('/api/tapo/discover', async (req, res) => { await discoverFromHA(); await scanForLocalIPs(); res.json(devices); });

app.post('/api/tapo/on', async (req, res) => {
  const { ip } = req.body;
  const dev = Object.values(devices).find(d => d.ip === ip);
  try {
    if (ip && dev && !dev.useHA) {
      const local = await loginDeviceByIp(EMAIL, PASSWORD, ip);
      await local.turnOn();
    } else if (dev && dev.useHA) {
      const domain = dev.entityId.startsWith('light.') ? 'light' : 'switch';
      await fetch(`http://192.168.1.101:8123/api/services/${domain}/turn_on`, {
        method: 'POST',
        headers: { 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIwOWI5OTlmY2JmMWY0OWQwYTFiYzBiMmM1M2NiZTgyMiIsImlhdCI6MTc3MzExOTk5OSwiZXhwIjoyMDg4NDc5OTk5fQ.0HfaVvG4_Ld5xuxzejS5sWxi5jRGREkNrPXN3s-uM0k', 'Content-Type': 'application/json' },
        body: JSON.stringify({ entity_id: dev.entityId })
      });
    }
    if (dev) dev.deviceOn = true;
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/tapo/off', async (req, res) => {
  const { ip } = req.body;
  const dev = Object.values(devices).find(d => d.ip === ip);
  try {
    if (ip && dev && !dev.useHA) {
      const local = await loginDeviceByIp(EMAIL, PASSWORD, ip);
      await local.turnOff();
    } else if (dev && dev.useHA) {
      const domain = dev.entityId.startsWith('light.') ? 'light' : 'switch';
      await fetch(`http://192.168.1.101:8123/api/services/${domain}/turn_off`, {
        method: 'POST',
        headers: { 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIwOWI5OTlmY2JmMWY0OWQwYTFiYzBiMmM1M2NiZTgyMiIsImlhdCI6MTc3MzExOTk5OSwiZXhwIjoyMDg4NDc5OTk5fQ.0HfaVvG4_Ld5xuxzejS5sWxi5jRGREkNrPXN3s-uM0k', 'Content-Type': 'application/json' },
        body: JSON.stringify({ entity_id: dev.entityId })
      });
    }
    if (dev) dev.deviceOn = false;
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/tapo/brightness', async (req, res) => {
  const { ip, brightness } = req.body;
  const dev = Object.values(devices).find(d => d.ip === ip);
  try {
    if (ip && dev && !dev.useHA) {
      const local = await loginDeviceByIp(EMAIL, PASSWORD, ip);
      await local.setBrightness(brightness);
    } else if (dev && dev.useHA) {
      await fetch('http://192.168.1.101:8123/api/services/light/turn_on', {
        method: 'POST',
        headers: { 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIwOWI5OTlmY2JmMWY0OWQwYTFiYzBiMmM1M2NiZTgyMiIsImlhdCI6MTc3MzExOTk5OSwiZXhwIjoyMDg4NDc5OTk5fQ.0HfaVvG4_Ld5xuxzejS5sWxi5jRGREkNrPXN3s-uM0k', 'Content-Type': 'application/json' },
        body: JSON.stringify({ entity_id: dev.entityId, brightness: Math.round(brightness / 100 * 255) })
      });
    }
    if (dev) { dev.brightness = brightness; dev.deviceOn = true; }
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.listen(4500, '0.0.0.0', async () => {
  console.log('[Tapo] Proxy v2 on :4500');
  await discoverFromHA();
  // Background scan for local IPs
  scanForLocalIPs();
});
