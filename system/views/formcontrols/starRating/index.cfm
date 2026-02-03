<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	value        = rc[ inputName ]   ?: 0;

	starCount = Val( args.starCount ?: "5" );
	step      = IsTrue( args.allowHalfStars ?: "" ) ? 0.5 : 1;

	language = getModel( "i18n" ).getFWLanguageCode();

	value = rc[ inputName ] ?: defaultValue;
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = Val( value );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<input type="hidden" id="#inputId#" name="#inputName#" data-min="0" data-max="#starCount#" data-stars="#starCount#" data-step="#step#" data-size="xs" data-language="#language#" class="#inputClass# rating" tabindex="#getNextTabIndex()#" value="#value#" #htmlAttributes# />
</cfoutput>
