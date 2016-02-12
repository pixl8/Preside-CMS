<cfscript>
	theForm   = prc.form ?: QueryNew( '' );
	formId    = theForm.id;
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.formbuilder.statusControls", args=QueryRowToStruct( theForm ) )#

	<div class="tabbable">
		#renderViewlet( event="admin.formbuilder.managementTabs", args={ activeTab="actions" } )#

		<div class="tab-content">
			<div class="tab-pane active">
				TODO
			</div>
		</div>
	</div>
</cfoutput>