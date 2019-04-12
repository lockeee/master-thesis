import random

def choose_split_face_edge():
	cut1 = 333 	## Adds one vertex and one edge
	cut2 = 666 	## Adds one vertex and two edges
				## Else triangulates random face --> >2 edges
	n = randint(0,1000)
	if n < cut1:
		return 1
	if n < cut2:
		return 2
	return 3

def random_3_graph(nodes):
	## Starting with a K_4
	G = Graph([(0, 1, None), (0, 2, None), (0, 3, None), (1, 2, None), (1, 3, None), (2, 3, None)])
	while len(G.vertices())<nodes:
		index = choose_split_face_edge()
		if index == 1:
			l = len(G.vertices())
			G = add_vertex_via_split(G)
			if len( G.vertices() ) == l :
				index = 2
		if index == 2:
			G = add_vertex_on_edge(G)
		if index == 3:
			G = add_vertex_in_face(G)
	if G.vertex_connectivity() > 2:
		return G
	else:
		return random_3_graph(node)

def random_int_3_graph(nodes):
	G = random_3_graph(nodes+1)
	return give_one_internally_3_con_graphs_with_sus(G)


def add_vertex_via_split(graph):
	## Adds one vertex and one edge
	list_of_vertices = []
	for vertex in graph.vertices():
		if graph.degree(vertex) > 3:
			list_of_vertices.append(vertex)
	if len(list_of_vertices) > 0 :
		n = randint(0,len(list_of_vertices)-1)
		push_vertex = list_of_vertices[n]
		deg_vert = graph.degree(push_vertex)
		r = range(2,deg_vert-1)
		random.shuffle(r)
		for i in r:
			C = Combinations(range(deg_vert),i)
			C = C.list()
			random.shuffle(C)
			for comb in C:
				G = copy(graph)
				neighbors = G.neighbors(push_vertex)
				add_vertex = G.add_vertex()
				G.add_edge(push_vertex,add_vertex)
				for j in comb:
					G.delete_edge(push_vertex,neighbors[j])
					G.add_edge(add_vertex,neighbors[j])
				if G.is_planar():
					return G
		return graph
	else:
		return graph



def add_vertex_on_edge(graph):
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
	vertices_to_connect = vertices_edge(vertices)
	graph.delete_edge(edge1)
	new_vertex = graph.add_vertex()
	graph.add_edges([[new_vertex,edge1[0]],[new_vertex,edge1[1]]])
	for vertex in vertices_to_connect:
		graph.add_edge(new_vertex,vertex)
	return graph


def add_vertex_in_face(graph):
	## adds one vertex and >2 edges
	n = randint(0,len(graph.faces())-1)
	face = graph.faces()[n]
	vertices = []
	for edge in face:
		vertices.append(edge[0])
	vertices_to_connect = vertices_face(vertices)
	new_vertex = graph.add_vertex()
	for vertex in vertices_to_connect:
		graph.add_edge(new_vertex,vertex)
	return graph

def vertices_face(list_of_vertices):
	n = 3
	index = list(range(len(list_of_vertices)))
	random.shuffle(index)
	vertices_to_connect = []
	for i in range(n):
		vertices_to_connect.append(list_of_vertices[index[i]])
	return vertices_to_connect

def vertices_edge(list_of_vertices):
	n = 1 
	index = list(range(len(list_of_vertices)))
	random.shuffle(index)
	vertices_to_connect = []
	for i in range(n):
		vertices_to_connect.append(list_of_vertices[index[i]])
	return vertices_to_connect

def give_one_internally_3_con_graphs_with_sus(graph):
	vL = graph.vertices()
	vL.shuffle()
	for v in vL:
		Nv = graph.neighbors(v)
		Nv.shuffle()
		sL = []
		for j in Combinations(len(Nv),3):
			suspensions = ( Nv[j[0]] , Nv[j[1]] , Nv[j[2]] )
			sL.append(suspensions)
		sL.shuffle()
		for suspensions in sL:	
			G = copy(graph)
			G.delete_vertex(v)
			if is_internally_3_connected(G,suspensions):
				return G


