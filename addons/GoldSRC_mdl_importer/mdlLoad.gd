tool
extends Node
var file
var textures = []
var fileDict = {}
var bones = []
var boneIndex = 0
var boneMap = {}
var matCache = {}
var boneLocalTransforms = []
var boneLocalTransformsInv = []
var seqGroupFiles = []
var textureFiltering

var DFilePath = "res://addons/GoldSRC_mdl_importer/DFile.gd"
var matCapShaderPath = "res://addons/GoldSRC_mdl_importer/matCap.shader"




enum A{
	POSX = 0,
	POSY = 1,
	POSZ = 2,
	ROTX = 3,
	ROTY = 4,
	ROTZ = 5,
}

func clearData():
	textures = []
	fileDict = {}
	bones = []
	boneIndex = 0
	boneMap = {}
	matCache = {}
	boneLocalTransforms = []
	boneLocalTransformsInv = []
	seqGroupFiles = []


func mdlParse(path,textureFilter = false): 
	textureFiltering = textureFilter
	
	clearData()
	var modelName = getModelNameFromPath(path)
	var meshArr = []

	file = load(DFilePath).new()
	if !file.loadFile(path):
		print("model file not found:",path)
		return false
		
	fileDict["magic"] = file.get_String(4)
	
	if  fileDict["magic"] == "IDSQ":
		return null
	
	fileDict["version"] = file.get_32()
	fileDict["name"] = file.get_String(64)
	fileDict["size"] = file.get_32()
	fileDict["eyePosition"] = getVectorXZY(file)
	fileDict["min"] = getVectorXZY(file)
	fileDict["max"] = getVectorXZY(file)
	fileDict["bbmin"] = getVectorXZY(file)
	fileDict["bbmax"] = getVectorXZY(file)
	fileDict["flags"] = file.get_32()
	fileDict["numBones"] = file.get_32()
	fileDict["boneIndex"] = file.get_32()
	fileDict["numbonecontrollers"] = file.get_32()
	fileDict["bonecontrollerindex"] = file.get_32()
	fileDict["numhitboxes"] = file.get_32()
	fileDict["hitboxindex"] = file.get_32()
	fileDict["numseq"] = file.get_32()
	fileDict["seqindex"] = file.get_32()
	fileDict["numseqgroups"] = file.get_32()
	fileDict["seqgroupindex"] = file.get_32()
	fileDict["numTextures"] = file.get_32()
	fileDict["textureindex"] = file.get_32()
	fileDict["texturedataindex"] = file.get_32()
	fileDict["numskinref"] = file.get_32()
	fileDict["numskinfamilies"] = file.get_32()
	fileDict["skinindex"] = file.get_32()
	fileDict["numbodyparts"] = file.get_32()
	fileDict["bodypartindex"] = file.get_32()
	fileDict["numattachments"] = file.get_32()
	fileDict["attachmentindex"] = file.get_32()
	fileDict["soundtable"] = file.get_32()
	fileDict["soundindex"] = file.get_32()
	fileDict["soundgroups"] = file.get_32()
	fileDict["soundgroupindex"] = file.get_32()
	fileDict["numtransitions"] = file.get_32()
	fileDict["transitionindex"] = file.get_32()
	

		
	seqGroupFiles.append(file)
		
	for file in fileDict["numseqgroups"]-1:
		var fileToFind = path.substr(path.find_last("/"))
		fileToFind = fileToFind.split(".")[0]
		fileToFind += "0" + String(file+1) + ".mdl"
		fileToFind = path.substr(0,path.find_last("/")) + fileToFind
		var fExist= File.new()
		var doesExist = fExist.file_exists(fileToFind)
		if doesExist:
			file = load(DFilePath).new()
			file.loadFile(fileToFind)
			seqGroupFiles.append(file)
				
			
		
	file.seek(fileDict["textureindex"])
	for i in fileDict["numTextures"]:
		textures.append(parseTexture())
			
	if fileDict["numTextures"] == 0:
		var searchPath = path.split(".")[0]
		searchPath = searchPath + "t.mdl"
		var fExist= File.new()
		var doesExist = fExist.file_exists(searchPath)
		fExist.close()
					
		if doesExist:
			var textureParse = Node.new()
			var script = load(self.get_script().get_path())
			textureParse.set_script(script)
			add_child(textureParse)
			textures = textureParse.mdlParseTextures(searchPath,textureFilter)
		
	parseBones()
	fileDict["sequences"] = parseSequence()
	if !fileDict["sequences"].empty():
		boneItt3(fileDict["sequences"][0]["blends"][0][0])

	meshArr = parseBodyParts(fileDict["numbodyparts"],modelName)
	var meshNodeArr = []
		

	for m in meshArr:
		var meshNode = MeshInstance.new()
		meshNode.mesh = m["mesh"]
		meshNode.name = m["meshName"]
		meshNode.visible = m["visible"]
		var eyePos = fileDict["eyePosition"]
		meshNodeArr.append(meshNode)
			

	var skel = initSkel()
	skel.name = modelName
		
	if !fileDict["sequences"].empty():
		initSkelAnimations(skel)
		
	for i in meshNodeArr:
		skel.add_child(i)
		i.set_owner(skel)
		
		
	skel.rotation_degrees.x = -90
	skel.rotation_degrees.z = 90

	return skel
	
	
	
