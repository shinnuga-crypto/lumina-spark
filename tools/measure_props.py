"""Measure generated prop sprites without changing any image pixels."""
from collections import deque
import json
from pathlib import Path
import numpy as np
from PIL import Image

root=Path(__file__).resolve().parents[1]/'assets/campaign'
metadata={}
for name,cols,rows in [('props-surface',2,3),('props-shaft',3,3)]:
    im=Image.open(root/f'{name}.png').convert('RGBA')
    factor=2
    alpha=np.array(im.getchannel('A').resize((im.width//factor,im.height//factor)))>80
    groups={}
    for y in range(alpha.shape[0]):
        for x in range(alpha.shape[1]):
            if not alpha[y,x]: continue
            alpha[y,x]=False; queue=deque([(x,y)])
            lo_x=hi_x=x; lo_y=hi_y=y; area=0
            while queue:
                cx,cy=queue.popleft(); area+=1
                lo_x=min(lo_x,cx); hi_x=max(hi_x,cx); lo_y=min(lo_y,cy); hi_y=max(hi_y,cy)
                for nx,ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
                    if 0<=nx<alpha.shape[1] and 0<=ny<alpha.shape[0] and alpha[ny,nx]:
                        alpha[ny,nx]=False; queue.append((nx,ny))
            if area<150: continue
            cx=(lo_x+hi_x)*factor/2; cy=(lo_y+hi_y)*factor/2
            slot=min(rows-1,int(cy/(im.height/rows)))*cols+min(cols-1,int(cx/(im.width/cols)))
            box=[max(0,lo_x*factor-4),max(0,lo_y*factor-4),min(im.width,(hi_x+1)*factor+4),min(im.height,(hi_y+1)*factor+4)]
            if slot in groups:
                old=groups[slot]; box=[min(old[0],box[0]),min(old[1],box[1]),max(old[2],box[2]),max(old[3],box[3])]
            groups[slot]=box
    if len(groups)!=cols*rows: raise ValueError((name,groups))
    rects=[[b[0],b[1],b[2]-b[0],b[3]-b[1]] for _,b in sorted(groups.items())]
    metadata[name]=rects
    print(name,rects)
(root/'props-regions.json').write_bytes((json.dumps(metadata,indent=2)+'\n').encode())
