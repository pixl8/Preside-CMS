<!---@feature presideForms--->
<cfscript>
	inputName       = args.name            ?: "";
	inputId         = args.id              ?: "";
	inputClass      = args.class           ?: "";
	defaultValue    = args.defaultValue    ?: "";
	accept          = args.accept          ?: "";
	placeholder     = args.placeholder     ?: "";
	maximumfilesize = args.maximumfilesize ?: "";
	placeholder     = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );

	filename = isEmptyString( defaultValue ) || IsJSON( defaultValue ) ? "" : ListLast( defaultValue, "/" );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input type="file" id="#inputId#" class="#inputClass# form-control" placeholder="#placeholder#" name="#inputName#" tabindex="#getNextTabIndex()#"<cfif Len( Trim( accept ) )> accept="#accept#"</cfif> #htmlAttributes# />
	<input type="hidden" class="maxFileSize" id="maxFileSize_#inputId#" name="maxFileSize" value="#maximumfilesize#">
	<span class="form-control-filename">#filename#</span>
</cfoutput>
