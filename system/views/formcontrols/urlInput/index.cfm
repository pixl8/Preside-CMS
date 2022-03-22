<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: ( args.savedValue ?: "" );
	placeholder  = args.placeholder  ?: "";
	placeholder  = EncodeForHTML( translateResource( uri=placeholder, defaultValue=placeholder ) );

	protocolDefaultValue   = "";
	domainPathDefaultValue = "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	} else if ( REFindNoCase( "^https?:\/\/([-_A-Z0-9]+\.)+[-_A-Z0-9]+(\/.*)?$", value ) ) {
		protocolDefaultValue = ArrayFirst( REMatch( "^https?:\/\/", value ) );
		domainPathDefaultValue = ReplaceNoCase( value, protocolDefaultValue, "" );
	}

	protocol       = args.protocol ?: "";
	protocolValues = isEmptyString( protocol ) ? "http://,https://" : protocol;

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
			)#
		</div>
		<div class="col-md-9">
			#renderFormControl(
				  argumentCollection = args
				, type               = "textInput"
				, name               = inputName & "_domain_path"
				, id                 = inputId   & "_domain_path"
				, class              = inputClass & " url-input url-input-domain-path"
				, layout             = ""
				, defaultValue       = domainPathDefaultValue
			)#
		</div>
	</div>
	<input type="hidden" class="#inputClass#" id="#inputId#" name="#inputName#" value="#value#" />
</cfoutput>