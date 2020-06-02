<cfscript>
	actions = args.actions ?: [];
</cfscript>

<cfoutput>
	<ul class="list-unstyled form-items">
		<cfloop array="#actions#" item="action" index="i">
			#renderViewlet( event="admin.formbuilder.workbenchFormAction", args=action )#
		</cfloop>
	</ul>
	<div class="instructions<cfif !actions.len()> empty</cfif>">
		<p class="empty-notice">#translateResource( "formbuilder:empty.form.actions.notice")#</p>
		<p class="not-empty-notice">#translateResource( "formbuilder:drag.new.actions.instructions")#</p>
		<i class="fa fa-fw fa-lg fa-plus blue"></i>
	</div>
</cfoutput>