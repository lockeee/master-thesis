
def run_iterator_test(nodes,print_info=True):
	SLTR = [0]*500
	FAA = [0]*500
	No_FAA = [0]*500
	Only_FAA = []
	Only_non_int_flow = []
	i = 0
	for G in graphs.planar_graphs(nodes, minimum_connectivity=3,minimum_degree=4):
		if print_info:
			if mod(i,100) == 0:
				print i
		en =  len(G.edges())
		# Check for vertex/edge ratio:
		if check_vertex_edge_crit(nodes,en):
				SLTR[en] = SLTR[en] + 1
		else:
			if has_faa(G):
				sltr = get_sltr(G)
				if sltr == None:
					Only_FAA.append(G.sparse6_string())
					FAA[en] = FAA[en] + 1
				else:
					SLTR[en] = SLTR[en] + 1
			else:
				No_FAA[en] = No_FAA[en] + 1

			
		i = i+1
	if print_info:
		print "Finished checking all graphs on " + str(nodes) + " nodes."
		str1 = ""
		str2 = ""
		str3 = ""
		for i in range(500):
			if SLTR[i] != 0:
				str1 = str1 + " / " + str(i) + "-" + str(SLTR[i]) 
			if FAA[i] != 0:
				str2 = str2 + " / " + str(i) + "-" + str(FAA[i])
			if No_FAA[i] != 0:
				str3 = str3 + " / " + str(i) + "-" + str(No_FAA[i]) 
		print "SLTR:" + str1
		print "Only FAA:" + str2
		print "Neither:" + str3
	print _test_sparse_graphs(Only_FAA,print_info=print_info)
	return Only_FAA


def mini_test(nodes,number,print_info=True):
	SLTR = [0]*500
	FAA = [0]*500
	No_FAA = [0]*500
	Has_SLTR = []
	Only_non_int_flow = []
	for i in range(number):
		if print_info: 
			if mod(i,5) == 0:
				print i
		G = random_3_graph(nodes)
		en =  len(G.edges())
		if has_faa(G):
			sltr = get_sltr(G)
			if sltr == None:
				FAA[en] = FAA[en] + 1
			else:
				SLTR[en] = SLTR[en] + 1
				Has_SLTR.append(G)
		else:
			No_FAA[en] = No_FAA[en] + 1
	if print_info:
		print "Finished checking some graphs on " + str(nodes) + " nodes."
		str1 = ""
		str2 = ""
		str3 = ""
		for i in range(500):
			if SLTR[i] != 0:
				str1 = str1 + " / " + str(i) + "-" + str(SLTR[i]) 
			if FAA[i] != 0:
				str2 = str2 + " / " + str(i) + "-" + str(FAA[i])
			if No_FAA[i] != 0:
				str3 = str3 + " / " + str(i) + "-" + str(No_FAA[i]) 
		print "SLTR:" + str1
		print "Only FAA:" + str2
		print "Neither:" + str3
	#print _test_sparse_graphs(Only_FAA,print_info=print_info)
	return Has_SLTR

def _test_sparse_graphs(string_list,print_info=True):
	Only_non_int_flow = []
	if print_info:
		print "Checking for non integer multi-flow-solution in only FAA graphs..."
	for faa in string_list:
		G = Graph(faa)
		sltr = get_sltr(G,check_non_int_flow=True)
		if sltr != None:
			sltr = get_sltr(G)
			if sltr != None:
				print "Mistake found?! -- " + faa.sparse6_string()
			else:
				Only_non_int_flow.append(faa.sparse6_string())
	return Only_non_int_flow

def rerun_non_sltr():
	with open("Non-SLTR11.sage","r") as file:
		while True:
			sparse_graph = file.readline()
			if len(sparse_graph) < 5:
				break
			graph = Graph(sparse_graph[1:-3])
			dual = get_dual(graph)
			print has_sltr(dual)



def looking_for_graphs_with_only_some_sltrs(nodes,print_info=True):
	SLTR_only_some_faces = []
	i = 0
	for G in graphs.planar_graphs(nodes, minimum_connectivity=3):
		if print_info:
			if mod(i,20) == 0:
				print i
		if not check_vertex_edge_crit(nodes,len(G.edges())):
			if has_faa(G):
				cf = 0
				cns = 0
				for face in G.faces():
					cf += 1
					sltr = get_sltr(G,outer_face=face)
					if sltr == None:
						cns += 1
				if cns > 0 and cns < cf:
					SLTR_only_some_faces.append(G.sparse6_string())
		i = i+1
	if print_info:
		print "Finished checking all graphs on " + str(nodes) + " nodes and found " + str(len(SLTR_only_some_faces)) + " graphs."
	return SLTR_only_some_faces

def check_vertex_edge_crit(nodes,edges):
	#if nodes > 8 and edges > ((nodes-4)*3):
	#	return True
	return False

def get_dual(graph):
	graph.allow_multiple_edges(False)
	graph.allow_loops(False)
	dual = graph.planar_dual()
	dual.relabel()
	return dual