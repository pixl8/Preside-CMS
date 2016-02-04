<cfscript>
	inputName          		= args.name             			?: "";
	inputId            		= args.id               			?: "";
	inputClass         		= args.class            			?: "";
	placeholder        		= args.placeholder      			?: "";
	defaultValue       		= args.defaultValue     			?: "";
	extraClasses       		= args.extraClasses     			?: "";
	values             		= args.values                		?: "";
	labels             		= len( args.labels ) 				?  args.labels : args.values;

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
	<cfloop array="#values#" index="i" item="selectValue">
		<cfset selected   = ListFindNoCase( value, selectValue ) />
		<cfset valueFound = valueFound || selected />

		<label class="checkbox-inline">
			<input type="checkbox"
				   class="#inputClass# #extraClasses#"
				   name="#inputName#"
				   id="#inputId#"
				   tabindex="#getNextTabIndex()#"
				   value="#HtmlEditFormat( selectValue )#" <cfif selected> checked="checked"</cfif> >
				   #HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
		</label>
		</cfloop>
	</select>
</cfoutput>