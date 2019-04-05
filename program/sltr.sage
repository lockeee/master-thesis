import sage.all
	
def get_sltr(graph,suspensions=None,outer_face=None):
	## Returns a list of the faces and assigned vertices with the outer face first ##
	if suspensions != None:
		G = copy(graph)
		## We are looking for the outer face ##
		for face in G.faces():
			if is_outer_face(face, suspensions):
				## face is the outer_face ##
				[Flow, has_sltr] = calculate_2flow(G,face,suspensions)
				if has_sltr:
					return get_good_faa(G,Flow[1],face,suspensions)
				else:
					if Flow != None:
						print 'Only non integer Flow found for: G = Graph(' + str(G.edges()) + ')'
					break
	else:					
		## We will check all posible triplets as suspensions ##
		H = copy(graph)
		if outer_face != None: 
			face = outer_face
			nodes = []
			for i in face:
				nodes.append(i[0])
			n = tuple(nodes)
			## Find all possible suspensions for this face ##
			for j in Combinations(len(n),3):
				suspensions = ( n[j[0]] , n[j[1]] , n[j[2]] )
				[Flow, has_sltr] = calculate_2flow(H,face,suspensions)
				if has_sltr:
					return get_good_faa(H,Flow[1],face,suspensions)
				else:
					if Flow != None:
						print 'Only non integer Flow found for: G = Graph(' + str(H.edges()) + ')'
		else:
			## Just take arbitrary face
			face = H.faces()[0]
			nodes = []
			for i in face:
				nodes.append(i[0])
			n = tuple(nodes)					
			## Find all possible suspensions for this face ##
			for j in Combinations(len(n),3):
				suspensions = ( n[j[0]] , n[j[1]] , n[j[2]] )
				[Flow, has_sltr] = calculate_2flow(H,face,suspensions)
				if has_sltr:
					return get_good_faa(H,Flow[1],face,suspensions)
				else:
					if Flow != None:
						print 'Only non integer Flow found for: G = Graph(' + str(H.edges()) + ')'
	return None
	
def get_good_faa(G, Flow2,outer_face=None,suspensions=None):
	gFAA = []
	if len(Flow2.vertices()) == 0:
		if outer_face == None :
			## Triangulation ##
			for i in G.faces():
				gFAA.append([face2ints([name_face_vertex(i)[2:]])])
			return gFAA
		else:
			## Only assigned vertices to outer face ##
			name = face2ints([name_face_vertex(outer_face)[2:]])
			add = []
			for i in outer_face:
				if i[0] not in suspensions:
					add.append(i[0])
			gFAA = [[name,add]]
			for i in interior_faces(G,oF = outer_face):
				gFAA.append([face2ints([name_face_vertex(i)[2:]])])
			return gFAA
	else:
		## interior vertices to assign ##
		gFAA = []
		firstN = copy(Flow2.neighbors_in('o2'))
		for i in range(len(firstN)):
			name = Flow2.neighbors_in(firstN[i])[0][:-3]
			#name = name[:-3]
			names = name.split(',')
			names = [names[0][2:],names[1][2:]]
			name0 = face2ints(names)
			x = True
			for j in range(len(gFAA)):
				if  name0 == gFAA[j][0]:
					x = False
					gFAA[j][1].append(int(names[1]))
					break
			if x:
				add = [name0]
				add.append([int(names[1])])
				gFAA.append(add)
		## Append vertices assigned to outer Face ##
		name = name_face_vertex(outer_face)[2:]
		name = [face2ints([name])]
		add = []
		for i in outer_face:
			if i[0] not in suspensions:
				add.append(i[0])
		name.append(add)
		gFAA.insert(0,name)	
		## Append triangles ##
		for i in interior_faces(G,oF = outer_face):
			if len(i) == 3:
				gFAA.append([face2ints([name_face_vertex(i)[2:]])])
		return gFAA
		  
def is_internally3connected(G,suspensions):
	H = copy(G)
	v = H.add_vertex()
	H.add_edges([[v,suspensions[0]],[v,suspensions[1]],[v,suspensions[2]]])
	for v in H.vertices():
		K = copy(H)
		K.delete_vertex(v)
		if K.is_biconnected() == False:
			return False
	return True
		
def calculate_2flow(G,outer_face,suspensions):
	H = graph2flow(G, outer_face, suspensions)
	flow1 = give_flow1(G,outer_face)
	flow2 = give_flow2(G,outer_face)
	try:
		return [H.multicommodity_flow([['i1','o1',flow1],['Di2','o2',flow2]],
									use_edge_labels=True) , True]
	except EmptySetError:
		pass
	try:
		return [H.multicommodity_flow([['i1','o1',flow1],['Di2','o2',flow2]],
									use_edge_labels=True,integer = False) , False]
	except EmptySetError:
		pass
	return [None,False]
	
