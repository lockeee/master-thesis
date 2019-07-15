import random

def _choose_split_face_edge(cut1 = None,cut2=None,cut3=None):
	if cut1 ==None:
		cut1 = 400 	## Adds one vertex and one edge
	if cut2 ==None:	
		cut2 = 630 	## Adds one vertex and two edges
	if cut3 ==None:
		cut3 = 100  ## Triangulates random face --> >2 edges
	## Else adds random edge in Graph

	n = randint(0,1000)
	if n < cut1:
		return 1
	if n < cut2:
		return 2
	if n < cut3:
		return 3
	return 4

def random_3_graph(nodes,cut=None):
	## Starting with a K_4
	G = Graph([(0, 1, None), (0, 2, None), (0, 3, None), (1, 2, None), (1, 3, None), (2, 3, None)])
	while len(G.vertices())<nodes:
		if cut != None:
			index = _choose_split_face_edge(cut1=cut[0],cut2=cut[1],cut3=cut[2])
		else:
			index = _choose_split_face_edge()
		if index == 1:
			l = len(G.vertices())
			G = _add_vertex_via_split(G)
			if len( G.vertices() ) == l:
				index = 2
		if index == 2:
			G = _add_vertex_on_edge(G)
		if index == 3:
			G = _add_vertex_in_face(G)
		if index == 4:
			G = _add_edge_in_face(G)
	face = G.faces()[randint(0,len(G.faces())-1)]
	l2 = _give_suspension_list(G,face)
	suspensions = l2[randint(0,len(l2)-1)]
	return [G,suspensions,face,None]

def random_int_3_graph(nodes):
	if randint(0,10) < 3:
		[G,suspensions,face,embedding] = random_3_graph(nodes)
		face = G.faces()[randint(0,len(G.faces())-1)]
		l2 = _give_suspension_list(G,face)
		suspensions = l2[randint(0,len(l2)-1)]
		return [G,suspensions,face,None]
	else:
		[G,suspensions,face,embedding] = random_3_graph(nodes+1)
		return _give_one_internally_3_con_graph_with_sus(G)


def _add_vertex_via_split(graph):
	## Adds one vertex and one edge
	list_of_vertices = []
	for vertex in graph.vertices():
		if graph.degree(vertex) > 3:
			list_of_vertices.append(vertex)
	if len(list_of_vertices) > 0 :
		push_vertex = list_of_vertices[randint(0,len(list_of_vertices)-1)]
		deg_vert = graph.degree(push_vertex)
		r = range(2,deg_vert-1)
		sN = _sorted_neighbors(graph,push_vertex)
		random.shuffle(r)
		add_vertex = graph.add_vertex()
		graph.add_edge(push_vertex,add_vertex)
		for i in range(r[0]):
			graph.delete_edge(push_vertex,sN[i])
			graph.add_edge(add_vertex,sN[i])
	return graph

def _sorted_neighbors(G,v):
	n = len(G.neighbors(v))
	N = G.neighbors(v)[randint(0,n-1)]
	sN = [N]
	edge = (v,N)
	while True:
		for face in G.faces():
			stop = False
			if edge in face:
				for E in face:
					if E[1] == v:
						sN.append(E[0])
						edge = (v,E[0])
						if len(sN) == n:
							if randint(0,1) == 1:
								sN.reverse()
							return sN
						break

def _add_vertex_on_edge(graph):
	## Adds one vertex and two edges
	n = randint(0,len(graph.edges())-1)
	edge1 = graph.edges()[n]
	edge2 = (edge1[1],edge1[0],None)
	face1 = []
	face2 = []
	for face in graph.faces():
		if (edge1[0],edge1[1]) in face:
			face1 = face
		if (edge2[0],edge2[1]) in face:
			face2 = face
	vertices = []
	for edge in face1+face2:
		if edge[0] not in edge1:
			vertices.append(edge[0])
	vertices_to_connect = _vertices_edge(vertices)
	graph.delete_edge(edge1)
	new_vertex = graph.add_vertex()
	graph.add_edges([[new_vertex,edge1[0]],[new_vertex,edge1[1]]])
	for vertex in vertices_to_connect:
		graph.add_edge(new_vertex,vertex)
	return graph


def _add_vertex_in_face(graph):
	## adds one vertex and >2 edges
	face = graph.faces()[randint(0,len(graph.faces())-1)]
	vertices = []
	for edge in face:
		vertices.append(edge[0])
	vertices_to_connect = _vertices_face(vertices)
	new_vertex = graph.add_vertex()
	for vertex in vertices_to_connect:
		graph.add_edge(new_vertex,vertex)
	return graph

def _add_edge_in_face(graph):
	## adds one edge in face
	fl = []
	for face in graph.faces():
		if len(face) > 2:
			b = randint(0,len(face)-1)
			n = randint(2,len(face)-1)
			a = (b+n)%len(face)
			graph.add_edge(face[b][0],face[a][0])
	return graph	

def _vertices_face(list_of_vertices):
	n = randint(3,len(list_of_vertices))
	index = list(range(len(list_of_vertices)))
	random.shuffle(index)
	vertices_to_connect = []
	for i in range(n):
		vertices_to_connect.append(list_of_vertices[index[i]])
	return vertices_to_connect

def _vertices_edge(list_of_vertices):
	n = 1 
	index = list(range(len(list_of_vertices)))
	random.shuffle(index)
	vertices_to_connect = []
	for i in range(n):
		vertices_to_connect.append(list_of_vertices[index[i]])
	return vertices_to_connect

def _give_one_internally_3_con_graph_with_sus(graph):
	vL = graph.vertices()	
	iterator = range(len(vL))
	shuffle(iterator)
	for i in iterator:
		v = graph.vertices()[i]
		Nv = graph.neighbors(v)
		sL = []
		for j in Combinations(len(Nv),3):
			suspensions = ( Nv[j[0]] , Nv[j[1]] , Nv[j[2]] )
			sL.append(suspensions)
		shuffle(sL)
		for suspensions in sL:	
			G = copy(graph)
			G.set_pos(pos=G.layout(layout='planar',set_embedding = True))
			embedding = G.get_embedding()
			new_embedding = _make_new_dict(embedding,v)
			G.delete_vertex(v)
			outer_face = _give_resulting_outer_face(G,Nv,new_embedding)
			if is_internally_3_connected(G,suspensions):
				return [G,suspensions,outer_face,new_embedding]

def _make_new_dict(D,v):
	nD = dict()
	for en in D.iteritems():
		if en[0] != v:
			n = []
			for i in en[1]:
				if i != v:
					n.append(i)
			nD[en[0]] = n
	return nD

def _give_resulting_outer_face(graph,neighbors,embedding):
	for face in graph.faces(embedding=embedding):
		found = True
		vertex_list = []
		for edge in face:
			vertex_list.append(edge[0])
		for n in neighbors:
			if not n in vertex_list:
				found = False
		if found:
			return face
	raise ValueError("No outer face found for edges: " + str(graph.edges()) + ", faces: " + str(graph.faces()) + " and neighbors: " + str(neighbors))




