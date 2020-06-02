<cfset itemTypesByCategory = args.itemTypesByCategory ?: [] />

<cfoutput>
	<div class="accordion-style2 formbuilder-item-type-picker">
		<cfloop array="#itemTypesByCategory#" index="i" item="category">
			<div class="group">
				<h3 class="accordion-header">#category.title#</h3>
				<div>
					<ul class="formbuilder-item-type-picker-item-list">
						<cfloop array="#category.types#" index="n" item="type">
							<li class="item-type"
							    data-item-template="true"
							    data-item-type="#type.id#"
							    data-requires-configuration="#type.requiresConfiguration#"
							    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.itemConfigDialog', queryString='itemtype=#type.id#' )#"
							    data-config-title="#translateResource( uri="formbuilder:itemconfig.modal.title", data=[ type.title ] )#">

								<span>
									<i class="fa fa-fw #type.iconClass#"></i>&nbsp;
									#type.title#
								</span>
								<i class="pull-right fa fa-fw fa-reorder grey"></i>
							</li>
						</cfloop>
					</ul>
					<div class="clearfix"></div>
				</div>
			</div>
		</cfloop>
	</div>
</cfoutput>