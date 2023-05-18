<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";

	remoteUrl   = args.remoteUrl   ?: "";
	prefetchUrl = args.prefetchUrl ?: "";

	resultTemplate     = selectedTemplate = '<i class="fa {{iconClass}}"></i> {{text}}';
	resultTemplateId   = "result_template_"   & CreateUUID();
	selectedTemplateId = "selected_template_" & CreateUUID();

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = EncodeForHTML( value );
</cfscript>

<cfoutput>
	<script type="text/mustache" id="#resultTemplateId#">#resultTemplate#</script>
	<script type="text/mustache" id="#selectedTemplateId#">#selectedTemplate#</script>
	<select class="#inputClass# object-picker icon-picker"
			name="#inputName#"
			id="#inputId#"
			tabindex="#getNextTabIndex()#"
			data-placeholder="#placeholder#"
			data-value="#value#"
			data-remote-url="#remoteUrl#"
			data-prefetch-url="#prefetchUrl#"
			data-result-template="#resultTemplateId#"
			data-selected-template="#selectedTemplateId#"
	>
	</select>
</cfoutput>