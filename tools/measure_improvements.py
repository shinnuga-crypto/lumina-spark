"""Measure GPTImage atlas frames and shared miniboss anchors, preserving pixels."""
from pathlib import Path
from PIL import Image
import json,numpy as np
root=Path(__file__).resolve().parents[1]/'assets/improvements'
data={}
for name,count in [('doors',4),('devices',3),('electricity',4),('wind',4),('miniboss',3)]:
 im=Image.open(root/(name+'.png')).convert('RGBA');w,h=im.size
 cuts=[i/count for i in range(count+1)]
 if name=='miniboss':cuts=[0,1/3,.64,1]
 entry={'regions':[]};anchors=[]
 for i in range(count):
  left,right=round(w*cuts[i]),round(w*cuts[i+1]);cell=im.crop((left,0,right,h))
  box=cell.getchannel('A').point(lambda a:255 if a>=40 else 0).getbbox()
  if not box:raise ValueError((name,i,'empty'))
  x0,y0,x1,y1=box;entry['regions'].append([left+x0,y0,x1-x0,y1-y0])
  if name=='miniboss':
   a=np.array(cell.crop(box)).astype(float);r,g,b,alpha=[a[:,:,j] for j in range(4)]
   yy,xx=np.indices(alpha.shape)
   mask=(alpha>180)&(g>135)&(b>140)&(r<g*.75)&(yy<(y1-y0)*.4)
   ys,xs=np.where(mask)
   if len(xs)==0:raise ValueError(('visor not found',i))
   anchors.append([round(float(np.median(xs))+4,2),y1-y0])
 if name=='miniboss':entry.update(anchors=anchors,scale=150/entry['regions'][0][3])
 data[name]=entry
(root/'regions.json').write_bytes((json.dumps(data,indent=2)+'\n').encode('utf-8'))
print({name:len(entry['regions']) for name,entry in data.items()})
