"""Measure transparent sprite regions; preserve the generated source pixels."""
from collections import deque
import json
from pathlib import Path
import numpy as np
from PIL import Image

root=Path(__file__).resolve().parents[1]/'assets/campaign'
im=Image.open(root/'actors-v2.png').convert('RGBA')
a=np.array(im.getchannel('A').resize((768,512)))>100
regions=[]
for y in range(a.shape[0]):
    for x in range(a.shape[1]):
        if not a[y,x]: continue
        a[y,x]=False
        todo=deque([(x,y)]); xs=[]; ys=[]
        while todo:
            cx,cy=todo.popleft(); xs.append(cx); ys.append(cy)
            for nx,ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
                if 0<=nx<a.shape[1] and 0<=ny<a.shape[0] and a[ny,nx]:
                    a[ny,nx]=False; todo.append((nx,ny))
        if len(xs)>2000:
            x0=max(0,min(xs)*2-4); y0=max(0,min(ys)*2-4)
            x1=min(im.width,max(xs)*2+6); y1=min(im.height,max(ys)*2+6)
            regions.append([x0,y0,x1-x0,y1-y0])
regions.sort(key=lambda r:(int((r[1]+r[3]/2)/512),r[0]+r[2]/2))
if len(regions)!=6: raise ValueError(f'expected six isolated actors, got {regions}')
(root/'regions.json').write_bytes((json.dumps({'actors':regions},indent=2)+'\n').encode())
print(regions)
