<cfscript>
	object              = rc.object ?: ""
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
	managePermsTitle    = translateResource( uri="cms:datamanager.manageperms.title", data=[ LCase( objectTitleSingular ) ] );

	prc.pageIcon  = "lock";
	prc.pageTitle = managePermsTitle;
</cfscript>

<cfoutput>

</cfoutput>