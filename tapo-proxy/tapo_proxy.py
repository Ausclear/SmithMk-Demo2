#!/usr/bin/env python3
"""SmithMk Tapo Proxy — Python, uses mihai-dinculescu/tapo library.
Scans local network for Tapo devices, controls directly. NO HA.
Run: pip install tapo flask && python tapo_proxy.py
"""
import asyncio, json, time, threading
from flask import Flask, request, jsonify
from tapo import ApiClient

app = Flask(__name__)

EMAIL = "smithmk@aussiebb.com.au"
PASSWORD = "MkS.9272103"

devices = {}  # ip -> {nickname, ip, model, type, isPlug, deviceOn, brightness, ...}

async def try_device(ip):
    """Try to connect to a Tapo device at the given IP."""
    try:
        client = ApiClient(EMAIL, PASSWORD)
        # Try as plug first
        try:
            dev = await client.p100(ip)
            info = await dev.get_device_info()
            info_dict = info.to_dict() if hasattr(info, 'to_dict') else vars(info)
            nickname = info_dict.get('nickname', ip)
            model = info_dict.get('model', 'P100')
            return {
                'ip': ip, 'nickname': nickname, 'model': model,
                'type': 'SMART.TAPOPLUG', 'isPlug': True,
                'deviceOn': info_dict.get('device_on', False),
                'brightness': 0, 'hue': 0, 'saturation': 0,
                'colorTemp': 0, 'reachable': True
            }
        except:
            pass
        # Try as light strip
        try:
            dev = await client.l920(ip)
            info = await dev.get_device_info()
            info_dict = info.to_dict() if hasattr(info, 'to_dict') else vars(info)
            nickname = info_dict.get('nickname', ip)
            model = info_dict.get('model', 'L920')
            return {
                'ip': ip, 'nickname': nickname, 'model': model,
                'type': 'SMART.TAPOBULB', 'isPlug': False,
                'deviceOn': info_dict.get('device_on', False),
                'brightness': info_dict.get('brightness', 0),
                'hue': info_dict.get('hue', 0),
                'saturation': info_dict.get('saturation', 0),
                'colorTemp': info_dict.get('color_temp', 0),
                'reachable': True
            }
        except:
            pass
    except:
        pass
    return None

async def scan_network():
    global devices
    print("[Tapo] Scanning network...")
    subnet = "192.168.1."
    skip = {1, 47, 101, 203}  # router, VM, QNAP, Hue
    
    tasks = []
    for i in range(2, 255):
        if i in skip:
            continue
        tasks.append(try_device(subnet + str(i)))
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    for r in results:
        if r and isinstance(r, dict):
            devices[r['ip']] = r
            print(f"[Tapo] Found: {r['nickname']} at {r['ip']} ({r['model']}) on={r['deviceOn']}")
    
    print(f"[Tapo] Scan complete: {len(devices)} devices")

async def poll_devices():
    for ip, dev in list(devices.items()):
        try:
            client = ApiClient(EMAIL, PASSWORD)
            if dev['isPlug']:
                d = await client.p100(ip)
            else:
                d = await client.l920(ip)
            info = await d.get_device_info()
            info_dict = info.to_dict() if hasattr(info, 'to_dict') else vars(info)
            dev['deviceOn'] = info_dict.get('device_on', False)
            dev['brightness'] = info_dict.get('brightness', 0)
            dev['hue'] = info_dict.get('hue', 0)
            dev['saturation'] = info_dict.get('saturation', 0)
            dev['reachable'] = True
        except:
            dev['reachable'] = False

def bg_loop():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(scan_network())
    while True:
        time.sleep(10)
        loop.run_until_complete(poll_devices())

# Background thread for async scanning/polling
threading.Thread(target=bg_loop, daemon=True).start()

@app.route('/api/tapo/devices')
def get_devices():
    return jsonify(devices)

@app.route('/api/tapo/discover', methods=['POST'])
def do_discover():
    loop = asyncio.new_event_loop()
    loop.run_until_complete(scan_network())
    return jsonify(devices)

@app.route('/api/tapo/on', methods=['POST'])
def turn_on():
    ip = request.json.get('ip')
    try:
        loop = asyncio.new_event_loop()
        async def _on():
            client = ApiClient(EMAIL, PASSWORD)
            dev = devices.get(ip, {})
            if dev.get('isPlug'):
                d = await client.p100(ip)
            else:
                d = await client.l920(ip)
            await d.on()
        loop.run_until_complete(_on())
        if ip in devices: devices[ip]['deviceOn'] = True
        return jsonify({'ok': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/tapo/off', methods=['POST'])
def turn_off():
    ip = request.json.get('ip')
    try:
        loop = asyncio.new_event_loop()
        async def _off():
            client = ApiClient(EMAIL, PASSWORD)
            dev = devices.get(ip, {})
            if dev.get('isPlug'):
                d = await client.p100(ip)
            else:
                d = await client.l920(ip)
            await d.off()
        loop.run_until_complete(_off())
        if ip in devices: devices[ip]['deviceOn'] = False
        return jsonify({'ok': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/tapo/brightness', methods=['POST'])
def set_brightness():
    ip = request.json.get('ip')
    bri = request.json.get('brightness', 50)
    try:
        loop = asyncio.new_event_loop()
        async def _bri():
            client = ApiClient(EMAIL, PASSWORD)
            d = await client.l920(ip)
            await d.set_brightness(bri)
        loop.run_until_complete(_bri())
        if ip in devices: devices[ip]['brightness'] = bri; devices[ip]['deviceOn'] = True
        return jsonify({'ok': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    from flask_cors import CORS
    try:
        CORS(app)
    except:
        # flask-cors not installed, add manual CORS
        @app.after_request
        def cors(response):
            response.headers['Access-Control-Allow-Origin'] = '*'
            response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
            response.headers['Access-Control-Allow-Methods'] = 'GET,POST,OPTIONS'
            return response
    
    print("[Tapo] Proxy on :4500 — Python, NO HA, direct local only")
    app.run(host='0.0.0.0', port=4500)
