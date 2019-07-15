import sage.all

def has_sltr(graph,suspensions=None,outer_face=None,embedding=None,just_non_int_flow = True,check_non_int_flow=False):
	if suspensions != None and outer_face == None:
		raise ValueError("If the suspensions are given we also need an outer face")
	else:
		sltr = get_sltr(graph,suspensions=suspensions,outer_face=outer_face,embedding=embedding,just_non_int_flow = just_non_int_flow)
		return sltr != None

def get_sltr(graph,suspensions=None,outer_face=None,embedding=None,just_non_int_flow = True,check_non_int_flow=False,plotting=False,ipe=None):
	## Returns a list of the faces and assigned vertices with the outer face first ##
	if embedding != None:
		graph.set_embedding(embedding)
	if suspensions != None:
		if outer_face == None:
			raise ValueError("If the suspensions are given we also need an outer face")
		return _get_sltr(graph,suspensions,outer_face,check_non_int_flow,just_non_int_flow,plotting=plotting,ipe=ipe)
	else:			
		## We will check all posible triplets as suspensions ##
		if outer_face != None:
			## outer face is given
			for suspensions in _give_suspension_list(graph,outer_face):
				return _get_sltr(graph,suspensions,outer_face,check_non_int_flow,just_non_int_flow,plotting=plotting,ipe=ipe)
		else:
			## Checking all outer faces:
			for outer_face in graph.faces():
				for suspensions in _give_suspension_list(graph,outer_face):
					gFAA = _get_sltr(graph,suspensions,outer_face,check_non_int_flow,just_non_int_flow,plotting=plotting,ipe=ipe)
					if gFAA != None:
						return gFAA
	return False

def _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow,plotting=False,ipe=None):
	[gFAA, has_sltr] = _calculate_2_flow(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow)
	if has_sltr:
		if plotting:
			plot_sltr(graph,suspensions,outer_face,faa = gFAA,plotting=True,ipe=ipe)
		return gFAA
	return None

def _get_good_faa(G, Flow2,outer_face=None,suspensions=None,return_angle_edges=None):
	gFAA = []
	if Flow2 == None or len(Flow2.vertices()) == 0 or len(Flow2.neighbors_in('Do2')) == 0:
		## In this case the only assigned vertices are those around the outer face
		if outer_face == None :
			## Triangulation ##
			for i in G.faces():
				gFAA.append([_face_2_ints(_name_face_vertex(i)[2:]),[]])
			return gFAA
		else:
			## Only assigned vertices to outer face ##
			name = _face_2_ints(_name_face_vertex(outer_face)[2:])
			add = []
			for i in name:
				if i not in suspensions:
					add.append(i)
			gFAA = [[name,add]]
			for f in _interior_faces(G,oF = outer_face):
				gFAA.append([_face_2_ints(_name_face_vertex(f)[2:]),[]])
			return [gFAA,[]]
	else:
		## In this case we have assigned vertices on the inside
		non_int = False
		## Checking wether we have a non-int Flow2 minus numerical noise
		for e in Flow2.edges():
			if 0.00001 < e[2] < 0.99999:
				non_int = True
				break
		if non_int:
			Flow = _get_faa_from_non_int_solution(G,Flow2)
		else:
			Flow = Flow2
		## interior vertices to assign ##
		if Flow != None:
			dummy_verts = Flow.neighbors_in('Do2')
			list_A = []
			angle_edges = []
			for v in dummy_verts:
				angles_v2 = Flow.neighbors_in(v)
				for a2 in angles_v2:
					list_A.append(a2)
					angle_edges.append([Flow.neighbors_in(a2)[0],a2])
			for v in list_A:
				a2 = copy(v)
				name = a2[:-3]
				names = name.split(',')
				[names1,names2] = [_face_2_ints(names[0][2:]),_face_2_ints(names[1][2:])]
				x = True
				for j in range(len(gFAA)):
					if  names1 == gFAA[j][0]:
						x = False
						gFAA[j][1].append(names2[0])
				if x:
					add = [names1]
					add.append(names2)
					gFAA.append(add)
			## Append vertices assigned to outer Face ##
			name = _name_face_vertex(outer_face)[2:]
			name = [_face_2_ints(name)]
			add = []
			for i in outer_face:
				if i[0] not in suspensions:
					add.append(i[0])
			name.append(add)
			gFAA.insert(0,name)	
			## Append triangles ##
			for i in _interior_faces(G,oF = outer_face):
				if len(i) == 3:
					gFAA.append([_face_2_ints(_name_face_vertex(i)[2:]),[]])
			if return_angle_edges:
				return [gFAA,angle_edges]
			else:
				return [gFAA,angle_edges]
		else:
			"uuuups"

