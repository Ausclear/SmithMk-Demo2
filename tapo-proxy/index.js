const express = require('express');
const { cloudLogin, loginDevice, loginDeviceByIp } = require('tp-link-tapo-connect');
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
let devices = {};
async function discover() {
  try {
    console.log('[Tapo] Discovering...');
    const cloud = await cloudLogin(EMAIL, PASSWORD);
    const plugs = await cloud.listDevicesByType('SMART.TAPOPLUG');
    const bulbs = await cloud.listDevicesByType('SMART.TAPOBULB');
    for (const d of [...plugs, ...bulbs]) {
      const alias = d.alias || d.deviceName || d.deviceMac;
      try {
        const local = await loginDevice(EMAIL, PASSWORD, d);
        const info = await local.getDeviceInfo();
        devices[alias] = {
          ip: info.ip || d.ip, mac: d.deviceMac, type: d.deviceType,
          model: info.model || '', alias,
          nickname: info.nickname ? Buffer.from(info.nickname, 'base64').toString('utf8') : alias,
          deviceOn: info.device_on || false, brightness: info.brightness || 0,
          hue: info.hue || 0, saturation: info.saturation || 0,
          colorTemp: info.color_temp || 0, signalLevel: info.signal_level || 0,
          reachable: true
        };
        console.log(`[Tapo] ${devices[alias].nickname} (${devices[alias].ip}) on=${info.device_on}`);
      } catch (e) {
        devices[alias] = { ip: null, mac: d.deviceMac, type: d.deviceType, alias, nickname: alias, deviceOn: false, reachable: false };
      }
    }
    console.log(`[Tapo] Found ${Object.keys(devices).length} devices`);
  } catch (e) { console.error('[Tapo] Discovery failed:', e.message); }
}
async function pollAll() {
  for (const [, dev] of Object.entries(devices)) {
    if (!dev.ip) continue;
    try {
      const local = await loginDeviceByIp(EMAIL, PASSWORD, dev.ip);
      const info = await local.getDeviceInfo();
      dev.deviceOn = info.device_on || false; dev.brightness = info.brightness || 0;
      dev.hue = info.hue || 0; dev.saturation = info.saturation || 0;
      dev.colorTemp = info.color_temp || 0; dev.reachable = true;
    } catch { dev.reachable = false; }
  }
}
setInterval(pollAll, 10000);
setInterval(discover, 300000);
app.get('/api/tapo/devices', (req, res) => res.json(devices));
app.post('/api/tapo/discover', async (req, res) => { await discover(); res.json(devices); });
app.post('/api/tapo/on', async (req, res) => {
  try { const local = await loginDeviceByIp(EMAIL, PASSWORD, req.body.ip); await local.turnOn();
    const d = Object.values(devices).find(x => x.ip === req.body.ip); if (d) d.deviceOn = true;
    res.json({ ok: true }); } catch (e) { res.status(500).json({ error: e.message }); }
});
app.post('/api/tapo/off', async (req, res) => {
  try { const local = await loginDeviceByIp(EMAIL, PASSWORD, req.body.ip); await local.turnOff();
    const d = Object.values(devices).find(x => x.ip === req.body.ip); if (d) d.deviceOn = false;
    res.json({ ok: true }); } catch (e) { res.status(500).json({ error: e.message }); }
});
app.post('/api/tapo/brightness', async (req, res) => {
  try { const local = await loginDeviceByIp(EMAIL, PASSWORD, req.body.ip); await local.setBrightness(req.body.brightness);
    const d = Object.values(devices).find(x => x.ip === req.body.ip); if (d) { d.brightness = req.body.brightness; d.deviceOn = true; }
    res.json({ ok: true }); } catch (e) { res.status(500).json({ error: e.message }); }
});
app.post('/api/tapo/colour', async (req, res) => {
  try { const { ip, hue, saturation, brightness } = req.body;
    const local = await loginDeviceByIp(EMAIL, PASSWORD, ip); await local.setColour(hue, saturation, brightness);
    const d = Object.values(devices).find(x => x.ip === ip); if (d) { d.hue = hue; d.saturation = saturation; d.brightness = brightness; d.deviceOn = true; }
    res.json({ ok: true }); } catch (e) { res.status(500).json({ error: e.message }); }
});
app.listen(4500, '0.0.0.0', async () => { console.log('[Tapo] Proxy on :4500'); await discover(); });
