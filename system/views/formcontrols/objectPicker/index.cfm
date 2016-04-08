<cfscript>
	object              	= args.object           ?: "";
	inputName           	= args.name             ?: "";
	inputId             	= args.id               ?: "";
	inputClass          	= args.class            ?: "";
	placeholder         	= args.placeholder      ?: "";
	placeholder         	= HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	defaultValue        	= args.defaultValue     ?: "";
	sortable            	= args.sortable         ?: "";
	ajax                	= args.ajax             ?: true;
	remoteUrl           	= args.remoteUrl        ?: "";
	prefetchUrl         	= args.prefetchUrl      ?: "";
	records             	= args.records          ?: QueryNew('');
	searchable          	= args.searchable       ?: true;
	multiple            	= args.multiple         ?: false;
	extraClasses        	= args.extraClasses     ?: "";
	resultTemplate      	= args.resultTemplate   ?: "{{text}}";
	selectedTemplate    	= args.selectedTemplate ?: "{{text}}";
	disabledValues      	= args.disabledValues   ?: "";
	quickAdd            	= args.quickAdd         ?: false;
	quickAddUrl         	= args.quickAddUrl      ?: event.buildAdminLink( linkTo="datamanager.quickAddForm", querystring="object=#object#&multiple=#IsTrue( multiple )#" );
	quickAddModalTitle  	= translateResource( args.quickAddModalTitle ?: "cms:datamanager.quick.add.modal.title" );
	quickEdit           	= args.quickEdit        					 ?: false;
	removeObjectPickerClass	= args.removeObjectPickerClass     			 ?: false;
	objectPickerClass  		= removeObjectPickerClass					 ?  "" : "object-picker" ;

	resultTemplateId   		= Len( Trim( resultTemplate ) ) 			 ? "result_template_" & CreateUUId() : "";
	selectedTemplateId 		= Len( Trim( selectedTemplate ) ) 			 ? "selected_template_" & CreateUUId() : "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	if ( quickAdd ) {
		quickAdd = args.hasQuickAddPermission ?: ( hasCmsPermission( "presideobject.#object#.add" ) || hasCmsPermission( permissionKey="datamanager.add", context="datamanager", contextKeys=[ object ] ) );
		if ( quickAdd ) {
			extraClasses = ListAppend( extraClasses, "quick-add", ' ' );
		}
	}
	if ( quickEdit ) {
		quickEdit = args.hasQuickEditPermission ?: ( hasCmsPermission( "presideobject.#object#.edit" ) || hasCmsPermission( permissionKey="datamanager.edit", context="datamanager", contextKeys=[ object ] ) );
		if ( quickEdit ) {
			extraClasses = ListAppend( extraClasses, "quick-edit", ' ' );

			quickEditUrl        = args.quickEditUrl      ?: event.buildAdminLink( linkTo="datamanager.quickEditForm", querystring="object=#object#&id=" );
			quickEditModalTitle = translateResource( args.quickEditModalTitle ?: "cms:datamanager.quick.edit.modal.title" );

			selectedTemplate &= ' <a class="fa fa-pencil quick-edit-link" href="#quickEditUrl#{{value}}" title="#HtmlEditFormat( quickEditModalTitle )#"></a>';
		}
	}

	if ( !searchable ) {
		extraClasses = ListAppend( extraClasses, "non-searchable", " " );
	}
</cfscript>

<cfoutput>
	<cfif Len( Trim( resultTemplate ) ) >
		<script type="text/mustache" id="#resultTemplateId#">#resultTemplate#</script>
	</cfif>
	<cfif Len( Trim( selectedTemplate ) ) >
		<script type="text/mustache" id="#selectedTemplateId#">#selectedTemplate#</script>
	</cfif>
	<select class="#inputClass# #objectPickerClass# #extraClasses#"
	        name="#inputName#"
	        id="#inputId#"
	        tabindex="#getNextTabIndex()#"
	        data-placeholder="#placeholder#"
	        data-sortable="#( IsBoolean( sortable ) && sortable ? 'true' : 'false' )#"
	        data-value="#HtmlEditFormat( value )#"
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
			<cfif IsBoolean( quickEdit ) and quickEdit>
				data-quick-edit-url="#quickEditUrl#"
				data-quick-edit-modal-title="#quickEditModalTitle#"
			</cfif>
	>
		<cfif !IsBoolean( ajax ) || !ajax>
			<option>#HtmlEditFormat( translateResource( "cms:option.pleaseselect", "" ) )#</option>
			<cfloop query="records">
				<option value="#records.id#"<cfif ListFindNoCase( value, records.id )> selected="selected"</cfif><cfif ListFindNoCase( disabledValues, records.id )> disabled="disabled"</cfif>>#HtmlEditFormat( records.label )#</option>
			</cfloop>
		</cfif>
	</select>
</cfoutput>