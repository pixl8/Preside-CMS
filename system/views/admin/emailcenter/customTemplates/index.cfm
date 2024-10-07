<!---@feature admin and customEmailTemplates--->
<cfscript>
	objectName          = "email_template"
	gridFields          = [ "name", "sending_method", "send_date", "last_sent_date", "datecreated", "datemodified" ];
	sortableFields      = [ "name", "sending_method", "last_sent_date", "datecreated", "datemodified" ];
	objectTitle         = translateResource( uri = "preside-objects.#objectName#:title"         , defaultValue = objectName );
	objectTitleSingular = translateResource( uri = "preside-objects.#objectName#:title.singular", defaultValue = objectName );
	objectDescription   = translateResource( uri = "preside-objects.#objectName#:description"   , defaultValue = "" );
	addRecordTitle      = translateResource( uri = "cms:emailcenter.customTemplates.add.btn" );
	canAdd              = IsTrue( prc.canAdd    ?: false );
	canDelete           = IsTrue( prc.canDelete ?: false );
</cfscript>
<cfoutput>
	<div class="top-right-button-group">
		<cfif canAdd>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="emailCenter.customTemplates.add" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#addRecordTitle#
				</button>
			</a>
		</cfif>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, useMultiActions = canDelete
		, datasourceUrl   = event.buildAdminLink( linkTo="emailCenter.customTemplates.getRecordsForAjaxDataTables" )
		, multiActionUrl  = event.buildAdminLink( linkTo='emailCenter.customTemplates.deleteAction' )
		, gridFields      = gridFields
		, sortableFields  = sortableFields
		, draftsEnabled   = false
	} )#
</cfoutput>