func mdlParseTextures(path,textureFilter): 
	textureFiltering = textureFilter
	file = load(DFilePath).new()
	
	if !file.loadFile(path):
		print("file not found")
		return false
		
	fileDict["magic"] = file.get_String(4)
	fileDict["version"] = file.get_32()
	fileDict["name"] = file.get_String(64)
	fileDict["size"] = file.get_32()
	fileDict["eyePosition"] = getVectorXZY(file)
	fileDict["min"] = getVectorXZY(file)
	fileDict["max"] = getVectorXZY(file)
	fileDict["bbmin"] = getVectorXZY(file)
	fileDict["bbmax"] = getVectorXZY(file)
	fileDict["flags"] = file.get_32()
	fileDict["numBones"] = file.get_32()
	fileDict["boneIndex"] = file.get_32()
	fileDict["numbonecontrollers"] = file.get_32()
	fileDict["bonecontrollerindex"] = file.get_32()
	fileDict["numhitboxes"] = file.get_32()
	fileDict["hitboxindex"] = file.get_32()
	fileDict["numseq"] = file.get_32()
	fileDict["seqindex"] = file.get_32()
	fileDict["numseqgroups"] = file.get_32()
	fileDict["seqgroupindex"] = file.get_32()
	fileDict["numTextures"] = file.get_32()
	fileDict["textureindex"] = file.get_32()
	fileDict["texturedataindex"] = file.get_32()
	

	file.seek(fileDict["textureindex"])
	
	
	for i in fileDict["numTextures"]:
		textures.append(parseTexture())
	
	return textures

func saveScene():
	var i = 0
	for c in get_children():
		c.set_owner(self)

	var packed_scene = PackedScene.new()
	packed_scene.pack(self)
	ResourceSaver.save(String(i) + ".tscn", packed_scene)
	

func parseTexture():
	var textureDict = {}

	textureDict["name"] = file.get_String(64)
	textureDict["flags"] = file.get_32()
	textureDict["width"] = file.get_32()
	textureDict["height"] = file.get_32()
	textureDict["index"] = file.get_32()
	
	
	var chrome = false
	var additive = false
	var transparent = false
	var w = textureDict["width"]
	var h =  textureDict["height"]
	
	if textureDict["flags"] & 2  > 0: chrome = true
	if textureDict["flags"] & 64 > 0: transparent = true
	if textureDict["flags"] & 32 > 0: additive = true
	
	
	
	var image = Image.new()
	image.create(w,h,false,Image.FORMAT_RGBA8)
	
	var pPos = file.get_position()
	
	file.seek(textureDict["index"])
	
	var pallete = []
	var colorArr = []
	
	for y in h:
		for x in w:
			var colorIndex = file.get_8()
			colorArr.append(colorIndex)
	

	for c in 256:
		var r = file.get_8() / 255.0
		var g = file.get_8() / 255.0
		var b = file.get_8() / 255.0
		

		pallete.append(Color(r,g,b))
		
	image.lock()
	
	
	for y in h:
		for x in w:
			var colorIndex = colorArr[x+(y*w)]
			
			var color = pallete[colorIndex]
			
			if colorIndex == pallete.size()-1 and transparent:
				color = Color(0,0,0,0)
			
			image.set_pixel(x,y,color)

	
	image.unlock()
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	if !textureFiltering:
		texture.flags -= texture.FLAG_FILTER
		
		
	file.seek(pPos)
	
	return {"texture":texture,"chrome":chrome,"additive":additive,"transparent":transparent}
	

