<cfscript>
	objectName          = "security_group";
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[  objectTitleSingular  ] );

	prc.pageIcon     = "group";
	prc.pageTitle    = translateResource( "cms:usermanager.groupspage.title");
	prc.pageSubTitle = translateResource( "cms:usermanager.groupspage.subtitle");
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<cfif hasCmsPermission( "groupmanager.add" )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="usermanager.addGroup" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#addRecordTitle#
				</button>
			</a>
		</cfif>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, useMultiActions = true
		, multiActionUrl  = event.buildAdminLink( linkTo='userManager.deleteGroupAction' )
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=userManager.getGroupsForAjaxDataTables" )
		, gridFields      = [ "label", "description" ]
	} )#
</cfoutput>