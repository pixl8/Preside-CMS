<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	basedOn      = args.basedOn      ?: "label";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<input type="text" class="#inputClass# auto-slug form-control" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#HtmlEditFormat( value )#" data-based-on="#basedOn#" tabindex="#getNextTabIndex()#">
</cfoutput>