func parseSequence():
	var sequences = []
	file.seek(fileDict["seqindex"])
	for i in fileDict["numseq"]:
		var sequenceDict = {}
		sequenceDict["name"] = file.get_String(32)
		sequenceDict["fps"] = file.get_float32()
		sequenceDict["flags"] = file.get_32()
		sequenceDict["activity"] = file.get_32()
		sequenceDict["actweight"] = file.get_32()
		sequenceDict["numevents"] = file.get_32()
		sequenceDict["eventindex"] = file.get_32()
		sequenceDict["numframes"] = file.get_32()
		sequenceDict["numpivots"] = file.get_32()
		sequenceDict["pivotIndex"] = file.get_32()
		sequenceDict["motionType"] = file.get_32()
		sequenceDict["motionBone"] = file.get_32()
		sequenceDict["linearMovement"] = getVectorXZY(file)
		sequenceDict["autoMovePosIndex"] = file.get_32()
		sequenceDict["autoMovoeAngleIndex"] = file.get_32()
		sequenceDict["bbMin"] = getVectorXZY(file)
		sequenceDict["bbMax"] = getVectorXZY(file)
		sequenceDict["numBlends"] = file.get_32()
		sequenceDict["animIndex"] = file.get_32()
		sequenceDict["blendType0"] = file.get_32()
		sequenceDict["blendType1"] = file.get_32()
		sequenceDict["blendStart0"] = file.get_float32()
		sequenceDict["blendStart1"] = file.get_float32()
		sequenceDict["blendEnd0"] = file.get_float32()
		sequenceDict["blendEnd1"] = file.get_float32()
		sequenceDict["blendParent"] = file.get_float32()
		sequenceDict["seqGroup"] = file.get_32()
		sequenceDict["entryMode"] = file.get_32()
		sequenceDict["exitNode"] = file.get_32()
		sequenceDict["nodeFlags"] = file.get_32()
		sequenceDict["nextFlags"] = file.get_32()
		
		sequenceDict["blends"] = []
	
		
		sequences.append(sequenceDict)
		var preOffset = file.get_position()
		for b in sequenceDict["numBlends"]:
			var blend = parseBlend(sequenceDict["animIndex"],sequenceDict["numBlends"],sequenceDict["numframes"],sequenceDict["seqGroup"])
			sequenceDict["blends"].append(blend)
		file.seek(preOffset)
		
		
	return sequences

func parseBlend(startOffset,numBlends,numFrames,group):
	var sFile = seqGroupFiles[group]
	var numBones = fileDict["numBones"]
	sFile.seek(startOffset)
	
	var boneToOffset = []
	var blendOffsets = []
	
	
	var blendLength = 6 * numBones#a pos and rot for each bone
	for o in numBlends*blendLength:
		blendOffsets.append(sFile.get_16())#an offset for each value xyz rxryryx
	

	var allFrames = []
	for f in numFrames:
		allFrames.append({"pos":[],"rot":[]})
	
	
	for boneIdx in numBones:
		var bone =  bones[boneIdx]
		var boneFrameData = []
		for i in 6:
			var offset = blendOffsets[boneIdx*6+i]
			if offset == 0:
				boneFrameData.append(createEmptyData(numFrames))
			else:
				boneFrameData.append(parseAnimData(numFrames,sFile))

		
		for f in numFrames:
			var bonePos = Vector3(boneFrameData[A.POSX][f],boneFrameData[A.POSY][f],boneFrameData[A.POSZ][f])
			var boneRot = Vector3(boneFrameData[A.ROTX][f],boneFrameData[A.ROTY][f],boneFrameData[A.ROTZ][f])
			
			allFrames[f]["pos"].append(bonePos* bone["scaleP"]) 
			allFrames[f]["rot"].append(boneRot* bone["scaleR"]) 

	return allFrames

