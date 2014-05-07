<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	templates    = args.templates    ?: ArrayNew(1);

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<select class="uber-select" data-placeholder="#placeholder#" name="#inputName#" id="#inputId#" tabindex="#getNextTabIndex()#">
		<option>#translateResource( "cms:option.pleaseselect", "" )#</option>
		<cfloop array="#templates#" index="template">
			<option value="#template.getId()#"<cfif value eq template.getId()> selected="selected"</cfif>>#translateResource( uri=template.getName(), defaultValue=template.getID() )#</option>
		</cfloop>
	</select>
</cfoutput>