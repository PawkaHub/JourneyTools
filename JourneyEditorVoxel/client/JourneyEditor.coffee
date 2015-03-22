renderer = undefined
camera = undefined
scene = undefined
projector = undefined
controls = undefined
mouse2D = undefined
mouse3D = undefined
ray = undefined
intersector = undefined
lastPutDelDate = Date.now()
vector = new THREE.Vector3()
plane = undefined

objects = []

# Rollover
rollOveredFace = undefined
theta = 45
rollOverMesh = undefined
rollOverMaterial = undefined
voxelPosition = new THREE.Vector3()
tmpVec = new THREE.Vector3()

# Cube Parameters
cubeColors = [
  (new (THREE.Color)).setRGB(1, 0.5, 0.5)
  (new (THREE.Color)).setRGB(0, 1, 0)
  (new (THREE.Color)).setRGB(0, 0, 1)
  (new (THREE.Color)).setRGB(1, 1, 0)
  (new (THREE.Color)).setRGB(1, 0, 1)
  (new (THREE.Color)).setRGB(0, 1, 1)
  (new (THREE.Color)).setRGB(1, 0.5, 0.5)
  (new (THREE.Color)).setRGB(1, 0.5, 1)
  (new (THREE.Color)).setRGB(0.5, 0.5, 1)
  (new (THREE.Color)).setRGB(0.5, 0.5, 0.5)
]
cubeType = 0
cubeGeo = undefined
cubeMaterials = []
i = undefined

# Controls
isAltDown = false
isCtrlDown = false
isShiftDown = false
isWDown = false
isADown = false
isDDown = false
isSDown = false
mouseMoving = false

