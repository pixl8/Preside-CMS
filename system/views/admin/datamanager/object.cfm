<cfscript>
	objectName          = rc.id          ?: "";
	gridFields          = prc.gridFields ?: ["label","datecreated","datemodified"];
	objectTitle         = prc.objectTitlePlural ?: "";
	objectTitleSingular = prc.objectTitle       ?: "";
	objectIcon          = translateResource( uri = "preside-objects.#objectName#:iconClass"     , defaultValue = "" );
	objectDescription   = translateResource( uri = "preside-objects.#objectName#:description"   , defaultValue = "" );
	addRecordTitle      = translateResource( uri = "cms:datamanager.addrecord.title"            , data = [  objectTitleSingular  ] );
	managePermsTitle    = translateResource( uri = "cms:datamanager.manageperms.link"           , data = [  objectTitleSingular  ] );

	prc.pageIcon        = objectIcon.reReplace( "^fa-", "" );
	prc.pageTitle       = objectTitle;
	prc.pageSubTitle    = objectDescription;
	batchEditableFields = prc.batchEditableFields ?: {};
	canAdd              = IsTrue( prc.canAdd         ?: "" );
	canDelete           = IsTrue( prc.canDelete      ?: "" );
	canSort             = IsTrue( prc.canSort        ?: "" );
	canManagePerms      = IsTrue( prc.canManagePerms ?: "" );
	isMultilingual      = IsTrue( prc.isMultilingual ?: "" );
	draftsEnabled       = IsTrue( prc.draftsEnabled  ?: "" );
</cfscript>
<cfoutput>
	<div class="top-right-button-group">
		<cfif canAdd>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="datamanager.addRecord", queryString="object=#objectName#" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#addRecordTitle#
				</button>
			</a>
		</cfif>
		<cfif canSort>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="datamanager.sortRecords", queryString="object=#objectName#" )#" data-global-key="o">
				<button class="btn btn-info btn-sm">
					<i class="fa fa-sort-amount-asc"></i>
					Sort records
				</button>
			</a>
		</cfif>
		<cfif canManagePerms>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="datamanager.manageperms", queryString="object=#objectName#" )#" data-global-key="p">
				<button class="btn btn-default btn-sm">
					<i class="fa fa-lock"></i>
					#managePermsTitle#
				</button>
			</a>
		</cfif>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName          = objectName
		, useMultiActions     = canDelete
		, multiActionUrl      = event.buildAdminLink( linkTo='datamanager.multiRecordAction', querystring="object=#objectName#" )
		, batchEditableFields = batchEditableFields
		, gridFields          = gridFields
		, isMultilingual      = isMultilingual
		, draftsEnabled       = draftsEnabled
		, allowDataExport     = true
	} )#
</cfoutput>