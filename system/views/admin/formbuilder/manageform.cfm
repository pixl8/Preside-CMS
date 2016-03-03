<cfscript>
	formId  = ( rc.id ?: "" )
	theForm = prc.form ?: QueryNew('');
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.formbuilder.statusControls", args=QueryRowToStruct( theForm ) )#

	<div class="tabbable">
		#renderViewlet( event="admin.formbuilder.managementTabs", args={ activeTab="manage" } )#

		<div class="tab-content">
			<div class="tab-pane active formbuilder-workbench">
				<div class="row">
					<div class="col-md-5 col-lg-4">
						<div id="tab-fields" class="item-type-picker">
							#renderViewlet( "admin.formbuilder.itemTypePicker" )#
						</div>
					</div>
					<div class="col-md-7 col-lg-8">
						<div class="formbuilder-workbench-items">
							#renderViewlet( event="admin.formbuilder.itemsManagement", args={ formId=formId } )#
						</div>
						<br>
						<div class="with-padding">
							<cfif IsTrue( theForm.use_captcha ?: "" )>
								<p class="disabled"><em>#translateResource( 'formbuilder:protected.with.captcha' )#</em></p>
							</cfif>
							<br>
							<div class="form-group">
								<button disabled class="btn btn-disabled">#theForm.button_label ?: 'submit'#</button>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>