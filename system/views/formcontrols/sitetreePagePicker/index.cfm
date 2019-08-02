<cfscript>
	inputName          = args.name         ?: "";
	inputId            = args.id           ?: "";
	inputClass         = args.class        ?: "";
	placeholder        = args.placeholder  ?: "";
	defaultValue       = args.defaultValue ?: "";
	remoteUrl          = args.remoteUrl    ?: "";
	prefetchUrl        = args.prefetchUrl  ?: "";
	sortable           = args.sortable     ?: "";
	multiple           = args.multiple     ?: "";
	resultTemplate     = selectedTemplate = '<span class="result-container"><span class="parent">{{{parent}}} /</span> <span class="title {{inactiveClass}}">{{text}}</span>';
	resultTemplateId   = "result_template_" & CreateUUId();
	selectedTemplateId = "selected_template_" & CreateUUId();
	filterBy             = args.filterBy             ?: "";
	filterByField        = args.filterByField        ?: filterBy;
	disabledIfUnfiltered = args.disabledIfUnfiltered ?: false;


	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<script type="text/mustache" id="#resultTemplateId#">#resultTemplate#</script>
	<script type="text/mustache" id="#selectedTemplateId#">#selectedTemplate#</script>
	<select class="#inputClass# object-picker sitetree-page-picker"
	        name="#inputName#"
	        id="#inputId#"
	        tabindex="#getNextTabIndex()#"
	        data-placeholder="#placeholder#"
	        data-sortable="#( IsBoolean( sortable ) && sortable ? 'true' : 'false' )#"
	        data-value="#value#"
	        data-prefetch-url="#prefetchUrl#"
	        data-remote-url="#remoteUrl#"
	    	data-result-template="#resultTemplateId#"
	    	data-selected-template="#selectedTemplateId#"
	    	data-modal-title="#translateResource( 'cms:sitetree.browser.title' )#"
	    	<cfif !isEmpty( filterBy )>
				data-filter-by='#filterBy#'
			</cfif>
			<cfif !isEmpty( filterByField )>
				data-filter-by-field='#filterByField#'
			</cfif>
			<cfif !isEmpty( disabledIfUnfiltered )>
				data-disabled-if-unfiltered='#disabledIfUnfiltered#'
			</cfif>
	        <cfif IsBoolean( multiple ) && multiple>
	        	multiple="multiple"
	        </cfif>
	></select>
</cfoutput>