Template.editor.onRendered ->
  canvas = document.querySelector('canvas')
  console.log 'render',canvas

  # Get the context
  context = canvas.getContext('webgl')

  console.log 'context',context

  # Create the WebGL renderer
  renderer = new THREE.WebGLRenderer(
    canvas: canvas
    antialias: true
    preserveDrawingBuffer: true
    devicePixelRatio: window.devicePixelRatio
    context: context
  )

  renderer.setSize window.innerWidth, window.innerHeight

  # Create the WebGL Scene
  scene = new THREE.Scene()

  # Create the Camera
  VIEW_ANGLE = 45
  SCREEN_WIDTH = window.innerWidth
  SCREEN_HEIGHT = window.innerHeight
  NEAR = 1
  FAR = 20000
  camera = new THREE.PerspectiveCamera(VIEW_ANGLE, SCREEN_WIDTH / SCREEN_HEIGHT, NEAR, FAR)

  # Set camera rotation
  #camera.rotation.x = -0.6051906356540627
  #camera.rotation.y = -0.7066131158840689
  #camera.rotation.z = -0.4221458606660759

  # Set camera position
  #camera.position.x = -1289.4799254958377
  camera.position.y = 100000
  #camera.position.z = 1242.2560149451172
  window.camera = camera
  #camera.lookAt scene.position

  # Orbit Controls
  #controls = new THREE.OrbitControls(camera)

  # First Person Controls
  controls = new THREE.FirstPersonControls( camera )
  controls.movementSpeed = 1000
  controls.lookSpeed = 0.125
  controls.lookVertical = false
  controls.constrainVertical = false
  controls.verticalMin = 1.1
  controls.verticalMax = 2.2
  window.controls = controls
  #controls.addEventListener 'change', disableMouseMove

  # Roll-over helpers
  rollOverGeo = new THREE.BoxGeometry(50, 50, 50)
  rollOverMaterial = new THREE.MeshBasicMaterial(
    color: 0xff0000
    opacity: 0.5
    transparent: true)
  rollOverMesh = new THREE.Mesh(rollOverGeo, rollOverMaterial)
  rollOverMesh.visible = false
  scene.add rollOverMesh

  # Cubes
  cubeGeo = new THREE.BoxGeometry(50, 50, 50)
  i = 0
  while i < cubeColors.length
    cubeMaterials[i] = new THREE.MeshLambertMaterial(
      color: 0x00ff80
      shading: THREE.FlatShading
      map: THREE.ImageUtils.loadTexture(''))
    cubeMaterials[i].color.copy cubeColors[i]
    cubeMaterials[i]._cubeType = i
    i++
  setCubeType cubeType

  # Picking
  projector = new THREE.Projector()
  window.projector = projector

  THREEx.WindowResize renderer, camera

  # Grid
  ###planeW = 200
  planeH = 200
  plane = new THREE.Mesh(new THREE.PlaneGeometry(planeW * 50, planeH * 50, planeW, planeH), new THREE.MeshBasicMaterial(
    color: 0x555555
    wireframe: true))
  plane.applyMatrix(new THREE.Matrix4().makeRotationX( - Math.PI / 2 ))
  #plane.rotation.x = -90 * Math.PI / 180
  scene.add plane
  objects.push plane###

  # Grid
  size = 200
  step = 50
  geometry = new THREE.Geometry()
  i = -size
  while i <= size
    geometry.vertices.push new THREE.Vector3(-size, 0, i)
    geometry.vertices.push new THREE.Vector3(size, 0, i)
    geometry.vertices.push new THREE.Vector3(i, 0, -size)
    geometry.vertices.push new THREE.Vector3(i, 0, size)
    i += step
  material = new THREE.LineBasicMaterial(
    color: 0x555555
    opacity: 0.75
    transparent: true)
  line = new THREE.Line(geometry, material, THREE.LinePieces)
  scene.add line

  mouse2D = new THREE.Vector3(0, 200, 0.5)

  mouse = new THREE.Vector2()
  ray = new THREE.Raycaster()

  geometry = new THREE.PlaneBufferGeometry(10000, 10000)
  geometry.applyMatrix(new THREE.Matrix4().makeRotationX(-Math.PI / 2))
  plane = new THREE.Mesh(geometry)
  #plane.visible = false
  scene.add plane
  objects.push plane

  window.objects = objects

  # Lights
  ambientLight = new THREE.AmbientLight(0x606060)
  scene.add ambientLight
  directionalLight = new THREE.DirectionalLight(0xffffff)
  directionalLight.position.set(1, 1, 1).normalize()
  scene.add directionalLight

  #Start the animation loop
  animate()

Template.editor.events
  mouseenter: (event) ->
    rollOverMesh.visible = true
  mouseleave: (event) ->
    rollOverMesh.visible = false
  mousemove: (event) ->
    console.log('go')
    mouseMoving = true
    #vector.set(event.clientX / window.innerWidth * 2 - 1, -(event.clientY / window.innerHeight) * 2 + 1, 0.5)
    mouse2D.x = event.clientX / window.innerWidth * 2 - 1
    mouse2D.y = -(event.clientY / window.innerHeight) * 2 + 1
    Meteor.clearTimeout(timer);
    timer = Meteor.setTimeout(disableMouseMove
    ,10);
  mouseup: (event) ->
    wasMoving = mouseMoving
    mouseMoving = false
    if !wasMoving
      putDelVoxel()
    return

disableMouseMove = ->
  mouseMoving = false

animate = ->
  requestAnimationFrame animate
  render()

render = ->
  #console.log('render')
  #putDelVoxel()

  if mouseMoving
    # handle rollOverMesh
    mouse2DClone = mouse2D.clone()
    mouse3D = mouse2DClone.unproject(camera)
    #window.ray = ray
    ray.set(camera.position, mouse3D.sub(camera.position).normalize())
    intersects = ray.intersectObjects(objects)
    #console.log('intersects',intersects)
    if intersects.length > 0
      #console.log 'intersect'
      intersector = getRealIntersector(intersects)
      if intersector
        setVoxelPosition intersector
        #console.log 'hur',voxelPosition.x
        rollOverMesh.position.set(voxelPosition.x,voxelPosition.y,voxelPosition.z)

  #if isWDown
  #  distance = camera.position.distanceTo voxelPosition
  #  camera.translateZ( - 10 )
  #  #controls.panUp(10)
  #  camera.translateZ(10)
  #  #camera.translateX(10)
  #  #camera.translateY(10)
  #if isADown
  #  #controls.panLeft(10)
  #  camera.translateX(-10)
  #if isDDown
  #  #controls.panLeft(-10)
  #  camera.translateX(10)
  #if isSDown
  #  #controls.panUp(-10)
  #  camera.translateZ( 10 )
  controls.update()
  renderer.render scene, camera

