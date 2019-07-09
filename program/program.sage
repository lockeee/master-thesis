attach("graph2ipe.sage")
attach("pseudo_random_3_graph.sage")
attach("sltr.sage")
attach("faa.sage")

def sltr(graph,suspensions=None,outer_face=None,embedding=None,just_non_int_flow = True,check_non_int_flow=False):
	## returns Good-FAA if found and NONE if not
	return get_sltr(graph,suspensions=suspensions,outer_face=outer_face,embedding=embedding,just_non_int_flow = just_non_int_flow,check_non_int_flow=check_non_int_flow)

def random_sltr(vertices,just_non_int_flow = True,check_non_int_flow=False,plotting=False,ipe=None,cut=None):
	## Creates pseudo random 3 graph and calculates an SLTR
	[G,suspensions,face,embedding] = random_3_graph(vertices,cut=cut)
	gFAA = sltr(G,suspensions=suspensions,outer_face=face,embedding=embedding,just_non_int_flow = just_non_int_flow,check_non_int_flow=check_non_int_flow)
	if gFAA != None and plotting:
		[Plot,G] = plot_sltr(G,suspensions,face,faa = gFAA ,plotting=plotting,ipe=ipe)
	return [G,gFAA]