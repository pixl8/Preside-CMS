<cfscript>
	items = args.items ?: [];
</cfscript>

<cfoutput>
	<ul class="list-unstyled form-items">
		<cfloop array="#items#" item="item" index="i">
			<li class="item-type ui-draggable"
			    data-id="#item.id#"
			    data-item-template="false"
			    data-item-type="#item.type.id#"
			    data-requires-configuration="#item.type.requiresConfiguration#"
			    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.itemConfigDialog', queryString='itemtype=#item.type.id#&itemid=#item.id#' )#"
			    data-config-title="#translateResource( uri='formbuilder:itemconfig.modal.title', data=[ item.type.title ] )#">
				<a>#item.type.title#</a>
			</li>

		</cfloop>
	</ul>
	<div class="instructions<cfif !items.len()> empty</cfif>">
		<p class="empty-notice">#translateResource( "formbuilder:manage.empty.form.notice")#</p>
		<p class="not-empty-notice">#translateResource( "formbuilder:manage.drag.new.items.instructions")#</p>
		<i class="fa fa-fw fa-lg fa-plus blue"></i>
	</div>
</cfoutput>