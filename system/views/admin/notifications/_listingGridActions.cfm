<cfparam name="args.id"   type="string"  />
<cfparam name="args.read" type="boolean" />

<cfoutput>
	<div class="action-buttons">
		<a class="blue" href="#event.buildAdminLink( linkTo="notifications.view", queryString="id=#args.id#")#" data-context-key="v">
			<i class="fa fa-eye bigger-130"></i>
		</a>
		<cfif !args.read>
			<a class="green" href="#event.buildAdminLink( linkTo="notifications.readAction", queryString="id=#args.id#")#" data-context-key="r">
				<i class="fa fa-check bigger-130"></i>
			</a>
		<cfelse>
			<a class="disabled" disabled="disabled"><i class="fa fa-check bigger-130 grey"></i></a>
		</cfif>
		<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="notifications.dismissAction", queryString="id=#args.id#")#" data-context-key="d" title="#translateResource( 'cms:notifications.discard.prompt' )#">
			<i class="fa fa-trash bigger-130"></i>
		</a>
	</div>
</cfoutput>