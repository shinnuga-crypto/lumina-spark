"""Measure atlas regions/head scale only. Never change source pixels or animation.json."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
reference = json.loads((ROOT/'assets/motion/animation.json').read_text())['reference_head_metric']
result = {'reference_head_metric': reference, 'sets': {}}
# Anchors are anatomical hip points or the midpoint between planted feet, in atlas pixels.
# The heavy ground effect crosses the nominal grid: use measured unequal bottom cells.
specs = {
 'ground': (3,2, [[240,460],[710,460],[1260,460],[260,943],[710,943],[1265,943]], [[397,273],[604,245],[1152,246],[142,752],[569,775],[1131,781]]),
 'air': (3,2, [[201,306],[686,305],[1208,305],[253,814],[688,816],[1245,813]], [[430,274],[577,235],[1108,239],[116,751],[556,773],[1108,779]]),
 'heavy': (2,2, [[354,461],[1070,461],[320,963],[1100,963]], [[264,249],[964,256],[254,743],[1037,762]]),
 'heavy-air': (2,2, [[375,333],[1095,341],[324,803],[1070,806]], [[294,234],[1009,269],[249,717],[1009,724]]),
 'dash': (2,2, [[320,285],[1051,299],[304,804],[1050,803]], [[259,163],[990,209],[737,717],[974,697]])
}
for name,(cols,rows,anchors,muzzles) in specs.items():
 file=f'assets/motion/{name}-v3.png'
 a=np.asarray(Image.open(ROOT/file).convert('RGBA')).astype(float)
 h,w=a.shape[:2]; frames=[]
 for i in range(cols*rows):
  x=i%cols*w//cols; y=i//cols*h//rows
  endx=(i%cols+1)*w//cols; endy=(i//cols+1)*h//rows
  if name=='heavy' and i==2: endx=824
  if name=='heavy' and i==3: x=824
  b=a[y:endy,x:endx]; r,g,blue,alpha=[b[:,:,j] for j in range(4)]
  yy,xx=np.where((alpha>180)&(r>g*1.4)&(blue>g*1.12)&(r>120))
  x0,x1=np.percentile(xx,[3,97]); y0,y1=np.percentile(yy,[3,97])
  metric=float(np.sqrt((x1-x0)*(y1-y0)))
  scale=reference/metric
  anchor=[anchors[i][0]-x,anchors[i][1]-y]
  # Floating poses are attached by the hip, 51 world pixels above the physics foot origin.
  if name in ('air','heavy-air','dash'): anchor[1]+=51/scale if name!='dash' else 43/scale
  frame={'region':[x,y,endx-x,endy-y], 'anchor':anchor,
         'muzzle':[muzzles[i][0]-x,muzzles[i][1]-y],
         'head_metric':metric,'head_bounds':[float(x0),float(y0),float(x1),float(y1)],'scale':scale}
  frames.append(frame)
 result['sets'][name]={'file':file,'frames':frames}
 print(name, 'head scale range',round(min(f['scale'] for f in frames),4),round(max(f['scale'] for f in frames),4))

# Campaign VFX regions exclude adjacent effects and beam end caps; body interiors can tile.
beam_image=Image.open(ROOT/'assets/campaign/beam-v3.png'); bw,bh=beam_image.size
beam=[]
for row in range(4):
 for col in range(4):
  cw=bw/4; ch=bh/4
  if row==1:
   beam.append([round((col+.5)*cw-65),325,130,220])
  else:
   margin=5 if row==3 else 12
   beam.append([round(col*cw)+margin,round(row*ch)+margin,round(cw)-2*margin,round(ch)-2*margin])
result['sets']['beam']={'file':'assets/campaign/beam-v3.png','regions':beam}
raid=Image.open(ROOT/'assets/campaign/airraid-v3.png'); rw,rh=raid.size
raid_regions=[]
for i in range(6):
 x=i%3*rw//3; y=i//3*rh//2
 a=np.asarray(raid.crop((x,y,x+rw//3,y+rh//2))).astype(float)
 valid=a[:,:,3]>110; yy,xx=np.where(valid)
 # Atlas crop is a drawing region; original alpha and pixels stay intact.
 left=max(0,int(xx.min())-3); top=max(0,int(yy.min())-3)
 right=min(rw//3,int(xx.max())+4); bottom=min(rh//2,int(yy.max())+4)
 raid_regions.append([x+left,y+top,right-left,bottom-top])
result['sets']['airraid']={'file':'assets/campaign/airraid-v3.png','regions':raid_regions}
(ROOT/'assets/motion/v3-regions.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Saved v3-regions.json; source images unchanged')
