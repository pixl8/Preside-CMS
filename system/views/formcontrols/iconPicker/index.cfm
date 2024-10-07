<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	savedValue   = args.savedValue   ?: "";

	resultTemplate     = selectedTemplate = '<i class="fa {{classes}}"></i> {{text}}';
	resultTemplateId   = "result_template_"   & CreateUUID();
	selectedTemplateId = "selected_template_" & CreateUUID();

	value = event.getValue( name=inputName, defaultValue=defaultValue );

	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	if ( !Len( value ) ) {
		value = savedValue;
	}

	value = EncodeForHTML( value );

	icons = args.icons ?: [];

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<script type="text/mustache" id="#resultTemplateId#">#resultTemplate#</script>
	<script type="text/mustache" id="#selectedTemplateId#">#selectedTemplate#</script>
	<select class="#inputClass# object-picker icon-picker"
			name="#inputName#"
			id="#inputId#"
			tabindex="#getNextTabIndex()#"
			data-placeholder="#placeholder#"
			data-value="#value#"
			data-result-template="#resultTemplateId#"
			data-selected-template="#selectedTemplateId#"
			data-display-limit="#ArrayLen( icons )#"
			#htmlAttributes#
	>
		<cfloop item="icon" array="#icons#">
			<cfset selected=ListFind( value, icon ) />
			<option
				value="#icon#"
				class="fa-#icon#"
				<cfif selected> selected="selected"</cfif>
			>
				#icon#
			</option>
		</cfloop>
	</select>
</cfoutput>
