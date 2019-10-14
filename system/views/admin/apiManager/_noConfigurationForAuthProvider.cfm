<cfscript>
	authProvider = args.authProvider ?: "";
</cfscript>

<cfoutput>
	<p class="alert alert-warning">
		<i class="fa fa-fw fa-exclamation-triangle"></i>
		#translateResource( uri="cms:apiManager.configureauth.no.viewlet", data=[ authProvider ] )#
	</p>
</cfoutput>