def _get_faa_from_non_int_solution(G,Flow):
	## First calculates a new one-flow graph to then get an FAA, i.e. an integral flow, that is contained in Flow.
	ass_flow = int(round(Flow.edge_label('Do2','o2')))
	D = DiGraph([['Do2','o2',ass_flow]])
	for face in G.faces():
		D.add_edge('i2',_name_face_vertex(face),len(face)-3)
	dummy_verts = Flow.neighbors_in('Do2')
	for v in dummy_verts:
		D.add_edge(v,'Do2',1)
		angles_v2 = Flow.neighbors_in(v)
		for a2 in angles_v2:
			D.add_edge(a2,v,1)
			a1 = Flow.neighbors_in(a2)[0]
			D.add_edge(a1,a2,1)
			face = a1.split(',')[0]
			D.add_edge(face,a1,1)
	[val,F_new] = D.flow('i2','o2', value_only=False, integer=True, use_edge_labels=True)
	if val == ass_flow:
		return F_new
	else:
		print "We found a non-int flow that contains no FAA?!"
		return None

##### CREATING AND CALCULATIONS TWO FLOW GRAPH ###################################################################################################################################################
####################################################################################################################################################################
####################################################################################################################################################################
####################################################################################################################################################################


def _calculate_2_flow(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow):
	## First builds the flow graph, to then calculate a solution 2-flow
	H = _graph_2_flow(graph, outer_face, suspensions)
	flow1 = _give_flow_1(graph,outer_face,suspensions)
	flow2 = _give_flow_2(graph,outer_face,suspensions)
	if check_just_non_int_flow:
		try:
			Flow = H.multicommodity_flow([['i1','o1',flow1],['i2','o2',flow2]],use_edge_labels=True,integer = False,verbose = 0)
			[gFAA,angle_edges] = _get_good_faa(graph, Flow[1],outer_face=outer_face,suspensions=suspensions,return_angle_edges=True)
			if not check_non_int_flow:
				return [gFAA,True]
			else:
				if len(angle_edges) == 0:
					return [gFAA,True]
				H.delete_edges(angle_edges)
				ass_flow = len(angle_edges)
				new_flow = flow2-ass_flow
				H.add_edge('o2','o1',new_flow)
				H.add_edge('i1','i2',new_flow)
				(f,Flow1) = H.flow('i1','o1',value_only=False,use_edge_labels=True,integer = True)
				if flow1+new_flow == f:
					return [gFAA,True]
				else:
					try:
						Flow = [H.multicommodity_flow([['i1','o1',flow1],['i2','o2',flow2]],use_edge_labels=True,integer = True) , True]
						[gFAA,angle_edges] = _get_good_faa(graph, Flow[1],outer_face=outer_face,suspensions=suspensions,return_angle_edges=True)
						print_info(graph, outer_face, suspensions, check_non_int_flow, check_just_non_int_flow)
						raise ValueError("Counter example to FAA extraction found!!! There is a GFAA but not extractable from non-int solution!")
						return [gFAA,True]		
					except EmptySetError:
						print_info(graph, outer_face, suspensions, check_non_int_flow, check_just_non_int_flow)
			 			raise ValueError("Counter Example Found to non-int-flow conjecture!!! There is non-int solution but no GFAA!")

		except:
		   	pass
	else:	
		try:
			Flow = H.multicommodity_flow([['i1','o1',flow1],['i2','o2',flow2]],use_edge_labels=True,integer = True)
			[gFAA,angle_edges] = _get_good_faa(graph, Flow[1],outer_face=outer_face,suspensions=suspensions,return_angle_edges=True)
			return [gFAA,True]		
		except EmptySetError:
			pass
		if check_non_int_flow:
			try:
				Flow = [H.multicommodity_flow([['i1','o1',flow1],['i2','o2',flow2]],use_edge_labels=True,integer = False) , False]
				print "Only non integer flow found ... :("
				print_info(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow)
			except EmptySetError:
				pass
	return [None,False]

