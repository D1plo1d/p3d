# Utils
# -----------------------------------------------------

# check if a string starts with the given substring
startsWith = (str, substring) ->
  str[0..substring.length-1] == substring

eachLine = (str, callback) ->
  # Note: this implementation may becomes a serious memory concern in large strings.
  # If so it should be replaced with a better one which does not rely on String.split
  callback(line, i) for line, i in str.split(/\r?\n/)
  return undefined

capitalize = (str) -> "#{str[0].toUpperCase()}#{str[1..]}"

sign = (num) -> if num > 0 then +1 else if num < 0 then -1 else 0

fileExt = (str) -> str.split('.').pop()

ajax = (opts, callback) ->
  xhr = new XMLHttpRequest()
  xhr.open("GET", opts.url, true)
  xhr.responseType = "blob"
  xhr.onload = ( -> callback xhr.response ) if callback?
  xhr.send()
  return xhr

parseXml = (text) ->
  if (self.DOMParser)
    new DOMParser().parseFromString(text,"text/xml")
  else # Internet Explorer
    xmlDoc=new ActiveXObject("Microsoft.XMLDOM")
    xmlDoc.async=false
    xml.loadXML(text)

hermiteSpline = (s, v, t) -> # see http://en.wikipedia.org/wiki/Cubic_Hermite_spline
  # (2*s^3 - 3*s^2 + 1)*v[0] + (s^3 - 2*s^2 + s)*t[0] + (-2*s^3 + 3*s^2)*v[1] + (s^3-s^2)*t[1]
  c = [
    [ 2*Math.pow(s,3) - 3*Math.pow(s,2) + 1, Math.pow(s,3) - 2*Math.pow(s,2) + s ],
    [ -2*Math.pow(s,3) + 3*Math.pow(s,2), Math.pow(s,3) - Math.pow(s,2) ]
  ]
  v[0][i]*c[0][0] + t[0][i]*c[0][1] + v[1][i]*c[1][0] + t[1][i]*c[1][1] for i in [0..2]

base64_encode = (data) ->
  # http://kevin.vanzonneveld.net
  # +   original by: Tyler Akins (http://rumkin.com)
  # +   improved by: Bayron Guevara
  # +   improved by: Thunder.m
  # +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
  # +   bugfixed by: Pellentesque Malesuada
  # +   improved by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
  # +   improved by: Rafał Kukawski (http://kukawski.pl)
  # *     example 1: base64_encode('Kevin van Zonneveld');
  # *     returns 1: 'S2V2aW4gdmFuIFpvbm5ldmVsZA=='
  # mozilla has this native
  # - but breaks in 2.0.0.12!
  #if (typeof this.window['btoa'] == 'function') {
  #    return btoa(data);
  #}
  b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
  o1 = undefined; o2 = undefined; o3 = undefined; h1 = undefined
  h2 = undefined; h3 = undefined; h4 = undefined; bits = undefined
  i = 0
  ac = 0
  enc = ""
  tmp_arr = []
  return data unless data
  loop # pack three octets into four hexets
    o1 = data.charCodeAt(i++)
    o2 = data.charCodeAt(i++)
    o3 = data.charCodeAt(i++)
    bits = o1 << 16 | o2 << 8 | o3
    h1 = bits >> 18 & 0x3f
    h2 = bits >> 12 & 0x3f
    h3 = bits >> 6 & 0x3f
    h4 = bits & 0x3f

    # use hexets to index into b64, and append result to encoded string
    tmp_arr[ac++] = b64.charAt(h1) + b64.charAt(h2) + b64.charAt(h3) + b64.charAt(h4)
    break unless i < data.length
  enc = tmp_arr.join("")
  r = data.length % 3
  ((if r then enc.slice(0, r - 3) else enc)) + "===".slice(r or 3)


# Web Worker Interface
# -----------------------------------------------------

