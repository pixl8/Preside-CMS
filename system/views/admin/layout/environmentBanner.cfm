<cfscript>
	iconClass = args.iconClass ?: "";
	cssClass  = args.cssClass  ?: "alert-danger";
	message   = args.message   ?: "";
</cfscript>

<cfoutput>
	<cfif Len( Trim( message ) )>
		<div class="environment-banner text-center alert #cssClass#">
			<cfif Len( Trim( iconClass ) )>
				<i class="fa fa-fw #iconClass#"></i>
			</cfif>
			#translateResource( uri=message, defaultValue=message )#
		</div>
	</cfif>
</cfoutput>