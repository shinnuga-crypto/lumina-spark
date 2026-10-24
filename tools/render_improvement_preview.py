"""Build a review sheet from native game captures, without touching asset art."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
out=Path(__file__).resolve().parents[1]/'test-output'
sheet=Image.new('RGB',(1280,792),'#152237');draw=ImageDraw.Draw(sheet)
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',21)
for i,(name,title) in enumerate([
 ('door-open','扉・スイッチ：GPTImage素材へ更新'),
 ('miniboss','中盤のミニボス「搬送路の番人」'),
 ('ceiling','低重力：天井電流・空中慣性・↓急降下'),
 ('clear','スコア・コンボ・クリアランク')]):
 x=i%2*640;y=i//2*396
 im=Image.open(out/(name+'.png')).convert('RGB').resize((640,360),Image.Resampling.LANCZOS)
 sheet.paste(im,(x,y+36));draw.text((x+12,y+5),title,font=font,fill='white')
sheet.save(out/'improvements-preview.png')
