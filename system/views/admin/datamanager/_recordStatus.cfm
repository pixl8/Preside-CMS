<cfscript>
	isDraft   = IsTrue( args._version_is_draft );
	hasDrafts = IsTrue( args._version_has_drafts );

	statusText   = translateResource( "cms:datamanager.record.status.published" )
	statusIcon   = "check-circle";
	statusColour = "green";

	if ( isDraft ) {
		statusText   = translateResource( "cms:datamanager.record.status.draft" );
		statusIcon   = "edit";
		statusColour = "light-grey";
	} else if ( hasDrafts ) {
		statusText &= " &nbsp; <em class=""light-grey"">#translateResource( "cms:datamanager.datamanager.status.has.drafts" )#</em>";
	}
</cfscript>

<cfoutput>
	<i class="fa fa-fw fa-#statusIcon# #statusColour#"></i>
	#statusText#
</cfoutput>