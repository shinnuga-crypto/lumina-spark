"""Author the two additional stages as ordinary editable JSON layouts."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
surface = {'name': '02  地上 / 夜明けの迎撃線', 'width': 11280, 'height': 720,
           'arena': [10000, 0, 1280, 720], 'platforms': [], 'enemies': [],
           'shelters': [], 'strikes': [], 'vents': [], 'belts': [], 'crumble': [], 'crushers': [], 'plugs': []}
for i in range(10):
    x = i * 1000
    # Generous approach and landing zones; short gaps stay within one jump.
    floors = [[x, 610, 1000, 130]] if i in (0, 2, 5, 8, 9) else [[x, 610, 620, 130], [x+760, 610, 240, 130]]
    surface['platforms'] += floors + [[x+240, 470, 230, 24], [x+610, 360 if i%2 else 430, 210, 24]]
    surface['enemies'] += [[7, x+540, 270], [8 if i%2 else 7, x+850, 355]]
    if i > 1: surface['enemies'].append([10 if i%3==0 else 9, x+360, 575 if i%3==0 else 390])
    if i in (1, 4, 7):
        surface['shelters'].append([x+100, 380, 300, 28])
        surface['platforms'].append([x+100, 380, 300, 28])
        surface['strikes'].append([x+430, 540])
    if i in (0, 3, 6, 8): surface['vents'].append([x+120, 610, 90, 120])
    if i in (2, 5, 8): surface['belts'].append([x+480, 610, 420, -100 if i==5 else 100])
surface['platforms'] += [[10000, 610, 1280, 130], [10210, 450, 210, 24], [10670, 460, 190, 24]]

shaft = {'name': '03  地下 / 星骸の深淵', 'width': 1280, 'height': 6380,
         'arena': [0, 5580, 1280, 800], 'platforms': [[0,610,480,80],[760,610,520,80]],
         'enemies': [], 'shelters': [], 'strikes': [], 'vents': [], 'belts': [],
         'crumble': [], 'crushers': [], 'plugs': [[480,610,280,30]]}
for i in range(8):
    y = 970+i*580
    # Alternating ledges encourage steering during the descent, never a blind fall.
    shaft['platforms'] += [[0 if i%2==0 else 760, y, 520, 32], [760 if i%2==0 else 0, y+260, 520, 32]]
    if i not in (2, 5):
        shaft['crumble'].append(len(shaft['platforms']))
        shaft['platforms'].append([480,y+130,280,22])
    shaft['enemies'] += [[9, 600, y-90], [10, 250 if i%2==0 else 1010, y-35]]
    if i%2==1: shaft['enemies'].append([8, 620, y+200])
    if i in (1, 3, 6): shaft['crushers'].append([0 if i%2 else 1,y+110,4.8+i*0.1])
shaft['platforms'] += [[0,6300,1280,100],[150,6070,240,24],[510,5930,220,24]]
for y in (2550,4290):
    shaft['platforms'] += [[0,y,480,60],[760,y,520,60]]
    shaft['plugs'].append([480,y,280,30])
for name, data in [('stage2',surface),('stage3',shaft)]:
    (root/'data'/f'{name}.json').write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    print(name, len(data['platforms']), 'platforms', len(data['enemies']), 'enemies')
