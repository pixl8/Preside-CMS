<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	icon         = args.icon         ?: "";
	defaultValue = args.defaultValue ?: "";
	multiple     = isTrue( args.multiple ?: "" );
	inputType    = multiple ? "text" : "email";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<label>
		<span class="block <cfif Len( Trim( icon ) )>input-icon input-icon-right</cfif>">
			<input type="#inputType#" class="#inputClass# span12" placeholder="#placeholder#" name="#inputName#" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#"<cfif multiple> multiple</cfif> #htmlAttributes# />
			<cfif Len( Trim ( icon ) )>
				<i class="fa fa-#icon#"></i>
			</cfif>
		</span>
	</label>
</cfoutput>
