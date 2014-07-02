<cfscript>
	param name="args._version_number" type="numeric";

	object   = rc.object ?: "";
	id       = rc.id ?: "";
	property = rc.property ?: "";

	loadLink = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=frontendediting.getVersionContent&object=#object#&id=#id#&property=#property#&version=#args._version_number#" );
</cfscript>

<cfoutput>
	<div class="action-buttons btn-group">
		<a href="#loadLink#" class="load-version" title="#translateResource( 'cms:frontendeditor.loadversion.link.title' )#">
			<i class="fa fa-pencil"></i>
		</a>
	</div>
</cfoutput>