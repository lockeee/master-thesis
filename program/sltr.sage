import sage.all
attach("graph2ipe.sage")

def has_sltr(graph,suspensions=None,outer_face=None,embedding=None,check_non_int_flow=False,check_just_non_int_flow = True,with_tri_check=False):
	if suspensions != None and outer_face == None:
		raise ValueError("If the suspensions are given we also need an outer face")
	else:
		if with_tri_check:
			return _has_sltr_with_tri(graph,suspensions=suspensions,outer_face=outer_face,check_just_non_int_flow=check_just_non_int_flow)
		return get_sltr(graph,suspensions=suspensions,outer_face=outer_face,embedding=embedding,check_non_int_flow=check_non_int_flow,check_just_non_int_flow = check_just_non_int_flow , return_sltr = False)


def get_sltr(graph,suspensions=None,outer_face=None,embedding=None,check_non_int_flow=False,check_just_non_int_flow = False , return_sltr = True):
	## Returns a list of the faces and assigned vertices with the outer face first ##
	if embedding != None:
		graph.set_embedding(embedding)
	if suspensions != None:
		if outer_face == None:
			raise ValueError("If the suspensions are given we also need an outer face")
		sltr = _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow,return_sltr)
		if sltr != None:
			if return_sltr:
				return sltr
			else:
				return True
	else:					
		## We will check all posible triplets as suspensions ##
		if outer_face != None:
			## outer face is given
			for suspensions in _give_suspension_list(graph,outer_face):
				sltr = _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow,return_sltr)
				if sltr != None:
					if return_sltr:
						return sltr
					else:
						return True
		else:
			## Checking all outer faces:
			for outer_face in graph.faces():
				for suspensions in _give_suspension_list(graph,outer_face):
					sltr = _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow,return_sltr)
					if sltr != None:
						if return_sltr:
							return sltr
						else:
							return True
	if not return_sltr:
		return False

# def _get_sltr_via_faa(graph,suspensions,outer_face):
# 	fv_list = []
# 	outer_nodes = []
# 	for e in outer_face:
# 		outer_nodes.append(e[0])
# 	for f in graph.faces():
# 		fv = []
# 		for e in f:
# 			if e[0] not in outer_nodes:
# 				fv.append(e[0])
# 		fv_list.append(fv)
	


def _get_sltr(graph,suspensions,outer_face,check_non_int_flow,check_just_non_int_flow,return_sltr):
	[Flow, has_sltr] = _calculate_2_flow(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow)
	if check_just_non_int_flow:
		if Flow != None:
			if return_sltr:
				try:
					return _get_good_faa(graph,Flow[1],outer_face,suspensions)
				except EmptySetError:
					print "Couldn't convert to Good-FAA"
					print Flow[1].edges()
					pass
			else:
				return True
	else:
		if has_sltr:
			return _get_good_faa(graph,Flow[1],outer_face,suspensions)
		else:
			return None

def _get_good_faa(G, Flow2,outer_face=None,suspensions=None):
	gFAA = []
	if len(Flow2.vertices()) == 0:
		if outer_face == None :
			## Triangulation ##
			for i in G.faces():
				gFAA.append([_face_2_ints([_name_face_vertex(i)[2:]]),[]])
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
				gFAA.append([_face_2_ints([_name_face_vertex(i)[2:]]),[]])
			return gFAA
	else:
		non_int = False
		for e in Flow2.edges():
			if 0.0001 < e[2] < 0.999:
				non_int = True
			break
		## interior vertices to assign ##
		gFAA = []
		bags_out = Flow2.neighbors_in('o2')
		firstN = []
		for b in bags_out:
			bag_in = copy(Flow2.neighbors_in(b))
			for dv2 in bag_in:
				dv = Flow2.neighbors_in(dv2)
				firstN.append([dv[0],dv2])
		for [v,b] in firstN:
			## IGNORE TOOO SMALL EDGES ---> NUMERICAL NOISE...
			if Flow2.edge_label(v,b) > 0.00001:
				name = Flow2.neighbors_in(v)[0][:-3]
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
				gFAA.append([_face_2_ints([_name_face_vertex(i)[2:]]),[]])
		return gFAA
		  
