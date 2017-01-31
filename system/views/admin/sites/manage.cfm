<cfscript>
	objectName          = "site";
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="sites.addSite" )#" data-global-key="a">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-plus"></i>
				#translateResource( uri="cms:sites.addrecord.title", data=[  objectTitleSingular  ] )#
			</button>
		</a>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, useMultiActions = false
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=sites.getSitesForAjaxDataTables" )
		, gridFields      = [ "name", "domain", "path" ]
	} )#
</cfoutput>