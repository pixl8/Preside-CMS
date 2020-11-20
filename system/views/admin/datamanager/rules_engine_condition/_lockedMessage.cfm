<cfscript>
	lockedReason = args.record.locked_reason ?: "";
	unlockLink   = args.unlockLink           ?: "";
	canUnlock    = IsTrue( args.canUnlock ?: "" );
</cfscript>
<cfoutput>
	<div class="alert alert-warning">
		<p><i class="fa fa-fw fa-lock"></i> <strong>#translateResource( "preside-objects.rules_engine_condition:condition.is.locked" )#</strong></p>
		<p>#translateResource( "preside-objects.rules_engine_condition:condition.is.locked.description" )#</p>

		<cfif Len( lockedReason )>
			<p><blockquote>#renderContent( "plaintext", lockedReason )#</blockquote></p>
		</cfif>

		<cfif canUnlock>
			<p>
				<a href="#unlockLink#" class="btn btn-warning confirmation-prompt" title="#HtmlEditFormat( translateResource( "preside-objects.rules_engine_condition:unlock.btn.title" ) )#" data-confirmation-match="#HtmlEditFormat( translateResource( "preside-objects.rules_engine_condition:unlock.btn.password" ) )#">
					<i class="fa fa-fw fa-lock-open"></i>
					#translateResource( "preside-objects.rules_engine_condition:unlock.btn" )#
				</a>
			</p>
		</cfif>
	</div>
</cfoutput>