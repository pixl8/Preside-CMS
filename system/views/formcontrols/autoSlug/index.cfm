<cfscript>
	inputName    	= args.name         				?: "";
	inputId      	= args.id           				?: "";
	placeholder  	= args.placeholder  				?: "";
	defaultValue 	= args.defaultValue 				?: "";
	basedOn      	= args.basedOn      				?: "label";
	parentPageSlug 	= prc.parentPage._hierarchy_slug 	? : "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<input type="text" class="auto-slug form-control" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#HtmlEditFormat( value )#" data-based-on="#basedOn#" tabindex="#getNextTabIndex()#" data-ulrPrefix="#cgi.http_host##parentPageSlug#">
</cfoutput>