import sage.all
attach("graph2ipe.sage")

def has_sltr(graph,suspensions=None,outer_face=None):
	return get_sltr(graph,suspensions,outer_face) != None

	
def get_sltr(graph,suspensions=None,outer_face=None,check_non_int_flow=False,check_just_non_int_flow = False):
	## Returns a list of the faces and assigned vertices with the outer face first ##
	if suspensions != None:
		if outer_face != None:
			return _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow)
		## We are looking for the outer face ##
		else:
			for outer_face in graph.faces():
				if _is_outer_face(outer_face, suspensions):
					## face is the outer_face ##
					return _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow)
	else:					
		## We will check all posible triplets as suspensions ##
		if outer_face != None: 
			## outer face is given
			for suspensions in _give_suspension_list(graph,outer_face):
				sltr = _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow)
				if sltr != None:
					return sltr
		else:
			## Checking all outer faces:
			for outer_face in graph.faces():
				for suspensions in _give_suspension_list(graph,outer_face):
					sltr = _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow)
					if sltr != None:
						return sltr
def _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow):
	[Flow, has_sltr] = _calculate_2_flow(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow)
	if has_sltr:
		return _get_good_faa(graph,Flow[1],outer_face,suspensions)
	else:
		if Flow != None:
			print 'Only non integer Flow found for: G = Graph(' + graph.sparse6_String() + ')'
	return

	
def _get_good_faa(G, Flow2,outer_face=None,suspensions=None):
	gFAA = []
	if len(Flow2.vertices()) == 0:
		if outer_face == None :
			## Triangulation ##
			for i in G.faces():
				gFAA.append([_face_2_ints([_name_face_vertex(i)[2:]])])
			return gFAA
		else:
			## Only assigned vertices to outer face ##
			name = _face_2_ints([_name_face_vertex(outer_face)[2:]])
			add = []
			for i in outer_face:
				if i[0] not in suspensions:
					add.append(i[0])
			gFAA = [[name,add]]
			for i in _interior_faces(G,oF = outer_face):
				gFAA.append([_face_2_ints([_name_face_vertex(i)[2:]])])
			return gFAA
	else:
		## interior vertices to assign ##
		gFAA = []
		firstN = copy(Flow2.neighbors_in('o2'))
		for i in range(len(firstN)):
			name = Flow2.neighbors_in(firstN[i])[0][:-3]
			names = name.split(',')
			names = [names[0][2:],names[1][2:]]
			name0 = _face_2_ints(names)
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
		name = _name_face_vertex(outer_face)[2:]
		name = [_face_2_ints([name])]
		add = []
		for i in outer_face:
			if i[0] not in suspensions:
				add.append(i[0])
		name.append(add)
		gFAA.insert(0,name)	
		## Append triangles ##
		for i in _interior_faces(G,oF = outer_face):
			if len(i) == 3:
				gFAA.append([_face_2_ints([_name_face_vertex(i)[2:]])])
		return gFAA
		  
def is_internally_3_connected(G,suspensions):
	H = copy(G)
	v = H.add_vertex()
	H.add_edges([[v,suspensions[0]],[v,suspensions[1]],[v,suspensions[2]]])
	for v in H.vertices():
		K = copy(H)
		K.delete_vertex(v)
		if K.is_biconnected() == False:
			return False
	return True

def _give_suspension_list(graph,outer_face=None):
	sus_list = []
	if outer_face != None:
		nodes = []
		for i in outer_face:
			nodes.append(i[0])
		n = tuple(nodes)					
		## Find all possible suspensions for this face ##
		for j in Combinations(len(n),3):
			suspensions = ( n[j[0]] , n[j[1]] , n[j[2]] )
			sus_list.append(suspensions)
	else:
		for outer_face in graph.faces():
			nodes = []
			for i in outer_face:
				nodes.append(i[0])
			n = tuple(nodes)					
			## Find all possible suspensions for this face ##
			for j in Combinations(len(n),3):
				suspensions = ( n[j[0]] , n[j[1]] , n[j[2]] )
				sus_list.append(suspensions)
	return sus_list
		
