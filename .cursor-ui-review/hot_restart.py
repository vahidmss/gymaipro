import asyncio
import json
import sys

try:
    import websockets
except ImportError:
    import subprocess

    subprocess.check_call(
        [sys.executable, '-m', 'pip', 'install', 'websockets', '-q']
    )
    import websockets

URI = 'ws://127.0.0.1:2436/VH01BtzlggE=/ws'


async def main() -> None:
    async with websockets.connect(URI, max_size=8_000_000) as ws:
        await ws.send(
            json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': 'getVM'})
        )
        vm = json.loads(await ws.recv())
        isolates = vm.get('result', {}).get('isolates', [])
        print('isolates', [i.get('name') for i in isolates])
        if not isolates:
            print('no isolate')
            return
        main_iso = next(
            (
                i
                for i in isolates
                if 'main' in (i.get('name') or '').lower()
            ),
            isolates[0],
        )
        iid = main_iso['id']
        await ws.send(
            json.dumps(
                {
                    'jsonrpc': '2.0',
                    'id': 2,
                    'method': 'ext.flutter.hotRestart',
                    'params': {'isolateId': iid},
                }
            )
        )
        while True:
            msg = json.loads(await asyncio.wait_for(ws.recv(), timeout=45))
            if msg.get('id') == 2:
                print('hotRestart result:', msg)
                break


if __name__ == '__main__':
    asyncio.run(main())
