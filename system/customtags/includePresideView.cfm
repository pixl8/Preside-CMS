<cfif thisTag.executionMode == "start"><cfsilent>
	<cfparam name="attributes.view" type="string" required="true" />

	<cfscript>
		StructAppend( variables, caller.rendererVariables ?: ( caller.attributes.rendererVariables ?: {} ) );

		viewpath = getModel( "presideRenderer" ).locateView(
			view=reReplace( attributes.view, "^(\\|/)", "" )
		) & ".cfm";

		variables.args  = attributes.args ?: {};
		variables.event = caller.event;
		variables.rc    = event.getCollection();
		variables.prc   = event.getCollection( private=true );

	</cfscript></cfsilent><cfinclude template="#viewpath#">
</cfif>
