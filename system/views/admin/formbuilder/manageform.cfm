<cfscript>
	formId  = ( rc.id ?: "" )
	theForm = prc.form ?: QueryNew('');
</cfscript>

<cfoutput>
	<div class="tabbable">
		#renderViewlet( event="admin.formbuilder.managementTabs", args={ activeTab="manage" } )#

		<div class="tab-content">
			<div class="tab-pane active formbuilder-workbench">
				<div class="row">
					<div class="col-md-4 col-lg-3">
						<div id="tab-fields" class="item-type-picker">
							#renderViewlet( "admin.formbuilder.itemTypePicker" )#
						</div>
					</div>
					<div class="col-md-8 col-lg-9">
						<div class="formbuilder-workbench-items">
							#renderViewlet( event="admin.formbuilder.itemsManagement", args={ formId=formId } )#
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>