<cfscript>
	inputName               = args.name                    ?: "";
	inputId                 = args.id                      ?: "";
	inputClass              = args.class                   ?: "";
	placeholder             = args.placeholder             ?: "";
	placeholder             = translateResource( uri=placeholder, defaultValue=placeholder );
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

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
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
</cfscript>

<cfoutput>
	<select class="#inputClass# #objectPickerClass# #extraClasses#"
		name="#inputName#"
		id="#inputId#"
		tabindex="#getNextTabIndex()#"
		data-placeholder="#placeholder#"
		data-sortable="#( IsBoolean( sortable ) && sortable ? 'true' : 'false' )#"
		data-value="#value#"
		data-display-limit="0"
		<cfif IsBoolean( multiple ) && multiple>
			multiple="multiple"
		</cfif>
	>
		<cfif len( trim( placeholder ) ) || includeEmptyOption>
			<option value="">#placeholder#</option>
		</cfif>
		<cfloop array="#values#" index="i" item="selectValue">
			<cfset selectValue = htmlEditFormat( selectValue ) />
			<cfset selected    = listFindNoCase( value, selectValue ) />
			<cfset valueFound  = valueFound || selected />
			<option value="#selectValue#"<cfif selected> selected="selected"</cfif>>
				#htmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
			</option>
		</cfloop>
		<cfif value.len() && !valueFound && addMissingValues>
			<option value="#value#" selected="selected">#value#</option>
		</cfif>
	</select>
</cfoutput>