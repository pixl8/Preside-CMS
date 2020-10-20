<cfparam name="args.id"            type="string" />
<cfparam name="args.type"          type="struct" />
<cfparam name="args.formId"        type="string" />
<cfparam name="args.configuration" type="struct" />
<cfparam name="args.placeholder"   type="string" />
<cfparam name="args.isV2"          type="boolean" default="false" />

<cfoutput>
	<li class="item-type ui-draggable form-item"
	    data-id="#args.id#"
	    data-item-template="false"
	    data-item-type="#args.type.id#"
	    data-requires-configuration="#args.type.requiresConfiguration#"
	    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.itemConfigDialog', queryString='itemtype=#args.type.id#&itemid=#args.id#&formId=#args.formid#' )#"
	    data-config-clone="#event.buildAdminLink( linkTo='formbuilder.itemConfigDialog', queryString='itemtype=#args.type.id#&itemid=#args.id#&clone=true' )#"
	    data-config-title="#translateResource( uri='formbuilder:itemconfig.modal.title', data=[ args.type.title ] )#">

		<div class="pull-left">
			<i class="fa fa-fw #args.type.iconClass#"></i>&nbsp;
			#args.placeholder#
		</div>
		<div class="pull-right">
			<span class="item-type-name">#args.type.title#</span>
			<div class="action-buttons btn-group">
				<cfif args.type.requiresConfiguration>
					<a href="##" class="edit-link">
						<i class="fa fa-pencil"></i>
					</a>

					<cfif not args.isV2>
						<a href="##" class="clone-link" title="#translateResource( uri='formbuilder:clone.item.link.title', data=[ args.type.title ] )#">
							<i class="fa fa-fw fa-clone"></i>
						</a>
					</cfif>
				<cfelse>
					<a class="grey disabled"><i class="fa fa-fw"></i></a>

					<cfif not args.isV2>
						<a class="grey disabled"><i class="fa fa-fw"></i></a>
					</cfif>
				</cfif>

				<a href="##" class="delete-link" title="#translateResource( uri='formbuilder:delete.item.link.title', data=[ args.type.title ] )#">
					<i class="fa fa-trash"></i>
				</a>

				<a href="##" class="sort-link">
					<i class="fa fa-reorder"></i>
				</a>
			</div>
		</div>
		<div class="clearfix"></div>
	</li>
</cfoutput>