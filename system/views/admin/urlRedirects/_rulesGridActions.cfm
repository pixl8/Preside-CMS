<cfparam name="args.id"    type="string" />
<cfparam name="args.label" type="string" />

<cfoutput>
	<div class="action-buttons">
		<cfif hasCmsPermission( "urlRedirects.editRule" )>
			<a class="blue" href="#event.buildAdminLink( linkTo="urlRedirects.editRule", queryString="id=#args.id#")#" data-context-key="e">
				<i class="fa fa-pencil bigger-130"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "urlRedirects.deleteRule" )>
			<a class="red confirmation-prompt" data-context-key="d" href="#event.buildAdminLink( linkTo="urlRedirects.deleteRuleAction", queryString="id=#args.id#" )#" title="#translateResource( uri='cms:urlRedirects.deleteRule.prompt', data=[args.label] )#">
				<i class="fa fa-trash-o bigger-130"></i>
			</a>
		</cfif>
	</div>
</cfoutput>