def print_info(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow,embedding=None):
	print "Graph  " + graph.sparse6_string()
	print "Face:  " + str(outer_face)
	print "Suspensions:  " + str(suspensions)
	print "Check non int = " + str(check_non_int_flow)
	print "Check just non int = " + str(check_non_int_flow)
	if embedding != None:
		print "Embedding = " + str(embedding)
	
def _graph_2_flow(G,outer_face,suspensions):
	## G is a planar, suspended, internally 3-connected graph ##
	ass_flow = _give_ass_flow(G,outer_face,suspensions)
	H = DiGraph([['Do2','o2', ass_flow]])
	_add_vertices_2_sink_edges(H,G,suspensions)
	for face in _interior_faces(G,oF = outer_face):
		_face_2_flow(H,face)
	## Fixing outer face
	for sV in outer_face:
		if H.has_vertex('D' + _name_vertex_vertex(sV[0])):
			H.delete_vertex('D' + _name_vertex_vertex(sV[0]))
	for oE in outer_face :
		H.delete_edge('i1',_name_edge_vertex(oE))
	return H
	
def _give_flow_1(G,outer_face,suspensions):
	## E_int + 3*F_int ##
	flow1 = len(G.edges()) - len(outer_face)
	return flow1

def _give_flow_2(G,outer_face,suspensions):
	## sum(F_int -3)
	flow = 0
	for face in G.faces():
		if len(face) > 3:
			flow += len(face)
	if len(outer_face) > 3:
		flow -= len(outer_face)
	return flow

def _give_ass_flow(G,outer_face,suspensions):
	flow = -len(outer_face)+3
	for face in G.faces():
		flow += len(face)-3
	return flow

def _face_2_flow(H,face):
	## H is the new FlowGraph ##
	name = _name_face_vertex(face)
	if len(face) > 3:
		H.add_edge(name,'o1' , len(face)-3)
		H.add_edge(name,'o2' , 3)
	_add_outer_ring(H,face,name)

def _add_outer_ring(H,face_edges,nameFace):
	n = len(face_edges)
	for i in range(n):
		# edge-vertex
		edge_vertex = _name_edge_vertex(face_edges[i])
		H.add_edge('i1',edge_vertex,1)
		if n > 3:
			## dummy-edge in face
			small_Square = _name_edge_vertex(face_edges[i],face_edges)
			H.add_edges([(edge_vertex,small_Square,1),(small_Square,nameFace,1)])
		## edges to adjacent vertex-vertices
		forVName = _name_vertex_vertex(face_edges[i][1])
		backVName = _name_vertex_vertex(face_edges[i][0])
		H.add_edges([(edge_vertex,forVName,1),(edge_vertex,backVName,1)])
		if n > 3:
			# Triangles only needed if face > 3
			_add_triangle(H, face_edges, small_Square, backVName, forVName)
		
def _add_triangle(H,face,next_Square,node,nextNode):
	name = _name_face_vertex(face) + ',' + node + ','
	## Nodes for Source1 ##
	H.add_edges([('i2',name + 'T1' ,1),
		( name + 'T1' , name + 'T2' , 1),
		( name + 'T2' , name + 'T3' , 1),
		( name + 'T3' , name + 'T4' , 1),
		( name + 'T4' , next_Square , 1),
		( name + 'T4' , _name_face_vertex(face) + ',' + nextNode + ',T3', 1)])	
	## Nodes for Source2 ##
	dummyName = 'D' + node 
	H.add_edges([( name + 'T2' , dummyName , 1),
		( dummyName , 'Do2' , 1 )])
		
def _add_vertices_2_sink_edges(H,G,suspensions):
	for v in G.vertices():
		if v in suspensions:
			d = G.degree(v) - 2
			if d > 0:
				H.add_edge(_name_vertex_vertex(v), 'o1' , d )
		else:
			d = G.degree(v) - 3
			if d > 0:
				H.add_edge(_name_vertex_vertex(v), 'o1' , d )	

