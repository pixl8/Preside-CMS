<cfscript>
	theForm   = prc.form ?: QueryNew( '' );
	formId    = theForm.id;
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.formbuilder.statusControls", args=QueryRowToStruct( theForm ) )#

	<div class="tabbable">
		#renderViewlet( event="admin.formbuilder.managementTabs", args={ activeTab="actions" } )#

		<div class="tab-content">
			<div class="tab-pane active formbuilder-workbench">
				<div class="row">
					<div class="col-md-5 col-lg-4">
						<div id="tab-fields" class="item-type-picker">
							#renderViewlet( "admin.formbuilder.actionsPicker" )#
						</div>
					</div>
					<div class="col-md-7 col-lg-8">
						<div class="formbuilder-workbench-items">
							#renderViewlet( event="admin.formbuilder.actionsManagement", args={ formId=formId } )#
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>