func createEmptyData(numFrames):
	var animData = []
	for i in numFrames:
		animData.append(0)
	return animData

func parseAnimData(numFrames,sFile):
	var animData = []
	
	for i in numFrames:
		animData.append(0)
	
	var i = 0
	while i < numFrames:

		var compressedSize = sFile.get_8()
		var uncompressedSize = sFile.get_8()
		var compressedData = []
		for c in compressedSize:
			compressedData.append(sFile.get_16u())
			
		var j = 0
			
		while(j < uncompressedSize and i < numFrames):
			var index = min(compressedSize-1,j)
			animData[i] = compressedData[index]
			j+=1
			i+=1

	return animData
	

func parseBones():
	file.seek(fileDict["boneIndex"])
	for b in fileDict["numBones"]:
		bones.append(parseBone())

func parseBone():
	var boneDict = {}

	boneDict["name"] = file.get_String(32)
	boneDict["parentIndex"] = file.get_32()
	boneDict["unused"] = file.get_32()
	boneDict["x"] = file.get_32()
	boneDict["y"] = file.get_32()
	boneDict["z"] = file.get_32()
	boneDict["rotX"] = file.get_32()
	boneDict["rotY"] = file.get_32()
	boneDict["rotZ"] = file.get_32()
	boneDict["pos"] = getVectorXZY(file)
	boneDict["rot"] =getVectorRot(file)
	boneDict["scaleP"] = getVectorXZY(file)
	boneDict["scaleR"] = getVectorXZY(file)
	boneDict["index"] = String(boneIndex)
	boneDict["transform"] = Transform.IDENTITY

	if boneDict["name"] == "": boneDict["name"] = String(boneIndex)

	boneIndex += 1
	return boneDict



func parseBodyParts(numBodyParts,modelName):
	file.seek(fileDict["bodypartindex"])
	var bodyPartArr = []
	var bodyPartEntry = []
	var meshes = []
	for i in numBodyParts:
		var bodyPart = {}
		bodyPart["name"] = file.get_String(64)
		bodyPart["numModels"] = file.get_32()
		bodyPart["base"] = file.get_32()
		bodyPart["modelIndex"] = file.get_32()
		bodyPartEntry.append(bodyPart)
	
	for b in bodyPartEntry:
		var bodyPartName = b["name"]
		file.seek(b["modelIndex"])
		var isFirst = true
		
		for n in b["numModels"]:
			
			var bodyPartMesh = parseModel()
			if n != 0: bodyPartName += String(n)
			bodyPartArr.append({"mesh":bodyPartMesh,"meshName":bodyPartName,"visible":isFirst})#
			isFirst = false
	
	return bodyPartArr
	