##################################################################################################################################
## Coherent naming in the flow graph seems to be Important########################################################################

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

##### HELPING FUNCTIONS ###############################################################################################################################################
####################################################################################################################################################################	
####################################################################################################################################################################
####################################################################################################################################################################
	
def _interior_faces(G,oF = None, sus = None):
	## Returns a list of interior faces of G
	try:
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
		print "Mistake in _interior_faces()"
		print oF
		for face in G.faces():
			print face
		print "Supposed outer_face not in faces"

def _give_suspension_list(graph,outer_face=None):
	## Returns a list of of all possible sets of three vertices from outer face
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
		## In this case for all faces even.
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

def _find_face(graph,this_face):
	### Returns this face in the rigth ordering in case the embedding or something was changed
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

	
def _face_2_ints(face):
	verts = copy(face).split()
	## for a face name as str the vertices of this face are returned as list of ints.
	face_name = []
	for j in verts:
		face_name.append(int(j))
	return face_name


##### PLOTTING ###################################################################################################################################################
####################################################################################################################################################################
####################################################################################################################################################################
####################################################################################################################################################################

def plot_planar_graph(graph):
	P = graph.layout(layout='planar',set_embedding = True)
	show(graph.plot(pos=P))	

def plot_sltr(graph,suspensions,outer_face,faa = None,plotting=True,ipe=None):
	## Calculates a SLTR if necesary and gives back a plot of this graoh nad changes the planar positions to the SLTR drawing.
	## ipe as a string creates an ipe file with the drawing
	if faa == None:
		faa = get_sltr(graph,suspensions=suspensions,outer_face=outer_face)
	if faa != None:
		layout = _get_good_faa_layout(graph,faa,suspensions=suspensions,outer_face=outer_face)
		graph.set_pos(layout)
		# if plotting:
		# 	Plot = graph.plot(axes = False)
		# 	Plot.show()
		# if ipe != None:
		# 	graph2ipe(graph,ipe)
		# if plotting:
		# 	return [Plot,graph]
		# else:
		# 	return [None,graph]
	else:
		print "No SLTR found for given parameters"

def _get_good_faa_layout(graph,faa,suspensions=None,outer_face=None):
	if suspensions == None:
		if len(faa[0]) > 1:
			suspensions = []
			for node in faa[0][0]:
				if node not in faa[0][1]:
					suspensions.append(node)
		else:
			suspensions = copy(faa[0][0])
	if outer_face == None:
		if len(faa[0]) > 1:
			face_nodes = faa[0][0]
		else:
			face_nodes = faa[0]
		outer_face = []
		for i in range(len(face_nodes)-1):
			outer_face.append([face_nodes[i],face_nodes[i+1]])
		outer_face.append([face_nodes[i+1],face_nodes[0]])
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
	pos = _get_good_faa_layout_iteration(graph,faa,faa_dict,0,suspensions,None,outer_face)
	return pos

def _get_good_faa_layout_iteration(G,faa,faa_dict,count,suspensions,weights,outer_face):
	## Recursively calculates a good embedding 
	
	## const is for the stopping of the first iteration approach
	const = 1

	V = G.vertices()
	n = len(V)
	count += 1
	if weights == None:
		sol = _get_plotting_matrix_iteration(G,suspensions,faa_dict,count,weights)
		pos = {V[i]:sol[i] for i in range(n)}
		G.set_pos(pos)
		weights2 = _calculate_weights(G,faa,faa_dict,suspensions,count,outer_face=outer_face,W=copy(weights))
	else:
		sol = _get_plotting_matrix_iteration(G,suspensions,faa_dict,count,weights)
		pos = {V[i]:sol[i] for i in range(n)}
		G.set_pos(pos)
		weights2 = _calculate_weights(G,faa,faa_dict,suspensions,count,outer_face=outer_face,W=copy(weights))
		M = weights-weights2
		norm = M.norm()
		# if mod(count,5) == 0:
		# 	print norm
		# 	show(G)
		if norm < const:
			print "Stopped because of Norm, count is:" , count
			return pos
		elif count == 30:
			[pos,weights] = _calculate_position_iteratively(G,faa,faa_dict,suspensions,outer_face,weights)
			#graph2ipe(G,"example1_1")
			#[pos,W] = _calculate_position_iteratively(G,faa,faa_dict,suspensions,outer_face)
			G.set_pos(pos)
			return pos
	return _get_good_faa_layout_iteration(G,faa,faa_dict,count,suspensions,weights2,outer_face)	

