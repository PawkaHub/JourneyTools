/**
 * @author mrdoob / http://mrdoob.com/
 */

Menubar.Add = function ( editor ) {

	var container = new UI.Panel();
	container.setClass( 'menu' );

	var title = new UI.Panel();
	title.setClass( 'title' );
	title.setTextContent( 'Add' );
	container.add( title );

	var options = new UI.Panel();
	options.setClass( 'options' );
	container.add( options );

	//

	var meshCount = 0;
	var lightCount = 0;
	var cameraCount = 0;

	editor.signals.editorCleared.add( function () {

		meshCount = 0;
		lightCount = 0;
		cameraCount = 0;

	} );

	// Group

	var option = new UI.Panel();
	option.setClass( 'option' );
	option.setTextContent( 'Group' );
	option.onClick( function () {

		var mesh = new THREE.Group();
		mesh.name = 'Group ' + ( ++ meshCount );

		editor.addObject( mesh );
		editor.select( mesh );

	} );
	options.add( option );

	//

	options.add( new UI.HorizontalRule() );

	// Plane

	var option = new UI.Panel();
	option.setClass( 'option' );
	option.setTextContent( 'Plane' );
	option.onClick( function () {

		var width = 200;
		var height = 200;

		var widthSegments = 1;
		var heightSegments = 1;

		var geometry = new THREE.PlaneGeometry( width, height, widthSegments, heightSegments );
		var material = new THREE.MeshPhongMaterial();
		var mesh = new THREE.Mesh( geometry, material );
		mesh.name = 'Plane ' + ( ++ meshCount );

		editor.addObject( mesh );
		editor.select( mesh );

	} );
	options.add( option );

	// Box

	var option = new UI.Panel();
	option.setClass( 'option' );
	option.setTextContent( 'Box' );
	option.onClick( function () {

		var width = 100;
		var height = 100;
		var depth = 100;

		var widthSegments = 1;
		var heightSegments = 1;
		var depthSegments = 1;

		var geometry = new THREE.BoxGeometry( width, height, depth, widthSegments, heightSegments, depthSegments );
		var mesh = new THREE.Mesh( geometry, new THREE.MeshPhongMaterial() );
		mesh.name = 'Box ' + ( ++ meshCount );

		editor.addObject( mesh );
		editor.select( mesh );

	} );
	options.add( option );

	// Cylinder

	var option = new UI.Panel();
	option.setClass( 'option' );
	option.setTextContent( 'Cylinder' );
	option.onClick( function () {

		var radiusTop = 20;
		var radiusBottom = 20;
		var height = 100;
		var radiusSegments = 32;
		var heightSegments = 1;
		var openEnded = false;

		var geometry = new THREE.CylinderGeometry( radiusTop, radiusBottom, height, radiusSegments, heightSegments, openEnded );
		var mesh = new THREE.Mesh( geometry, new THREE.MeshPhongMaterial() );
		mesh.name = 'Cylinder ' + ( ++ meshCount );

		editor.addObject( mesh );
		editor.select( mesh );

	} );
	options.add( option );

	//

	options.add( new UI.HorizontalRule() );

	// DirectionalLight

	var option = new UI.Panel();
	option.setClass( 'option' );
	option.setTextContent( 'DirectionalLight' );
	option.onClick( function () {

		var color = 0xffffff;
		var intensity = 1;

		var light = new THREE.DirectionalLight( color, intensity );
		light.name = 'DirectionalLight ' + ( ++ lightCount );
		light.target.name = 'DirectionalLight ' + ( lightCount ) + ' Target';

		light.position.set( 0.5, 1, 0.75 ).multiplyScalar( 200 );

		editor.addObject( light );
		editor.select( light );

	} );
	options.add( option );

	//

	options.add( new UI.HorizontalRule() );

	// PerspectiveCamera

	var option = new UI.Panel();
	option.setClass( 'option' );
	option.setTextContent( 'PerspectiveCamera' );
	option.onClick( function() {

		var camera = new THREE.PerspectiveCamera( 50, 1, 1, 10000 );
		camera.name = 'PerspectiveCamera ' + ( ++ cameraCount );

		editor.addObject( camera );
		editor.select( camera );

	} );
	options.add( option );

	return container;

}
