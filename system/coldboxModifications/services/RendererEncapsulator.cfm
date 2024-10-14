<cfscript>
	// Merge variables from renderer
	StructAppend( variables, attributes.rendererVariables, false );

	variables.viewsHelper           = StructKeyExists( variables, "viewsHelper"           ) ? variables.viewsHelper           : "";
	variables.viewHelperPath        = StructKeyExists( variables, "viewHelperPath"        ) ? variables.viewHelperPath        : "";
	variables.isViewsHelperIncluded = StructKeyExists( variables, "isViewsHelperIncluded" ) ? variables.isViewsHelperIncluded : false;
	variables.renderedHelpers       = StructKeyExists( variables, "renderedHelpers"       ) ? variables.renderedHelpers       : {};

	// Localize context
	variables.event = attributes.event;
	variables.rc 	= attributes.rc;
	variables.prc 	= attributes.prc;
	StructAppend( variables, variables.rc, false );

	// Spoof the arguments scope for backwards compat.  i.e. arguments.args
	variables.arguments = attributes;

 	// Also add these to variables as well for scope-less lookups
	StructAppend( variables, variables.arguments, true );

	// global views helper
	if( len( variables.viewsHelper ) AND ! variables.isViewsHelperIncluded  ){
		include "#variables.viewsHelper#";
		variables.isViewsHelperIncluded = true;
	}

	// view helpers ( directory + view + whatever )
	if(
		Len( attributes.viewHelperPath ?: "" ) AND
		NOT StructKeyExists( variables.renderedHelpers, hash( attributes.viewHelperPath.toString() ) )
	){
		attributes.viewHelperPath.each( function( item ){
			include "#attributes.item#";
		} );
		variables.renderedHelpers[ hash( attributes.viewHelperPath.toString() ) ] = true;
	}

	function includeWrapper( viewPath ){
		// we do this for backward compat: any
		// views with 'var' declarations
		// break without this
		include template=arguments.viewPath;
	}

	includeWrapper( "#attributes.viewPath#.cfm" );
</cfscript>