isWorker = (self.document == undefined)
webWorkerAttrs = ['normals', 'vertices', 'indices', 'nOfTriangles', 'chunks']
if !isWorker
  webWorkerFn = arguments.callee
  # Getting a blob url reference to this script's closure
  webWorkerURL = =>
    return @webWorkerURL if @webWorkerURL?
    # Removing the closure from the worker's js because it caused syntax issues in chrome 24
    str = webWorkerFn.toString()
    str = str.replace(/^\s*function\s*\(\) {/, "").replace(/}\s*$/, '')

    webWorkerBlob = new Blob [str], type: "text/javascript"
    @webWorkerURL = (window.URL || window.webkitURL).createObjectURL webWorkerBlob
else
  parserPipeline = null
  data = null
  # Transferable Objects from the worker to the main thread are broken in firefox 18
  attemptTransfer = navigator.userAgent.toLowerCase().indexOf('firefox/18') == -1
  # Running a slave P3D instance in the webworker
  @onmessage = (event) ->
    parser = new P3D.Parser(event.data)
    # Returning the data
    msg = {}
    msg[k] = parser[k] for k in webWorkerAttrs
    transfers = ( parser[k].buffer for k in ['normals', 'vertices', 'indices'] )
    if parser.chunks?
      transfers.push chunk[k].buffer for k in ['normals', 'vertices', 'indices'] for chunk in parser.chunks
    postMessage msg, if attemptTransfer then transfers else undefined


# P3D
# -----------------------------------------------------
class self.P3D

  _fileTypeWhitelist: ["Stl", "Amf", "Obj"]

  # Creates a P3D parser which loads the src url or HTML5 file object and 
  # fires the callback when it's geometry is ready
  # Arguments:
  #  src: A url (string) or File object
  #  type: (optional) the file type of the src. If no type is given P3D will 
  #        attempt to determine it from the file extension.
  #  opts: (optional) a object containing properties for this parser
  #     background: (boolean) if true this parser will spawn a webworker and run outside the UI thread
  #  callback: the fn to run once the 3d geometry has been parsed
  constructor: (@src, @opts) ->
    args = arguments
    @opts = {background: true} if args.length < 3 or !( @opts? )
    @callback = args[args.length-1]

    # Determining the file name and the file type
    @filename = if typeof(@src) == "string" then @src.split("/").pop().replace("/", "") else @src.name
    @fileType = capitalize fileExt(@filename).toLowerCase()

    if @_fileTypeWhitelist.indexOf(@fileType) == -1
      throw "Unable to parse file extension or unsupported file extension: #{@fileType}"

    @opts.background = false if @fileType == "Amf"

    # Loading the object
    if typeof(@src) == "string" # load from URL
      ajax url: @src, (response) => @_initReader "Text", response
    else # load from local file or blob (HTML5 file API)
      @_initReader "Text", @src


  # Blob Loading
  # ------------------------------------------------------

  _initReader: (type, @blob) ->
    @dataType = type
    r = @reader = new FileReader()
    r.onload = @_onReaderLoad
    r["readAs#{type}"] @blob

  _binaryStlCheck: (text) ->
    @fileType == "Stl" and @dataType == "Text" and text[0..80].match(/^solid /) == null

  _onReaderLoad: () =>
    data = @reader.result
    delete @reader
    # If the STL file turns out not to be a text file then reread it as an array buffer
    return @_initReader("ArrayBuffer", @blob) if @_binaryStlCheck(data)
    @_parse data


  # Parsing Interface (File API/AJAX agnostic)
  # ------------------------------------------------------

  _dataTypeInfo: -> if @dataType == 'Text' then 'Text' else 'Binary'

  _parsingDebugMsg: (done) -> if P3D.debug
    if done == true
      seconds = (new Date().getTime() - @_parserStartMs)/1000
      suffix = "[ DONE #{seconds}s ]"
    else
      @_parserStartMs = new Date().getTime()
      suffix = ''
    console.log "Parsing #{@filename} as #{@_dataTypeInfo().toLowerCase()} #{@fileType.toUpperCase()}.. #{suffix}"

  _parse: (data) ->
    @_parsingDebugMsg(false)
    parserOpts = pipeline: ["_parse#{@dataType}#{@fileType}"], data: data
    if @opts.background == true
      console.log "Running as a background job"
      worker = new Worker webWorkerURL()
      worker.onmessage = (e) => @_onParsingComplete(e.data)
      worker.addEventListener "error", ((e) -> console.log e), false
      worker.postMessage = worker.webkitPostMessage || worker.postMessage
      worker.postMessage parserOpts, if @dataType == 'Text' then [] else [data]
      # TODO: remove data parser dependancy. it is long and bloated and won't work in web workers.
    else
      @_onParsingComplete new P3D.Parser parserOpts

  _onParsingComplete: (parser) ->
    @[k] = parser[k] for k in webWorkerAttrs
    @verts = @vertices
    @_parsingDebugMsg(true)
    @callback @


  # Exporting Methods
  # ------------------------------------------------------

  # TODO: This method only works for small objects with less then ~196614 verts. I don't know why.
  # TODO: determine if this bug was solved with the uint16 indices fix
  exportTextStl: ->
    str = "solid P3D\n"
    formatFloat = (flt, i)-> (if sign(flt) >= 0 or i == 0 then " " else "") + flt.toExponential(6)
    formatVector = (array, v) -> (formatFloat(array[i], if v then i else 1) for i in [0..2]).join(" ")

    @_eachFace (f, i) ->
      str += "  facet normal #{ formatVector f.normals[0], false }\n"
      str += "    outer loop\n"
      str += "      vertex #{ formatVector v, true }\n" for v in f.vertices
      str += "    endloop\n"
      str += "  endfacet\n"

    str += "endsolid P3D"
    str = str.replace(/e\+([0-9][^0-9])/g, "e+0$1")
    str = str.replace(/e\-([0-9][^0-9])/g, "e-0$1")
    return new Blob [str], type: "application/octet-stream"


