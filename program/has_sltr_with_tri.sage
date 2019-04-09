def _has_sltr_with_tri(graph,suspensions=None,outer_face=None):
	if suspensions != None:
		if outer_face != None:
			return _has_separating_triangle_sltr(graph,outer_face,suspensions)
		## We are looking for the outer face ##
		else:
			for outer_face in graph.faces():
				if _is_outer_face(outer_face, suspensions):
					## face is the outer_face ##
					return _has_separating_triangle_sltr(graph,outer_face,suspensions)
	else:					
		## We will check all possible triplets as suspensions ##
		if outer_face != None: 
			## outer face is given
			for suspensions in _give_suspension_list(graph,outer_face):
				return _has_separating_triangle_sltr(graph,outer_face,suspensions)
		else:
			## Checking all outer faces and all suspensions ##
			for outer_face in graph.faces():
				for suspensions in _give_suspension_list(graph,outer_face):
					return _has_separating_triangle_sltr(graph,outer_face,suspensions)

def _has_separating_triangle_sltr(graph,outer_face,suspensions):
	found_separator = False
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
							found_separator = True
							if _check_parts(graph,graph_parts,([V[i],Nv[j],Nv[k]]),outer_face,suspensions):
								return True
	if found_separator:
		return False
	return has_sltr(graph,outer_face=outer_face,suspensions=suspensions,with_tri_check=False)

def _check_parts(graph,graph_parts,triangle,outer_face,suspensions):
	[g1,g2] = graph_parts.connected_components_subgraphs()
	if _check_order(graph,g1.vertices(),g2.vertices(),triangle,outer_face,suspensions):
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