def graph2flow(G,outer_face,suspensions):
	## G is a planar, suspended, internally 3-connected graph ##
	interior_Faces = interior_faces(G,oF = outer_face)
	H = DiGraph([['i1','o2','o1'],[('Di2' , 'i2' , give_flow2(G,outer_face))]])
	add_vertices2sink_edges(H,G,suspensions)
	for face in interior_Faces:
		face2flow(H,face)	
	for sV in outer_face:
		H.set_edge_label('D' + name_vertex_vertex(sV[0]) , 'o2' , 0 )
	for oE in outer_face :
		H.delete_edge('i1',name_edge_vertex(oE))
	return H
	
def give_flow1(G,outer_face):
	return len(G.edges())-len(outer_face) + 3*(len(G.faces())-1)
	
def give_flow2(G,outer_face):
	flow2 = 0
	innerFaces = interior_faces(G,oF = outer_face)
	for i in range(len(innerFaces)):
		flow2 = flow2 + ( len(innerFaces[i]) - 3 )
	return flow2
	
def interior_faces(G,oF = None, sus = None):
	faces = copy(G.faces())
	if oF != None:
		face = find_face(G,oF)
		faces.remove(face)
		return faces
	if sus != None:
		for face in faces:
			count = 0
			for edge in face:
				for i in sus:
					if i == edge[0]:
						count = count+1
				if count == 3:
					faces.remove(face)
					return faces

def find_face(graph,this_face):
	length = len(this_face)
	for face in graph.faces():
		if len(face) == length:
			for i in range(length):
				cw_count = 0
				ccw_count = 0
				for j in range(length):
					if this_face[(j+i)%length][0] == face[j][0]:
						cw_count += 1
					if this_face[(-j+i)%length][1] == face[j][0]:
						ccw_count += 1
				if ccw_count == length or cw_count == length:
					return face




def face2flow(H,face):
	## H is the new FlowGraph ##
	name = name_face_vertex(face)
	H.add_vertex(name)
	H.add_edges([('i1','B' + name,3),(name,'o1' , len(face) )])
	add_outer_ring(H,face,name)

def add_outer_ring(H,edges,nameFace):
	for i in range(len(edges)):
		toAdd1 = name_edge_vertex(edges[i])
		toAdd2 = name_edge_vertex(edges[i],edges)
		H.add_edges([(toAdd1,toAdd2,1),
			(toAdd2,nameFace,1),
			('i1',toAdd1,1)])
		forVName = name_vertex_vertex(edges[i][1])
		backVName = name_vertex_vertex(edges[i][0])
		H.add_edges([(toAdd1,forVName,1),(toAdd1,backVName,1)])
		add_triangle(H, edges, toAdd2, backVName, forVName)
		
def add_triangle(H,face,dummyEdge,node,nextNode):
	name = name_face_vertex(face) + ',' + node + ','
	## Nodes for Source1 ##
	H.add_edges([('B' + name_face_vertex(face),name + 'T1' ,1),
		( name + 'T1' , name + 'T2' , 1),
		( name + 'T2' , name + 'T3' , 1),
		( name + 'T3' , name + 'T4' , 1),
		( name + 'T4' , dummyEdge , 1),
		( name + 'T4' , name_face_vertex(face) + ',' + nextNode + ',T3', 1)])	
	## Nodes for Source2 ##
	dummyName = 'D' + node 
	H.add_edges([('i2',name + 'T1' , 1),
		( name + 'T2' , dummyName , 1),
		( dummyName , 'o2' , 1 )])
		
def add_vertices2sink_edges(H,G,suspensions):
	vertices = G.vertices()
	for i in range(len(vertices)):
		if vertices[i] in suspensions:
			H.add_edge(name_vertex_vertex(vertices[i]), 'o1' , G.degree(vertices[i]) - 2 )
		else:	
			H.add_edge(name_vertex_vertex(vertices[i]), 'o1' , G.degree(vertices[i]) - 3 )
	
def face2ints(face):
	nodes = face[0].split()
	face_name = []
	for j in nodes:
		face_name.append(int(j))
	return face_name

def get_suspensions(faa):
	outer_face = faa[0][0]
	outer_nodes = faa[0][1]
	return copy(outer_face).remove(outer_nodes)	

def is_outer_face(face,sus):
	count = 0
	for edge in face:
		for i in sus:
			if i == edge[0]:
				count = count+1
	if count == 3:
		return True
	return False

	
## Coherent naming in the flow graph seems to be Important##
def name_face_vertex(face):
	name = ''                  
	for i in range(len(face)):
		name = name+str(face[i][0])+' '
	name = name[:-1]
	return 'F:'+name 
	
