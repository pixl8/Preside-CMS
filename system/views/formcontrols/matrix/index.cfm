<cfscript>
	inputName          		= args.name             			?: "";
	inputId            		= args.id               			?: "";
	inputClass         		= args.class            			?: "";
	placeholder        		= args.placeholder      			?: "";
	defaultValue       		= args.defaultValue     			?: "";
	rows             		= args.rows                		    ?: "";
	columns             	= args.columns			     	    ?: "";
	options             	= args.options			     	    ?: "";

	if ( len( rows ) ) { rows = ListToArray( rows ); }
	if ( len( columns ) ) { columns = ListToArray( columns ); }

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
	valueFound = false;
</cfscript>

<cfoutput>
	<table class="table">
		<tr>
			<td></td>
			<cfloop array="#columns#" index="i" item="selectedvalue">
				<td><label>#selectedvalue#</label></td>
			</cfloop>
		</tr>
		<cfloop array="#rows#" index="row">
			<tr>
			<td><label>#row#</label></td>
			<cfloop array="#columns#" index="i" item="selectedvalue">
				<cfset selected = ListFindNoCase( value, selectedvalue ) />
				<td><input type="#options#"
					class="#inputClass#"
					name="#inputname#_#row#"
					id="#row##inputid#"
					tabindex="#getNextTabIndex()#"
					value="#HtmlEditFormat( selectedvalue )#" <cfif selected> checked="checked"</cfif> >
				</td>
			</cfloop>
			</tr>
		</cfloop>
	</table>
</cfoutput>