def _calculate_2_flow(G,outer_face,suspensions,check_non_int_flow=False,check_just_non_int_flow=False):
	H = _graph_2_flow(G, outer_face, suspensions)
	flow1 = _give_flow_1(G,outer_face)
	flow2 = _give_flow_2(G,outer_face)
	if check_just_non_int_flow:
		try:
			return [H.multicommodity_flow([['i1','o1',flow1],['Di2','o2',flow2]],use_edge_labels=True,integer = False) , False]
		except EmptySetError:
			pass
	else:
		try:
			return [H.multicommodity_flow([['i1','o1',flow1],['Di2','o2',flow2]],use_edge_labels=True) , True]
		except EmptySetError:
			pass
		if check_non_int_flow:
			try:
				return [H.multicommodity_flow([['i1','o1',flow1],['Di2','o2',flow2]],use_edge_labels=True,integer = False) , False]
			except EmptySetError:
				pass
	return [None,False]
	
def _graph_2_flow(G,outer_face,suspensions):
	## G is a planar, suspended, internally 3-connected graph ##
	H = DiGraph([['i1','o2','o1'],[('Di2' , 'i2' , _give_flow_2(G,outer_face))]])
	_add_vertices_2_sink_edges(H,G,suspensions)
	for face in _interior_faces(G,oF = outer_face):
		_face_2_flow(H,face)	
	for sV in outer_face:
		H.set_edge_label('D' + _name_vertex_vertex(sV[0]) , 'o2' , 0 )
	for oE in outer_face :
		H.delete_edge('i1',_name_edge_vertex(oE))
	return H
	
def _give_flow_1(G,outer_face):
	return len(G.edges())-len(outer_face) + 3*(len(G.faces())-1)
	
def _give_flow_2(G,outer_face):
	flow2 = 0
	innerFaces = _interior_faces(G,oF = outer_face)
	for i in range(len(innerFaces)):
		flow2 = flow2 + ( len(innerFaces[i]) - 3 )
	return flow2
	
def _interior_faces(G,oF = None, sus = None):
	faces = copy(G.faces())
	if oF != None:
		face = _find_face(G,oF)
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

def _find_face(graph,this_face):
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




def _face_2_flow(H,face):
	## H is the new FlowGraph ##
	name = _name_face_vertex(face)
	H.add_vertex(name)
	H.add_edges([('i1','B' + name,3),(name,'o1' , len(face) )])
	_add_outer_ring(H,face,name)

def _add_outer_ring(H,edges,nameFace):
	for i in range(len(edges)):
		toAdd1 = _name_edge_vertex(edges[i])
		toAdd2 = _name_edge_vertex(edges[i],edges)
		H.add_edges([(toAdd1,toAdd2,1),
			(toAdd2,nameFace,1),
			('i1',toAdd1,1)])
		forVName = _name_vertex_vertex(edges[i][1])
		backVName = _name_vertex_vertex(edges[i][0])
		H.add_edges([(toAdd1,forVName,1),(toAdd1,backVName,1)])
		_add_triangle(H, edges, toAdd2, backVName, forVName)
		
def _add_triangle(H,face,dummyEdge,node,nextNode):
	name = _name_face_vertex(face) + ',' + node + ','
	## Nodes for Source1 ##
	H.add_edges([('B' + _name_face_vertex(face),name + 'T1' ,1),
		( name + 'T1' , name + 'T2' , 1),
		( name + 'T2' , name + 'T3' , 1),
		( name + 'T3' , name + 'T4' , 1),
		( name + 'T4' , dummyEdge , 1),
		( name + 'T4' , _name_face_vertex(face) + ',' + nextNode + ',T3', 1)])	
	## Nodes for Source2 ##
	dummyName = 'D' + node 
	H.add_edges([('i2',name + 'T1' , 1),
		( name + 'T2' , dummyName , 1),
		( dummyName , 'o2' , 1 )])
		
