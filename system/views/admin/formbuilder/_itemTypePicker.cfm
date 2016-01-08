<cfscript>
	itemTypesByCategory = args.itemTypesByCategory ?: [];
</cfscript>

<cfoutput>
	<div class="formbuilder-item-type-picker">
		<cfloop array="#itemTypesByCategory#" index="i" item="category">
			<dl>
				<dt>#category.title#</dt>

				<cfloop array="#category.types#" index="n" item="type">
					<dd data-id="#type.id#" data-requires-configuration="#type.requiresConfiguration#" class="item-type">
						<a>#type.title#</a>
					</dd>
				</cfloop>
			</dl>
		</cfloop>
		<div class="clearfix"></div>
	</div>
</cfoutput>