def _calculate_2_flow(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow):
	H = _graph_2_flow(graph, outer_face, suspensions)
	flow1 = _give_flow_1(graph,outer_face,suspensions)
	flow2 = _give_flow_2(graph,outer_face,suspensions)
	if check_just_non_int_flow:
		try:
			Flow = [H.multicommodity_flow([['i1','o1',flow1],['i2','o2',flow2]],use_edge_labels=True,integer = False,verbose = 0) , None]
			aL = _give_angle_edges(Flow[0][1])
			integral_flow = len(aL)==flow2
			if integral_flow:
				return Flow
			while not integral_flow:
				(faa,Flow2) = _get_faa_from_non_int_solution(aL,flow2)
				H.delete_edges(faa)
				(f,Flow1) = H.flow('i1','o1',value_only=False,use_edge_labels=True,integer = True)
				if flow1 == f:
					return [[Flow1,Flow2],True]
				else:
					print_info(graph, outer_face, suspensions, check_non_int_flow, check_just_non_int_flow)
					raise ValueError("Counter Example Found :(")
		except:
			pass
	else:	
		try:
			return [H.multicommodity_flow([['i1','o1',flow1],['i2','o2',flow2]],use_edge_labels=True,integer = True) , True]
		except EmptySetError:
			H2 = copy(H)
			H2.add_edges([['i1','i2',flow2],['o2','o1',flow2]])
			[f1,sol] = H2.edge_cut('i1','o1', value_only=False, use_edge_labels=True)
			print "one_flow",(flow1,flow2,f1)
			if f1 == flow1+flow2:
				C = H.multiway_cut(['i1','i2','o1','o2'], value_only=False, use_edge_labels=True, solver=None, verbose=0)
				c = 0
				for edge in C:
					c += edge[2]
				print C
				print "cut",(flow1,flow2,c)
				if flow1+flow2==c:
					l = []
					sol = Graph(sol)
					for v in sol.vertices():
						if v[:2] == 'DV':
							if sol.edge_label(v,'o2') == 1:
								l.append(v)
					print (len(l),flow2)
					aL = _give_angle_edges(H)
					for i in range(100):
						(faa,Flow2) = _get_faa_from_non_int_solution(aL,flow2)
						H2 = copy(H)
						H2.delete_edges(faa)
						[f1,sol] = H2.flow('i1','o1', value_only=False, integer=True, use_edge_labels=True)
						if mod(i,10) == 0:
							print i
						if f1 == flow1:
							print 'ups'
			else:
				#print sol
				# print graph.sparse6_string()
				# print outer_face
				# print suspensions
				pass
		if check_non_int_flow:
			try:
				Flow = [H.multicommodity_flow([['i1','o1',flow1],['i2','o2',flow2]],use_edge_labels=True,integer = False) , False]
				print "Only non integer flow found"
				print_info(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow)
			except EmptySetError:
				pass
	return [None,False]
	
def _graph_2_flow(G,outer_face,suspensions):
	## G is a planar, suspended, internally 3-connected graph ##
	H = DiGraph()
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
	flow1 = 0
	for face in G.faces():
		if len(face) > 3:
			flow1 += 3
	if len(outer_face) > 3:
		flow1 -= 3
	flow1 += len(G.edges()) - len(outer_face)
	return flow1

def _give_flow_2(G,outer_face,suspensions):
	## sum(F_int -3)
	flow2 = -len(outer_face) + 3
	for face in G.faces():
		flow2 += ( len(face) - 3 )
	return flow2

def _face_2_flow(H,face):
	## H is the new FlowGraph ##
	name = _name_face_vertex(face)
	if len(face) > 3:
		H.add_vertex(name)
		H.add_edges([('i1','B' + name,3),(name,'o1' , len(face) )])
	_add_outer_ring(H,face,name)

def _add_outer_ring(H,edges,nameFace):
	n = len(edges)
	for i in range(n):
		# edge-vertex
		toAdd1 = _name_edge_vertex(edges[i])
		H.add_edge('i1',toAdd1,1)
		if n > 3:
			## dummy-edge in face
			toAdd2 = _name_edge_vertex(edges[i],edges)
			H.add_edges([(toAdd1,toAdd2,1),(toAdd2,nameFace,1)])
		## edges to adjacent vertex-vertices
		forVName = _name_vertex_vertex(edges[i][1])
		backVName = _name_vertex_vertex(edges[i][0])
		H.add_edges([(toAdd1,forVName,1),(toAdd1,backVName,1)])
		if n > 3:
			# Triangles only needed if face > 3
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
	dummyName2 = 'D2' + node
	H.add_edges([('i2',name + 'T1' , 1),
		( name + 'T2' , dummyName , 1),
		( dummyName , dummyName2 , 1 ),
		( dummyName2 , 'D' + _name_face_vertex(face) , 1 ),
		( 'D' + _name_face_vertex(face) , 'o2' , len(face) - 3 )])
		
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

def is_internally_3_connected(G,suspensions):
	H = copy(G)
	v = H.add_vertex()
	H.add_edges([[v,suspensions[0]],[v,suspensions[1]],[v,suspensions[2]]])
	return H.vertex_connectivity()>2

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
	
