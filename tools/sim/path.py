exec(open('sim.py').read().split("starts=")[0])
from collections import deque
NAME={0:'Bedroom',1:'Bathroom',2:'Study',3:'Kitchen',5:'Living',6:'Dining',7:'Foyer',8:'Laundry','G':'EMPTY'}
for seed in [((6,2,5,0,1,3,7,-1,8),7),((0,7,1,3,5,2,-1,8,6),8),((6,3,2,0,8,1,-1,7,5),7)]:
    dist={seed:0};par={};dq=deque([seed]);goal=None
    while dq:
        s=dq.popleft()
        if s[0]==SOLVED: goal=s;break
        for t,k in moves(s):
            w=k=='slide';nd=dist[s]+w
            if nd<dist.get(t,1e9):
                dist[t]=nd;par[t]=(s,k);(dq.append if w else dq.appendleft)(t)
    steps=[];s=goal
    while s!=seed:
        p,k=par[s];steps.append((k,s));s=p
    steps.reverse()
    sl=[f"{NAME[t[1]]}->{t[0].index(t[1])}" for k,t in steps if k=='slide']
    print(seed,len(sl),"slides:"," ".join(sl))
