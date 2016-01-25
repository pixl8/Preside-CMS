<cfscript>
	theForm   = prc.form ?: QueryNew( '' );
	formId    = theForm.id;
	canDelete = hasCmsPermission( "formbuilder.deleteSubmissions" );
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.formbuilder.statusControls", args=QueryRowToStruct( theForm ) )#

	<div class="tabbable">
		#renderViewlet( event="admin.formbuilder.managementTabs", args={ activeTab="submissions" } )#

		<div class="tab-content">
			<div class="tab-pane active">
				#renderView( view="/admin/datamanager/_objectDataTable", args={
					  objectName      = "formbuilder_formsubmission"
					, useMultiActions = canDelete
					, multiActionUrl  = event.buildAdminLink( linkTo='formbuilder.deleteSubmissionsAction', querystring="formId=#formId#" )
					, datasourceUrl   = event.buildAdminLink( linkTo='formbuilder.listSubmissionsForAjaxDataTable', querystring="formId=#formId#" )
					, gridFields      = [ "submitted_by", "datecreated", "form_instance", "submitted_data" ]
					, allowSearch     = true
				} )#
			</div>
		</div>
	</div>
</cfoutput>