
from itertools import combinations
from sys import argv

def graph2ipe(G,path):

	ipestyle = 'ipestyle.txt'

	pos = G.get_pos()
	P = pos.values()
	print "P",P
	E = G.edges(labels=False)
	F = G.faces()

	ipe_file = path+'.ipe'
	print "write ipefile to:",ipe_file
	with open(ipe_file,'w') as g:
		g.write("""<?xml version="1.0"?>
			<!DOCTYPE ipe SYSTEM "ipe.dtd">
			<ipe version="70005" creator="Ipe 7.1.4">
			<info created="D:20150825115823" modified="D:20150825115852"/>
			""")
		with open(ipestyle) as f:
			for l in f.readlines():
				g.write("\t\t"+l)
		g.write("""<page>
			<layer name="alpha"/>
			<layer name="beta"/>
			<view layers="alpha beta" active="alpha"/>\n""")

	
		# normalize
		x0 = min(x for (x,y) in P)
		y0 = min(y for (x,y) in P)
		P = [(x-x0,y-y0) for (x,y) in P]
		x1 = max(x for (x,y) in P)
		y1 = max(y for (x,y) in P)

		#scale 
		c = 100
		M = 592-2*c
		P = [(c+float(x*M)/x1,c+float(y*M)/y1) for (x,y) in P]
	
		add = -G.vertices()[0]
		print add
		# write edges	
		for (i,j) in E:
			(xi,yi) = P[i+add]
			(xj,yj) = P[j+add]
			g.write('<path layer="beta" stroke="black">\n')
			g.write(str(xi)+' '+str(yi)+' m\n')
			g.write(str(xj)+' '+str(yj)+' l\n')
			g.write('</path>\n')
	
		# write points
		for (x,y) in P:
			g.write('<use layer="alpha" name="mark/disk(sx)" pos="'+str(x)+' '+str(y)+'" size="large" stroke="black"/>\n')
	
		g.write("""</page>\n</ipe>""")
	
	
