<cfscript>
	objectName          = "security_role"
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitleSingular ) ] );

	prc.pageIcon     = "group";
	prc.pageTitle    = translateResource( "cms:usermanager.rolespage.title");
	prc.pageSubTitle = translateResource( "cms:usermanager.rolespage.subtitle");
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="usermanager.addRole" )#" data-global-key="a">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-plus"></i>
				#addRecordTitle#
			</button>
		</a>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, useMultiActions = true
		, multiActionUrl  = event.buildAdminLink( linkTo='userManager.deleteRoleAction' )
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=userManager.getRolesForAjaxDataTables" )
		, gridFields      = [ "label", "description" ]
	} )#
</cfoutput>