# Parsing Methods (File API/AJAX agnostic)
# ------------------------------------------------------
class self.P3D.Parser
  constructor: (opts) ->
    # Parsing the data from it's raw format
    @[opts.pipeline[0]](opts.data)
    # Running any post processing steps
    @[method]() for method in opts.pipeline[1..]

  _toMillimeters: (unitsOfMeasurement) ->
    conversions = {mm: 1.0, millimeter: 1.0, meter: 1000.0, inch: 25.4, feet: 304.8, micron: 0.001}
    scale = conversions[unitsOfMeasurement.toLowerCase()]
    return scale if scale?
    throw "#{unitsOfMeasurement} is not a known unit of measurement"

  # Initializing normals, verts and indices
  _initGeometry: (nOfTriangles, nOfIndices) ->
    @nOfTriangles = nOfTriangles # TODO: this is a bit of a misnomer, it's the number of verts / 3
    @normals = new Float32Array @nOfTriangles*9
    @vertices = @verts = new Float32Array @nOfTriangles*9
    if nOfIndices?
      @indices = new Uint32Array nOfIndices
    else
      indices = @indices = new Uint32Array @nOfTriangles*3
      indices[i] = i for i in [0 .. indices.length]
    return [@normals, @verts, @indices]

  # Adds a face's vertices and normals to the mesh at the given index
  _addFace: (face, mesh, index) -> for attr in ['vertices', 'normals']
    mesh[attr][index+j*3+k] = face[attr][j][k] for j in [0..2] for k in [0..2]

  # Expanding (duplicating) the normals and verts so that there is a 1:1 of verts to indices
  # This allows us to modify the normals on a per-face basis in edges and makes mesh spliting trivial
  _expandVerts: ->
    @nOfTriangles = @indices.length/3 # TODO: when noftriangles is fixed this will be implicit
    exp = {}
    exp[attr] = new Float32Array(@nOfTriangles*9) for attr in ['vertices', 'normals']
    @_eachFace (face, i) => @_addFace(face, exp, i*9)
    @indices[i] = i for i in [0..@indices.length-1]
    @[attr] = exp[attr] for attr in ['vertices', 'normals']
    @verts = @vertices

  #_parseTextAMF: (text) ->
  # TODO: inflate the zip file here
  # new Blob([arrayBuffer], "application/zip")

  _parseTextAmf: (text) ->
    xml = parseXml text
    root = xml.documentElement
    xmlEval = (query) -> xml.evaluate query, xml, null, XPathResult.ANY_TYPE, null
    read = (node, k) -> node.getElementsByTagName(k)[0].textContent
    $ = (query, callback) ->
      results = xmlEval query
      while (node = results.iterateNext())?
        callback(node)
      undefined

    # Scaling the object to mm
    #console.log xml
    unitStr = root.getAttribute("unit") || root.getAttribute("units")
    scale = @_toMillimeters unitStr

    # initializing indice and vert counts
    vertCount = 0; indiceCount = 0
    nOfTriangles = xmlEval('count(//triangle)').numberValue
    nOfVerts = xmlEval('count(//vertex)').numberValue
    [normals, verts, indices] = @_initGeometry nOfVerts, nOfTriangles*3

    # Parsing Vertices
    $ "//vertex", (node) ->
      coords = node.getElementsByTagName("coordinates")[0]
      normalNodeList = node.getElementsByTagName("normal")
      if normalNodeList.length == 1
        n = for k, i in ['nx', 'ny', 'nz']
          normals[vertCount+i] = parseFloat(read normalNodeList[0], k)
      for k in ['x', 'y', 'z']
        verts[vertCount++] = parseFloat(read coords, k) * scale

    # Parsing Faces
    $ "//triangle", (node) ->
      indices[indiceCount++] = parseInt(read node, "v#{k}") for k in [1..3]

    # Helper Functions
    isFlat = (face) -> ( (n = face.normals)[0] == n[1] == n[2] )
    cross = (vA, vB) -> [
        vA[1]*vB[2] - vA[2]*vB[1],
        vA[2]*vB[0] - vA[0]*vB[2],
        vA[0]*vB[1] - vA[1]*vB[0]
      ]
    magnitude = (v) -> Math.sqrt Math.pow(v[0],2) + Math.pow(v[1],2) + Math.pow(v[2],2)
    normalize = (v) -> (length = magnitude(v); v[i] = v[i]/length for i in [0..2])

    @_expandVerts()
    nOfTriangles = @nOfTriangles

    # Define the normals for verts without a normal as the normal vector of the face
    @_eachFace @_calculateVertexNormals

    #return
    # Counting Curved Surfaces
    subdivisionLevels = 4
    trianglesPerSurface = Math.pow 4, subdivisionLevels
    @_eachFace (face) => ( nOfTriangles += trianglesPerSurface-1 if !isFlat face )

    # Subdividing Curved Surfaces
    exp = {}
    exp[attr] = new Float32Array(nOfTriangles*9) for attr in ['vertices', 'normals']
    vertCount = 0

    subdivide = (face, fIndex) ->
      # calculating each edge midpoint and normal
      midVerts = []
      midNormals = []
      for edge in [[0,1], [1,2], [2,0]]
        v = [ face.vertices[edge[0]], face.vertices[edge[1]] ]
        n = [ face.normals[edge[0]], face.normals[edge[1]] ]
        d = ( v[1][i] - v[0][i] for i in [0..2] )
        t = for i in [0..1]
          crossProduct = cross cross(n[i], d), n[i]
          ( magnitude(d) * crossProduct[j] / magnitude(crossProduct) for j in [0..2] )
        midVerts.push v01 = hermiteSpline(0.5, v, t, fIndex)
        # TODO: these normals are probably only aproximately correct.
        # What is the proper way to calculate these??
        midNormals.push n01 = normalize( (n[1][i] + n[0][i])/2 for i in [0..2] )

      newFaces = for i in [0..2] # calculating the outer subdivided faces
        vertices: [ midVerts[i], midVerts[ j = (i+2)%3 ], face.vertices[i] ]
        normals: [ midNormals[i], midNormals[j], face.normals[i] ]
      #newFaces = []
      newFaces.push # calculating the center subdivided faces
        vertices: midVerts, normals: midNormals

      return newFaces

    # iterating through each original face and subdividing it if it is has non-uniform normals
    @_eachFace (face, fIndex) =>
      if isFlat face
        for attr in ['vertices', 'normals']
          exp[attr][vertCount+j*3+k] = face[attr][j][k] for j in [0..2] for k in [0..2]
        vertCount += 9
      else
        faces = [face]
        newFaces = []
        for i in [0..subdivisionLevels-1]
          newFaces = []
          for f in faces
            newFaces.push f2 for f2 in subdivide f, fIndex + Math.pow(4,i)
          faces = newFaces
        # adding each subdivided face to the mesh
        for f in newFaces
          @_addFace f, exp, vertCount
          #addFace face, exp, vertCount
          vertCount += 9


    indices = @indices = new Float32Array(nOfTriangles*3)
    @indices[i] = i for i in [0..@indices.length-1]
    @[attr] = exp[attr] for attr in ['vertices', 'normals']
    @verts = @vertices

    # TODO: temporarily using face normals for the subdivided faces until I figure out how to calculate them.
    @nOfTriangles = nOfTriangles
    @_eachFace @_calculateVertexNormals

    # Parsing Edges (TODO)
    # $ "//edge", (node) ->
    #  for k in ['v1', 'dx1', 'dy1', 'dz1', 'v2', 'dx2', 'dy2', 'dz2']
    #    s = node.getElementsByTagName(k).textContent
    #    verts[vertCount++] = parseFloat s
    # TODO: eventually we will be able to pull normals from the AMF file
    #@_eachFace @_calculateVertexNormals

    @nOfTriangles = nOfTriangles
    undefined

  # Runs a generalized line-based text parser on the given text
  _parseEachLine: (text, prefixes, opts, callback) ->
    # Finding the number of triangles in the mesh
    nOfTriangles = 0

    lines = (fn) -> eachLine text, (line, index) -> 
      fn(line, index) if index >= opts.headerLines

    lines (line) -> ( nOfTriangles++ if line.indexOf(prefixes.face) != -1 )

    # Initializing normals and verts
    @_initGeometry(nOfTriangles)

    lines (line, index) ->
      # Stripping whitespace and relaying it to the callback
      line = line.replace(/^\s+|\s+$/g, '').replace(/\s{2,}/g, ' ').toLowerCase()
      callback line, index
    undefined


  _parseTextObj: (text) ->
    prefixes = normal: "vn ", vert: "v ", face: "f "
    indexCount = 0; vertCount = 0

    @_parseEachLine text, prefixes, headerLines: 0, (line, index) =>
      # Parsing verts
      if startsWith line, prefixes.vert
        vectorStrings = line.split(/\s/)[1..]
        throw "Parsing Error: #{vectorStrings.length} vector vertex" if vectorStrings.length < 3
        for s in vectorStrings[0..2]
          @vertices[vertCount++] = v = parseFloat(s)
          throw "Parsing Error: Vertex vector ##{vertCount} is not a number" if isNaN(v) or !isFinite(v)
      else if startsWith line, prefixes.face
        for str in line.split(/\s/)[1..]
          @indices[indexCount++] = parseInt( str.split('/')[0] ) - 1
      undefined

    @_expandVerts()
    # Calculating normals
    @_eachFace @_calculateVertexNormals
    undefined

  _parseTextStl: (text) -> # text stl format parser
    prefixes = normal: "facet normal ", vert: "vertex ", face: "facet"
    ignoredPrefixes = ["outer", "endloop", "facet", "endfacet", "endsolid"]
    normalCount = 0; vertCount = 0

    @_parseEachLine text, prefixes, headerLines: 1, (line, index) =>
      # Parsing verts
      if startsWith line, prefixes.vert
        vectorStrings = line.split(/\s/)[1..]
        throw "Parsing Error: #{vectorStrings.length} vector vertex" if vectorStrings.length != 3
        for s in vectorStrings
          @vertices[vertCount++] = v = parseFloat(s)
          throw "Parsing Error: Vertex vector ##{vertCount} is not a number" if isNaN(v) or !isFinite(v)
      # Catching invalid lines
      else if line.length > 0
        return if startsWith(line, k) for k in ignoredPrefixes
        throw "Parsing Error: Invalid Line \n #{line}"
      undefined
    # Calculating normals
    @_eachFace @_calculateVertexNormals
    undefined

  _parseArrayBufferStl: (arrayBuffer) -> # binary stl format parser
    # Note: binary STLs are encoded as little endian
    data = new DataView arrayBuffer, 80
    dataPointer = 0

    _read = (method, bytes) ->
      val = data[method] dataPointer, true
      dataPointer += bytes
      return val
    readFloat32 = -> _read "getFloat32", 4
    readUint32 = ->  _read "getUint32", 4
    readUint16 = ->  _read "getUint16", 2

    # Header data
    nOfTriangles = readUint32()
    [normals, verts, indices] = @_initGeometry nOfTriangles

    # Parsing the verts and normals of each triangle
    for i in [0 .. nOfTriangles-1]
      readFloat32()  for j in [0..2] # discard the STL's normals, we will calculate them later
      verts[i*9+j] = readFloat32()  for j in [0..8]
      readUint16() # 2 byte "attributes byte count"
    @_eachFace @_calculateVertexNormals
    undefined # not returning the comprehension


  # Mesh Manipulation Methods (File API/AJAX and Parser agnostic)
  # ---------------------------------------------------------------

  # iterates over all the faces of the mesh
  _eachFace: (fn) =>
    indices = @indices
    for i in [0..@indices.length-3] by 3
      fn @_face(indices.subarray i, i+3), i/3
    undefined# not returning the comprehension

  _face: (fIndices) ->
    indices: fIndices
    normals:  ( @normals.subarray  index*3, index*3+3 for index in fIndices )
    vertices: ( @vertices.subarray index*3, index*3+3 for index in fIndices )

  _flipFace: (f) ->
    firstIndex   = f.indices[0]
    f.indices[0] = f.indices[1]
    f.indices[1] = firstIndex

  _calculateVertexNormals: (f) ->
    # calculating vectors for 2 edges of the face
    v = ( f.vertices[i][j] - f.vertices[0][j] for j in [0..2] for i in [1..2] )
    # calculating the normal vector see http://www.opengl.org/wiki/Calculating_a_Surface_Normal
    vN = [
      (v[0][1]*v[1][2]) - (v[0][2]*v[1][1]),
      (v[0][2]*v[1][0]) - (v[0][0]*v[1][2]),
      (v[0][0]*v[1][1]) - (v[0][1]*v[1][0])
    ]
    # scaling the normal vector into a unit normal vector
    len = Math.sqrt vN[0]*vN[0] + vN[1]*vN[1] + vN[2]*vN[2]
    vN[i] = vN[i]/len for i in [0..2]
    # overwriting the previous normals only if they were undefined
    for i in [0..2]
      if f.normals[i][0] == 0 and f.normals[i][1] == 0 and f.normals[i][2] == 0
        f.normals[i][j] = vN[j] for j in [0..2]

  # Splits the object into 2^16 vert chunks and returns the chunks
  split: () => # TODO: since each object's verts are 1:1 with indices at this point we can use monolithic subarrays here
    #console.log "splitting"
    bytesPerMesh = Math.pow(2,16) # is this even in bytes!?
    bytesPerMesh -= bytesPerMesh % 9 # Rounding the bytes per mesh down to the nearest face

    @chunks = for startIndex in [0..@indices.length-1] by bytesPerMesh
      oldIndices = @indices.subarray startIndex, startIndex + bytesPerMesh
      opts = indices: new Uint16Array(oldIndices.length), vertices: [], normals: []
      opts.indices[i] = i for i in [0..opts.indices.length-1]

      for oldIndex, newIndex in oldIndices
        for k in [0..2]
          opts.vertices[newIndex*3+k] = @vertices[oldIndex*3+k]
          opts.normals[ newIndex*3+k] = @normals[ oldIndex*3+k]
      opts[k] = new Float32Array(opts[k]) for k in ['vertices', 'normals']
      opts

P3D.prototype[k] = P3D.Parser.prototype[k] for k in ["_eachFace", "_face"]
P3D.debug = false
