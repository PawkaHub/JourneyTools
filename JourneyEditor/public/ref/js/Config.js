/**
 * @author mrdoob / http://mrdoob.com/
 */

var Config = function () {

	var name = 'threejs-editor';

	var storage = {
		'autosave': true,
		'theme': 'css/dark.css',

		'project/renderer': 'WebGLRenderer',
		'project/renderer/antialias': true,
		'project/vr': false,

		'camera/position': [ 500, 250, 500 ],
		'camera/target': [ 0, 0, 0 ],

		'ui/sidebar/animation/collapsed': true,
		'ui/sidebar/geometry/collapsed': false,
		'ui/sidebar/material/collapsed': false,
		'ui/sidebar/object3d/collapsed': false,
		'ui/sidebar/project/collapsed': true,
		'ui/sidebar/scene/collapsed': false,
		'ui/sidebar/script/collapsed': false
	};

	if ( window.localStorage[ name ] === undefined ) {

		window.localStorage[ name ] = JSON.stringify( storage );

	} else {

		var data = JSON.parse( window.localStorage[ name ] );

		for ( var key in data ) {

			storage[ key ] = data[ key ];

		}

	}

	return {

		getKey: function ( key ) {

			return storage[ key ];

		},

		setKey: function () { // key, value, key, value ...

			for ( var i = 0, l = arguments.length; i < l; i += 2 ) {

				storage[ arguments[ i ] ] = arguments[ i + 1 ];

			}

			window.localStorage[ name ] = JSON.stringify( storage );

			console.log( '[' + /\d\d\:\d\d\:\d\d/.exec( new Date() )[ 0 ] + ']', 'Saved config to LocalStorage.' );

		},

		clear: function () {

			delete window.localStorage[ name ];

		}

	}

};
