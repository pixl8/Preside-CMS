<cfparam name="attributes.value" default="" />

<cfif thisTag.executionMode is "start">
	<cfoutput>app-custom-tag:#attributes.value#</cfoutput>
</cfif>
