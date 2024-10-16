<!---@feature admin and emailCenter--->
<cfscript>
	objectName          = "email_blueprint"
	gridFields          = [ "name", "datecreated", "datemodified" ];
	objectTitle         = translateResource( uri = "preside-objects.#objectName#:title"         , defaultValue = objectName );
	objectTitleSingular = translateResource( uri = "preside-objects.#objectName#:title.singular", defaultValue = objectName );
	objectDescription   = translateResource( uri = "preside-objects.#objectName#:description"   , defaultValue = "" );
	addRecordTitle      = translateResource( uri = "cms:datamanager.addrecord.title"            , data = [ LCase( objectTitleSingular ) ] );
	canAdd              = IsTrue( prc.canAdd    ?: false );
	canDelete           = IsTrue( prc.canDelete ?: false );
</cfscript>
<cfoutput>
	<div class="top-right-button-group">
		<cfif canAdd>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="emailCenter.Blueprints.add" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#addRecordTitle#
				</button>
			</a>
		</cfif>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName          = objectName
		, useMultiActions     = canDelete
		, datasourceUrl       = event.buildAdminLink( linkTo="emailCenter.Blueprints.getRecordsForAjaxDataTables" )
		, multiActionUrl      = event.buildAdminLink( linkTo='emailCenter.Blueprints.deleteAction' )
		, gridFields          = gridFields
		, draftsEnabled       = false
	} )#
</cfoutput>