"""Measure anatomical scale, not effect/pose bounds. Keep source pixels intact."""
from pathlib import Path
from PIL import Image
import json, numpy as np, statistics, shutil

root=Path(__file__).resolve().parents[1]
base=root/'assets/motion'
def head_metric(im):
 a=np.array(im.convert('RGBA')).astype(float)
 r,g,b,alpha=[a[:,:,i] for i in range(4)]
 y,x=np.where((alpha>180)&(r>g*1.4)&(b>g*1.12)&(r>120))
 x0,x1=np.percentile(x,[3,97]);y0,y1=np.percentile(y,[3,97])
 return float(((x1-x0)*(y1-y0))**.5),float(np.median(x)),[float(x0),float(y0),float(x1),float(y1)]

meta=json.loads((base/'animation.json').read_text())
regions=json.loads((root/'assets/regions.json').read_text())
legacy={}
for name,source,index in [('idle','atlas',0),('jump','atlas',3),('dash','poses',0),('hurt','poses',1),('charge','poses',2),('victory','poses',3)]:
 r=regions[source][index]
 im=Image.open(root/'assets'/('atlas.png' if source=='atlas' else 'poses-v2.png')).convert('RGBA').crop((r[0],r[1],r[0]+r[2],r[1]+r[3]))
 metric,hx,head=head_metric(im)
 a=np.array(im);y,x=np.where(a[:,:,3]>220)
 floor=float(np.percentile(y,99.7))
 legacy[name]={'head_metric':metric,'anchor':[hx+7,floor],'head_bounds':head}
reference=legacy['idle']['head_metric']*104/regions['atlas'][0][3]
for pose in legacy.values():pose['scale']=reference/pose['head_metric']
meta['legacy_pose']=legacy
for name in ['walk','saber']:
 metrics=[head_metric(Image.open(base/f['file']))[0] for f in meta[name]['frames']]
 meta[name]['scale']=reference/statistics.median(metrics)
 meta[name]['head_metric']=statistics.median(metrics)

rig=base/'rig';rig.mkdir(exist_ok=True)
source=Image.open(base/'rig-raw.png').convert('RGBA')
pieces={
 'body':([40,0,710,545],[300,490],[680,315]),
 'near_thigh':([770,100,950,480],[855,155],[854,412]),
 'near_boot':([1180,100,1490,520],[1240,160],[1260,409]),
 'far_thigh':([210,550,420,970],[313,605],[325,889]),
 'far_boot':([760,550,1080,990],[830,622],[835,871])}
parts={}
for name,(box,start,end) in pieces.items():
 im=source.crop(box);im.save(rig/(name+'.png'))
 parts[name]={'file':'rig/'+name+'.png','origin':[start[0]-box[0],start[1]-box[1]],'end':[end[0]-box[0],end[1]-box[1]]}
 if name=='body':
  metric,_,bounds=head_metric(im)
  parts[name]['scale']=reference/metric
  parts[name]['head_metric']=metric
  parts[name]['head_bounds']=bounds
 if name.endswith('boot'):
  parts[name]['foot_cut']=250 if name=='near_boot' else 270
  pixels=np.array(im);ys,xs=np.where(pixels[:,:,3]>220)
  valid=ys>=parts[name]['foot_cut'];ys=ys[valid];xs=xs[valid]
  coords=np.stack([xs,ys],axis=1)
  outline=[]
  for angle in np.linspace(0,2*np.pi,48,endpoint=False):
   point=coords[np.argmax(coords@np.array([np.cos(angle),np.sin(angle)]))]
   if point.tolist() not in outline:outline.append(point.tolist())
  parts[name]['outline']=outline
meta['rig']=parts
if (base/'upper-raw.png').exists():
 upper=Image.open(base/'upper-raw.png').convert('RGBA')
 components={
  'body':([120,0,710,793],[450,738],[0,0]),
  'gun_arm':([960,70,1230,793],[1095,170],[1100,745]),
  'free_arm':([1550,140,1810,745],[1680,255],[1660,670])}
 for name,(box,start,end) in components.items():
  im=upper.crop(box);filename='torso-v2.png' if name=='body' else name+'.png';im.save(rig/filename)
  part={'file':'rig/'+filename,'origin':[start[0]-box[0],start[1]-box[1]],'end':[end[0]-box[0],end[1]-box[1]]}
  if name=='body':
   metric,_,bounds=head_metric(im)
   part.update(scale=reference/metric,head_metric=metric,head_bounds=bounds,
    gun_shoulder=[560-box[0],461-box[1]],free_shoulder=[340-box[0],465-box[1]])
  else:
   distance=((end[0]-start[0])**2+(end[1]-start[1])**2)**.5
   part['scale']=(45 if name=='gun_arm' else 28)/distance
   part['aim_angle']=-np.pi/2
  meta['rig'][name]=part
if (base/'air_saber/01.png').exists():
 frames=[];metrics=[]
 for i in range(6):
  im=Image.open(base/f'air_saber/{i+1:02}.png')
  metric,hx,bounds=head_metric(im);metrics.append(metric)
  frames.append({'file':f'air_saber/{i+1:02}.png','head_x':hx,'head_bounds':bounds})
 scale=reference/statistics.median(metrics)
 for frame in frames:
  x0,y0,x1,y1=frame.pop('head_bounds');hx=frame.pop('head_x')
  # Airborne hip stays 51px above the physical foot origin, boots tucked above it.
  hip_y=y1+(y1-y0)*.8
  frame['anchor']=[hx+4,hip_y+51/scale]
  frame['muzzle']=[244,(y0+y1)/2+18]
 meta['air_saber']={'scale':scale,'head_metric':statistics.median(metrics),'frames':frames}
meta['reference_head_metric']=reference
(base/'animation.json').write_bytes((json.dumps(meta,indent=2)+'\n').encode())
print('Reference skull:',reference)
print('Legacy scales:',{k:round(v['scale'],3) for k,v in legacy.items()})
print('Rig body scale:',parts['body']['scale'])
