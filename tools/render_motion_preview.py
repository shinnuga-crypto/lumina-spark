"""Contact sheet and slow review GIF from native Godot captures (not source art)."""
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
out=root/'test-output'
frames=[]
for i in range(32):
 im=Image.open(out/f'stride-{i}.png').convert('RGB').crop((380,470,620,630)).resize((480,320),Image.Resampling.NEAREST)
 frames.append(im)
frames[0].save(out/'walk-preview.gif',save_all=True,append_images=frames[1:],duration=30,loop=0)
items=['idle','walk','jump','dash','hurt','charge','saber']
sheet=Image.new('RGB',(len(items)*200,200),'#172233');draw=ImageDraw.Draw(sheet)
for i,name in enumerate(items):
 im=Image.open(out/f'size-{name}.png').crop((390,475,610,630)).resize((200,170))
 sheet.paste(im,(i*200,25));draw.text((i*200+5,5),name,fill='white')
sheet.save(out/'size-comparison.png')
sheet=Image.new('RGB',(8*180,200),'#172233');draw=ImageDraw.Draw(sheet)
for i in range(8):
 im=Image.open(out/f'motion-walk{i}.png').crop((400,485,600,625)).resize((180,170))
 sheet.paste(im,(i*180,25));draw.text((i*180+5,5),str(i+1),fill='white')
sheet.save(out/'walk-keyframes.png')
