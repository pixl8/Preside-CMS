<cfscript>
	object             = args.object           ?: "";
	inputName          = args.name             ?: "";
	inputId            = args.id               ?: "";
	placeholder        = args.placeholder      ?: "";
	defaultValue       = args.defaultValue     ?: "";
	sortable           = args.sortable         ?: "";
	ajax               = args.ajax             ?: true;
	remoteUrl          = args.remoteUrl        ?: "";
	prefetchUrl        = args.prefetchUrl      ?: "";
	records            = args.records          ?: QueryNew('');
	multiple           = args.multiple         ?: false;
	extraClasses       = args.extraClasses     ?: "";
	resultTemplate     = args.resultTemplate   ?: "";
	selectedTemplate   = args.selectedTemplate ?: "";
	disabledValues     = args.disabledValues   ?: "";
	quickAdd           = args.quickAdd         ?: false;
	quickAddUrl        = args.quickAddUrl      ?: event.buildAdminLink( linkTo="datamanager.quickAddForm", querystring="object=#object#" );
	quickAddModalTitle = translateResource( args.quickAddModalTitle ?: "cms:datamanager.quick.add.modal.title" );

	resultTemplateId   = Len( Trim( resultTemplate ) ) ? "result_template_" & CreateUUId() : "";
	selectedTemplateId = Len( Trim( selectedTemplate ) ) ? "selected_template_" & CreateUUId() : "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	if ( quickAdd ) {
		quickAdd = args.hasQuickAddPermission ?: ( hasPermission( "presideobject.#object#.add" ) || hasPermission( permissionKey="datamanager.add", context="datamanager", contextKeys=[ object ] ) );
		if ( quickAdd ) {
			extraClasses = ListAppend( extraClasses, "quick-add", ' ' );
		}
	}
</cfscript>

<cfoutput>
	<cfif Len( Trim( resultTemplate ) ) >
		<script type="text/mustache" id="#resultTemplateId#">#resultTemplate#</script>
	</cfif>
	<cfif Len( Trim( selectedTemplate ) ) >
		<script type="text/mustache" id="#selectedTemplateId#">#selectedTemplate#</script>
	</cfif>
	<select class="object-picker #extraClasses#"
	        name="#inputName#"
	        id="#inputId#"
	        tabindex="#getNextTabIndex()#"
	        data-placeholder="#placeholder#"
	        data-sortable="#( IsBoolean( sortable ) && sortable ? 'true' : 'false' )#"
	        data-value="#value#"
	        <cfif IsBoolean( multiple ) && multiple>
	        	multiple="multiple"
	        </cfif>
	        <cfif Len( Trim( remoteUrl ) )>
		        data-remote-url="#remoteUrl#"
			</cfif>
	        <cfif Len( Trim( prefetchUrl ) )>
		        data-prefetch-url="#prefetchUrl#"
		    </cfif>
		    <cfif Len( Trim( resultTemplateId ) )>
		    	data-result-template="#resultTemplateId#"
		    </cfif>
		    <cfif Len( Trim( selectedTemplateId ) )>
		    	data-selected-template="#selectedTemplateId#"
		    </cfif>
		    <cfif IsBoolean( quickAdd ) and quickAdd>
				data-quick-add-url="#quickAddUrl#"
				data-quick-add-modal-title="#quickAddModalTitle#"
			</cfif>
	>
		<cfif !IsBoolean( ajax ) || !ajax>
			<option>#translateResource( "cms:option.pleaseselect", "" )#</option>
			<cfloop query="records">
				<option value="#records.id#"<cfif ListFindNoCase( value, records.id )> selected="selected"</cfif><cfif ListFindNoCase( disabledValues, records.id )> disabled="disabled"</cfif>>#records.label#</option>
			</cfloop>
		</cfif>
	</select>
</cfoutput>