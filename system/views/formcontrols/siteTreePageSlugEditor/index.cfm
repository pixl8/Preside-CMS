<cfscript>
	inputName    = args.name         ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	paths        = args.paths        ?: [];

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	event.include( "/js/admin/specific/siteTreePageSlugEditor/" );
	parentSlug   = reMatch( '.*\/.*(?=\/.*?)\/', event.buildLink( page=( rc.id ?: "" ) ) ) ?: "";
	slugEditorId = createUUID();
</cfscript>

<cfoutput>
	<input type="hidden" name="parent_slug_ajax" value="#event.buildLink( linkTo="formcontrols.SiteTreePageSlugEditor.getParentPage" )#" />
	<input type="text" id="#slugEditorId#" name="#inputName#" value="#value#" class="#inputClass# slug-editor form-control" tabindex="#getNextTabIndex()#">
	<p class="text-muted"><span class="parent-slug">#parentSlug[1]#</span><span id="slug-editor-#slugEditorId#"></span>.html</p>
</cfoutput>