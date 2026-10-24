"""Measure anchors and cannon sockets on normalized frames; never redraw source art."""
from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,statistics
root=Path(__file__).resolve().parents[1]
result={}
for name,count in [('walk',8),('saber',6)]:
 frames=[];heights=[]
 for i in range(count):
  p=root/'assets/motion'/name/f'{i+1:02}.png'
  a=np.array(Image.open(p).convert('RGBA')).astype(float)
  y,x=np.indices(a.shape[:2]);r,g,b,alpha=[a[:,:,j] for j in range(4)]
  pink=(alpha>180)&(r>g*1.3)&(r>b*.95)&(r>120)&(y<180)
  ys,xs=np.where(pink)
  head=float(np.percentile(ys,5));headx=float(np.median(xs))
  valid=(alpha>150)&(y>190)
  fy,fx=np.where(valid)
  floor=float(np.percentile(fy,99))
  footmask=valid&(y>=floor-12)
  fxs=np.where(footmask)[1]
  anchorx=headx-5 if name=='walk' else float((fxs.min()+fxs.max())/2)
  cyan=(alpha>180)&(g>110)&(b>100)&(r<g*.9)&(x>145)&(y>head+20)&(y<head+100)
  columns=np.where(cyan.sum(axis=0)>=3)[0]
  mx=float(columns.max()-1) if len(columns) else 230
  my=float(np.median(np.where(cyan&(x>=mx-5))[0])) if len(columns) else 90
  frames.append({'file':f'{name}/{i+1:02}.png','anchor':[round(anchorx,2),round(floor,2)],'muzzle':[round(mx,2),round(my,2)]})
  heights.append(floor-head)
 result[name]={'scale':round(104/statistics.median(heights),6),'frames':frames}
result['legacy']={'idle':[380,150],'jump':[1720,144],'dash':[598,252],'hurt':[1180,325],'charge':[523,845]}
(root/'assets/motion/animation.json').write_bytes((json.dumps(result,indent=2)+'\n').encode())
# Diagnostic sheet: consistent world scale/anchor. Crosses mark feet and muzzle.
canvas=Image.new('RGBA',(960,360),(23,35,52,255));d=ImageDraw.Draw(canvas)
for i,f in enumerate(result['walk']['frames']):
 im=Image.open(root/'assets/motion'/f['file']);scale=result['walk']['scale']
 im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
 x=(i%4)*240+85;y=(i//4)*180+150
 ax,ay=f['anchor'];mx,my=f['muzzle']
 canvas.alpha_composite(im,(round(x-ax*scale),round(y-ay*scale)))
 gx=x+(mx-ax)*scale;gy=y+(my-ay)*scale
 d.line((gx-5,gy,gx+5,gy),fill='yellow',width=1);d.line((gx,gy-5,gx,gy+5),fill='yellow',width=1)
 d.line((x-5,y,x+5,y),fill='cyan');d.text(((i%4)*240+15,(i//4)*180+15),str(i+1),fill='white')
canvas.save(root/'test-output/walk-sockets.png')
print(json.dumps({n:{'scale':result[n]['scale'],'frames':len(result[n]['frames'])} for n in ['walk','saber']}))
if (root/'assets/motion/rig-raw.png').exists():
 import runpy
 runpy.run_path(str(root/'tools/calibrate_hero.py'),run_name='__main__')
