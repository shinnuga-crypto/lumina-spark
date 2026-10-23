import math, wave, struct, pathlib
root = pathlib.Path(__file__).resolve().parents[1] / 'assets'
rate=22050
def save(name, samples):
    with wave.open(str(root / (name+'.wav')), 'wb') as f:
        f.setparams((1,2,rate,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,v))*24000)) for v in samples))
for name, f0, f1, dur in [('shot',1100,330,.09),('hit',150,45,.22),('jump',280,780,.13),('dash',850,90,.15),('heal',440,1320,.35),('charge',180,1100,.3),('win',440,880,1.3)]:
    a=[]
    phase=0
    for i in range(int(dur*rate)):
        t=i/rate; phase+=2*math.pi*(f0+(f1-f0)*t/dur)/rate
        a.append((math.sin(phase)+.18*math.sin(phase*2))*(1-t/dur)*.6)
    save(name,a)
# Original 16-bar looping synth track, 120 BPM, A minor / F / C / G.
notes=[69,72,76,79,76,72,71,72,65,69,72,76,72,69,67,69,67,72,76,79,76,74,72,71,67,71,74,77,74,71,69,67]
bass=[45,41,48,43]
def hz(n): return 440*2**((n-69)/12)
samples=[]
for i in range(rate*32):
    t=i/rate
    step=int(t/.25); beat=int(t/.5)
    local=t% .25
    lead=math.sin(2*math.pi*hz(notes[step%32])*t)*math.exp(-local*10)*.18
    low=math.sin(2*math.pi*hz(bass[(beat//8)%4])*t)*.18
    kickt=t%.5
    kick=math.sin(2*math.pi*(65*kickt+2*(1-math.exp(-kickt*30))))*math.exp(-kickt*20)*.25
    hat=(math.sin(t*17321)+math.sin(t*23003))*.025*math.exp(-local*50)
    samples.append((lead+low+kick+hat)*min(1,t*5,(32-t)*20))
save('music',samples)
print('8 WAV assets generated')
