<cfparam name="args.id"   type="string" />
<cfparam name="args.type" type="struct" />

<cfoutput>
	<li class="item-type ui-draggable"
	    data-id="#args.id#"
	    data-item-template="false"
	    data-item-type="#args.type.id#"
	    data-requires-configuration="#args.type.requiresConfiguration#"
	    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.itemConfigDialog', queryString='itemtype=#args.type.id#&itemid=#args.id#' )#"
	    data-config-title="#translateResource( uri='formbuilder:itemconfig.modal.title', data=[ args.type.title ] )#">

		<div class="pull-left">#args.type.title#</div>
		<div class="pull-right">
			<div class="action-buttons btn-group">
				<a href="##">
					<i class="fa fa-pencil"></i>
				</a>

				<a href="##">
					<i class="fa fa-trash"></i>
				</a>
			</div>
		</div>
		<div class="clearfix"></div>
	</li>
</cfoutput>