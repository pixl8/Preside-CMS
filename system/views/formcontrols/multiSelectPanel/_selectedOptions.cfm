<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "form-control";
	extraClasses = args.extraClasses ?: "";
	sortable     = args.sortable     ?: false;
	selectSize   = args.selectSize   ?: "";
	defaultValue = args.defaultValue ?: "";
	values       = args.values       ?: "";
	labels       = ( structKeyExists( args, "labels") && len( args.labels ) ) ? args.labels : args.values;

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<p><small>#translateResource( "formcontrols.multiSelectPanel:selectedOptions.label" )#</small></p>
	<select class="#inputClass# #extraClasses# to"
			name="#inputName#_to"
			id="#inputId#_to"
			tabindex="#getNextTabIndex()#"
			multiple="multiple"
			size="#selectSize#"
			#htmlAttributes#
	>
		<cfloop array="#values#" index="i" item="selectedValue">
			<cfset simpleValue = selectedValue />

			<cfif !IsSimpleValue( selectedValue )>
				<cfset simpleValue = StructKeyList( selectedValue ) />
			</cfif>

			<cfset selected = IsSimpleValue( selectedValue ) && ListFindNoCase( value, simpleValue ) />

			<cfif isTrue( selected ) && ListLen( simpleValue, "." ) == 1>
				<option value="#HtmlEditFormat( simpleValue )#">
					#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
				</option>
			</cfif>

			<cfif !IsSimpleValue( selectedValue )>
				<optgroup id="#simpleValue#" label="#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#">
					<cfloop array="#selectedValue[ simpleValue ].fields ?: []#" index="j" item="relatedField">
						<cfset nestedValue = "#simpleValue#.#relatedField#" />
						<cfset selected    = ListFindNoCase( value, nestedValue ) />

						<cfif isTrue( selected )>
							<option value="#HtmlEditFormat( nestedValue )#">
								#HtmlEditFormat( translateResource( selectedValue[ simpleValue ].labels[j] ?: "", selectedValue[ simpleValue ].labels[j] ?: "" ) )#
							</option>
						</cfif>
					</cfloop>

					<option class="multi-select-panel-no-nested-option-selected" disabled>
						<i>#translateResource( "formcontrols.multiSelectPanel:selectedOptions.nested.none.label" )#</i>
					</option>
				</optgroup>
			</cfif>
		</cfloop>
	</select>
</cfoutput>
