<cfparam name="attributes.value" default="" />

<cfif thisTag.executionMode is "start">
	<cfoutput>extension-custom-tag:#attributes.value#</cfoutput>
</cfif>