def _calculate_weights(G,faa,faa_dict,suspensions,count,outer_face,W=None):
	## Calculates the lambda for one step in Approach 1
	n = len(G.vertices())
	if W == None:
		W = zero_matrix(RR,n,n)
	W = _weights_for_pseudo_segments(G,faa,faa_dict,pos,W,count)
	return W

def _weights_for_pseudo_segments(G,faa,faa_dict,pos,W,count):
	V = G.vertices()
	x = 1.2
	for seg in _list_pseudo_segments(G,faa,faa_dict):
		[R,L] = _nodes_on_left_right(G,seg,pos)
		vol_l1 = 0
		vol_r1 = 0
		c_l = 0
		c_r = 0
		for face in G.faces():
			face_nodes = _nodes_in_face(face)
			if list_in_list(face_nodes,L+seg):
				vol_l1 += _get_face_area(G,face)
				c_l += 1
			elif list_in_list(face_nodes,R+seg):
				vol_r1 += _get_face_area(G,face)
				c_r += 1
		if vol_l1 != 0 and vol_r1 != 0:
			vol_l = (vol_l1^x)*(c_r)^2
			vol_r = (vol_r1^x)*(c_l)^2
			for node in seg+R:
				j = V.index(node)
				for n in R:
					if G.has_edge(node,n):
						i = V.index(n)
						W[j,i] += vol_r
						W[i,j] += vol_r
			for node in seg+L:
				j = V.index(node)
				for n in L:
					if G.has_edge(node,n):
						i = V.index(n)
						W[j,i] += vol_l
						W[i,j] += vol_l
	return W

def _nodes_in_face(face):
	nodes = []
	for e in face:
		nodes.append(e[0])
	return nodes

def list_in_list(list1,list2):
	for elem in list1:
		if elem not in list2:
			return False
	else: 
		return True

def _nodes_on_left_right(G,segment,pos):
	V = copy(G.vertices())
	pos = copy(G.get_pos())
	v0 = segment[0]
	v1 = segment[1]
	i0 = V.index(v0)
	i1 = V.index(v1)
	x0 = pos[i0][0]
 	y0 = pos[i0][1]
 	vec0 = vector([x0,y0])
 	x1 = pos[i1][0]
 	y1 = pos[i1][1]
 	x = x1-x0
 	y = y1-y0
 	norm = sqrt(x**2+y**2)
 	x = x/norm
 	y = y/norm
 	A = Matrix([[x,y],[-y,x]])
 	L = [[],[]]
 	for v in V:
 		if v not in segment:
 			i = V.index(v)
 			vec = A*(vector([pos[i][0],pos[i][1]])-vec0)
 			if vec[1] > 0:
 				L[1].append(v)
 			else:
 				L[0].append(v)
 	return L

def _list_pseudo_segments(G,faa,faa_dict):
	D = copy(faa_dict)
	H = copy(G)
	segments = []
	while len(D) > 0:
		(v,(e1,e2)) = D.popitem()
		H.delete_edges([[v,e1],[v,e2]])
		[d1,d2] = [v,v]
		segment = [e1,v,e2]
		while D.has_key(e1):
			(n1,n2) = D[e1]
			if n1 != d1 and n2 == d1:
				d1 = e1
				e1 = n1
				segment = [e1] + segment
				D.pop(d1)
				H.delete_edge([e1,d1])
			elif n2 != d1 and n1 == d1:
				d1 = e1
				e1 = n2
				segment = [e1] + segment
				D.pop(d1)
				H.delete_edge([e1,d1])
			else:
				break
		while D.has_key(e2):
			(n1,n2) = D[e2]
			if n1 != d2 and n2 == d2:
				d2 = e2
				e2 = n1
				segment = segment + [e2]
				D.pop(d2)
				H.delete_edge([e2,d2])
			elif n2 != d2 and n1 == d2:
				d2 = e2
				e2 = n2
				segment = segment + [e2]
				D.pop(d2)
				H.delete_edge([e2,d2])
			else:
				break
		segments.append(segment)
	for e in H.edges():
		segments.append([e[0],e[1]])
	return segments
	
