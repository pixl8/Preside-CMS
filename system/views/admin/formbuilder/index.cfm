<cfscript>
	canAdd = IsTrue( prc.canAdd ?: "" );

	showButtonGroup = canAdd;
</cfscript>

<cfoutput>
	<cfif showButtonGroup>
		<div class="top-right-button-group">
			<cfif canAdd>
				<a class="pull-right inline" href="#event.buildAdminLink( linkTo="formbuilder.addForm" )#" data-global-key="a">
					<button class="btn btn-success btn-sm">
						<i class="fa fa-plus"></i>
						#translateResource( "formbuilder:add.form.btn" )#
					</button>
				</a>
			</cfif>
		</div>
	</cfif>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = "formbuilder_form"
		, useMultiActions = false
		, gridFields      = [ "name", "description", "locked", "active", "active_from", "active_to" ]
		, datasourceUrl   = event.buildAdminLink( "formbuilder.getFormsForAjaxDataTables" )
	} )#
</cfoutput>