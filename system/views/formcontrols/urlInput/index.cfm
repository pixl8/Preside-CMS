<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: ( args.savedValue ?: "" );
	placeholder  = args.placeholder  ?: "";
	placeholder  = EncodeForHTML( translateResource( uri=placeholder, defaultValue=placeholder ) );

	protocolDefaultValue = "";
	addressDefaultValue  = "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	} else if ( REFindNoCase( "^https?:\/\/([-_A-Z0-9]+\.)+[-_A-Z0-9]+(\/.*)?$", value ) ) {
		protocolDefaultValue = ArrayFirst( ReMatchNoCase( "^https?:\/\/", value ) );
		addressDefaultValue = ReplaceNoCase( value, protocolDefaultValue, "" );
	}

	protocolValues = "https://,http://";

	event.include( "/js/admin/specific/urlInput/" );
</cfscript>

<cfoutput>
	<div class="row row-url-input" id="#inputId#">
		<div class="col-md-3">
			#renderFormControl(
				  argumentCollection = args
				, type               = "select"
				, name               = inputName & "_protocol"
				, id                 = inputId   & "_protocol"
				, class              = inputClass & " url-input url-input-protocol"
				, layout             = ""
				, defaultValue       = protocolDefaultValue
				, values             = protocolValues
				, includeEmptyOption = true
				, placeholder        = ""
			)#
		</div>
		<div class="col-md-9">
			#renderFormControl(
				  argumentCollection = args
				, type               = "textInput"
				, name               = inputName & "_address"
				, id                 = inputId   & "_address"
				, class              = inputClass & " url-input url-input-domain-path"
				, layout             = ""
				, defaultValue       = addressDefaultValue
			)#
		</div>
	</div>
	<input type="hidden" class="#inputClass# url-input url-input-hidden" id="#inputId#" name="#inputName#" value="#value#" />
</cfoutput>