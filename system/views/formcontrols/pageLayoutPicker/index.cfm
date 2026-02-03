<!---@feature presideForms and sitetree--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	layouts      = args.layouts    ?: ArrayNew(1);

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) || value == "" ) {
		value = "index";
	}

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<select class="#inputClass# object-picker" data-placeholder="#placeholder#" name="#inputName#" id="#inputId#" tabindex="#getNextTabIndex()#" #htmlAttributes#>
		<option>#translateResource( "cms:option.pleaseselect", "" )#</option>
		<cfloop array="#layouts#" index="layout">
			<option value="#layout.value#"<cfif value eq layout.value> selected="selected"</cfif>>#layout.label#</option>
		</cfloop>
	</select>
</cfoutput>
