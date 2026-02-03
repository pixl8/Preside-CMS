<!---@feature admin and formbuilder--->
<cfscript>
	formId  = ( rc.id ?: "" );
	theForm = prc.form ?: QueryNew('');
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.formbuilder.statusControls", args=QueryRowToStruct( theForm ) )#
	#renderViewlet( event="admin.formbuilder.removalAlert", args=QueryRowToStruct( theForm ) )#

	<div class="tabbable">
		#renderViewlet( event="admin.formbuilder.managementTabs", args={ activeTab="manage" } )#

		<div class="tab-content">
			<div class="tab-pane active formbuilder-workbench">
				<div class="row">
					<div class="col-md-5 col-lg-4">
						<div id="tab-fields" class="item-type-picker">
							#renderViewlet( event="admin.formbuilder.itemTypePicker", args={ formId=formId } )#
						</div>
					</div>
					<div class="col-md-7 col-lg-8">
						<div class="formbuilder-workbench-items">
							#renderViewlet( event="admin.formbuilder.itemsManagement", args={ formId=formId } )#
						</div>
						<br>
						<div class="formbuilder-workbench-items">
							<ul class="list-unstyled setting-items">
								#renderViewlet( event="admin.formbuilder._workbenchSettingItem", args={
									  formId       = formId
									, itemTitle    = translateResource( uri='formbuilder:itemconfig.captcha.type.title' )
									, itemSubTitle = '(<code># IsTrue( theForm.use_captcha ?: "" ) ? "On" : "Off" #</code>)'
									, iconClass    = "fa-robot"
								})#
								#renderViewlet( event="admin.formbuilder._workbenchSettingItem", args={
									  formId       = formId
									, itemTitle    = translateResource( uri='formbuilder:itemconfig.submit_button.type.title' )
									, iconClass    = "fa-arrow-circle-right"
								})#
							</ul>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>