<cfscript>
	inputName          		= args.name             			?: "";
	inputId            		= args.id               			?: "";
	inputClass         		= args.class            			?: "";
	placeholder        		= args.placeholder      			?: "";
	defaultValue       		= args.defaultValue     			?: "";
	multiple           		= args.multiple         			?: false;
	sortable           		= args.sortable         			?: "";
	extraClasses       		= args.extraClasses     			?: "";
	values             		= args.values                		?: "";
	addMissingValues   		= IsTrue( args.addMissingValues 	?: "" );
	removeObjectPickerClass	= args.removeObjectPickerClass     	?: false;
	objectPickerClass  		= removeObjectPickerClass			?  "" : "object-picker" ;
	labels            		= ( structKeyExists( args, "labels") && len( args.labels ) )  ?  args.labels : args.values;

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
	valueFound = false;
</cfscript>

<cfoutput>
	<select class="#inputClass# #objectPickerClass# #extraClasses#"
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
			<cfset selected   = ListFindNoCase( value, selectValue ) />
			<cfset valueFound = valueFound || selected />
			<option value="#HtmlEditFormat( selectValue )#"<cfif selected> selected="selected"</cfif>>
				#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
			</option>
		</cfloop>
		<cfif value.len() && !valueFound && addMissingValues>
			<option value="#value#" selected="selected">#value#</option>
		</cfif>
	</select>
</cfoutput>