def _add_vertices_2_sink_edges(H,G,suspensions):
	vertices = G.vertices()
	for i in range(len(vertices)):
		if vertices[i] in suspensions:
			H.add_edge(_name_vertex_vertex(vertices[i]), 'o1' , G.degree(vertices[i]) - 2 )
		else:	
			H.add_edge(_name_vertex_vertex(vertices[i]), 'o1' , G.degree(vertices[i]) - 3 )
	
def _face_2_ints(face):
	nodes = face[0].split()
	face_name = []
	for j in nodes:
		face_name.append(int(j))
	return face_name

def _get_suspensions(faa):
	outer_face = faa[0][0]
	outer_nodes = faa[0][1]
	return copy(outer_face).remove(outer_nodes)	

def _is_outer_face(face,sus):
	count = 0
	for edge in face:
		for i in sus:
			if i == edge[0]:
				count = count+1
	if count == 3:
		return True
	return False

	
## Coherent naming in the flow graph seems to be Important##
def _name_face_vertex(face):
	name = ''                  
	for i in range(len(face)):
		name = name+str(face[i][0])+' '
	name = name[:-1]
	return 'F:'+name 
	
def _name_edge_vertex(edge, face = None):
	edge1 = copy(edge) 
	if edge1[0] < edge1[1]:                     
		name = str(edge1[0]) + ' ' + str(edge1[1])
	else:
		name = str(edge1[1]) + ' ' + str(edge1[0])
	if face != None :
		return 'DE:' + _name_face_vertex(face) + ' E:' + name
	else :
		return 'E:' + name
		
def _name_vertex_vertex(vertex):
	if type(vertex) == str:
		return vertex
	else:	
		return 'V:' + str(vertex)
		
##Plotting##	
def plot_planar_graph(graph):
	P = graph.layout(layout='planar',set_embedding = True)
	show(graph.plot(pos=P))	

def plot_sltr_or_aproximation(graph,sus=None,outer_face=None):
	faa = get_sltr(graph,suspensions=sus,outer_face=outer_face)
	if faa != None:
		plot_sltr(graph,faa=faa)
	else:
		plot_aproximation_to_sltr(graph,sus=sus,outer_face=outer_face)

def plot_sltr(graph,suspensions=None,outer_face = None, faa = None):
	if faa == None:
		faa = get_sltr(graph,suspensions=suspensions,outer_face=outer_face)
	if faa != None:
		layout = _get_good_faa_layout(graph,faa,suspensions=suspensions)
		graph.set_pos(layout)
		F = graph.plot()
		show(F)
	else:
		print "No SLTR found for given parameters"

def plot_aproximation_to_sltr(graph,sus=None,outer_face=None):
	ultimate = 3 ## at most ultimate triangulated faces
	if sus != None:
		if outer_face == None:
			for outer_face in graph.faces():
				if _is_outer_face(outer_face, sus):
					break
	Plot = plot_problem_graph(graph,ultimate,sus,outer_face)
	if Plot != None:
		Plot.show(axes = False)
	else:
		print('No close drawing found with at most ' + str(ultimate) + ' triangulated faces.')


def plot_problem_graph(graph,ultimate,sus=None,outer_face=None):
	colors = ['lightskyblue','lightgoldenrodyellow','lightsalmon', 'lightcoral','lightgreen']
	faces = copy(graph.faces())
	faces.sort(key = len)
	if sus != None:
		[face_list,layout] = _plot_problem_graph_iteration([[graph,[]]],ultimate,0,sus,outer_face)
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
		if outer_face != None:
			## No suspensions given ##
			for suspensions in _give_suspension_list(graph,outer_face):
					G = copy(graph)
					[face_list,layout] = _plot_problem_graph_iteration([[graph,[]]],ultimate,0,sus,outer_face)
					if layout != None:
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
			## nothing is given
			for outer_face in faces:
				for suspensions in _give_suspension_list(graph,outer_face):
					[face_list,layout] = _plot_problem_graph_iteration([[graph,[]]],ultimate,0,sus,outer_face)
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


