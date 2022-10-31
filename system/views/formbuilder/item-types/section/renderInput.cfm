<cfoutput>
	<fieldset class="formbuilder-accordion">
		<legend class="formbuilder-accordion-heading<cfif isTrue( args.is_collapsed ?: false )> formbuilder-accordion-heading-active</cfif>">
			#( args.label ?: "" )#
		</legend>
	</fieldset>
</cfoutput>
