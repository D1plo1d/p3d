class THREE.P3DGeometry extends THREE.Geometry

  constructor: (@opts = {}, @callback) ->
    THREE.Geometry.call @
    @load opts.src if opts.src?

  load: (src) => new P3D(src, @opts, @_onP3DLoad)

  _onP3DLoad: (p3d) =>
    i = 0
    @faces = []
    @vertices = []

    for i in [0..p3d.indices.length-3] by 3
      indices = p3d.indices.subarray i, i+3

      n = indices[0] * 3
      normal = new THREE.Vector3 p3d.normals[n], p3d.normals[n + 1], p3d.normals[n + 2]

      face3 = new THREE.Face3 i++, i++, i++
      face3.normal.copy normal
      face3.vertexNormals.push normal.clone(), normal.clone(), normal.clone()

      for index in indices
        n = index * 3
        @vertices.push new THREE.Vector3 p3d.vertices[n], p3d.vertices[n + 1], p3d.vertices[n + 2]

      @faces.push face3

    @computeCentroids()
    @computeFaceNormals()
    @computeVertexNormals()

    @callback?(p3d)