def _get_faa_from_non_int_solution(aL,flow2):
	faa = []
	used_V_out = []
	shuffle(aL)
	Flow2 = DiGraph()
	all_V_out = []
	for edge in aL:
		name = edge[0].split()[1]
		name1 = 'DV:'+name
		if edge[2] > 0.999:
			faa.append(edge)
			name2 = 'D2V:' + name
			name3 = 'D3V:' + name
			used_V_out.append(name1)
			Flow2.add_edge(name3,'o2',1)
			Flow2.add_edge(name2,name3,1)
			Flow2.add_edge(name1,name2,1)
			Flow2.add_edge(edge[0],edge[1],1)
			Flow2.add_edge(edge[1],name1,1)
		all_V_out.append(name1)
	if len(all_V_out) == flow2:
		print aL
	for edge in aL:
		if len(faa) >= flow2:
			break
		if 0.001  < edge[2] <= 0.999:
			name = edge[0].split()[1]
			name1 = 'DV:'+name
			if name1 not in used_V_out:
				faa.append(edge)
				name2 = 'D2V:'+name
				name3 = 'D3V:'+name
				used_V_out.append(name)
				Flow2.add_edge(name3,'o2',1)
				Flow2.add_edge(name2,name3,1)
				Flow2.add_edge(name1,name2,1)
				Flow2.add_edge(edge[0],edge[1],1)
				Flow2.add_edge(edge[1],name1,1)
	return (faa,Flow2)		

##### TEST STUFF ###################################################################################################################################################
####################################################################################################################################################################
####################################################################################################################################################################
####################################################################################################################################################################

def _check_non_int_flow(Flow,graph):
	E = _give_non_int_edges(Flow[0],graph)
	if len(E) > 0:
		print "Non-int-flow"
	t3_t4 = False
	for e in E:
		if e[0][-2:] == 'T3' and e[1][-2:] == 'T4':
			t3_t4 = True
	if t3_t4:
		print 'Flow1'
		print E	


def _check_cut(H,Flow,flow1,flow2):
	F = copy(H)
	aL = _give_angle_edges(H)
	shuffle(aL)
	vL = _give_dummy_vertices(Flow[0][1])
	dL = []
	for i in range(flow2):
		v = vL[i]
		string = v + ",T2"
		l = len(string)
		for a in aL:
			a[-l:] == string
			dL.append(a)
			break
	F.delete_edges(dL)
	print "cut"
	print flow1
	print flow2
	print F.edge_cut('i1', 'o1', value_only=False, use_edge_labels=True)

def _give_dummy_vertices(Flow1):
	vL = []
	for v in Flow1.vertices():
		if v[:1] == 'D':
			vL.append(v)
	shuffle(vL)
	return vL

def _give_angle_edges(H):
	aL = []
	for edge in H.edges():
		if str(edge[0])[-2:] == 'T1':
			## Clean numerical noise ##
			if 0.00001 < edge[2]:
				aL.append(edge)
	return aL

def _check_max_flows(H,flow1,flow2):
	F = copy(H)
	F1 = F.flow('i1','o1', value_only=False, integer=True, use_edge_labels=True)
	F.delete_edges(F1[1].edges())
	F2 = F.flow('i2','o2', value_only=True, integer=True, use_edge_labels=True)
	print flow2 - F2

def _give_edge_vertex_edges(H):
	aL = []
	for edge in H.edges():
		if str(edge[0])[:1] == 'E':
			if 0.001 < edge[2] < 0.999:
				aL.append(edge)
	return aL

def _give_non_int_edges(H,graph):
	aL = []
	zero = False
	for e in H.edges():
		if 0.001 < e[2] < 0.999:
			aL.append(e)
	return aL

##### TEST STUFF END ###############################################################################################################################################
####################################################################################################################################################################	
####################################################################################################################################################################
####################################################################################################################################################################
	
def _interior_faces(G,oF = None, sus = None):
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
		
##### PLOTTING ###################################################################################################################################################
####################################################################################################################################################################
####################################################################################################################################################################
####################################################################################################################################################################

def plot_planar_graph(graph):
	P = graph.layout(layout='planar',set_embedding = True)
	show(graph.plot(pos=P))	

def plot_sltr_or_approximation(G,sus=None,outer_face=None, ipe = None):
	graph=copy(G)
	faa = get_sltr(graph,suspensions=sus,outer_face=outer_face)
	if faa != None:
		[Plot,G] = plot_sltr(graph,faa=faa,plotting = False)
	else:
		[Plot,G] = plot_approximation_to_sltr(graph,sus=sus,outer_face=outer_face,plotting=False)
	if Plot != None and ipe != None:
		graph2ipe(G,ipe)
	if Plot != None:
		Plot.show(axes = False)