func parseModel():
	var modelDict = {}
	modelDict["name"] = file.get_String(64)
	modelDict["type"] = file.get_32()
	modelDict["boundingRadius"] = file.get_32()
	modelDict["numMesh"] = file.get_32()
	modelDict["meshindex"] = file.get_32()
	modelDict["numverts"] = file.get_32()
	modelDict["vertinfoindex"] = file.get_32()
	modelDict["vertIndex"] = file.get_32()
	modelDict["numNorms"] = file.get_32()
	modelDict["normInfoIndex"] = file.get_32()
	modelDict["normIndex"] = file.get_32()
	modelDict["numGroups"] = file.get_32()
	modelDict["groupsIndex"] = file.get_32()
	var prePos = file.get_position()
	
	var verts = []
	var norms = []
	var boneMap = []
	file.seek(modelDict["vertIndex"])
	for i in range(0,modelDict["numverts"]):
		verts.append(getVectorXZY(file))
	
	file.seek(modelDict["normIndex"])
	for i in range(0,modelDict["numNorms"]):
		norms.append(getVectorXZY(file))
	
	
	file.seek(modelDict["vertinfoindex"])
	for i in range(0,modelDict["numverts"]):
		boneMap.append(file.get_8())
	
	
	var meshs = []
	file.seek(modelDict["meshindex"])

	var runningMesh = null
	
	var lastTextureIdx = -1
	var totalMesh =  ArrayMesh.new()
	
	for i in range(0,modelDict["numMesh"]):
		var meshDict = parseMesh()
		var polyIdx = 0
		for poly in meshDict["triVerts"]:
			var v = []
			var n = []
			var uv = []
			var tex = []
			var bones = []
			
			for vertDict in poly:
				v.append(verts[vertDict["vertIndex"]])
				n.append(norms[vertDict["normIndex"]])
				uv.append(Vector2(vertDict["s"],vertDict["t"]))
				bones.append(boneMap[vertDict["vertIndex"]])
			var type = poly[0]["type"]
			
			var textureIdx = meshDict["skinref"]
			
			
			if runningMesh == null:
				runningMesh = SurfaceTool.new()
				var mat = createMat(textureIdx)
				runningMesh.set_material(mat)
				runningMesh.begin(Mesh.PRIMITIVE_TRIANGLES)
				lastTextureIdx = textureIdx
			
			if lastTextureIdx != textureIdx:#if texture changed
				var mat = createMat(lastTextureIdx)
				runningMesh.set_material(mat)
				runningMesh.commit(totalMesh)
				#totalMesh.surface_set_material(textureIdx,mat)
				runningMesh = SurfaceTool.new()
				runningMesh.begin(Mesh.PRIMITIVE_TRIANGLES)
			
			runningMesh = createMesh(v,n,type,uv,bones,meshDict["skinref"],lastTextureIdx,runningMesh)
			
			
			if i == modelDict["numMesh"]-1 and polyIdx == meshDict["triVerts"].size()-1:
				var test = textureIdx
				var mat = createMat(textureIdx)
				runningMesh.set_material(mat)
				runningMesh.commit(totalMesh)
				
			
			lastTextureIdx = meshDict["skinref"]
			polyIdx += 1
	file.seek(prePos)
	return totalMesh

func parseMesh():
	var meshDict = {}
	
	meshDict["numTris"]  = file.get_32()
	meshDict["triIndex"]  = file.get_32()
	meshDict["skinref"]  = file.get_32()
	meshDict["numNorms"]  = file.get_32()
	meshDict["normIndex"] = file.get_32()
	meshDict["triVerts"] = []
	
	var pPos = file.get_position()
	file.seek(meshDict["triIndex"])
	
	
	var count = 0
	
	for i in range(0,meshDict["numTris"]):
		var t = parseTrivert()
		if t == null:
			break
		meshDict["triVerts"].append(t)

	
	file.seek(pPos)
	return meshDict


	
func parseTrivert():
	
	var count = file.get_16u()
	
	if count == 0:
		return null
	var tris = []
	for i in abs(count):
		var vertDict = {}
		vertDict["vertIndex"]  = file.get_16()
		vertDict["normIndex"]  = file.get_16()
		vertDict["s"]  = file.get_16()
		vertDict["t"]  = file.get_16()
		vertDict["type"] = sign(count)
		tris.append(vertDict)

	return tris

func createMeshFromFan(vertices):

	var texture
	var surf = SurfaceTool.new()
	var mesh = Mesh.new()

	
	surf.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var TL = Vector2(INF,INF)
	var triVerts = []
	for v in vertices.size():
		triVerts.append(vertices[v])

	
	surf.add_triangle_fan(triVerts,[],[],[],[])
	surf.commit(mesh)
	var meshNode = MeshInstance.new()
	meshNode.mesh = mesh

	return meshNode


