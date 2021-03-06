P3D
====

A Coffeescript 3D Mesh parser for a better web.

P3D was originally developed to efficiently parse 3D mesh files for use in WebGL across all libraries (ThreeJS/PhiloGL/[your library here]). However P3D is not only independent of a specific WebGL interface but of WebGL altogether. This is by design, by remaining unbound to webGL P3D has been carefully constructed to support the next generation of in-browser 3D object manipulation applications regardless of the rendering and mesh manipulation technologies that they require.

P3D's cutting edge use of HTML5 APIs (WebWorker, Typed Array, Blob, File, Blob URLs and Transferable Objects) makes loading 3D models fast and unobtrusive. P3D's use of HTML5 WebWorkers allows P3D to drastically reduces browser lockup when processing file while P3D's use of typed arrays, transferable objects and blobs serve to keep memory usage and garbage collection overhead at a minimum.

The TL;DR here is: It's fast, it's standalone and it won't lock up the browser


Online Demo
------------

A online demo of P3D can be found [here](http://d1plo1d.github.com/p3d/examples/).


Project Status
---------------

Binary and ascii STLs and OBJ files are currently fully supported from either local HTML5 File/Blob sources and ajax urls. However AMF files are only partially supported at the present time (no compression or edge support yet).


Supported File Formats
------------------------

* STL (Binary and ASCII)
* OBJ
* AMF (Additive Manufacturing File Format)


Background Processing
-----------------------
WebWorker background processing is available via P3D's background option.*

*Due to a Javscript limitation on DOM APIs in WebWorkers, AMF files cannot be parsed in the background.


THREE.js Integration
---------------------

In addition to the platform independent P3D API there is now a threejs P3D geometry available for easier integration with threejs (see `lib/threejs_p3d_geometry.js`).


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


Development
------------

### Requirements

* NodeJS
* NPM
* `npm install` installs all other dependencies

### Cake Tasks

* `cake dev` - Watches and compiles .coffee files. Runs the P3D examples page on http://localhost:3033/
* `cake bam` - Compiles and minifies the library


License
--------

P3D is an open source library and has released under the MIT license. See LICENSE.
