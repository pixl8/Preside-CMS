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
	<p><small>#translateResource( "formcontrols.multiSelectPanel:availableOptions.label" )#</small></p>
	<select class="#inputClass# #extraClasses# from"
			name="#inputName#_from"
			id="#inputId#_from"
			tabindex="#getNextTabIndex()#"
			multiple="multiple"
			size="#selectSize#"
			#htmlAttributes#
	>
		<cfloop array="#values#" index="i" item="availableValue">
			<cfset simpleValue = availableValue />

			<cfif !IsSimpleValue( availableValue )>
				<cfset simpleValue = StructKeyList( availableValue ) />
			</cfif>

			<cfset selected = ListFindNoCase( value, simpleValue ) />

			<cfif isFalse( selected ) && IsSimpleValue( availableValue )>
				<option value="#HtmlEditFormat( simpleValue )#">
					#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
				</option>
			</cfif>

			<cfif !IsSimpleValue( availableValue )>
				<optgroup id="#simpleValue#" label="#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#">
					<cfloop array="#availableValue[ simpleValue ].fields ?: []#" index="j" item="relatedField">
						<cfset nestedValue = "#simpleValue#.#relatedField#" />
						<cfset selected    = ListFindNoCase( value, nestedValue ) />

						<cfif isFalse( selected )>
							<option value="#HtmlEditFormat( nestedValue )#">
								#HtmlEditFormat( translateResource( availableValue[ simpleValue ].labels[j] ?: "", availableValue[ simpleValue ].labels[j] ?: "" ) )#
							</option>
						</cfif>
					</cfloop>

					<option class="multi-select-panel-no-nested-option-available" disabled>
						<i>#translateResource( "formcontrols.multiSelectPanel:availableOptions.nested.none.label" )#</i>
					</option>
				</optgroup>
			</cfif>
		</cfloop>
	</select>
</cfoutput>
