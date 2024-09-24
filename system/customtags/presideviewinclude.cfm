<cfif thisTag.executionMode == "start"><cfsilent>
	<cfparam name="attributes.view" type="string" />

	<cfscript>
		viewpath = getModel( "presideRenderer" ).getViewPathForPresideViewInclude(
			view=reReplace( attributes.view, "^(\\|/)", "" )
		);
		variables.args  = attributes.args ?: {};
		variables.event = caller.event;
		variables.rc    = event.getCollection();
		variables.prc   = event.getCollection( private=true );

	</cfscript></cfsilent><cfinclude template="#viewpath#">
</cfif>