def plot_sltr(graph,suspensions=None,outer_face = None, faa = None,plotting=True):
	if faa == None:
		faa = get_sltr(graph,suspensions=suspensions,outer_face=outer_face)
	if faa[0] != None:
		layout = _get_good_faa_layout(graph,faa,suspensions=suspensions)
		graph.set_pos(layout)
		Plot = graph.plot(axes = False)
		if plotting:
			show(Plot)
		return [Plot,graph]
	else:
		print "No SLTR found for given parameters"

def plot_approximation_to_sltr(graph,sus=None,outer_face=None,plotting=True):
	ultimate = 2 ## at most ultimate triangulated faces
	if sus != None:
		if outer_face == None:
			for outer_face in graph.faces():
				if _is_outer_face(outer_face, sus):
					break
	[Plot,graph] = plot_problem_graph(graph,ultimate,outer_face,sus)
	if plotting:
		Plot.show(axes = False)
	if Plot != None:
		return [Plot,graph]
	else:
		print('No close drawing found with at most ' + str(ultimate) + ' triangulated faces.')


def plot_problem_graph(graph,ultimate,outer_face,sus=None):
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
	pos = _get_good_faa_layout_iteration(G,faa,faa_dict,0,suspensions,None)
	return pos

def _get_good_faa_layout_iteration(G,faa,faa_dict,count,suspensions,weights):
	constant = 1
	V = G.vertices()
	n = len(V)
	count += 1
	sol = _get_plotting_matrix_iteration(G,suspensions,faa_dict,weights)
	pos = {V[i]:sol[i] for i in range(n)}
	G.set_pos(pos)
	weights2 = _calculate_weights(G,faa,faa_dict,suspensions,count)
	if weights != None:
		M = weights-weights2
		norm = M.norm()
		if norm < constant or count == 50:
			return pos
	return _get_good_faa_layout_iteration(G,faa,faa_dict,count,suspensions,weights2)	
	
	

def _calculate_weights(G,faa,faa_dict,suspensions,count):
	V = G.vertices()
	n = len(V)
	W = zero_matrix(RR,n,n)
	pos = G.get_pos()

	##weights for edges ##

	# for E in G.edges():
	# 	print E
	# 	[v1,v2,l] = _segment(E,faa_dict)
	# 	q = _get_edge_length([v1,v2],pos)
	# 	i0 = V.index(v1)
	# 	i1 = V.index(v2)
	# 	W[i0,i1] += q^5
	# 	W[i1,i0] += q^5

# weights for faces ##	
		
	for face in G.faces():
		p = _get_face_area(face,pos)
		for E in face:
			[v1,v2,l] = _segment(E,face,faa)
			q = _get_edge_length([v1,v2],pos)
			i0 = V.index(E[0])
			i1 = V.index(E[1])
			W[i0,i1] += p 
			W[i1,i0] += p 
	
# weights for assigned ##

	# for v in V:
	# 	if faa_dict.has_key(v):
	# 		[v1,v2] = faa_dict[v]
	# 		[e1,e2,l] = _segment([v,v1,None],faa_dict)
	# 		q = _get_edge_length([e1,e2],pos)
	# 		i0 = V.index(v)
	# 		i1 = V.index(v1)
	# 		i2 = V.index(v2)
	# 		W[i0,i1] += q/l
	# 		W[i1,i0] += q/l

# # weights for not assigned ##
# 	for [face,ass] in faa:
# 		c = copy(face)
# 		for a in ass:
# 			c.remove(a)
# 		x1 = pos[c[0]][0]
# 		y1 = pos[c[0]][1]
# 		x2 = pos[c[1]][0]
# 		y2 = pos[c[1]][1]
# 		x3 = pos[c[2]][0]
# 		y3 = pos[c[2]][1]
# 		area = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
# 		area = abs(area/2)
# 		for i in range(len(face)):
# 			if face[i] not in ass:
# 				i0 = V.index(face[mod(i-1,len(face))])
# 				i1 = V.index(face[i])
# 				i2 = V.index(face[mod(i+1,len(face))])
# 				W[i0,i1] += area^2
# 				W[i1,i0] += area^2
# 				W[i1,i2] += area^2
# 				W[i2,i1] += area^2
	return W

