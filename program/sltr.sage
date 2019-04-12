import sage.all
attach("graph2ipe.sage")

def has_sltr(graph,suspensions=None,outer_face=None,with_tri_check=True):
	print "moving"
	print graph.faces()
	print outer_face
	print suspensions
	print ".."
	if suspensions != None and outer_face == None:
			raise ValueError("If the suspensions are given we also need an outer face")
	elif with_tri_check:
		return _has_sltr_with_tri(graph,suspensions=suspensions,outer_face=outer_face)
	return get_sltr(graph,suspensions=suspensions,outer_face=outer_face) != None


	
def get_sltr(graph,suspensions=None,outer_face=None,check_non_int_flow=False,check_just_non_int_flow = False):
	## Returns a list of the faces and assigned vertices with the outer face first ##
	if suspensions != None:
		if outer_face == None:
			raise ValueError("If the suspensions are given we also need an outer face")
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
			raise ValueError("Need to stop! :)")
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
	return H.vertex_connectivity(k=3)

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
		
def _calculate_2_flow(graph,outer_face,suspensions,check_non_int_flow=False,check_just_non_int_flow=False):
	H = _graph_2_flow(graph, outer_face, suspensions)
	flow1 = _give_flow_1(graph,outer_face,suspensions)
	flow2 = _give_flow_2(graph,outer_face,suspensions)
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
	H = DiGraph([['i1','o2','o1'],[('Di2' , 'i2' , _give_flow_2(G,outer_face,suspensions))]])
	_add_vertices_2_sink_edges(H,G,suspensions)
	for face in _interior_faces(G,oF = outer_face):
		_face_2_flow(H,face)	
	for sV in outer_face:
		H.set_edge_label('D' + _name_vertex_vertex(sV[0]) , 'o2' , 0 )
	for oE in outer_face :
		H.delete_edge('i1',_name_edge_vertex(oE))
	return H
	
def _give_flow_1(G,outer_face,suspensions):
	return len(G.edges())-len(outer_face) + 3*(len(G.faces())-1)

def _give_flow_2(G,outer_face,suspensions):
	flow2 = 0
	for face in G.faces():
		flow2 += ( len(face) - 3 )
	flow2 -= len(outer_face)
	return flow2
	
def _interior_faces(G,oF = None, sus = None):
	try:
		print G.faces()
		print oF
		print sus
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
	except ValueError:
		print (G.edges(),oF,sus)
		print "Supposed outer_face not in faces"

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

def plot_sltr_or_approximation(graph,sus=None,outer_face=None,ipe = None):
	faa = get_sltr(graph,suspensions=sus,outer_face=outer_face)
	if faa != None:
		[Plot,G] = plot_sltr(graph,faa=faa)
	else:
		[Plot,G] = plot_approximation_to_sltr(graph,sus=sus,outer_face=outer_face)
	if Plot != None and ipe != None:
		graph2ipe(G,ipe)

def plot_sltr(graph,suspensions=None,outer_face = None, faa = None):
	if faa == None:
		faa = get_sltr(graph,suspensions=suspensions,outer_face=outer_face)
	if faa != None:
		layout = _get_good_faa_layout(graph,faa,suspensions=suspensions)
		graph.set_pos(layout)
		Plot.show(axes = False)
		return [Plot,graph]
	else:
		print "No SLTR found for given parameters"

def plot_approximation_to_sltr(graph,sus=None,outer_face=None):
	ultimate = 2 ## at most ultimate triangulated faces
	if sus != None:
		if outer_face == None:
			for outer_face in graph.faces():
				if _is_outer_face(outer_face, sus):
					break
	[Plot,graph] = plot_problem_graph(graph,ultimate,sus,outer_face)
	Plot.show(axes = False)
	if Plot != None:
		return [Plot,graph]
	else:
		print('No close drawing found with at most ' + str(ultimate) + ' triangulated faces.')


def plot_problem_graph(graph,ultimate,sus=None,outer_face=None):
	if outer_face == None:
		raise ValueError("Needs outer face or suspensions to calculate approximation")
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
			G.set_pos(layout)
			P = G.plot(color_by_label={None: 'black' , 1: 'red'})
			for i in range(len(face_list)):
				[face,v] = face_list[i]
				P = P + polygon([layout[x[0]] for x in face], color=colors[i])
			return [P,G]
	else:
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
					G.set_pos(layout)
					P = G.plot(color_by_label={None: 'black' , 1: 'red'})
					for i in range(len(face_list)):
						[face,v] = face_list[i]
						P = P + polygon([layout[x[0]] for x in face], color=colors[i])
					return [P,G]


