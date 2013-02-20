class PhiloGL.O3D.P3DModel extends PhiloGL.O3D.Model

  constructor: (@opts = {}, callback ) ->
    @opts.render = @render
    PhiloGL.O3D.Model.call @, @opts;
    @load @opts.src, callback if @opts.src?

  load: (src, @callback) => new P3D(src, @opts.p3d, @_onP3DLoad)

  _onP3DLoad: (p3d) =>
    # Loading the model geometry
    @[k] = p3d[k] for k in ["vertices", "normals"]#, "indices"]

    # Resetting colors (works around PhiloGL's inability to update the colors properly)
    newColors = new Float32Array p3d.vertices.length*4/3
    newColors[i+j*4] = @colors[i] for i in [0..3] for j in [0..p3d.vertices.length/3]
    @colors = new Float32Array newColors

    @_loadedP3D = true
    @callback?(p3d, @)

  render: (gl, program, camera) => if @_loadedP3D?
    # By using draw arrays we can draw large objects without the need to split the meshes in to 2^16 vert chunks
    drawType = if @drawType? then gl.TRIANGLES else gl.get(@drawType)
    gl.drawArrays drawType, 0, @$verticesLength / 3
