import pickle,random,collections,statistics
exec(open('sim.py').read().split("starts=")[0])
ds,dt=pickle.load(open('tables.pkl','rb'))
NAME={0:'Bedroom',1:'Bathroom',2:'Study',3:'Kitchen',5:'Living',6:'Dining',7:'Foyer',8:'Laundry',-1:'EMPTY'}
def spawn_ok(s):
    b,pl=s
    if pl=='G': return False
    p=b.index(pl);g=b.index(-1)
    for d in D:
        if nb(p,d)==g and door(pl,d): return True
    return False
def walkdeg(s): return sum(1 for _,k in moves(s) if k=='walk')
rooms=[s for s in ds if s[1]!='G']
band=[s for s in rooms if 14<=ds[s]<=20]
ok=[s for s in band if spawn_ok(s)]
print("player-in-room states",len(rooms),"in 14-20:",len(band),"spawn-ok:",len(ok),"distinct boards:",len(set(b for b,_ in ok)))
print("per-slide count spawn-ok:",sorted(collections.Counter(ds[s] for s in ok).items()))
print("slide-dist median all rooms states",statistics.median(ds[s] for s in rooms))
# spawn_ok overall
print("spawn-ok fraction overall",sum(map(spawn_ok,rooms))/len(rooms))
# walled-in spawn: in ok, how many have zero walks (only slide)?
print("ok with zero walk exits",sum(1 for s in ok if walkdeg(s)==0))
# random walk generator acceptance
SOL=tuple([0,1,2,3,-1,5,6,7,8])
def rw(steps,rng):
    s=(SOL,7)
    for _ in range(steps):
        s=rng.choice(moves(s))[0]
    return s
rng=random.Random(1)
for steps in (50,100,200,400,1000):
    xs=[rw(steps,rng) for _ in range(3000)]
    acc=sum(1 for s in xs if s[1]!='G' and 14<=ds[s]<=20 and spawn_ok(s))
    print(f"randwalk {steps} steps: median opt slides {statistics.median(ds[s] for s in xs)}, accept {acc/len(xs):.1%}")
# slide-only random walk (non-backtracking) of k slides
def slidewalk(k,rng):
    s=(SOL,7);last=None;n=0;guard=0
    while n<k and guard<10000:
        guard+=1
        ms=moves(s)
        sl=[t for t,kk in ms if kk=='slide' and t[0]!=last]
        if sl and rng.random()<0.6:
            last=s[0]; s=rng.choice(sl); n+=1
        else:
            s=rng.choice([t for t,kk in ms])[0] if False else rng.choice(ms)[0]
    return s
def misplaced(b): return sum(1 for i,r in enumerate(b) if r!=-1 and r!=i)
# curate: optimal 16-18, spawn ok, foyer not home, >=6 misplaced, player has >=1 walk exit, gap not center, optimal path walks
cands=[s for s in ok if 16<=ds[s]<=18 and s[0][7]!=7 and misplaced(s[0])>=6 and walkdeg(s)>=1 and s[0].index(-1)!=4]
print("curated candidates",len(cands))
random.Random(42).shuffle(cands)
def grid(b): return " / ".join(" ".join(f"{NAME[b[r*3+c]]:>8}" for c in range(3)) for r in range(3))
for s in cands[:6]+[min(ok,key=lambda s:(-ds[s]))]:
    b,pl=s
    print(ds[s],"slides |",dt[s],"total moves | misplaced",misplaced(b),"| player in",NAME[pl],"| walks avail",walkdeg(s))
    print("   ",grid(b), "  board-tuple",b)
