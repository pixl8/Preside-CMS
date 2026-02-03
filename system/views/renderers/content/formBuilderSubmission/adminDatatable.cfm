<!---@feature admin and formbuilder--->
<cfparam name="args.renderedSubmission" type="string" default="" />

<cfoutput>
	<cfif not isEmptyString( args.renderedSubmission )>
		<div class="formbuilder-submission-preview">
			<span>#args.renderedSubmission#</span>
		</div>
	</cfif>
</cfoutput>