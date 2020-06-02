/**
 * creates a global function executeWithFormBuilderDependencies( codeToExecute )
 * that will run the supplied code if and when jquery and
 * jquery validate are available. Will attempt to dynamically
 * include the libs when not already available.
 *
 */

( function(){

	var jQueryCdn   = 'http://code.jquery.com/jquery-1.12.1.min.js'
	  , validateCdn = 'https://cdnjs.cloudflare.com/ajax/libs/jquery-validate/1.15.0/jquery.validate.min.js'
	  , jQueryLoaded, validateLoaded, librariesAreLoaded, loadDependency;

	librariesAreLoaded = function() {
		jQueryLoaded   = ( typeof jQuery !== "undefined" );
		validateLoaded = jQueryLoaded && ( typeof jQuery.validator !== "undefined" );

		return jQueryLoaded && validateLoaded;
	};
	librariesAreLoaded();

	loadDependency = function( url, success ) {
		var head   = document.getElementsByTagName('head')[0]
		  , done   = false
		  , script = document.createElement('script');

		script.src    = url;
		script.onload = script.onreadystatechange = function() {
			if ( !done && ( !this.readyState || this.readyState == 'loaded' || this.readyState == 'complete' ) ) {
				done = true;
				script.onload = script.onreadystatechange = null;
				head.removeChild( script );

				success();
			};
		};

		head.appendChild( script );
	};

	window.executeWithFormBuilderDependencies = function( codeToExecute ){
		var executed = false
		  , executeCallBackWhenLibsAvailable;

		executeCallBackWhenLibsAvailable = function( callback ) {
			if ( !executed && librariesAreLoaded() ) {
				executed = true;
				callback( window.jQuery );
			}
		}
		executeCallBackWhenLibsAvailable( codeToExecute );

		if ( !executed ) {
			if ( !jQueryLoaded ) {
				loadDependency( jqueryCdn, function(){ executeCallBackWhenLibsAvailable( codeToExecute ); } );
			}
			if ( !validateLoaded ) {
				loadDependency( validateCdn, function(){ executeCallBackWhenLibsAvailable( codeToExecute ); } );
			}
		}
	};

} )();