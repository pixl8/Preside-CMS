<cfscript>
	objectName          = rc.object         ?: "";
	parentObject        = rc.parentObject    ?: ""
	parentId            = rc.parentId        ?: "";
	relationshipKey     = rc.relationshipKey ?: "";
	gridFields          = prc.gridFields     ?: [ "label","datecreated","datemodified" ];

	objectTitle         = translateResource( uri="preside-objects.#objectName#:title"      , defaultValue=objectName )
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	objectDescription   = translateResource( uri="preside-objects.#objectName#:description", defaultValue="" );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitleSingular ) ] );

	canAdd    = prc.canAdd    ?: false;
	canDelete = prc.canDelete ?: false;

	datatableSourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="object=#objectName#&action=dataManager.getChildObjectRecordsForAjaxDataTables&useMultiActions=#canDelete#&gridFields=#ArrayToList( gridFields )#&parentId=#parentId#&relationshipKey=#relationshipKey#" );
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
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, datasourceUrl   = datatableSourceUrl
		, useMultiActions = canDelete
		, multiActionUrl  = event.buildAdminLink( linkTo='datamanager.multiRecordAction', querystring="object=#objectName#" )
		, gridFields      = gridFields
	} )#
</cfoutput>