def name_edge_vertex(edge, face = None):
	edge1 = copy(edge) 
	if edge1[0] < edge1[1]:                     
		name = str(edge1[0]) + ' ' + str(edge1[1])
	else:
		name = str(edge1[1]) + ' ' + str(edge1[0])
	if face != None :
		return 'DE:' + name_face_vertex(face) + ' E:' + name
	else :
		return 'E:' + name
		
def name_vertex_vertex(vertex):
	if type(vertex) == str:
		return vertex
	else:	
		return 'V:' + str(vertex)
		
##Plotting##	
def plot_sltr(graph=None,vertices=None,index=None,suspensions=None,show_originial = None):
	if graph != None:
		H = copy(graph)
		if show_originial:
			plot_planar_graph(H)
		faa = get_sltr(H,suspensions)
		if faa != None:
			layout = get_good_faa_layout(H,faa)
			F = H.plot(pos=layout)
			show(F)
		else:
			#plot_aproximation_to_sltr(H)
			print 'approx'
		return None
	if graph == None:
		i = 0
		for G in graphs.planar_graphs(vertices, minimum_connectivity=3):
			i += 1
			if i == index:
				if show_originial:
					plot_planar_graph(G)
				faa = get_sltr(G,suspensions)
				if faa != None:
					layout = get_good_faa_layout(G,faa)
					F = G.plot(pos=layout)
					show(F)
				else:
					plot_aproximation_to_sltr(G)
				return None

def plot_planar_graph(graph):
	P = graph.layout(layout='planar',set_embedding = True)
	show(graph.plot(pos=P))	

def plot_aproximation_to_sltr(graph,sus=None):
	ultimate = 2
	for limit in range(1,ultimate):
		Plot = plot_problem_graph(graph,limit,sus)
		if Plot != None:
			P.show(axes = False)
			return 
	print('No close drawing found with at most ' + str(ultimate) + ' triangulated faces.')
	return None

def plot_problem_graph(graph,limit,sus=None):
	colors = ['lightskyblue','lightgoldenrodyellow','lightsalmon', 'lightcoral','lightgreen']
	faces = copy(graph.faces())
	faces.sort(key = len)
	if sus != None:
		for oF in faces:
			if is_outer_face(oF, sus):
				[face_list,layout] = plot_problem_graph_iteration(graph,limit,0,sus,oF,[])
				if layout != None:
					G = copy(graph)
					## plot ##
					for i in range(len(face_list)):
						[face,v] = face_list[i]
						for e in face:
							G.set_edge_label(e[0],e[1],1)
						del layout[v]
					P = G.plot(pos=layout,color_by_label={None: 'black' , 1: 'red'})
					for i in range(len(face_list)):
						[face,v] = face_list[i]
						P = P + polygon([layout[x[0]] for x in face], color=colors[i])
					return P
				else:
					print 'No Approximation with those suspensions found...'
					return None
	else:
		## No suspensions given ##
		for oF in faces:
			nodes = []
			for edge in oF:
				nodes.append(edge[0])
			n = tuple(nodes)
			## Find all possible suspensions for this face ##
			suspensions = (0,0,0)
			for j in Combinations(len(n),3):
				suspensions = ( n[j[0]] , n[j[1]] , n[j[2]] )
				[face_list,layout] = plot_problem_graph_iteration(graph,limit,0,suspensions,oF,[])
				if layout != None:
					G = copy(graph)
					## plot ##
					for i in range(len(face_list)):
						[face,v] = face_list[i]
						for e in face:
							G.set_edge_label(e[0],e[1],1)
						del layout[v]
					P = G.plot(pos=layout,color_by_label={None: 'black' , 1: 'red'})
					for i in range(len(face_list)):
						[face,v] = face_list[i]
						P = P + polygon([layout[x[0]] for x in face], color=colors[i])
					return P
	return None


def plot_problem_graph_iteration(graph,limit,iteration,sus,outer_face,face_list):
	if iteration == limit:
		return [None,None]
	else:
		F = interior_faces(graph,outer_face)
		F.sort(key = len)
		for face in F:
			n = len(face)
			if n > 3:
				[G,v] = insert_point_to_face(graph,face)
				faa = get_sltr(G,suspensions = sus , outer_face = outer_face)
				if faa != None:
					layout = get_good_faa_layout(G,faa)
					face_list.append([face,v])
					return [face_list,layout]
				else:
					face_list_new = copy(face_list)
					face_list_new.append([face,v])
					return plot_problem_graph_iteration(G,limit,iteration+1,sus,outer_face,face_list_new)

