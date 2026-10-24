from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]/'assets/motion'
for name,cols,rows,raw in [('walk',4,2,'walk-v2-raw.png'),('saber',3,2,'saber-raw.png'),('air-saber',3,2,'air-saber-raw.png')]:
 if not (root/raw).exists():continue
 im=Image.open(root/raw).convert('RGBA');w,h=im.size
 cw,ch=round(w/cols),round(h/rows)
 strip=Image.new('RGBA',(cw*cols*rows,ch))
 for i in range(cols*rows):
  cell=im.crop((round((i%cols)*w/cols),round((i//cols)*h/rows),round((i%cols+1)*w/cols),round((i//cols+1)*h/rows)))
  strip.alpha_composite(cell,(i*cw,0))
 strip.save(root/(name+'-strip.png'))
