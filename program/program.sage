attach("graph2ipe.sage")
attach("pseudo_random_3_graph.sage")
attach("sltr.sage")
attach("faa.sage")

def sltr(graph, suspensions=None, face=None, non_int = True, check_int=True ,plotting=False):
	## returns Good-FAA if found and NONE if not
	return get_sltr(graph,suspensions=suspensions,outer_face=face,embedding=None,just_non_int_flow = non_int,check_non_int_flow=check_int,plotting=plotting)

def random_sltr(vertices, non_int=True, check_int=False, plotting=False, ipe=None, cut=None):
	## Creates pseudo random 3 graph and calculates an SLTR
	[G,suspensions,face,embedding] = random_3_graph(vertices,cut=cut)
	if has_faa(G,suspensions=suspensions):
		gFAA = sltr(G,suspensions=suspensions,outer_face=face,embedding=embedding,just_non_int_flow = non_int,check_non_int_flow=check_int)
		if gFAA != None:
			if plotting:
				[Plot,G] = plot_sltr(G,suspensions,face,faa = gFAA ,plotting=plotting,ipe=ipe)
			return [G,gFAA]
	return[G,None]