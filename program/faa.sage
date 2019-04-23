import itertools

def has_faa(graph,suspensions=None):
	return has_faa_via_flow(graph,suspensions)

def has_faa_via_flow(graph,suspensions=None):
	#Construct flow graph
	triangulation = True
	count = 0
	H = DiGraph([['source','sink'],[]])
	if suspensions == None:
		for node in graph.vertices():
			H.add_edge(node,'sink',1)
		for face in graph.faces():
			if len(face) > 3:
				triangulation = False
				facename = _name_face_vertex(face)
				H.add_edge('source',facename,len(face)-3)
				count = count + len(face) - 3 
				for edge in face:
					H.add_edge(facename,edge[0],1)	
	else:
		for node in graph.vertices():
			if node not in suspensions:
				H.add_edge(node,'sink',1)
		for face in graph.faces():
			if len(face) > 3:
				triangulation = False
				facename = _name_face_vertex(face)
				H.add_edge('source',facename,len(face)-3)
				count = count + len(face) - 3 
				for edge in face:
					H.add_edge(facename,edge[0],1)
	if triangulation:
		return True
	calculated_flow = H.flow('source','sink', value_only=True, integer=True, use_edge_labels=True, algorithm=None)
	if calculated_flow == count:
		return True
	return False

def _name_face_vertex(face):
	name = ''                  
	for i in range(len(face)):
		name = name+str(face[i][0])+' '
	name = name[:-1]
	return 'F:'+name 
