<cfscript>
	objectName          = "security_user"
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitleSingular ) ] );

	prc.pageIcon     = "group";
	prc.pageTitle    = translateResource( "cms:usermanager.userspage.title");
	prc.pageSubTitle = translateResource( "cms:usermanager.userspage.subtitle");
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="usermanager.addUser" )#" data-global-key="a">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-plus"></i>
				#addRecordTitle#
			</button>
		</a>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, useMultiActions = false
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=userManager.getUsersForAjaxDataTables" )
		, gridFields      = [ "active", "login_id", "label", "email_address" ]
	} )#

</cfoutput>