"""Measure the logo's transparent margins, preserving generated source pixels."""
from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]/'assets/title'
logo=Image.open(root/'logo.png').convert('RGBA')
box=logo.getchannel('A').point(lambda a:255 if a>=24 else 0).getbbox()
if not box:raise ValueError('empty logo')
x0,y0,x1,y1=box
metadata={'logo':[x0,y0,x1-x0,y1-y0],'keyart_size':list(Image.open(root/'keyart.png').size)}
(root/'regions.json').write_bytes((json.dumps(metadata,indent=2)+'\n').encode('utf-8'))
print(metadata)
