<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	paths        = args.paths        ?: [];
	autoSlug     = IsTrue( args.autoSlug ?: "" );
	basedOn      = args.basedOn      ?: "label";
	parentSlug   = args.parentSlug   ?: "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	event.include( "/js/admin/specific/siteTreePageSlugEditor/"  )
	     .include( "/css/admin/specific/siteTreePageSlugEditor/" );
</cfscript>

<cfoutput>
	<input type="hidden" name="parent_slug_ajax" value="#event.buildLink( linkTo="formcontrols.SiteTreePageSlugEditor.getParentPage" )#" disabled />
	<input type="text" id="#inputId#" name="#inputName#" placeholder="#placeholder#" value="#HtmlEditFormat( value )#" class="#inputClass# slug-editor form-control<cfif autoSlug> auto-slug</cfif>" tabindex="#getNextTabIndex()#"<cfif autoSlug> data-based-on="#basedOn#"</cfif>>
	<p class="text-muted page-url-preview">
		<span class="parent-slug">#parentSlug#</span><span class="page-slug"></span>.html
	</p>
</cfoutput>