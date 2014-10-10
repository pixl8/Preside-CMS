<cfscript>
	inputName          = args.name             ?: "";
	inputId            = args.id               ?: "";
	placeholder        = args.placeholder      ?: "";
	defaultValue       = args.defaultValue     ?: "";
	multiple           = args.multiple         ?: false;
	sortable           = args.sortable         ?: "";
	extraClasses       = args.extraClasses     ?: "";
	values             = args.values           ?: "";
	labels             = args.labels           ?: args.values;

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<select class="object-picker #extraClasses#"
	        name="#inputName#"
	        id="#inputId#"
	        tabindex="#getNextTabIndex()#"
	        data-placeholder="#translateResource( uri=placeholder, defaultValue=placeholder )#"
	        data-sortable="#( IsBoolean( sortable ) && sortable ? 'true' : 'false' )#"
	        data-value="#value#"
	        <cfif IsBoolean( multiple ) && multiple>
	        	multiple="multiple"
	        </cfif>
	>
		<cfloop array="#values#" index="i" item="selectValue">
			<option value="#HtmlEditFormat( selectValue )#"<cfif ListFindNoCase( value, selectValue )> selected="selected"</cfif>>
				#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
			</option>
		</cfloop>
	</select>
</cfoutput>