<cfscript>
	prc.pageTitle    = translateResource( "cms:notfound.page.title"    );
	prc.pageSubTitle = translateResource( "cms:notfound.page.subtitle" );
	prc.pageIcon     = "frown-o";
</cfscript>

<cfoutput>
	<p class="alert alert-danger">
		<i class="fa fa-fw fa-exclamation-triangle"></i>
		#translateresource(" cms:notfound.page.description" )#
	</p>
</cfoutput>

