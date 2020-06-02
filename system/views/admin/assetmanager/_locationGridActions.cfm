<cfparam name="args.id" type="string" />

<cfoutput>
	<a class="blue" href="#event.buildAdminLink( linkto="assetmanager.editLocation", querystring="id=#args.id#" )#" data-context-key="e">
		<i class="fa fa-fw fa-pencil"></i></a>
</cfoutput>