func createMesh(vertices,normals,type,uv,boneIndices,textureIndex,lastTextureIdx,runningMesh=null):
	var test = boneMap
	var seq = fileDict["sequences"]
	
	var surf = runningMesh
	
	
	var finalV = []
	var finalN = []
	var finalB = []
	for v in vertices.size():
		surf.add_normal(normals[v])
		surf.add_uv(uv[v])
		
		var boneIndex = boneIndices[v]
		var vert = vertices[v]
		vert =  bones[boneIndices[v]]["transform"].xform(vert)
		finalV.append(vert)
		finalN.append(normals[v])
		finalB.append(boneIndex)
		
		
		
	if type == -1:
		var ret = fanToTri(finalV,finalN,uv,finalB)
		var triVerts = ret["verts"]
		var triNomrals = ret["normals"]
		var triUvs = ret["uvs"]
		var triBones = ret["bones"]
		for v in triVerts.size():
			surf.add_normal(triNomrals[v])
			surf.add_uv(triUvs[v])
			surf.add_bones([triBones[v],-1,-1,-1])
			surf.add_weights([1,0,0,0])
			surf.add_vertex(triVerts[v])
	
	if type == 1:
		var ret = stripToTri(finalV,finalN,uv,finalB)
		var triVerts = ret["verts"]
		var triNormals = ret["normals"]
		var triUvs = ret["uvs"]
		var triBones = ret["bones"]
		for v in triVerts.size():
			surf.add_normal(triNormals[v])
			surf.add_uv(triUvs[v])
			surf.add_bones([triBones[v],0,0,0])
			surf.add_weights([1,0,0,0])
			surf.add_vertex(triVerts[v])
			
	return runningMesh

func createMat(textureIndex):
	
	if !matCache.has(textureIndex):
		var mat = SpatialMaterial.new()	
		if textures == null:
			return mat
		
		if textures.size() == 0:
			return mat
		
		var textDict =  textures[textureIndex]
		var isChrome = textDict["chrome"]
		var text = textDict["texture"]
		var transparent = textDict["transparent"]
		if !isChrome:
			mat.albedo_texture = text
			mat.uv1_scale.x /= text.get_width()
			mat.uv1_scale.y /= text.get_height()
			if textDict["additive"]: mat.params_blend_mode = SpatialMaterial.BLEND_MODE_ADD
			
			if textDict["transparent"]:
				#mat.flags_transparent = true
				mat.params_use_alpha_scissor = true
				mat.params_alpha_scissor_threshold = 1
				
			matCache[textureIndex] = mat
		else:
			var shader = load(matCapShaderPath)
			var shaderMat = ShaderMaterial.new()
			shaderMat.shader = shader
			shaderMat.set_shader_param("matcap_texture",text)
			matCache[textureIndex] = shaderMat
		
	
	
	return(matCache[textureIndex])

	
func boneItt3(seq):
	var anim = seq
	var numBones = fileDict["numBones"]
	
	var boneLocalPos = []
	
	for boneIdx in numBones:
		var bone = bones[boneIdx]
		var boneRot = bone["rot"]
		var bonePos = bone["pos"]
		var animPos = seq["pos"][boneIdx]
		var animRot = seq["rot"][boneIdx]
		
		var boneRestTransform = getTransform(bonePos,boneRot)
		
		bone["restTransform"] = boneRestTransform
		
		var pos = bonePos + animPos
		var rot = boneRot + animRot
		

		var t = getTransform(pos,rot)
		boneLocalTransforms.append(t)
		boneLocalTransformsInv.append(t.inverse())
		
		
		
	for boneIdx in numBones:
		var bone = bones[boneIdx]
		var t = boneLocalTransforms[boneIdx]
		var parentIdx = bone["parentIndex"]
		var parentBone = bones[parentIdx]
		
		while parentIdx >= 0:
			var pT = boneLocalTransforms[parentIdx]	
			t = pT * t
			
			parentIdx = parentBone["parentIndex"]
			parentBone = bones[parentIdx]
		 
		
		bone["transform"] = t
		


func getVectorXZY(file):
	var vec = file.get_Vector32()
	#return Vector3(-vec.x,vec.z,vec.y)
	return Vector3(vec.x,vec.y,vec.z)

func getVectorRot(file):
	var vec = file.get_Vector32()
	return Vector3(vec.x,vec.y,vec.z)


func getTransform(pos,rot):
	var t = Transform.IDENTITY	
	t.origin = pos 
	t.basis = t.basis.rotated(Vector3(1,0,0),rot.x)
	t.basis = t.basis.rotated(Vector3(0,1,0),rot.y)
	t.basis = t.basis.rotated(Vector3(0,0,1),rot.z)
	return t

