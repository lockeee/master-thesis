import random
load("sltr.sage")
load("faa.sage")


def random_3_graph(nodes):
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
		return random_3_graph(nodes)

def choose_split_face_edge():
	#true if face else false
	cut1 = 300
	cut2 = 900 
	n = randint(0,1000)
	if n < cut1:
		return 1
	if n < cut2:
		return 2
	return 3	

def add_vertex_via_split(graph):
	list_of_vertices = []
	for vertex in graph.vertices():
		if graph.degree(vertex) > 3:
			list_of_vertices .append(vertex)
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



def mini_test(nodes,number,print_info=True):
	SLTR = [0]*100
	FAA = [0]*100
	No_FAA = [0]*100
	Only_FAA = []
	Only_non_int_flow = []
	for i in range(number):
		if print_info:
			print i
		G = random_3_graph(nodes)
		en =  len(G.edges())
		if has_faa(G):
			sltr = get_sltr(G)
			if sltr == None:
				Only_FAA.append(G.sparse6_string())
				FAA[en] = FAA[en] + 1
			else:
				SLTR[en] = SLTR[en] + 1
		else:
			No_FAA[en] = No_FAA[en] + 1
	if print_info:
		print "Finished checking some graphs on " + str(nodes) + " nodes."
		str1 = ""
		str2 = ""
		str3 = ""
		for i in range(100):
			if SLTR[i] != 0:
				str1 = str1 + " / " + str(i) + "-" + str(SLTR[i]) 
			if FAA[i] != 0:
				str2 = str2 + " / " + str(i) + "-" + str(FAA[i])
			if No_FAA[i] != 0:
				str3 = str3 + " / " + str(i) + "-" + str(No_FAA[i]) 
		print "SLTR:" + str1
		print "Only FAA:" + str2
		print "Neither:" + str3
		print
		print "List of Only FAA graphs:"
		print Only_FAA
	return _test_sparse_graphs(Only_FAA,print_info=print_info)


def _test_sparse_graphs(string_list,print_info=True):
	Only_non_int_flow = []
	if print_info:
		print "Checking for non integer multi-flow-solution in only FAA graphs..."
	for faa in string_list:
		if print_info:
			print "Checking: " + faa
		sltr = get_sltr(G,check_non_int_flow=True,check_all_faces=True)
		if sltr != None:
			sltr = get_sltr(G)
			if sltr != None:
				print "Mistake found?! -- " + faa.sparse6_string()
			else:
				Only_non_int_flow.append(faa.sparse6_string())
	return Only_non_int_flow







