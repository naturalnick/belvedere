import itertools, collections, random, json, sys
N,E,S,W=0,1,2,3
D={N:(-1,0),E:(0,1),S:(1,0),W:(0,-1)}
OPP={N:S,S:N,E:W,W:E}
def rc(p): return divmod(p,3)
def nb(p,d):
    r,c=rc(p); dr,dc=D[d]; r+=dr;c+=dc
    return r*3+c if 0<=r<3 and 0<=c<3 else None
# room id = home position (0..8 except 4)
def door(room,d):  # True if doorway on side d (room's own frame, no rotation)
    r,c=rc(room)
    if d==N: return r!=0
    if d==S: return r!=2
    if d==W: return c!=0
    if d==E: return c!=2
SOLVED=tuple([0,1,2,3,-1,5,6,7,8])
# state: (board tuple, player) where player = room id or 'G'
def moves(st):
    b,pl=st
    gap=b.index(-1)
    out=[]
    if pl=='G':
        for d in D:
            q=nb(gap,d)
            if q is not None and door(b[q],OPP[d]): out.append(((b,b[q]),'walk'))
        return out
    p=b.index(pl)
    for d in D:
        q=nb(p,d)
        if q is None: continue
        if b[q]==-1:
            if door(pl,d): out.append(((b,'G'),'walk'))
            nbb=list(b); nbb[q]=pl; nbb[p]=-1
            out.append(((tuple(nbb),pl),'slide'))
        elif door(pl,d) and door(b[q],OPP[d]):
            out.append(((b,b[q]),'walk'))
    return out
starts=[(SOLVED,r) for r in SOLVED if r!=-1]+[(SOLVED,'G')]
# 0-1 BFS: slides cost 1, walks 0
from collections import deque
INF=10**9
ds={}; dq=deque()
for s in starts: ds[s]=0; dq.append(s)
while dq:
    s=dq.popleft(); d0=ds[s]
    for t,k in moves(s):
        w=1 if k=='slide' else 0
        nd=d0+w
        if nd<ds.get(t,INF):
            ds[t]=nd
            (dq.append if w else dq.appendleft)(t)
# total-moves BFS
dt={s:0 for s in starts}; dq=deque(starts)
while dq:
    s=dq.popleft()
    for t,k in moves(s):
        if t not in dt: dt[t]=dt[s]+1; dq.append(t)
assert set(dt)==set(ds)
boards=set(b for b,_ in ds)
print("reachable full states",len(ds))
print("reachable boards",len(boards),"of",9*8*7*6*5*4*3*2*1//2)
# symmetry check
und=all(any(u==s for u,_ in moves(t)) for s in list(ds)[:200000] for t,_ in moves(s))
print("every move reversible:",und)
# board-level slide dist (min over player positions)
bd={}
for (b,pl),d in ds.items(): bd[b]=min(bd.get(b,INF),d)
print("board slide-dist dist:",sorted(collections.Counter(bd.values()).items()))
print("max slide dist",max(ds.values()),"max total",max(dt.values()))
print("full state slide-dist dist (player in room):",sorted(collections.Counter(d for (b,pl),d in ds.items() if pl!='G').items()))
print("total-move dist:",sorted(collections.Counter(dt.values()).items()))
# gap positions
print("gap pos counts among reachable boards",collections.Counter(b.index(-1) for b in boards))
# per board, number of player components (walk-connected)
# edge cases: player room with 0 walk moves
walled=sum(1 for s in ds if s[1]!='G' and all(k=='slide' for _,k in moves(s)))
print("states where player has no walk moves (slide only):",walled,"of",len(ds))
nomove=sum(1 for s in ds if not moves(s)); print("dead states",nomove)
# number of player positions per board reachable
pc=collections.Counter()
for (b,pl) in ds: pc[b]+=1
print("player-position count per board distribution",sorted(collections.Counter(pc.values()).items()))
# compare: normal 8-puzzle distribution
dd={SOLVED:0};dq=deque([SOLVED])
while dq:
    b=dq.popleft();g=b.index(-1)
    for d in D:
        q=nb(g,d)
        if q is None: continue
        l=list(b);l[g],l[q]=l[q],l[g];t=tuple(l)
        if t not in dd: dd[t]=dd[b]+1;dq.append(t)
print("normal 8puzzle boards",len(dd),"max",max(dd.values()))
print("normal dist",sorted(collections.Counter(dd.values()).items()))
import pickle; pickle.dump((ds,dt),open('/workspace/manor/tables.pkl','wb'))
