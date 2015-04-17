<cfscript>
	prc.pageTitle    = translateResource( "cms:accessdenied.page.title"    );
	prc.pageSubTitle = translateResource( "cms:accessdenied.page.subtitle" );
	prc.pageIcon     = "ban";
</cfscript>

<cfoutput>
	<p class="alert alert-danger">
		<i class="fa fa-fw fa-exclamation-triangle"></i>
		#translateresource(" cms:accessdenied.page.description" )#
	</p>
</cfoutput>

