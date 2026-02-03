<!---@feature formbuilder--->
<cfscript>
	label         = args.label ?: "";
	isCollapsible = isTrue( args.is_collapsible ?: false );
	isCollapsed   = isTrue( args.is_collapsed   ?: false );
</cfscript>

<cfoutput>
	<fieldset class="formbuilder-section">
		<cfif not isEmptyString( label )>
			<legend class="<cfif isCollapsible>formbuilder-section-heading</cfif><cfif isCollapsed> formbuilder-section-heading-active</cfif>">
				#label#
			</legend>
		</cfif>
	</fieldset>
</cfoutput>