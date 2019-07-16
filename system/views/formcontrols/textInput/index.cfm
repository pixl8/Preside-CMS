<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	maxlength    = args.maxlength    ?: "";
	minlength    = args.minlength    ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder  = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	if ( inputId eq 'slug' ) {
		event.include( "/js/admin/specific/slugField/" );
		parentSlug  = reMatch( '.*\/.*(?=\/.*?)', event.buildLink( page=( rc.id ?: "" ) ) ) ?: "";
		previewLink = rc.id ?: "";
	}
</cfscript>

<cfoutput>
	<input type="text" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#value#" class="#inputClass# form-control" tabindex="#getNextTabIndex()#"<cfif isNumeric( maxlength ) and maxlength gt 0> maxlength="#maxlength#"</cfif> <cfif isNumeric( minlength ) and minlength gt 0> minlength="#minlength#"</cfif>>
	<cfif inputId eq 'slug'>
		<p class="text-muted">#parentSlug[1]#/<span id="pageSlug"></span>.html</p>
	</cfif>
</cfoutput>