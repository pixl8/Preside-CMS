<!---@feature webflow--->
<cfscript>
	event.include( "/js/frontend/webflow/actions/" );

	extraButtonGroupWith = args.extraButtonGroupWith ?: "next";
</cfscript>

<cfoutput>
	<div class="webflow-action-buttons clearfix">
		#( args.prevButton ?: "" )#
		<cfif extraButtonGroupWith == "prev">
			#( args.extraButton ?: "" )#
		</cfif>
		#( args.cancelButton ?: "" )#
		<cfif extraButtonGroupWith neq "prev">
			#( args.extraButton ?: "" )#
		</cfif>
		#( args.nextButton ?: "" )#
	</div>
</cfoutput>
