"""Measure opaque sprite bounds; do not modify generated image pixels."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]
configs={'atlas':('atlas.png',4,2),'poses':('poses-v2.png',2,2),'enemies':('enemies-v2.png',2,2),'explosion':('explosion.png',6,1),'charge':('charge.png',6,1),'muzzle':('muzzle.png',6,1),'tiles':('tiles.png',3,1),'core':('core.png',1,1)}
cuts={'tiles':[0,.38,.60,1],'explosion':[0,.13,.30,.49,.67,.84,1],'muzzle':[0,.11,.29,.515,.69,.90,1]}
result={}
for name,(filename,cols,rows) in configs.items():
 im=Image.open(root/'assets'/filename).convert('RGBA'); w,h=im.size
 rects=[]
 for i in range(cols*rows):
  x0=int(i%cols*w/cols);y0=int(i//cols*h/rows);x1=int((i%cols+1)*w/cols);y1=int((i//cols+1)*h/rows)
  if name in cuts:x0=int(cuts[name][i]*w);x1=int(cuts[name][i+1]*w)
  if name=='enemies' and i>=2:x0=0 if i==2 else int(w*.57);x1=int(w*.57) if i==2 else w
  alpha=im.crop((x0,y0,x1,y1)).getchannel('A')
  bbox=alpha.point(lambda a:255 if a>=40 else 0).getbbox()
  if not bbox:raise ValueError((name,i,'empty frame'))
  a,b,c,d=bbox
  rects.append([x0+a,y0+b,c-a,d-b])
 result[name]=rects
(root/'assets/regions.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps({k:len(v) for k,v in result.items()}))
