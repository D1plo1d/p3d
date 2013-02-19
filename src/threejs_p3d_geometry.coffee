class THREE.P3DGeometry extends THREE.Geometry

  constructor: (@opts = {}, @callback) ->
    THREE.Geometry.call @
    @load opts.src if opts.src?

  load: (src) => new P3D(src, @opts, @_onP3DLoad)

  _onP3DLoad: (p3d) =>
    i = 0
    @faces = []
    @vertices = []

    p3d._eachFace (face) =>

      n = face.normals[0]

      normal = new THREE.Vector3 n[0], n[1], n[2]

      face3 = new THREE.Face3 i++, i++, i++
      face3.normal.copy normal
      face3.vertexNormals.push normal.clone(), normal.clone(), normal.clone()

      for j in [0..2]
        v = face.vertices[j]
        @vertices.push new THREE.Vector3( v[0], v[1], v[2] )

      @faces.push face3

    @computeCentroids()
    @computeFaceNormals()
    @computeVertexNormals()

    @callback?(p3d)