getRealIntersector = (intersects) ->
  i = 0
  while i < intersects.length
    intersector = intersects[i]
    if intersector.object != rollOverMesh
      return intersector
    i++
  null

setVoxelPosition = (intersector) ->
  #console.log 'beam me up'
  window.intersector = intersector
  window.voxelPosition = voxelPosition
  tmpVec.copy intersector.face.normal
  voxelPosition.addVectors intersector.point, tmpVec
  #voxelPosition.add intersector.point, intersector.object.matrixRotationWorld.multiplyVector3(tmpVec)
  #multiply = intersector.object.matrixWorld.multiplyVector3(tmpVec)
  #voxelPosition.addVectors intersector.point, multiply
  voxelPosition.x = Math.floor(voxelPosition.x / 50) * 50 + 25
  voxelPosition.y = Math.floor(voxelPosition.y / 50) * 50 + 25
  voxelPosition.z = Math.floor(voxelPosition.z / 50) * 50 + 25

putDelVoxel = ->
  return if mouseMoving
  # rate limiter for the painting
  if Date.now() - lastPutDelDate < 0.5 * 1000
    return
  lastPutDelDate = Date.now()
  intersects = ray.intersectObjects(objects)
  if intersects.length > 0
    intersector = getRealIntersector(intersects)
    # delete cube
    if isCtrlDown
      console.log 'pasta',intersector.object
      if intersector.object != plane
        console.log 'kill'
        scene.remove intersector.object
    # create cube
    else
      intersector = getRealIntersector(intersects)
      setVoxelPosition intersector
      voxel = new THREE.Mesh(cubeGeo, cubeMaterials[cubeType])
      voxel.position.copy voxelPosition
      voxel.matrixAutoUpdate = false
      voxel.updateMatrix()
      scene.add voxel
      objects.push voxel

translateCubes = (dx, dy, dz) ->
  console.log 'translateCubes', dx, dy, dz
  children = scene.children
  voxels = []
  i = 0
  while i < children.length
    child = children[i]
    if child instanceof THREE.Mesh == false
      i++
      continue
    if child.geometry instanceof THREE.CubeGeometry == false
      i++
      continue
    if child == rollOverMesh
      i++
      continue
    child.position.x += dx * 50
    child.position.y += dy * 50
    child.position.z += dz * 50
    child.updateMatrix()
    i++
  return

setCubeType = (type) ->
  cubeType = type

# Global key events
window.onkeydown = (event) ->
  console.log 'event.keycode',event.keyCode
  switch event.keyCode
    when 17
      isCtrlDown = true
    when 18
      isAltDown = true
    when 49
      setCubeType 1
    when 50
      setCubeType 2
    when 51
      setCubeType 3
    when 52
      setCubeType 4
    when 53
      setCubeType 5
    when 54
      setCubeType 6
    when 55
      setCubeType 7
    when 56
      setCubeType 8
    when 57
      setCubeType 9
    when 87
      isWDown = true
    when 65
      isADown = true
    when 68
      isDDown = true
    when 83
      isSDown = true
  return

window.onkeyup = (event) ->
  switch event.keyCode
    when 17
      isCtrlDown = false
    when 18
      isAltDown = false
    when 87
      isWDown = false
    when 65
      isADown = false
    when 68
      isDDown = false
    when 83
      isSDown = false
  return