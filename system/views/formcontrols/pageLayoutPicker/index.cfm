<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	layouts      = args.layouts    ?: ArrayNew(1);

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<select class="#inputClass# object-picker" data-placeholder="#placeholder#" name="#inputName#" id="#inputId#" tabindex="#getNextTabIndex()#">
		<option>#translateResource( "cms:option.pleaseselect", "" )#</option>
		<cfloop array="#layouts#" index="layout">
			<option value="#layout.value#"<cfif value eq layout.value> selected="selected"</cfif>>#layout.label#</option>
		</cfloop>
	</select>
</cfoutput>