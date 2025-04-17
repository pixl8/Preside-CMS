<!---@feature admin and formbuilder--->
<cfparam name="args.renderedPage" type="string" default="" />

<cfoutput>
	<cfif not isEmptyString( args.renderedPage )>
		<div class="formbuilder-submission-preview">
			<span>#args.renderedPage# </span>
		</div>
	</cfif>
</cfoutput>