<!---@feature admin and formbuilder--->
<cfscript>
	formId = args.formId ?: "";
	items  = args.items ?: [];
</cfscript>

<cfoutput>
	<ul class="list-unstyled form-items">
		<cfloop array="#items#" item="item" index="i">
			#renderViewlet( event="admin.formbuilder.workbenchFormItem", args=item )#
		</cfloop>
	</ul>
	<div class="instructions<cfif !items.len()> empty</cfif>">
		<cfif isFeatureEnabled( "formbuilder2" )>
			<p class="empty-notice">
				<a class="btn btn-info" href="#event.buildAdminLink( linkto="formbuilder.importFormFields", queryString="id=#formId#" )#">
					<i class="fa fa-plus bigger-110"></i>
					#translateResource( "formbuilder:importFormFields.import.title" )#
				</a>
				<br />
				<br />
				#translateResource( "formbuilder:manage.empty.form.notice" )#
			</p>
		<cfelse>
			<i class="fa fa-fw fa-lg fa-plus blue"></i>
			<p class="empty-notice">#translateResource( "formbuilder:manage.empty.form.notice")#</p>
		</cfif>

		<p class="not-empty-notice">#translateResource( "formbuilder:manage.drag.new.items.instructions" )#</p>
	</div>
</cfoutput>