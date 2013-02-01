P3D
====

A Coffeescript 3D Mesh parser for a better web.

P3D was originally developed to efficiently parse 3D mesh files for use in WebGL across all libraries (ThreeJS/PhiloGL/[your library here]). However it is not only independent of a specific WebGL interface but of WebGL altogether. Thus P3D has been carefully designed to support the next generation of in-browser 3D object manipulation applications.


Project Status
---------------

Both binary and ascii STLs are currently fully supported from either local HTML5 File/Blob sources and ajax urls. However AMF files are only partially supported at the present time (no compression or edge support yet).

WebWorker background processing is available via P3D's background option.


Example Usage (in coffeescript)
--------------------------------

### Example 1: WebGL, Chunks and Ajax

```coffeescript
# Using P3D's chunking feature to load an object as 2^16 vert segments
# This allows us to load arbitrarily large objects even with WebGL's
# current limitation 2^16 verts per mesh.
# This example loads the mesh from a url in to a PhilloGL O3D.Model object.
# Requirements: PhiloGL

p3d = new P3D url, (p3d) -> for chunk, i in p3d.chunks
  console.log "loading #{p3d.filename} chunk ##{i}"
  model = new PhiloGL.O3D.Model()
  model[attr] = p3d[attr] for attr in ["vertices", "normals", "indices"]
```


### Example 2: HTML5 Local Files

```coffeescript
# This example loads the mesh from a file on the user's computer in to a PhilloGL O3D.Model object.
# Requirements: jQuery, PhiloGL

$("input[type=file].my-file-input").on "change", -> if @files.length > 0
  p3d = new P3D file, (p3d) -> for chunk, i in p3d.chunks
    console.log "loading #{p3d.filename} chunk ##{i}"
    model = new PhiloGL.O3D.Model()
    model[attr] = p3d[attr] for attr in ["vertices", "normals", "indices"]
```


### Example 3: Background Processing (web workers)

```coffeescript
# This example loads a mesh in a seperate thread using HTML5 webworkers and transferable objects
# Requirements: PhiloGL

p3d = new P3D url, background: true, (p3d) -> for chunk, i in p3d.chunks
  console.log "loading #{p3d.filename} chunk ##{i}"
  model = new PhiloGL.O3D.Model()
  model[attr] = p3d[attr] for attr in ["vertices", "normals", "indices"]
```

Requirements
-------------

P3D has no external requirements at the present time however it is expected that in future releases a javascript unzip/deflate library will be added as a requirement to allow P3D to parse zipped AMF files.


License
--------

P3D is an open source library and has released under the MIT license. See LICENSE.