func getTransformQuat(pos,rot):
	var t = Transform.IDENTITY	
	t.origin = pos 
	t.basis = t.basis.rotated(Vector3(1,0,0),rot.x)
	t.basis = t.basis.rotated(Vector3(0,1,0),rot.y)
	t.basis = t.basis.rotated(Vector3(0,0,1),rot.z)
	return  t.basis.get_rotation_quat()
	
	return t
	

func stripToTri(verts,normals,uv,boneArr):
	var tris = []
	var tNormals = []
	var tUv = []
	var tBones = []
	var size = verts.size()-2

	for i in size:
		if i % 2:
			tris += rearrange(verts,i,0,2,1)
			tNormals += rearrange(normals,i,0,2,1)
			tUv += rearrange(uv,i,0,2,1)
			tBones += rearrange(boneArr,i,0,2,1)
		
		else:	
			tris += rearrange(verts,i,0,1,2)
			tNormals += rearrange(normals,i,0,1,2)
			tUv += rearrange(uv,i,0,1,2)
			tBones += rearrange(boneArr,i,0,1,2)

			
	return{"verts":tris,"normals":tNormals,"uvs":tUv,"bones":tBones}

func fanToTri(verts,normals,uv,boneArr):
	var tris = []
	var tNormals = []
	var tUv = []
	var tBones = []
	var size = verts.size()-2
	
	for i in size:
		tris += rearrange(verts,0,0,i+1,i+2)
		tNormals += rearrange(normals,0,0,i+1,i+2)
		tUv   += rearrange(uv,0,0,i+1,i+2)
		tBones += rearrange(boneArr,0,0,i+1,i+2)
		

	return{"verts":tris,"normals":tNormals,"uvs":tUv,"bones":tBones}



func getModelNameFromPath(path):
	path = path.replace(".mdl","")
	path = path.split("/")
	path = path[path.size()-1]
	return path

func rearrange(arr,i,a,b,c):
	return [arr[i+a],arr[i+b],arr[i+c]]
	
func initSkel():
	var skel = Skeleton.new()
	for b in bones.size():
		var bone = bones[b]
		
		skel.add_bone(bone["name"])
		
	for b in bones.size():
		var bone = bones[b]
		var sBoneIdx = skel.find_bone(bone["name"])
		skel.set_bone_parent(sBoneIdx,bone["parentIndex"])
		skel.set_bone_rest(sBoneIdx,boneLocalTransforms[b])
		
	return skel
	
func initSkelAnimations(skel):
	var animPlayer : AnimationPlayer = AnimationPlayer.new() 
	animPlayer.name = "anims"
	var firstAnim = true
	for seq in fileDict["sequences"]:
		var anim = Animation.new()
		var fps = seq["fps"]
		var numFrames = seq["numframes"]
		var delta = 1/fps
		
		
		
		animPlayer.add_animation(seq["name"].to_lower(),anim)
		anim.length = delta*numFrames
		
		
		if firstAnim == true:
			animPlayer.set_autoplay(seq["name"].to_lower())
			firstAnim = false
		
		if seq["flags"] == 1: anim.loop = true
		
		for boneIdx in bones.size():
			var bone = bones[boneIdx]
			var animParentPath = "../" + skel.name + ":" + bone["name"]
			var trackIdx = anim.add_track(Animation.TYPE_TRANSFORM)
			anim.track_set_path(trackIdx, animParentPath)

			var prevKey = null

			for f in numFrames:
				var frameData =  seq["blends"][0][f]
				var allPos = frameData["pos"]
				var allRot = frameData["rot"]
				var pos = bone["pos"] + allPos[boneIdx]
				var rot =bone["rot"] + allRot[boneIdx]

				var t = boneLocalTransformsInv[boneIdx] * getTransform(pos,rot)
				
				t.translated(pos)
				var rotQuat = t.basis.get_rotation_quat()
				
				
				var key = {"location":t.origin,"rotation":rotQuat,"scale":Vector3(1,1,1)}
				var keyHash = key.hash()
				if prevKey != keyHash:
					anim.track_insert_key(trackIdx,f*delta,key)
				prevKey = keyHash
				
	skel.add_child(animPlayer)
	animPlayer.set_owner(skel)
	return


