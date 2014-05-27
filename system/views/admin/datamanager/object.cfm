<cfscript>
	objectName          = rc.id ?: "";
	gridFields          = prc.gridFields ?: ["label","datecreated","datemodified"];
	objectTitle         = translateResource( uri="preside-objects.#objectName#:title"      , defaultValue=objectName )
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	objectDescription   = translateResource( uri="preside-objects.#objectName#:description", defaultValue="" );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitleSingular ) ] );
	managePermsTitle    = translateResource( uri="cms:datamanager.manageperms.link", data=[ LCase( objectTitleSingular ) ] );

	prc.pageIcon     = "puzzle-piece";
	prc.pageTitle    = objectTitle;
	prc.pageSubTitle = objectDescription;
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif hasPermission( permissionKey="datamanager.add", context="datamanager", contextkeys=[ objectName ] )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="datamanager.addRecord", queryString="object=#objectName#" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#addRecordTitle#
				</button>
			</a>
		</cfif>
		<cfif hasPermission( permissionKey="datamanager.manageContextPerms", context="datamanager", contextkeys=[ objectName ] )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="datamanager.manageperms", queryString="object=#objectName#" )#" data-global-key="p">
				<button class="btn btn-default btn-sm">
					<i class="fa fa-lock"></i>
					#managePermsTitle#
				</button>
			</a>
		</cfif>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, useMultiActions = true
		, multiActionUrl  = event.buildAdminLink( linkTo='datamanager.multiRecordAction', querystring="object=#objectName#" )
		, gridFields      = gridFields
	} )#
</cfoutput>