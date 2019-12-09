<cfscript>
	object                  = args.object           ?: "";
	objectTitle             = translateResource( "preside-objects.#object#:title.singular" );
	inputName               = args.name             ?: "";
	inputId                 = args.id               ?: "";
	inputClass              = args.class            ?: "";
	placeholder             = args.placeholder      ?: "";
	placeholder             = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	defaultValue            = args.defaultValue     ?: "";
	sortable                = args.sortable         ?: "";
	ajax                    = args.ajax             ?: true;
	remoteUrl               = args.remoteUrl        ?: "";
	prefetchUrl             = args.prefetchUrl      ?: "";
	records                 = args.records          ?: QueryNew('');
	displayLimit            = args.displayLimit     ?: 200;
	searchable              = args.searchable       ?: true;
	deselectable            = args.deselectable     ?: true;
	multiple                = args.multiple         ?: false;
	extraClasses            = args.extraClasses     ?: "";
	labelRenderer           = args.labelRenderer    ?: "";
	defaultTemplate         = len( labelRenderer ) ? "{{{text}}}" : "{{text}}";
	resultTemplate          = args.resultTemplate   ?: defaultTemplate;
	selectedTemplate        = args.selectedTemplate ?: defaultTemplate;
	disabled                = isBoolean( args.disabled ?: "" ) && args.disabled;
	disabledValues          = args.disabledValues   ?: "";
	quickAdd                = args.quickAdd         ?: false;
	quickAddUrl             = args.quickAddUrl      ?: event.buildAdminLink( linkTo="datamanager.quickAddForm", querystring="object=#object#&multiple=#IsTrue( multiple )#" );
	quickAddModalTitle      = translateResource( args.quickAddModalTitle ?: "cms:datamanager.quick.add.modal.title" );
	quickEdit               = args.quickEdit                             ?: false;
	superQuickAdd           = IsTrue( args.superQuickAdd ?: false );
	superQuickAddUrl        = args.superQuickAddUrl ?: event.buildAdminLink( linkTo="datamanager.superQuickAddAction", querystring="object=#object#" );
	superQuickAddText       = args.superQuickAddText ?: translateResource( uri="cms:datamanager.super.quick.add.text", data=[ objectTitle ] );
	removeObjectPickerClass = args.removeObjectPickerClass               ?: false;
	objectPickerClass       = removeObjectPickerClass                    ?  "" : "object-picker" ;

	resultTemplateId        = Len( Trim( resultTemplate ) )              ? "result_template_" & CreateUUId() : "";
	selectedTemplateId      = Len( Trim( selectedTemplate ) )            ? "selected_template_" & CreateUUId() : "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	if ( !IsBoolean( ajax ) || !ajax ) {
		displayLimit = 0;
	}

	if ( quickAdd ) {
		quickAdd = args.hasQuickAddPermission ?: runEvent( event="admin.datamanager._checkPermission", private=true, prepostexempt=true, eventArguments={ key="add", object=object, throwOnError=false } );
		if ( quickAdd ) {
			extraClasses = ListAppend( extraClasses, "quick-add", ' ' );
		}
	}
	if ( quickEdit ) {
		quickEdit = args.hasQuickEditPermission ?: runEvent( event="admin.datamanager._checkPermission", private=true, prepostexempt=true, eventArguments={ key="edit", object=object, throwOnError=false } );
		if ( quickEdit ) {
			extraClasses = ListAppend( extraClasses, "quick-edit", ' ' );

			quickEditUrl        = args.quickEditUrl      ?: event.buildAdminLink( linkTo="datamanager.quickEditForm", querystring="object=#object#&id=" );
			quickEditModalTitle = translateResource( args.quickEditModalTitle ?: "cms:datamanager.quick.edit.modal.title" );

			selectedTemplate = '<span class="selected-text">' & selectedTemplate & '</span>';
			selectedTemplate &= ' <a class="fa fa-pencil quick-edit-link" href="#quickEditUrl#{{value}}" title="#HtmlEditFormat( quickEditModalTitle )#"></a>';
		}
	}

	if ( !searchable ) {
		extraClasses = ListAppend( extraClasses, "non-searchable", " " );
	}
	if ( !deselectable ) {
		extraClasses = ListAppend( extraClasses, "non-deselectable", " " );
	}
	if ( superQuickAdd ) {
		extraClasses = ListAppend( extraClasses, "super-quick-add", " " );
	}

	filterBy             = args.filterBy             ?: "";
	filterByField        = args.filterByField        ?: filterBy;
	disabledIfUnfiltered = args.disabledIfUnfiltered ?: false;
	includePlaceholder   = args.includePlaceholder   ?: true;
</cfscript>

<cfoutput>
	<cfif Len( Trim( resultTemplate ) ) >
		<script type="text/mustache" id="#resultTemplateId#">#resultTemplate#</script>
	</cfif>
	<cfif Len( Trim( selectedTemplate ) ) >
		<script type="text/mustache" id="#selectedTemplateId#">#selectedTemplate#</script>
	</cfif>
	<select class = "#inputClass# #objectPickerClass# #extraClasses#"
			name  = "#inputName#"
			id    = "#inputId#"
			<cfif isBoolean( ajax ) && ajax>
				<cfif !isEmpty( filterBy )>
					data-filter-by='#filterBy#'
				</cfif>
				<cfif !isEmpty( filterByField )>
					data-filter-by-field='#filterByField#'
				</cfif>
				<cfif !isEmpty( disabledIfUnfiltered )>
					data-disabled-if-unfiltered='#disabledIfUnfiltered#'
				</cfif>
			</cfif>
			<cfif disabled>disabled</cfif>
			tabindex           = "#getNextTabIndex()#"
			data-placeholder   = "#placeholder#"
			data-sortable      = "#( IsBoolean( sortable ) && sortable ? 'true' : 'false' )#"
			data-value         = "#HtmlEditFormat( value )#"
			data-display-limit = "#displayLimit#"
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
			<cfif superQuickAdd>
				data-super-quick-add-url="#superQuickAddUrl#"
				data-quick-add-text="#superQuickAddText#"
			</cfif>
	>
		<cfif !IsBoolean( ajax ) || !ajax>
			<cfif includePlaceholder>
				<option value="">#HtmlEditFormat( translateResource( "cms:option.pleaseselect", "" ) )#</option>
			</cfif>
			<cfloop query="records">
				<cfset labelArgs=queryRowToStruct( records, records.currentRow ) />
				<cfset labelArgs.labelRenderer = labelRenderer />
				<option value="#records.id#"<cfif ListFindNoCase( value, records.id )> selected="selected"</cfif><cfif ListFindNoCase( disabledValues, records.id )> disabled="disabled"</cfif>>#renderViewlet( event="admin.Labels.render", args=labelArgs )#</option>
			</cfloop>
		</cfif>
	</select>
</cfoutput>