<cfscript>
	inputName               = args.name                    ?: "";
	inputId                 = args.id                      ?: "";
	inputClass              = args.class                   ?: "";
	placeholder             = args.placeholder             ?: "";
	defaultValue            = args.defaultValue            ?: "";
	savedValue              = args.savedValue              ?: "";
	multiple                = args.multiple                ?: false;
	sortable                = args.sortable                ?: "";
	deselectable            = args.deselectable            ?: true;
	extraClasses            = args.extraClasses            ?: "";
	values                  = args.values                  ?: "";
	removeObjectPickerClass = args.removeObjectPickerClass ?: false;
	objectPickerClass       = removeObjectPickerClass ?  "" : "object-picker";
	addMissingValues        = IsTrue( args.addMissingValues   ?: "" );
	includeEmptyOption      = IsTrue( args.includeEmptyOption ?: "" );
	labels                  = ( structKeyExists( args, "labels") && len( args.labels ) ) ? args.labels : args.values;
	iconClasses             = ( structKeyExists( args, "iconClasses") && len( args.iconClasses ) ) ? args.iconClasses: [];

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }
	if ( IsSimpleValue( iconClasses ) ) { iconClasses = ListToArray( iconClasses ); }

	if ( !ArrayLen( iconClasses ) ) {
		for ( var ix=1; ix<=ArrayLen( values ); ix++ ) {
			ArrayAppend( iconClasses, "" );
		}
	}

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	if ( !len( value ) ) {
		value = savedValue;
	}

	if ( !deselectable ) {
		extraClasses = ListAppend( extraClasses, "non-deselectable", " " );
	}

	value      = htmlEditFormat( value );
	valueFound = false;

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<select class="#inputClass# #objectPickerClass# #extraClasses#"
		name="#inputName#"
		id="#inputId#"
		tabindex="#getNextTabIndex()#"
		data-placeholder="#translateResource( uri=placeholder, defaultValue=placeholder )#"
		data-sortable="#( IsBoolean( sortable ) && sortable ? 'true' : 'false' )#"
		data-value="#value#"
		data-display-limit="0"
		<cfif IsBoolean( multiple ) && multiple>
			multiple="multiple"
		</cfif>
		#htmlAttributes#
	>
		<cfif includeEmptyOption>
			<option value=""></option>
		</cfif>
		<cfloop array="#values#" index="i" item="selectValue">
			<cfset selectValue=EncodeForHTML( selectValue ) />
			<cfset selected=ListFindNoCase( value, selectValue ) />
			<cfset valueFound=valueFound || selected />
			<cfset label=EncodeForHTML( translateResource( labels[ i ] ?: "", labels[ i ] ?: "" ) ) />
			<option
				value="#selectValue#"
				title="#label#"
				data-iconClass="#iconClasses[i] ?: ""#"
				<cfif selected> selected="selected"</cfif>
			>
				#label#
			</option>
		</cfloop>
		<cfif value.len() && !valueFound && addMissingValues>
			<option value="#value#" selected="selected">#value#</option>
		</cfif>
	</select>
</cfoutput>