def insert_point_to_face(graph,face,edge_amount=None):
	points = []
	n = len(face)
	for i in range(n):
		points.append(face[i][0])
	if edge_amount != None:
		List = []
		for j in Combinations(n,edge_amount):
			G = copy(graph)
			v = G.add_vertex()
			for k in j:
				G.add_edge(v,points[k])
			List.append(G)
		return List
	else:
		G = copy(graph)
		v = G.add_vertex()
		for e in face:
			G.add_edge(v,e[0])
		return[G,v]


def get_good_faa_layout(graph,faa):
	if len(faa[0]) > 1:
		suspensions = []
		for node in faa[0][0]:
			if node not in faa[0][1]:
				suspensions.append(node)
	else:
		suspensions = copy(faa[0][0])
	faa_dict = dict()
	for face in faa:
		if len(face) > 1:
			l = len(face[0])
			for node in face[1]:
				if node not in suspensions:
					for j in range(l):
						if face[0][j] == node:
							n1 = face[0][(j-1)%l]
							n2 = face[0][(j+1)%l]
							faa_dict[node] = (n1,n2)
							break			
	G = copy(graph)
	pos = get_good_faa_layout_iteration(G,faa_dict,0,suspensions)
	return pos
	
def get_good_faa_layout_iteration(G,faa_dict,j,suspensions,weights=None):
	constant = 0.01
	V = G.vertices()
	n = len(V)
	if weights == None:
		j += 1
		sol = get_plotting_matrix_iteration(G,suspensions,faa_dict,weights)
		pos = {V[i]:sol[i] for i in range(n)}
		G.set_pos(pos)
		weights = calculate_weights(G,suspensions,j)
	j += 1
	sol2 = get_plotting_matrix_iteration(G,suspensions,faa_dict,weights)
	pos2 = {V[i]:sol2[i] for i in range(n)}
	G.set_pos(pos2)
	weights2 = calculate_weights(G,suspensions,j)
	M = weights-weights2
	if M.norm() < constant or j == 50:
		return pos2
	else:
		return get_good_faa_layout_iteration(G,faa_dict,j,suspensions,weights2)	
	
def calculate_weights(G,suspensions,j):
	V = G.vertices()
	n = len(V)
	W = zero_matrix(RR,n,n)
	pos = G.get_pos()
	
	##weights for edges ##
	for E in G.edges():
		q = get_edge_length(E,pos)
		## TODO: Find a better function q and p##
		q = q
		i0 = V.index(E[0])
		i1 = V.index(E[1])
		W[i0,i1] += q
		W[i1,i0] += q
		
	## weights for faces ##
	for F in G.faces():
	#for F in interior_faces(G,sus=suspensions):
		p = get_face_area(F,pos)
		## TODO: Find a better function q and p##
		p = p
		for E in F:
			i0 = V.index(E[0])
			i1 = V.index(E[1])
			W[i0,i1] += p
			W[i1,i0] += p
	return W
	
def get_face_area(F,pos):
	p = 0
	for edge in F:
		p += pos[edge[0]][0]*pos[edge[1]][1]  - pos[edge[1]][0]*pos[edge[0]][1]
	p = abs(p/2)
	return p
	
def get_edge_length(E,pos):
	p0 = pos[E[0]]
	p1 = pos[E[1]]
	l0 = (p0[0] - p1[0])^2
	l1 = (p0[1] - p1[1])^2
	q = sqrt(l0+l1)
	return q
	
def get_plotting_matrix_iteration(G,suspensions,faa_dict,weights=None):
	pos = dict()
	V = G.vertices()

	## set outer positions on triangle ##
	for i in range(3):
		ai = pi/2 + pi*2*i/3
		pos[suspensions[i]] = (100*cos(ai),100*sin(ai))

	n = len(V)
	M = zero_matrix(RR,n,n)
	b = zero_matrix(RR,n,2)

	for i in range(n):
		v = V[i]
		if v in pos:
			M[i,i] = 1
			b[i,0] = pos[v][0]
			b[i,1] = pos[v][1]
		else:
			if v in faa_dict:
				j1 = V.index(faa_dict[v][0])
				j2 = V.index(faa_dict[v][1])
				if weights != None :
					wn1 = weights[j1,i]
					wn2 = weights[j2,i]
				else:
					wn1 = wn2 = 1
				s = wn1 + wn2
				M[i,j1] = -wn1
				M[i,j2] = -wn2
				M[i,i] = s
			else:
				nv = G.neighbors(v)
				s = 0
				for u in nv:
					j = V.index(u)
					if weights != None :
						wu = weights[j,i]
					else:
						wu = 1
					s += wu
					M[i,j] = -wu
				M[i,i] = s
	return M.pseudoinverse()*b