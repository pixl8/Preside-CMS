<cfscript>
	inputName          = args.name             ?: "";
	inputId            = args.id               ?: "";
	inputClass         = args.class            ?: "";
	placeholder        = args.placeholder      ?: "";
	defaultValue       = args.defaultValue     ?: "";
	remoteUrl          = args.remoteUrl        ?: "";
	prefetchUrl        = args.prefetchUrl      ?: "";
	browserUrl         = args.browserUrl       ?: "";
	uploaderUrl        = args.uploaderUrl      ?: "";
	sortable           = args.sortable         ?: "";
	multiple           = args.multiple         ?: "";
	resultTemplate     = selectedTemplate = '<div class="result-container"><div class="icon-container" data-image={{largerImage}}>{{{icon}}}</div> <div class="folder-and-text"><span class="folder">{{folder}}</span> <span class="title">{{text}} <i class="text-muted">{{dimension}}</i></span></div></div>';
	resultTemplateId   = "result_template_" & CreateUUId();
	selectedTemplateId = "selected_template_" & CreateUUId();

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<script type="text/mustache" id="#resultTemplateId#">#resultTemplate#</script>
	<script type="text/mustache" id="#selectedTemplateId#">#selectedTemplate#</script>
	<select class="#inputClass# asset-picker"
	        name="#inputName#"
	        id="#inputId#"
	        tabindex="#getNextTabIndex()#"
	        data-placeholder="#placeholder#"
	        data-sortable="#( IsBoolean( sortable ) && sortable ? 'true' : 'false' )#"
	        data-value="#HtmlEditFormat( value )#"
	        data-prefetch-url="#prefetchUrl#"
	        data-remote-url="#remoteUrl#"
	        data-browser-url="#browserUrl#"
	    	data-result-template="#resultTemplateId#"
	    	data-selected-template="#selectedTemplateId#"
	    	data-modal-title="#translateResource( 'cms:assetmanager.browser.title' )#"
	    	data-uploader-url="#uploaderUrl#"
			data-uploader-modal-title="#translateResource( 'cms:assetmanager.uploader.title' )#"
	        <cfif IsBoolean( multiple ) && multiple>
	        	multiple="multiple"
	        </cfif>
	></select>
</cfoutput>