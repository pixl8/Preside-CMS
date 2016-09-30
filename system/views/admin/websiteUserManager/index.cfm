<cfscript>
	objectName          = "website_user"
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );

	prc.pageIcon     = "group";
	prc.pageTitle    = translateResource( "cms:websiteUserManager.userspage.title");
	prc.pageSubTitle = translateResource( "cms:websiteUserManager.userspage.subtitle");
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<div class="col-sm-5">
			<div class="col-sm-3">Active users</div>
			<div class="col-sm-2">
				#renderFormControl(
					  type  = "yesNoSwitch"
					, name  = "showActiveUsers"
					, class = "showActiveUsers"
				)#
			</div>	
		</div>
		<cfif hasCmsPermission( "websiteUserManager.add" )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="websiteUserManager.addUser" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitleSingular ) ] )#
				</button>
			</a>
		</cfif>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, id              = "allUsers"
		, useMultiActions = false
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=websiteUserManager.getUsersForAjaxDataTables&topic=#( rc.topic ?: '' )#&active=0" )
		, gridFields      = [ "active", "login_id", "display_name", "email_address", "last_request_made" ]
	} )#

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, id              = "activeUsers"
		, useMultiActions = false
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=websiteUserManager.getUsersForAjaxDataTables&topic=#( rc.topic ?: '' )#&active=1" )
		, gridFields      = [ "active", "login_id", "display_name", "email_address", "last_request_made" ]
	} )#
</cfoutput>