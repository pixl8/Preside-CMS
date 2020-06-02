<cfparam name="args.id"            type="string" />
<cfparam name="args.action"        type="struct" />
<cfparam name="args.configuration" type="struct" />
<cfparam name="args.placeholder"   type="string" />
<cfparam name="args.condition"     type="string" default="" />

<cfscript>
	formId = rc.id ?: "";
</cfscript>

<cfoutput>
	<li class="item-type ui-draggable form-item"
	    data-id="#args.id#"
	    data-item-template="false"
	    data-item-type="#args.action.id#"
	    data-requires-configuration="true"
	    data-config-endpoint="#event.buildAdminLink( linkTo='formbuilder.actionConfigDialog', queryString='action=#args.action.id#&actionId=#args.id#&formId=#formId#' )#"
	    data-config-title="#translateResource( uri='formbuilder:action.config.modal.title', data=[ args.action.title ] )#">

		<div class="pull-left">
			#args.placeholder#
		</div>
		<div class="pull-right">
			<cfif Len( Trim( args.condition ) )>
				<span class="light-grey">
					<i class="fa fa-fw fa-map-signs"></i>
					#renderLabel( "rules_engine_condition", args.condition )#
				</span>
			</cfif>
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