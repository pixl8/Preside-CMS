<cfset itemTypesByCategory = args.itemTypesByCategory ?: [] />

<cfoutput>
	<div class="formbuilder-item-type-picker">
		<cfloop array="#itemTypesByCategory#" index="i" item="category">
			<h3 class="formbuilder-item-type-picker-category-title">#category.title#</h3>
			<ul class="formbuilder-item-type-picker-item-list">
				<cfloop array="#category.types#" index="n" item="type">
					<li class="item-type"
					    data-item-template="true"
					    data-item-type="#type.id#"
					    data-requires-configuration="#type.requiresConfiguration#"
					    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.itemConfigDialog', queryString='itemtype=#type.id#' )#"
					    data-config-title="#translateResource( uri="formbuilder:itemconfig.modal.title", data=[ type.title ] )#">

						<span>#type.title#</span>
					</li>
				</cfloop>
			</ul>
		</cfloop>
		<div class="clearfix"></div>
	</div>
</cfoutput>