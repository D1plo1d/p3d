class PhiloGL.O3D.P3DModel extends PhiloGL.O3D.Model

  constructor: (@opts = {}, callback ) ->
    @opts.render = @render
    PhiloGL.O3D.Model.call @, @opts;
    @load @opts.src, callback if @opts.src?

  load: (src, @callback) => new P3D(src, @opts.p3d, @_onP3DLoad)

  _onP3DLoad: (p3d) =>
    realDynamic = @dynamic
    @dynamic = true

    # Loading the model geometry
    @[k] = p3d[k] for k in ["vertices", "normals"]#, "indices"]
    # Resetting colors (the custom setters in philoGL mean this will re-generate the colors array)
    @colors = new Float32Array @colors

    @dynamic = realDynamic
    @_loadedP3D = true
    @callback?(p3d, @)

  render: (gl, program, camera) => if @_loadedP3D?
    # By using draw arrays we can draw large objects without the need to split the meshes in to 2^16 vert chunks
    drawType = if @drawType? then gl.TRIANGLES else gl.get(@drawType)
    gl.drawArrays drawType, 0, @$verticesLength / 3
