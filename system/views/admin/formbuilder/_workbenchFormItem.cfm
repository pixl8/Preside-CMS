<cfparam name="args.id"   type="string" />
<cfparam name="args.type" type="struct" />

<cfoutput>
	<li class="item-type ui-draggable form-item"
	    data-id="#args.id#"
	    data-item-template="false"
	    data-item-type="#args.type.id#"
	    data-requires-configuration="#args.type.requiresConfiguration#"
	    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.itemConfigDialog', queryString='itemtype=#args.type.id#&itemid=#args.id#' )#"
	    data-config-title="#translateResource( uri='formbuilder:itemconfig.modal.title', data=[ args.type.title ] )#">

		<div class="pull-left">
			<cfif args.type.adminPlaceholderViewlet.len()>
				#renderViewlet( event=args.type.adminPlaceholderViewlet, args=args )#
			<cfelse>
				#args.type.title#
			</cfif>
		</div>
		<div class="pull-right">
			<div class="action-buttons btn-group">
				<a href="##" class="edit-link">
					<i class="fa fa-pencil"></i>
				</a>

				<a href="##" class="delete-link" title="#translateResource( uri='formbuilder:delete.item.link.title', data=[ args.type.title ] )#">
					<i class="fa fa-trash"></i>
				</a>
			</div>
		</div>
		<div class="clearfix"></div>
	</li>
</cfoutput>