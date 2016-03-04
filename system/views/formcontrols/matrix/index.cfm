<cfscript>
	inputName        = args.name         ?: "";
	inputId          = args.id           ?: "";
	inputClass       = args.class        ?: "";
	defaultValue     = args.defaultValue ?: "";
	rows             = args.rows         ?: [];
	columns          = args.columns      ?: [];
	questionInputIds = args.questionInputIds ?: [];
	multiple     = IsTrue( args.multiple ?: "" );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
	valueFound = false;
	inputType = multiple ? 'checkbox' : 'radio';
</cfscript>

<cfoutput>
	<table class="table">
		<tr>
			<td>&nbsp;</td>
			<cfloop array="#columns#" index="i" item="answer">
				<td><label>#answer#</label></td>
			</cfloop>
		</tr>
		<cfloop array="#rows#" item="question" index="i">
			<cfset questionInputId = questionInputIds[ i ] ?: question />
			<tr>
				<td>
					<label>#question#</label>
					<label class="error"></label>
				</td>
				<cfloop array="#columns#" index="i" item="answer">
					<cfset selected = ListFindNoCase( value, answer ) />
					<td>
						<input type     = "#inputType#"
						       class    = "#inputClass#"
						       name     = "#questionInputId#"
						       id       = "#questionInputId#"
						       tabindex = "#getNextTabIndex()#"
						       value    = "#HtmlEditFormat( answer )#"
						       <cfif selected> checked="checked"</cfif> >
					</td>
				</cfloop>
			</tr>
		</cfloop>
	</table>
</cfoutput>