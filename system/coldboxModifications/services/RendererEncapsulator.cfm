<cfscript>
	// Merge variables from renderer
	StructAppend( variables, attributes.rendererVariables, false );

	variables.isViewsHelperIncluded = variables.isViewsHelperIncluded ?: false;
	variables.renderedHelpers 		= variables.renderedHelpers       ?: {};

	// Localize context
	variables.event = attributes.event;
	variables.rc 	= attributes.rc;
	variables.prc 	= attributes.prc;

	// Spoof the arguments scope for backwards compat.  i.e. arguments.args
	variables.arguments = {
		view 			= attributes.view,
		viewPath 		= attributes.viewPath,
		viewHelperPath 	= attributes.viewHelperPath,
		args 			= attributes.args
	};

 	// Also add these to variables as well for scope-less lookups
	StructAppend( variables, variables.arguments, true );

	// global views helper
	if( len( variables.viewsHelper ) AND ! variables.isViewsHelperIncluded  ){
		include "#variables.viewsHelper#";
		variables.isViewsHelperIncluded = true;
	}

	// view helpers ( directory + view + whatever )
	if(
		arguments.viewHelperPath.len() AND
		NOT variables.renderedHelpers.keyExists( hash( arguments.viewHelperPath.toString() ) )
	){
		arguments.viewHelperPath.each( function( item ){
			include "#arguments.item#";
		} );
		variables.renderedHelpers[ hash( arguments.viewHelperPath.toString() ) ] = true;
	}

	function includeWrapper( viewPath ){
		// we do this for backward compat: any
		// views with 'var' declarations
		// break without this
		include template=arguments.viewPath;
	}

	includeWrapper( "#arguments.viewPath#.cfm" );
</cfscript>