def _plot_problem_graph_iteration(graph_list,ultimate,iteration,sus,outer_face):
	graph_list_new = []
	if iteration > ultimate:
		return
	else:
		for l in graph_list:
			graph = l[0]
			face_list = l[1]
			F = _interior_faces(graph,outer_face)
			F.sort(key = len)
			for face in F:
				if len(face) > 3:
					[G,v] = _insert_point_to_face(graph,face)
					faa = get_sltr(G,suspensions = sus , outer_face = outer_face)
					if faa != None:
						layout = _get_good_faa_layout(G,faa,suspensions=sus)
						face_list.append([face,v])
						return [face_list,layout]
					else:
						face_list_new = copy(face_list)
						face_list_new.append([face,v])
						graph_list_new.append([G,face_list_new])
		return _plot_problem_graph_iteration(graph_list_new,ultimate,iteration+1,sus,outer_face)
		

def _insert_point_to_face(graph,face,edge_amount=None):
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


def _get_good_faa_layout(graph,faa,suspensions = None):
	if suspensions == None:
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
	pos = _get_good_faa_layout_start(G,faa_dict,0,suspensions)
	return pos
	
def _get_good_faa_layout_start(G,faa_dict,j,suspensions):
	constant = 1
	V = G.vertices()
	n = len(V)
	sol = _get_plotting_matrix_iteration(G,suspensions,faa_dict)
	pos = {V[i]:sol[i] for i in range(n)}
	G.set_pos(pos)
	weights = _calculate_weights(G,faa_dict,suspensions,j)
	return _get_good_faa_layout_iteration(G,faa_dict,j,suspensions,weights)

def _get_good_faa_layout_iteration(G,faa_dict,j,suspensions,weights=None):
	constant = 1
	V = G.vertices()
	n = len(V)
	j += 1
	sol2 = _get_plotting_matrix_iteration(G,suspensions,faa_dict,weights)
	pos2 = {V[i]:sol2[i] for i in range(n)}
	G.set_pos(pos2)
	weights2 = _calculate_weights(G,faa_dict,suspensions,j)
	M = weights-weights2
	if M.norm() < constant or j == 50:
		return pos2
	else:
		return _get_good_faa_layout_iteration(G,faa_dict,j,suspensions,weights2)	
	
def _calculate_weights(G,faa_dict,suspensions,j):
	V = G.vertices()
	n = len(V)
	W = zero_matrix(RR,n,n)
	pos = G.get_pos()
	
	##weights for edges ##
	for E in G.edges():
		q = _get_edge_length(E,pos)
		## TODO: Find a better function q and p##
		i0 = V.index(E[0])
		i1 = V.index(E[1])
		W[i0,i1] += q
		W[i1,i0] += q
		
	## weights for faces ##
	for F in G.faces():
		p = _get_face_area(F,pos)
		## TODO: Find a better function q and p##
		for E in F:
			i0 = V.index(E[0])
			i1 = V.index(E[1])
			W[i0,i1] += p
			W[i1,i0] += p
	return W
	
def _get_face_area(F,pos):
	p = 0
	for i in range(len(F)):
		x1 = pos[F[i][0]][0]
		x2 = pos[F[i][0]][1]
		y1 = pos[F[i][1]][0]
		y2 = pos[F[i][1]][1]
		p += x1*y2 - x2*y1
	p = abs(p/2)
	return p
	
def _get_edge_length(E,pos):
	p0 = pos[E[0]]
	p1 = pos[E[1]]
	l0 = (p0[0] - p1[0])^2
	l1 = (p0[1] - p1[1])^2
	q = sqrt(l0+l1)
	return q
	
def _get_plotting_matrix_iteration(G,suspensions,faa_dict,weights=None):
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
					wn1 = 1
					wn2 = 1
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