def _quadrant_weigth(graph,vertex,face,pos)
	n = len(face)
	for i in range(n):
		if face[i][0] == vertex:
			v_l = face[mod(i-1,n)][0]
			v_r = face[mod(i-1,n)][1]
			break
	x_v = pos[vertex][0]
	y_v = pos[vertex][1]
	x_l = pos[v_l][0]
	y_l = pos[v_l][1]
	x_r = pos[v_r][0]
	y_r = pos[v_r][1]
	l = [[],[],[]]
	for v in G.vertices():
		if 


def _segment(edge,face,faa):
	[e1,e2] = [edge[0],edge[1]]
	[d1,d2] = [e1,e2]
	[b1,b2] = [True,True]
	l = 1
	node_face = []
	for e in face:
		node_face.append(e[0])
	for [f,a] in faa:
		if f == node_face:
			n = len(f)
			f = f+f+f
			for i in range(n,2*n):
				if f[i] == e1:
					if f[i-1] == e2:
						j1 = i
						j2 = i-1
						while b1:
							if f[j1] in a:
								j1 += 1
								d1 = f[j1]
								l += 1
							else:
								b1 = False
						while b2:
							if f[j2] in a:
								j2 -= 1
								d2 = f[j2]
								l += 1
							else:
								b2 = False
					else:
						if f[i+1] == e2:
							j1 = i
							j2 = i+1
							while b1:
								if f[j1] in a:
									j1 -= 1
									d1 = f[j1]
									l += 1
								else:
									b1 = False
							while b2:
								if f[j2] in a:
									j2 += 1
									d2 = f[j2]
									l += 1
								else:
									b2 = False
	return [d1,d2,l]
	
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
	a0 = pi/2
	a1 = pi/2 + pi*2/3
	a2 = pi/2 + pi*4/3
	pos[suspensions[0]] = (100*cos(a0),100*sin(a0))
	pos[suspensions[1]] = (100*cos(a1),100*sin(a1))
	pos[suspensions[2]] = (100*cos(a2),100*sin(a2))

## True gives flat triangle for pictures
	flat_triangle = False
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
			if faa_dict.has_key(v):
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

def _has_sltr_with_tri(graph,suspensions=None,outer_face=None,check_just_non_int_flow=False):
	if suspensions != None:
		return _has_separating_triangle_sltr(graph,outer_face,suspensions,check_just_non_int_flow)
	else:					
		## We will check all possible triplets as suspensions ##
		if outer_face != None: 
			## outer face is given
			for suspensions in _give_suspension_list(graph,outer_face):
				if _has_separating_triangle_sltr(graph,outer_face,suspensions,check_just_non_int_flow):
					return True
			return False
		else:
			## Checking all outer faces and all suspensions ##
			for outer_face in graph.faces():
				for suspensions in _give_suspension_list(graph,outer_face):
					if _has_separating_triangle_sltr(graph,outer_face,suspensions,check_just_non_int_flow):
						return True
			return False

def _has_separating_triangle_sltr(graph,outer_face,suspensions,check_just_non_int_flow):
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
			if _check_parts(graph,graph_parts,triangle,outer_face,suspensions,check_just_non_int_flow):
				return True
		return False
	return has_sltr(graph,outer_face=outer_face,suspensions=suspensions,check_just_non_int_flow=check_just_non_int_flow,with_tri_check=False)

def _av(list_item):
	return abs(len(list_item[0][0])-len(list_item[0][1]))

def _check_parts(graph,graph_parts,triangle,outer_face,suspensions,check_just_non_int_flow):
	if len(graph_parts) > 2:
		return False
	[g1,g2] = graph_parts
	if _check_order(graph,g1,g2,triangle,outer_face,suspensions,check_just_non_int_flow):
		return True
	return False

def _check_order(graph,vertices_one,vertices_two,triangle,outer_face,suspensions,check_just_non_int_flow):
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
		if not _has_separating_triangle_sltr(outer_graph,outer_face,suspensions,check_just_non_int_flow):
			return False
	## stuff for inner graph ##
	inner_graph = copy(graph)
	inner_graph.delete_vertices(outer_vertices)
	if len(inner_graph.vertices()) > 7:
		for face in inner_graph.faces():
			if _is_outer_face(face,triangle):
				inner_face = face
				break
		return _has_separating_triangle_sltr(inner_graph,inner_face,triangle,check_just_non_int_flow)
	return True

def print_info(graph,outer_face,suspensions,check_non_int_flow,check_just_non_int_flow,embedding=None):
	print "Graph  " + graph.sparse6_string()
	print "Face:  " + str(outer_face)
	print "Suspensions:  " + str(suspensions)
	print "Check non int = " + str(check_non_int_flow)
	print "Check just non int = " + str(check_non_int_flow)
	if embedding != None:
		print "Embedding = " + str(embedding)
