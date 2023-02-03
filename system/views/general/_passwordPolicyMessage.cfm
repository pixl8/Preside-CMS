<cfscript>
	detailMessages = args.detailMessages ?: [];
	customMessage  = args.customMessage  ?: "";
	renderTitle    = args.renderTitle    ?: true;
</cfscript>

<cfoutput>
	<cfif !isEmpty( detailMessages ) || !isEmptyString( customMessage )>
		<div class="password-policy-message">
	</cfif>

		<cfif !isEmpty( detailMessages )>
			<cfif renderTitle>
				<h4>#translateResource( "cms:passwordpolicy.title" )#</h4>
			</cfif>

			<ul>
				<cfloop array="#detailMessages#" item="message">
					<li>#ucFirst( message )#</li>
				</cfloop>
			</ul>
		</cfif>

		<cfif !isEmptyString( customMessage )>
			#renderContent( "richeditor", customMessage )#
		</cfif>

	<cfif !isEmpty( detailMessages ) || !isEmptyString( customMessage )>
		</div>
	</cfif>
</cfoutput>