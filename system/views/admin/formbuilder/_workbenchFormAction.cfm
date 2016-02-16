<cfparam name="args.id"            type="string" />
<cfparam name="args.action"        type="struct" />
<cfparam name="args.configuration" type="struct" />
<cfparam name="args.placeholder"   type="string" />

<cfoutput>
	<li class="item-type ui-draggable form-item"
	    data-id="#args.id#"
	    data-item-template="false"
	    data-item-type="#args.action.id#"
	    data-requires-configuration="true"
	    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.actionConfigDialog', queryString='action=#args.action.id#&actionId=#args.id#' )#"
	    data-config-title="#translateResource( uri='formbuilder:action.config.modal.title', data=[ args.action.title ] )#">

		<div class="pull-left">
			#args.placeholder#
		</div>
		<div class="pull-right">
			<div class="action-buttons btn-group">
				<a href="##" class="edit-link">
					<i class="fa fa-pencil"></i>
				</a>

				<a href="##" class="delete-link" title="#translateResource( uri='formbuilder:delete.action.link.title', data=[ args.action.title ] )#">
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