def _plot_problem_graph_iteration(graph_list,ultimate,iteration,sus,outer_face):
	graph_list_new = []
	if iteration == ultimate:
		return [None,None]
	else:
		for entry in graph_list:
			graph = entry[0]
			face_list = entry[1]
			iF = _interior_faces(graph,outer_face)
			iF.sort(key=len)
			for face in iF:
				if len(face) > 3:
					[G,v] = _insert_point_to_face(graph,face)
					if has_faa(G):
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
	## True gives flat triangle for pictures
	flat_triangle = False

	pos = dict()
	V = G.vertices()

	## set outer positions on triangle ##
	a0 = pi/2
	a1 = pi/2 + pi*2/3
	a2 = pi/2 + pi*4/3
	
	pos[suspensions[0]] = (100*cos(a0),100*sin(a0))
	pos[suspensions[1]] = (100*cos(a1),100*sin(a1))
	pos[suspensions[2]] = (100*cos(a2),100*sin(a2))

	if flat_triangle:
		pos[suspensions[0]] = (100*cos(a1),100*sin(a0))

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

## Ways to make the algorithm faster...	

def _has_sltr_with_tri(graph,suspensions=None,outer_face=None):
	if suspensions != None:
		return _has_separating_triangle_sltr(graph,outer_face,suspensions)
	else:					
		## We will check all possible triplets as suspensions ##
		if outer_face != None: 
			## outer face is given
			for suspensions in _give_suspension_list(graph,outer_face):
				if _has_separating_triangle_sltr(graph,outer_face,suspensions):
					return True
			return False
		else:
			## Checking all outer faces and all suspensions ##
			for outer_face in graph.faces():
				for suspensions in _give_suspension_list(graph,outer_face):
					if _has_separating_triangle_sltr(graph,outer_face,suspensions):
						return True
			return False

def _has_separating_triangle_sltr(graph,outer_face,suspensions):
	separator_list = []
	V = graph.vertices()
	n = len(V)
	for i in range(n):
		Nv = graph.neighbors(V[i])
		for j in range(len(Nv)):
			if Nv[j] > V[i]:
				for k in range(j,len(Nv)):
					if graph.has_edge(Nv[j],Nv[k]):
						graph_parts = copy(graph)
						graph_parts.delete_vertices([V[i],Nv[j],Nv[k]])
						if not graph_parts.is_connected():
							graph_parts = graph_parts.connected_components()
							separator_list.append([graph_parts,([V[i],Nv[j],Nv[k]])])
	if len(separator_list) > 0:
		separator_list.sort(key=_av)
		for [graph_parts,triangle] in separator_list:				
			if _check_parts(graph,graph_parts,triangle,outer_face,suspensions):
				return True
		return False
	return has_sltr(graph,outer_face=outer_face,suspensions=suspensions,with_tri_check=False)

def _av(list_item):
	return abs(len(list_item[0][0])-len(list_item[0][1]))

def _check_parts(graph,graph_parts,triangle,outer_face,suspensions):
	if len(graph_parts) > 2:
		return False
	[g1,g2] = graph_parts
	if _check_order(graph,g1,g2,triangle,outer_face,suspensions):
		return True
	return False

def _check_order(graph,vertices_one,vertices_two,triangle,outer_face,suspensions):
	two_out = False
	for i in suspensions:
		if i in vertices_two:
			two_out = True
			break
	if two_out:
		outer_vertices = vertices_two
		inner_vertices = vertices_one
	else:
		outer_vertices = vertices_one 
		inner_vertices = vertices_two
	## stuff for outer graph ##
	outer_graph = copy(graph)
	outer_graph.delete_vertices(inner_vertices)
	if len(outer_graph.vertices()) > 7:
		if not _has_separating_triangle_sltr(outer_graph,outer_face,suspensions):
			return False
	## stuff for inner graph ##
	inner_graph = copy(graph)
	inner_graph.delete_vertices(outer_vertices)
	if len(inner_graph.vertices()) > 7:
		for face in inner_graph.faces():
			if _is_outer_face(face,triangle):
				inner_face = face
				break
		return _has_separating_triangle_sltr(inner_graph,inner_face,triangle)
	return True
