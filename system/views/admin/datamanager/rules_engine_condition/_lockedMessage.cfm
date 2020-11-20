<cfscript>
	lockedReason = args.record.locked_reason ?: "";
</cfscript>
<cfoutput>
	<div class="alert alert-warning">
		<p><i class="fa fa-fw fa-lock"></i> <strong>#translateResource( "preside-objects.rules_engine_condition:condition.is.locked" )#</strong></p>
		<p>#translateResource( "preside-objects.rules_engine_condition:condition.is.locked.description" )#</p>

		<cfif Len( lockedReason )>
			<p><blockquote>#renderContent( "plaintext", lockedReason )#</blockquote></p>
		</cfif>
	</div>
</cfoutput>