def _get_face_area(G,F):
	pos = G.get_pos()
	p = 0
	for i in range(len(F)):
		x1 = pos[F[i][0]][0]
		x2 = pos[F[i][0]][1]
		y1 = pos[F[i][1]][0]
		y2 = pos[F[i][1]][1]
		p += x1*y2 - x2*y1
	p = abs(p/2)
	return p

def _get_face_area_nodes(G,nodes):
	face = [[nodes[len(nodes)-1],nodes[0]]]
	for j in range(len(nodes)-1):
		face.append([nodes[j],nodes[j+1]])
	return _get_face_area(G,face)

def _calculate_position_iteratively(G,faa,faa_dict,suspensions,outer_face,weights=None):
	## Calculates the lamda for the second or the combined approach
	count = 0
	V = G.vertices()					
	n = len(V)
	m = len(G.faces())
	sol = _get_plotting_matrix_iteration(G,suspensions,faa_dict,count,None)
	pos = {V[i]:sol[i] for i in range(n)}
	W = zero_matrix(RR,n,n)
	for E in G.edges():
		i0 = V.index(E[0])
		i1 = V.index(E[1])
		W[i0,i1] = 2
		W[i1,i0] = 2
	while count < 2*n+10:
		G.set_pos(pos)
		max_face = []
		max_face_area = 0
		for face in _interior_faces(G,oF=outer_face):
			area = _get_face_area(G,face)
			if max_face_area < area:
					max_face_area = area
		for face in _interior_faces(G,oF=outer_face):
			area = _get_face_area(G,face)	
			if area >= max_face_area*0.9:
				max_face.append(face)
		for face in max_face:
			q = _get_face_area(G,face)
			for E in face:
				i0 = V.index(E[0])
				i1 = V.index(E[1])
				W[i0,i1] *= 2
				W[i1,i0] *= 2
		if weights == None:
			sol = _get_plotting_matrix_iteration(G,suspensions,faa_dict,count,W)
		else:
			sol = _get_plotting_matrix_iteration(G,suspensions,faa_dict,count,W+weights)
		pos1 = {V[i]:sol[i] for i in range(n)}
		if int(round(pos1[V.index(suspensions[0])][1])) == 100:
			pos = pos1
			count += 1
		else:
			return [pos,W+weights]
	return [pos,W+weights]

def _get_plotting_matrix_iteration(G,suspensions,faa_dict,count,weights=None,normal_rubber=False):
	## calculates positions for given lambda
	
	pos = dict()
	V = G.vertices()
	scale = 100
	## set outer positions on triangle ##
	a0 = pi/2
	a1 = pi/2 + pi*2/3
	a2 = pi/2 + pi*4/3
	pos[suspensions[0]] = (scale*cos(a0),scale*sin(a0))
	pos[suspensions[1]] = (scale*cos(a1),scale*sin(a1))
	pos[suspensions[2]] = (scale*cos(a2),scale*sin(a2))

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
			if not normal_rubber:
				if faa_dict.has_key(v):
					## SLTR part
					j1 = V.index(faa_dict[v][0])
					j2 = V.index(faa_dict[v][1])
					if weights != None :
						wn1 = weights[j1,i]
						wn2 = weights[j2,i]
					else:
						wn1 = 1
						wn2 = 1
					M[i,j1] = -wn1
					M[i,j2] = -wn2
					M[i,i] = wn1 + wn2
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
			else:
				## normal rubber band part
				nv = G.neighbors(v)
				s = 0
				for u in nv:
					j = V.index(u)
					if weights != None :
						wu = weights[j,i]
					else:
						wu = 1
					s += wu
					M[i,j] += -wu
				M[i,i] += s
	return M.pseudoinverse()*b

