import time
import random

def run_iterator_test(nodes,print_info=True):
	just_one_face = False
	start = time.time()
	SLTR = [0]*500
	FAA = [0]*500
	No_FAA = [0]*500
	Has_SLTR = []
	Only_FAA = []
	Nothing = []
	Only_non_int_flow = []
	i = 0
	j = 0
	for graph in graphs.planar_graphs(nodes+1, minimum_connectivity=3):
		if j < 394:
			pass
		else:
			for [G,suspensions,outer_face] in give_internally_3_con_graphs_with_sus(graph):
				entry = G
				if entry in Has_SLTR or entry in Only_FAA or entry in Nothing:
					pass
				else:
					en =  len(G.edges())
					if has_faa(G):
						sltr = has_sltr(G,suspensions=suspensions,outer_face=outer_face)
						if sltr:
							SLTR[en] = SLTR[en] + 1
							Has_SLTR.append(entry)
						else:
							Only_FAA.append(entry)
							FAA[en] = FAA[en] + 1
					else:
						No_FAA[en] = No_FAA[en] + 1
						Nothing.append(entry)
					i = i+1
		j += 1
		if print_info:
					if mod(j,1) == 0:
						print (j,i)
	if print_info:
		print "Finished checking graphs on " + str(nodes) + " nodes."
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
	end = time.time()
	print "Took " + str(int(end-start)) + " seconds."
	return [Has_SLTR,Only_FAA,Nothing]

def run_iterator_test_with_iso_check(nodes):
	L = run_iterator_test(nodes)
	gL = [[],[],[]]
	for i in range(3):
		for G in L[i]:
			isnot = True
			for H in gL[i]:
				if G.is_isomorphic(H):
					isnot = False
					break
			if isnot:
				gL[i].append(G)
	check_lists(gL)

def check_lists(gL):
	SLTR = [0]*500
	FAA = [0]*500
	No_FAA = [0]*500
	for j in range(3):
		for graph in gL[j]:
			en = len(graph.edges())
			if j == 0:
				SLTR[en] = SLTR[en] + 1
			if j == 1:
				FAA[en] = FAA[en] + 1
			if j == 2:
				No_FAA[en] = No_FAA[en] + 1
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


def mini_test(nodes,number,print_info=True):
	start = time.time()
	SLTR = [0]*500
	FAA = [0]*500
	No_FAA = [0]*500
	Has_SLTR = []
	Only_non_int_flow = []
	for i in range(number):
		if print_info: 
			if mod(i,5) == 0:
				print i
		[graph,suspensions,outer_face] = random_int_3_graph(nodes)
		en = len(G.edges())
		if has_faa(G):
			sltr = get_sltr(graph,suspensions=suspensions,outer_face=outer_face,check_non_int_flow=True,check_just_non_int_flow = True)
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
	end = time.time()
	print "Took " + str(int(end-start)) + " seconds."
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
			if mod(i,4405) == 0:
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
					print G.sparse6_string()
		i = i+1
	if print_info:
		print "Finished checking all graphs on " + str(nodes) + " nodes and found " + str(len(SLTR_only_some_faces)) + " graphs."
	return SLTR_only_some_faces

def check_vertex_edge_crit_sltr(nodes,edges):
	if nodes > 8 and edges > ((nodes-4)*3):
		return True
	return False

def check_vertex_edge_crit_no_sltr(nodes,edges):
	if nodes > 4 and edges < ((nodes-2)*2)+1:
		return True
	return False

def get_dual(graph):
	graph.allow_multiple_edges(False)
	graph.allow_loops(False)
	dual = graph.planar_dual()
	dual.relabel()
	return dual

def give_internally_3_con_graphs_with_sus(graph):
	glist = []
	for v in graph.vertices():
		Nv = graph.neighbors(v)
		print "node: " + str(v) + "  neigh:  " + str(Nv)
		print graph.edges()
		for j in Combinations(len(Nv),3):
			G = copy(graph)
			suspensions = ( Nv[j[0]] , Nv[j[1]] , Nv[j[2]] )
			for n in Nv:
				if n not in suspensions:
					G.delete_edge(n,v)
			if G.vertex_connectivity > 2:
				G.delete_vertex(v)
				outer_face = _give_resulting_outer_face(G,Nv)
				print "moving"
				print G.faces()
				print outer_face
				print suspensions
				print ".."
				glist.append([G,suspensions,outer_face])
	return glist

def _give_resulting_outer_face(graph,neighbors):
	print "faces: " + str(graph.faces())
	for face in graph.faces():
		found = True
		vertex_list = []
		for edge in face:
			vertex_list.append(edge[0])
		print "v" + str(vertex_list)
		print "n" + str(neighbors)
		for n in neighbors:
			if not n in vertex_list:
				found = False
		if found:
			print "found"
			return face
	raise ValueError("No outer face found.")
