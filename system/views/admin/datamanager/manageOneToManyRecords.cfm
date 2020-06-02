<cfscript>
	objectName          = rc.object             ?: "";
	parentObject        = rc.parentObject       ?: "";
	parentId            = rc.parentId           ?: "";
	relationshipKey     = rc.relationshipKey    ?: "";
	gridFields          = prc.gridFields        ?: [ "label","datecreated","datemodified" ];
	canAdd              = IsTrue( prc.canAdd    ?: "" );
	canDelete           = IsTrue( prc.canDelete ?: "" );

	objectTitle         = translateResource( uri="preside-objects.#objectName#:title"      , defaultValue=objectName );
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	objectDescription   = translateResource( uri="preside-objects.#objectName#:description", defaultValue="" );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[  objectTitleSingular  ] );

	datatableSourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="object=#objectName#&action=dataManager.getChildObjectRecordsForAjaxDataTables&useMultiActions=#canDelete#&gridFields=#ArrayToList( gridFields )#&parentId=#parentId#&relationshipKey=#relationshipKey#" );
</cfscript>

<cfoutput>
	<cfif canAdd>
		<div class="top-right-button-group">
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="datamanager.addOneToManyRecord", queryString="object=#objectName#&parentId=#parentId#&relationshipKey=#relationshipKey#" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#addRecordTitle#
				</button>
			</a>
			<div class="clearfix"></div>
		</div>
	</cfif>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, datasourceUrl   = datatableSourceUrl
		, useMultiActions = canDelete
		, multiActionUrl  = event.buildAdminLink( linkTo='datamanager.multiOneToManyRecordAction', querystring="object=#objectName#&parentId=#parentId#&relationshipKey=#relationshipKey#" )
		, gridFields      = gridFields
	} )#
</cfoutput>