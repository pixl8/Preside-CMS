<cfparam name="args.id"             type="string" />
<cfparam name="args.condition_name" type="string" default="" />

<cfoutput>
	<div class="action-buttons">
		<cfif hasCmsPermission( "rulesEngine.edit" )>
			<a class="blue" href="#event.buildAdminLink( linkTo="rulesEngine.editCondition", queryString="id=#args.id#")#" data-context-key="e">
				<i class="fa fa-pencil bigger-130"></i>
			</a>
		</cfif>

		<cfif hasCmsPermission( "rulesEngine.delete" )>
			<a class="red confirmation-prompt" data-context-key="d" href="#event.buildAdminLink( linkTo="rulesEngine.deleteConditionAction", queryString="id=#args.id#" )#" title="#translateResource( uri='cms:rulesengine.deleteCondition.prompt', data=[args.condition_name] )#">
				<i class="fa fa-trash-o bigger-130"></i>
			</a>
		</cfif>
	</div>
</cfoutput>