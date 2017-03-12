<cfscript>
	object                  = args.object           ?: "";
	inputName               = args.name             ?: "";
	inputId                 = args.id               ?: "";
	inputClass              = args.class            ?: "";
	placeholder             = args.placeholder      ?: "";
	placeholder             = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	defaultValue            = args.defaultValue     ?: "";
	records                 = args.records          ?: QueryNew('');
	extraClasses            = args.extraClasses     ?: "";
	multiple                = isBoolean( args.multiple ?: "" ) && args.multiple;
	sortable                = isBoolean( args.sortable ?: "" ) && args.sortable;
	disabled                = isBoolean( args.disabled ?: "" ) && args.disabled;
	disabledValues          = args.disabledValues   ?: "";
	fields                  = args.fields           ?: "";
	targetFields            = len( args.targetFields ) ? args.targetFields : fields;
	formName                = args.formName         ?: "";
	relationshipKey         = args.relationshipKey  ?: args.sourceObject;
	labelRenderer           = args.labelRenderer    ?: "";
	configuratorLabelUrl    = event.buildAdminLink( linkTo="labels.renderJson", querystring="labelRenderer=#labelRenderer#" );
	configuratorAddUrl      = event.buildAdminLink( linkTo="datamanager.configuratorForm", querystring="object=#object#&formName=#formName#" );
	objectSingularName      = translateResource( "preside-objects.#object#:title.singular" );
	configuratorModalTitle  = translateResource( uri=args.quickAddModalTitle ?: "cms:datamanager.configurator.add.modal.title", data=[ lcase( objectSingularName ) ] );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	extraClasses = ListAppend( extraClasses, "configurator-add non-searchable", ' ' );
</cfscript>

<cfoutput>
	<input class = "#inputClass# object-configurator #extraClasses#"
			name  = "#inputName#"
			id    = "#inputId#"
			<cfif disabled>disabled</cfif>
			tabindex         = "#getNextTabIndex()#"
			data-placeholder = "#placeholder#"
			data-value       = "#HtmlEditFormat( value )#"
			<cfif IsBoolean( multiple ) && multiple>
				multiple      = "multiple"
			</cfif>
			<cfif IsBoolean( sortable ) && sortable>
				data-sortable = "true"
			</cfif>
			data-configurator-label-url     = "#configuratorLabelUrl#"
			data-configurator-form-url      = "#configuratorAddUrl#"
			data-configurator-modal-title   = "#configuratorModalTitle#"
			data-relationship-key           = "#relationshipKey#"
			data-configurator-fields        = "#fields#"
			data-configurator-target-fields = "#targetFields#"
	>
</cfoutput>
