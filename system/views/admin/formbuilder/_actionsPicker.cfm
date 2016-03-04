<cfset actions = args.actions ?: [] />

<cfoutput>
	<div class="accordion-style2 formbuilder-item-type-picker">
		<div class="group">
			<h3 class="accordion-header">#translateResource( uri="formbuilder:action.picker.actions.title" )#</h3>
			<div>
				<ul class="formbuilder-item-type-picker-item-list">
					<cfloop array="#actions#" index="i" item="action">
						<li class="item-type"
						    data-item-template="true"
						    data-item-type="#action.id#"
						    data-requires-configuration="true"
						    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.actionConfigDialog', queryString='action=#action.id#' )#"
						    data-config-title="#translateResource( uri="formbuilder:action.config.modal.title", data=[ action.title ] )#">

							<span><i class="fa fa-fw #action.iconclass#"></i> #action.title#</span>
							<i class="pull-right fa fa-fw fa-reorder grey"></i>
						</li>
					</cfloop>
				</ul>
				<div class="clearfix"></div>
			</div>
		</div>
	</div>
</cfoutput>