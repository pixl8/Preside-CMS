<cfset itemTypesByCategory = args.itemTypesByCategory ?: [] />

<cfoutput>
	<div class="formbuilder-item-type-picker">
		<cfloop array="#itemTypesByCategory#" index="i" item="category">
			<dl>
				<dt>#category.title#</dt>

				<cfloop array="#category.types#" index="n" item="type">
					<dd class="item-type"
					    data-item-template="true"
					    data-item-type="#type.id#"
					    data-requires-configuration="#type.requiresConfiguration#"
					    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.itemConfigDialog', queryString='itemtype=#type.id#' )#"
					    data-config-title="#translateResource( uri="formbuilder:itemconfig.modal.title", data=[ type.title ] )#">

						<span>#type.title#</span>
					</dd>
				</cfloop>
			</dl>
		</cfloop>
		<div class="clearfix"></div>
	</div>
</cfoutput>