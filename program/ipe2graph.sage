


from sys import argv
import xml.etree.ElementTree as ET

def read_ipe_file(path):

	tree = ET.parse(path)
	root = tree.getroot()
	page = root.find('page')

	P = []
	for u in page.iterfind('use'):
		attr = u.attrib
		if attr['name']=='mark/disk(sx)':
			x,y = [float(t) for t in attr['pos'].split(" ")]

			if 'matrix' in attr:
				M = [int(t) for t in attr['matrix'].split(" ")]
				x0 = x
				y0 = y
				x = M[0]*x0+M[2]*y0+M[4]
				y = M[1]*x0+M[3]*y0+M[5]

			p = (x,y)
			#assert(p not in P) # valid embedding
			P.append(p)

	E = []
	for u in page.iterfind('path'):
		attr = u.attrib
		if 'matrix' in attr:
			M = [int(t) for t in attr['matrix'].split(" ")]

		lines = u.text.split("\n")
		pts = []
		for l in lines:
			if l == '': continue
			x,y = [float(z) for z in l.split()[:2]]
			if 'matrix' in attr:
				x0 = x
				y0 = y
				x = M[0]*x0+M[2]*y0+M[4]
				y = M[1]*x0+M[3]*y0+M[5]
			p = (x,y)
			if p not in P: 
				continue
			i = P.index(p)
			pts.append(i)
		pts.sort()
		e = tuple(pts)
		print e
		#assert(len(pts) == 2) # no hypergraph
		if e not in E:
			E.append(e)

	pos = {i:P[i] for i in range(len(P))}
	return Graph(E,pos=pos)

