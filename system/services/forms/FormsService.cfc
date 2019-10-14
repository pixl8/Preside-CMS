/**
 * @singleton
 * @autodoc
 * @presideService
 */
component displayName="Forms service" {

// CONSTRUCTOR
	/**
	 * @formDirectories.inject           presidecms:directories:forms
	 * @presideObjectService.inject      PresideObjectService
	 * @siteService.inject               SiteService
	 * @validationEngine.inject          ValidationEngine
	 * @i18n.inject                      i18n
	 * @coldbox.inject                   coldbox
	 * @presideFieldRuleGenerator.inject PresideFieldRuleGenerator
	 * @featureService.inject            featureService
	 * @defaultContextName.inject        coldbox:fwSetting:EventAction
	 * @configuredControls.inject        coldbox:setting:formControls
	 */
	public any function init(
		  required array  formDirectories
		, required any    presideObjectService
		, required any    siteService
		, required any    validationEngine
		, required any    i18n
		, required any    coldbox
		, required any    presideFieldRuleGenerator
		, required any    featureService
		, required string defaultContextName
		, required struct configuredControls
	) {
		_setValidationEngine( arguments.validationEngine );
		_setPresideObjectService( arguments.presideObjectService );
		_setI18n( arguments.i18n );
		_setColdbox( arguments.coldbox );
		_setFormDirectories( arguments.formDirectories );
		_setPresideFieldRuleGenerator( arguments.presideFieldRuleGenerator );
		_setFeatureService( arguments.featureService );
		_setDefaultContextName( arguments.defaultContextName );
		_setConfiguredControls( arguments.configuredControls );
		_setSiteService( arguments.siteService );

		_loadForms();

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Returns an array of form names that are indexed
	 * by the service.
	 *
	 * @autodoc
	 *
	 */
	public array function listForms() {
		var forms = StructKeyArray( _getForms() );

		ArraySort( forms, "textnocase" );

		return forms;
	}

	/**
	 * Returns whether or not the given form exists.
	 *
	 * @autodoc
	 * @formName.hint           The name of the form to check
	 * @checkSiteTemplates.hint Whether or not to check within the current active site template
	 *
	 */
	public boolean function formExists( required string formName, boolean checkSiteTemplates=true ) {
		var forms = _getForms();

		return StructKeyExists( forms, arguments.formName ) || ( arguments.checkSiteTemplates && StructKeyExists( forms, _getSiteTemplatePrefix() & arguments.formName ) );
	}

	/**
	 * Returns the raw structural definition of the given form
	 *
	 * @autodoc                      true
	 * @formName.hint                The name of the form to get
	 * @autoMergeSiteForm.hint       Whether or not to automatically merge any matching form definitions in the current active site template
	 * @stripPermissionedFields.hint Whether or not to strip tabs, fieldsets and fields to which the logged in admin user does not have permission
	 * @permissionContext.hint       When checking for permissioned fields, the permission context to use. See [[permissionservice-haspermission]].
	 * @permissionContextKeys.hint   When checking for permissioned fields, the permission context keys to use. See [[permissionservice-haspermission]].
	 */
	public struct function getForm(
		  required string  formName
		,          boolean autoMergeSiteForm       = true
		,          boolean stripPermissionedFields = false
		,          string  permissionContext       = ""
		,          array   permissionContextKeys   = []
	) {
		var forms                  = _getForms();
		var objectName             = "";
		var theForm                = "";
		var siteTemplateFormName   = arguments.autoMergeSiteForm ? ( _getSiteTemplatePrefix() & arguments.formName ) : "";
		var siteTemplateFormExists = arguments.autoMergeSiteForm ? ( siteTemplateFormName != arguments.formName && formExists( siteTemplateFormName, false ) ) : false;

		if ( arguments.autoMergeSiteForm && siteTemplateFormExists ) {
			if ( formExists( arguments.formName, false )  ) {
				theForm = mergeForms( arguments.formName, siteTemplateFormName, false );
			} else {
				theForm = forms[ siteTemplateFormName ];
			}
		} else if ( formExists( arguments.formName ) ) {
			theForm = forms[ arguments.formName ];
		} else {
			objectName = _getPresideObjectNameFromFormNameByConvention( arguments.formName );
			if ( _getPresideObjectService().objectExists( objectName ) ) {
				theForm = getDefaultFormForPresideObject( objectName );
			} else {
				throw(
					  type    = "FormsService.MissingForm"
					, message = "The form, [#arguments.formName#], could not be found"
				);
			}
		}

		if ( arguments.stripPermissionedFields ) {
			theForm = removePermissionedFieldsFromFormDefinition(
				  formDefinition        = theForm
				, permissionContext     = arguments.permissionContext
				, permissionContextKeys = arguments.permissionContextKeys
			);
		}

		return theForm;
	}

	/**
	 * Merges the definitions of two or more forms, register the new form and
	 * and returns the raw structure of the merged form as the result.
	 *
	 * @autodoc
	 * @formName.hint          Name of the source form
	 * @mergeWithFormName.hint Name (or array of names) of the form(s) to merge with
	 * @autoMergeSiteForm.hint Whether or not to automatically merge any matching form definitions in the current active site template
	 */
	public struct function mergeForms( required string formName, required any mergeWithFormName, boolean autoMergeSiteForm=true ) {
		var mergedName = getMergedFormName( arguments.formName, arguments.mergeWithFormName, false );
		var merged     = "";

		if ( formExists( mergedName ) ) {
			return getForm( mergedName );
		}

		if ( !isArray( arguments.mergeWithFormName ) ) {
			arguments.mergeWithFormName = [ arguments.mergeWithFormName ];
		}
		merged = getForm( arguments.formName, arguments.autoMergeSiteForm );
		for( var formNameToMerge in arguments.mergeWithFormName ) {
			merged = _mergeForms(
				  form1 = Duplicate( merged )
				, form2 = Duplicate( getForm( formNameToMerge, arguments.autoMergeSiteForm ) )
			);
		}

		_registerForm( mergedName, merged );

		return merged;
	}

	/**
	 * Returns the raw definition of the given field
	 * within the given form.
	 *
	 * @autodoc
	 * @formName.hint  Name of the form in which the field is defined
	 * @fieldName.hint Name of the field to get
	 *
	 */
	public struct function getFormField( required string formName, required string fieldName ) {
		var frm = getForm( arguments.formName );

		for( var tab in frm.tabs ){
			for( var fieldset in tab.fieldsets ) {
				for( var field in fieldset.fields ) {
					if ( ( field.name ?: "" ) eq arguments.fieldName ) {
						return field;
					}
				}
			}
		}

		throw(
			  type = "FormsService.MissingField"
			, message = "The form field, [#arguments.fieldName#], could not be found in the form, [#arguments.formName#]"
		);
	}

	/**
	 * Returns an array of the field names defined in the form.
	 *
	 * @autodoc
	 * @formName.hint Name of the form whose fields you wish to list.
	 */
	public array function listFields( required string formName, stripPermissionedFields=true, string permissionContext="", array permissionContextKeys=[], array suppressFields =[] ) {
		var frm            = getForm( argumentCollection=arguments );
		var ignoreControls = [ "readonly", "oneToManyManager" ];
		var fields         = [];

		for( var tab in frm.tabs ){
			if ( IsBoolean( tab.deleted ?: "" ) && tab.deleted ) {
				continue;
			}
			for( var fieldset in tab.fieldsets ) {
				if ( IsBoolean( fieldset.deleted ?: "" ) && fieldset.deleted ) {
					continue;
				}
				for( var field in fieldset.fields ) {
					var control = ( field.control ?: "default" ) == "default" ? _getDefaultFormControl( argumentCollection=field ) : field.control;

					if ( !ignoreControls.findNoCase( control ) && !( IsBoolean( field.deleted ?: "" ) && field.deleted ) && !arguments.suppressFields.findNoCase( field.name ) ) {
						ArrayAppend( fields, field.name ?: "" );
					}
				}
			}
		}

		return fields;
	}

	/**
	 * Returns a struct containing arrays of the field names explicitly enabled/disabled for automatic whitespace trimming
	 *
	 * @autodoc
	 * @formName.hint Name of the form whose autoTrim fields you wish to list.
	 */
	public struct function listAutoTrimFields( required string formName, stripPermissionedFields=true, string permissionContext="", array permissionContextKeys=[], array suppressFields =[] ) {
		var frm            = getForm( argumentCollection=arguments );
		var ignoreControls = [ "readonly", "oneToManyManager" ];
		var fields         = { enabled=[], disabled=[] };

		for( var tab in frm.tabs ){
			if ( IsBoolean( tab.deleted ?: "" ) && tab.deleted ) {
				continue;
			}
			for( var fieldset in tab.fieldsets ) {
				if ( IsBoolean( fieldset.deleted ?: "" ) && fieldset.deleted ) {
					continue;
				}
				for( var field in fieldset.fields ) {
					var control         = ( field.control ?: "default" ) == "default" ? _getDefaultFormControl( argumentCollection=field ) : field.control;
					var deleted         = IsBoolean( field.deleted         ?: "" ) && field.deleted;

					if ( !IsBoolean( field.autoTrim ?: "" ) || ignoreControls.findNoCase( control ) || deleted || arguments.suppressFields.findNoCase( field.name ) ) {
						continue;
					}
					if ( field.autoTrim ) {
						fields.enabled.append( field.name ?: "" );
					} else {
						fields.disabled.append( field.name ?: "" );
					}
				}
			}
		}

		return fields;
	}

	/**
	 * Returns a default form definition for the given
	 * Preside object name
	 *
	 * @autodoc
	 * @objectName.hint Name of the object whose definition you wish to get
	 *
	 */
	public struct function getDefaultFormForPresideObject( required string objectName ) {
		var fields     = _getPresideObjectService().getObjectProperties( objectName=arguments.objectName );
		var fieldNames = _getPresideObjectService().getObjectAttribute( objectName=arguments.objectName, attributeName="propertyNames" );
		var formLayout = {
			tabs = [{
				title       = "",
				description = "",
				id          = "default",
				fieldsets   = [{
					title       = "",
					description = "",
					fields      = [],
					id          = "default"
				}]
			}]
		};

		for( var fieldName in fieldNames ){
			var field = fields[ fieldName ];
			if ( ( field.control ?: "" ) != "none" ) {
				ArrayAppend( formLayout.tabs[1].fieldsets[1].fields, field );

				formLayout.tabs[1].fieldsets[1].fields[ ArrayLen( formLayout.tabs[1].fieldsets[1].fields ) ].sourceObject = arguments.objectName;
			}
		}

		formLayout.tabs[1].fieldsets[1].fields.sort( function( field1, field2 ){
			var order1 = Val( field1.sortOrder ?: 999999999 );
			var order2 = Val( field2.sortOrder ?: 999999999 );

			return order1 == order2 ? 0 : ( order1 > order2 ? 1 : -1 );
		} );

		_applyDefaultLabellingToForm( formName="preside-objects.#objectName#.default", frm=formLayout );

		return formLayout;
	}

	/**
	 * Renders the given form
	 *
	 * @autodoc
	 * @formName.hint            Name of the form to render
	 * @mergeWithFormName.hint   Name of a secondary form to merge with the primary form
	 * @context.hint             Context in which to render the form, e.g. 'admin' or 'website'. See [[presideforms-rendering]] for more details.
	 * @fieldLayout.hint         Viewlet for rendering a field layout. See [[presideforms-rendering]] for more details.
	 * @fieldsetLayout.hint      Viewlet for rendering a fieldset layout. See [[presideforms-rendering]] for more details.
	 * @tabLayout.hint           Viewlet for rendering a tab layout. See [[presideforms-rendering]] for more details.
	 * @formLayout.hint          Viewlet for rendering an overall form layout. See [[presideforms-rendering]] for more details.
	 * @formId.hint              HTML ID of the wrapping form element. This is used for the js validation logic if generated.
	 * @validationResult.hint    An existing validation result object with which to display errors in the form (see [[validation-framework]] and [[presideforms-validation]] for more details)
	 * @includeValidationJs.hint Whether or not to generate and include validation javascript with the form
	 * @savedData.hint           Structure of pre-existing data with which to pre-populate values in the form
	 * @additionalArgs.hint      Structure of additional dynamic args to be passed to the renders of fields, fieldsets and tabs. See [[presideforms-rendering]] for more details.
	 * @fieldNamePrefix.hint     A prefix to add to each field name
	 * @fieldNameSuffix.hint     A suffix to add to each field name
	 * @suppressFields.hint      An array of field names to hide from the rendering
	 *
	 */
	public string function renderForm(
		  required string  formName
		,          string  mergeWithFormName       = ""
		,          string  context                 = "admin"
		,          string  fieldLayout             = "formcontrols.layouts.field"
		,          string  fieldsetLayout          = "formcontrols.layouts.fieldset"
		,          string  tabLayout               = "formcontrols.layouts.tab"
		,          string  formLayout              = "formcontrols.layouts.form"
		,          string  formId                  = ""
		,          string  component               = ""
		,          any     validationResult        = ""
		,          boolean includeValidationJs     = true
		,          string  validationJsJqueryRef   = "presideJQuery"
		,          struct  savedData               = {}
		,          struct  additionalArgs          = {}
		,          string  fieldNamePrefix         = ""
		,          string  fieldNameSuffix         = ""
		,          array   suppressFields          = []
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = ""
		,          array   permissionContextKeys   = []
	) {
		var interceptorArgs = arguments;
		$announceInterception( "preRenderForm", interceptorArgs );

		var mergedFormName    = Len( Trim( arguments.mergeWithFormName ) ) ? getMergedFormName( arguments.formName, arguments.mergeWithFormName ) : arguments.formName;
		var frm               = getForm( argumentCollection=arguments, formName=mergedFormName );
		var coldbox           = _getColdbox();
		var i18n              = _getI18n();
		var renderedTabs      = CreateObject( "java", "java.lang.StringBuffer" );
		var activeTab         = true;
		var renderedFieldSets = "";
		var renderedFields    = "";
		var renderArgs        = "";
		var tabs              = [];

		for( var tab in frm.tabs ){
			if ( IsBoolean( tab.deleted ?: "" ) && tab.deleted ) {
				continue;
			}

			renderedFieldSets = CreateObject( "java", "java.lang.StringBuffer" );
			if ( not Len( Trim( tab.id ?: "" ) ) ) {
				tab.id = CreateUUId();
			}

			for( var fieldset in tab.fieldsets ) {
				if ( IsBoolean( fieldset.deleted ?: "" ) && fieldset.deleted ) {
					continue;
				}

				renderedFields = CreateObject( "java", "java.lang.StringBuffer" );

				for( var field in fieldset.fields ) {
					if ( ( IsBoolean( field.deleted ?: "" ) && field.deleted ) || arguments.suppressFields.findNoCase( field.name ) ) {
						continue;
					}
					if ( ( field.control ?: "default" ) neq "none" ) {
						renderArgs = {
							  name               = arguments.fieldNamePrefix & ( field.name ?: "" ) & arguments.fieldNameSuffix
							, type               = field.control ?: "default"
							, context            = arguments.context
							, savedData          = arguments.savedData
						};

						if ( not IsSimpleValue( validationResult ) and validationResult.fieldHasError( renderArgs.name ) ) {
							renderArgs.error = i18n.translateResource(
								  uri          = validationResult.getError( renderArgs.name )
								, defaultValue = validationResult.getError( renderArgs.name )
								, data         = validationResult.listErrorParameterValues( renderArgs.name )
							);
						}

						if ( renderArgs.type eq "default" ) {
							renderArgs.type = _getDefaultFormControl( argumentCollection = field );
						}

						if ( StructKeyExists( arguments.savedData, field.name ) ) {
							renderArgs.defaultValue = arguments.savedData[ field.name ];
						} else if ( StructKeyExists( arguments.savedData, renderArgs.name ) ) {
							renderArgs.defaultValue = arguments.savedData[ renderArgs.name ];
						} else if ( StructKeyExists( field, "default" ) ) {
							renderArgs.defaultValue = _runDefaultValueFunction( field.sourceObject ?: "", field.default );
						}

						renderArgs.layout = field.layout ?: _formControlHasLayout( renderArgs.type ) ? arguments.fieldlayout : "";

						renderArgs.append( field, false );
						renderArgs.append( _getI18nFieldAttributes( field=field ) );
						renderArgs.append( arguments.additionalArgs.fields[ field.name ?: "" ] ?: {} );

						renderedFields.append( renderFormControl( argumentCollection=renderArgs ) );
					}
				}

				renderArgs = Duplicate( fieldset );
				renderArgs.content = renderedFields.toString();
				renderArgs.append( _getI18nTabOrFieldsetAttributes( fieldset ) );
				renderArgs.append( arguments.additionalArgs.fieldsets[ fieldset.id ?: "" ] ?: {} );

				renderedFieldSets.append( coldbox.renderViewlet(
					  event = ( fieldset.layout ?: arguments.fieldsetLayout )
					, args  = renderArgs
				) );
			}

			renderArgs         = Duplicate( tab );
			renderArgs.content = renderedFieldSets.toString();
			renderArgs.active  = activeTab;
			renderArgs.append( _getI18nTabOrFieldsetAttributes( tab ) );
			renderArgs.append( arguments.additionalArgs.tabs[ tab.id ?: "" ] ?: {} );

			tabs.append( renderArgs );

			renderedTabs.append( coldbox.renderViewlet(
				  event = ( tab.layout ?: arguments.tabLayout )
				, args  = renderArgs
			) );
			activeTab = false;
		}

		var formArgs = {
			  formId                = arguments.formId
			, formName              = mergedFormName
			, content               = renderedTabs.toString()
			, tabs                  = tabs
			, validationResult      = arguments.validationResult
			, validationJs          = arguments.includeValidationJs ? getValidationJs( argumentCollection=arguments ) : ""
			, validationJsJqueryRef = arguments.validationJsJqueryRef
		};

		formArgs.append( frm, false );

		interceptorArgs.rendered = coldbox.renderViewlet( event=arguments.formLayout, args=formArgs );

		$announceInterception( "postRenderForm", arguments );

		return interceptorArgs.rendered;
	}

	/**
	 * Renders an individual form control. If in doubt, you should
	 * use `renderForm` instead of rendering individual form controls.
	 *
	 * @autodoc
	 * @name.hint           The name of the field to use
	 * @type.hint           The control type, e.g. 'richeditor'
	 * @context.hint        The context
	 * @id.hint             The HTML ID to use for the rendered form control
	 * @label.hint          The label for the control. Can be an i18n resource URI.
	 * @defaultValue.hint   The default value to prepopulate the control with (e.g. a saved value from the database)
	 * @help.hint           Help text to accompany the control. Can be an i18n resource URI.
	 * @savedData.hint      Structure of saved data for the entire form that is being rendered.
	 * @savedDataField.hint If specified, the form control's defaultValue will be sourced from this alternate field in savedData
	 * @error.hint          Error string to display with the control
	 * @required.hint       Whether or not the form field is required
	 * @layout.hint         Viewlet to use to render the field's layout
	 */
	public string function renderFormControl(
		  required string  name
		, required string  type
		,          string  context        = _getDefaultContextName()
		,          string  id             = arguments.name
		,          string  label          = ""
		,          string  savedValue     = ""
		,          string  defaultValue   = ""
		,          string  help           = ""
		,          struct  savedData      = {}
		,          string  savedDataField = ""
		,          string  error          = ""
		,          boolean required       = false
		,          string  layout         = "formcontrols.layouts.field"

	) {
		var coldbox         = _getColdbox();
		var handler         = _getFormControlHandler( type=arguments.type, context=arguments.context );
		var renderedControl = "";

		if ( len( arguments.savedDataField ) && StructKeyExists( arguments.savedData, arguments.savedDataField ) ) {
			arguments.defaultValue = arguments.savedData[ arguments.savedDataField ];
		}

		try {
			renderedControl = coldbox.renderViewlet(
				  event = handler
				, args  = arguments
			);
		} catch ( "HandlerService.EventHandlerNotRegisteredException" e ) {
			renderedControl = "**control, [#arguments.type#], not found**";
		} catch ( "missinginclude" e ) {
			renderedControl = "**control, [#arguments.type#], not found**";
		}

		if ( Len( Trim( arguments.layout ) ) && Len( Trim( renderedControl ) ) ) {
			var layoutArgs = {
				  control  = renderedControl
				, label    = arguments.label
				, for      = arguments.id
				, error    = arguments.error
				, required = arguments.required
				, help     = arguments.help
			};
			layoutArgs.append( arguments, false );

			renderedControl = coldbox.renderViewlet(
				  event = arguments.layout
				, args  = layoutArgs
			);
		}

		return renderedControl;
	}

	/**
	 * Renders a form control suitable for the given object and object field name (property name).
	 * Supplied arguments will be passed on to the [[formsservice-renderformcontrol]] method along
	 * with the calculated form control type and any other arguments.
	 *
	 * @autodoc
	 * @objectName.hint Name of the object whose field you wish to get a form control for
	 * @fieldName.hint  Name of the field (property) on the object that you wish to get a form control for
	 */
	public string function renderFormControlForObjectField( required string objectName, required string fieldName ) {
		var pobjService     = _getPresideObjectService();
	    var fieldBaseI18n   = pobjService.getResourceBundleUriRoot( arguments.objectName );
		var fieldAttributes = pobjService.getObjectProperty( objectName, arguments.fieldName );
		var fieldType       = pobjService.getDefaultFormControlForPropertyAttributes( argumentCollection = fieldAttributes );
	    var formControlArgs = Duplicate( fieldAttributes );
	    var i18n            = _getI18n();

	    formControlArgs.append( arguments, false );

	    formControlArgs.type         = fieldType;
	    formControlArgs.sourceObject = arguments.objectName;
	    formControlArgs.label        = i18n.translateResource( uri=fieldBaseI18n & "field.#arguments.fieldName#.title"      , defaultValue=arguments.fieldName );
	    formControlArgs.placeholder  = i18n.translateResource( uri=fieldBaseI18n & "field.#arguments.fieldName#.placeholder", defaultValue="" );
	    formControlArgs.help         = i18n.translateResource( uri=fieldBaseI18n & "field.#arguments.fieldName#.help"       , defaultValue="" );
	    formControlArgs.object       = formControlArgs.relatedto ?: "";

	    return renderFormControl( argumentCollection = formControlArgs );
	}

	/**
	 * Validates the given form using the [[validation-framework]].
	 * Returns a [[api-validationresult|validation result]] object.
	 *
	 * @autodoc
	 * @formName.hint         Name of the form to validate
	 * @formData.hint         Data from the form submission
	 * @preProcessData.hint   Whether or not to _preprocess_ form submissions (see [[validation-engine]])
	 * @ignoreMissing.hint    Whether or not to ignore entirely missing fields in the supplied data
	 * @validationResult.hint A pre-existing validation result to which to add any errors found during validation
	 * @fieldNamePrefix.hint  Prefix to add to fieldnames in error messages
	 * @fieldNameSuffix.hint  Suffix to add to fieldnames in error messages
	 */
	public any function validateForm(
		  required string  formName
		, required struct  formData
		,          boolean preProcessData          = true
		,          boolean ignoreMissing           = false
		,          any     validationResult        = _getValidationEngine().newValidationResult()
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = ""
		,          array   permissionContextKeys   = []
		,          string  fieldNamePrefix         = ""
		,          string  fieldNameSuffix         = ""
		,          array   suppressFields          = []
	) {
		var ruleset = _getValidationRulesetFromFormName( argumentCollection=arguments );
		var result  = arguments.preProcessData ? preProcessForm( argumentCollection = arguments ) : "";
		var data    = Duplicate( arguments.formData );

		// add active "site" id to form data, should unique indexes require checking against a specific site
		data.site = data.site ?: _getColdBox().getRequestContext().getSiteId();

		if ( arguments.preProcessData ) {
			return _getValidationEngine().validate(
				  ruleset         = ruleset
				, data            = data
				, result          = result
				, ignoreMissing   = arguments.ignoreMissing
				, fieldNamePrefix = arguments.fieldNamePrefix
				, fieldNameSuffix = arguments.fieldNameSuffix
				, suppressFields  = arguments.suppressFields
			);
		}

		return _getValidationEngine().validate(
			  ruleset         = ruleset
			, data            = data
			, result          = arguments.validationResult
			, fieldNamePrefix = arguments.fieldNamePrefix
			, fieldNameSuffix = arguments.fieldNameSuffix
			, suppressFields  = arguments.suppressFields
		);
	}

	/**
	 * Returns raw javascript validation logic for the given form.
	 *
	 * @autodoc
	 * @formName          Name of the form definition from which to generate the validation js
	 * @mergeWithFormName Secondary form name for merging with the primary form
	 *
	 */
	public any function getValidationJs(
		  required string  formName
		,          string  mergeWithFormName     = ""
		,          string  validationJsJqueryRef = "presideJQuery"
		,          string  fieldNamePrefix       = ""
		,          string  fieldNameSuffix       = ""
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = ""
		,          array   permissionContextKeys   = []
	) {
		var validationFormName = Len( Trim( mergeWithFormName ) ) ? getMergedFormName( formName, mergeWithFormName ) : formName;

		return _getValidationEngine().getJqueryValidateJs(
			  ruleset         = _getValidationRulesetFromFormName( argumentCollection=arguments, formName=validationFormName )
			, jqueryReference = arguments.validationJsJqueryRef
			, fieldNamePrefix = arguments.fieldNamePrefix
			, fieldNameSuffix = arguments.fieldNameSuffix
		);
	}

	/**
	 * Pre-processes an entire form submission (runs any mapped preprocessors
	 * for each field to get a generated value prior to validation and/or
	 * persisting to the database).
	 *
	 * @autodoc
	 * @formName         Name of the form
	 * @formData         Submitted form data
	 * @validationResult A pre-existing validation result to which to append any errors found during preprocessing
	 */
	public any function preProcessForm( required string formName, required struct formData, any validationResult=_getValidationEngine().newValidationResult(), array suppressFields= [] ) {
		var formFields       = listFields( formName=arguments.formName, suppressFields=arguments.suppressFields );
		var fieldValue       = "";

		for( var field in formFields ){
			fieldValue = arguments.formData[ field ] ?: "";
			if ( Len( fieldValue ) ) {
				try {
					arguments.formData[ field ] = preProcessFormField(
						  formName   = arguments.formName
						, fieldName  = field
						, fieldValue = fieldValue
					);
				} catch( any e ) {
					validationResult.addError(
						  fieldName = field
						, message   = e.message
					);
				}
			}
		}

		return validationResult;
	}

	/**
	 * Pre-processes an individual field's data submission (runs any mapped preprocessors
	 * for each field to get a generated value prior to validation and/or
	 * persisting to the database).
	 *
	 * @autodoc
	 * @formName   The name of the form in which the field is defined
	 * @fieldName  The name of the field
	 * @fieldValue The submitted value that will be pre-processed
	 *
	 */
	public any function preProcessFormField( required string formName, required string fieldName, required string fieldValue ) {
		var field        = getFormField( formName = arguments.formName, fieldName = arguments.fieldName );
		var preProcessor = _getPreProcessorForField( argumentCollection = field );

		if ( Len( Trim( preProcessor ) ) ) {
			return _getColdbox().runEvent(
				  event          = preProcessor
				, prePostExempt  = true
				, private        = true
				, eventArguments = { fieldName=arguments.fieldName, preProcessorArgs=field }
			);
		}

		return arguments.fieldValue;
	}

	/**
	 * Returns the resultant form name that is generated when merging two or more form definitions
	 *
	 * @autodoc
	 * @formName.hint          Name of the source form
	 * @mergeWithFormName.hint Name (or array of names) of the form(s) to be merged with the source form
	 * @createIfNotExists.hint Whether or not to create and register the form definition if it does not already exist.
	 */
	public string function getMergedFormName( required string formName, required any mergeWithFormName, boolean createIfNotExists=true ) {
		var mergedName = _getSiteTemplatePrefix() & formName;

		if ( !isArray( mergeWithFormName ) ) {
			mergeWithFormName = [ mergeWithFormName ];
		}
		for( var formNameToMerge in mergeWithFormName ) {
			mergedName &= ".merged.with." & _getSiteTemplatePrefix() & formNameToMerge;
		}

		if ( createIfNotExists && !formExists( mergedName ) ) {
			mergeForms( formName, mergeWithFormName );
		}

		return mergedName;
	}

	/**
	 * Creates and registers a new dynamic form. Supply a 'generator closure'
	 * to add code to help generate the form definition. Closure accepts a [[api-formdefinition]] argument
	 * as the first argument. e.g.
	 * \n
	 * ```luceescript\n
	 * createForm( function( formDefinition ){\n
	 *     formDefinition.addField( name="myfield", fieldset="default", tab="default" );\n
	 * } );\n
	 * ```\n
	 *
	 * @autodoc
	 * @generator.hint Closure that accepts as its first argument a [[api-formdefinition]] object so that calling code can build the form definition.
	 * @basedOn.hint   Name of the form to base the new dynamic form on. Generator closure will take the full definition of the original form so that it can then make modifications and additions that it needs
	 * @formName.hint  If supplied, specifies the name of the form that will be registered. If not supplied, a name will be generated based on the unique full definition of the form. Warning, if using this argument, ensure that the name will be unique for each distinct form definition.
	 *
	 */
	public string function createForm( any generator, string basedOn="", string formName ) {
		var basedOnDef     = Len( Trim( arguments.basedOn ) ) ? Duplicate( getForm( arguments.basedOn ) ) : { tabs=[] };
		var formDefinition = new FormDefinition( basedOnDef );

		if ( StructKeyExists( arguments, "generator" ) ) {
			arguments.generator( formDefinition );
		}

		var rawDefinition = formDefinition.getRawDefinition();

		if ( !Len( Trim( arguments.formName ) ) ) {
			arguments.formName = _generateFormNameFromDefinition( rawDefinition );
		}

		_registerForm( arguments.formName, rawDefinition );

		return arguments.formName;
	}

	/**
	 * Takes a form definition (struct) and removes all the tabs, fieldsets and fields
	 * to which the currently logged in admin user does not have permission to edit.
	 * Returns a new structure with the potentially removed elements.
	 *
	 * @autodoc                    true
	 * @formDefinition.hint        Original form definition (remains untouched by this method)
	 * @permissionContext.hint     Optional context for permission lookups (see [[permissionsservice-haspermission]])
	 * @permissionContextKeys.hint Optional array of context keys for permission lookups (see [[permissionsservice-haspermission]])
	 *
	 */
	public struct function removePermissionedFieldsFromFormDefinition(
		  required struct formDefinition
		,          string permissionContext     = ""
		,          array  permissionContextKeys = []
	) {
		var strippedDefinition = Duplicate( formDefinition );
		var tabs               = strippedDefinition.tabs ?: [];

		for( var i=tabs.len(); i>0; i-- ) {
			var tab           = tabs[ i ];
			var permissionKey = ( tab.permissionKey ?: "" ).trim();
			var removeTab     = permissionKey.len() && !$hasAdminPermission(
				  permissionKey = permissionKey
				, context       = arguments.permissionContext
				, contextKeys   = arguments.permissionContextKeys
			);

			if ( removeTab ) {
				tabs.deleteAt( i );
			} else {
				var fieldsets = tab.fieldsets ?: [];
				for( var n=fieldsets.len(); n>0; n-- ) {
					var fieldset = fieldsets[ n ];
					var fieldsetPermissionKey = ( fieldset.permissionKey ?: "" ).trim();
					var removeFieldset = fieldsetPermissionKey.len() && !$hasAdminPermission(
						  permissionKey = fieldsetPermissionKey
						, context       = arguments.permissionContext
						, contextKeys   = arguments.permissionContextKeys
					);

					if ( removeFieldset ) {
						fieldsets.deleteAt( n );
					} else {
						var fields = fieldset.fields;
						for( var x=fields.len(); x>0; x-- ){
							var field              = fields[ x ];
							var fieldPermissionKey = field.permissionKey ?: "";
							var removeField = fieldPermissionKey.len() && !$hasAdminPermission(
								  permissionKey = fieldPermissionKey
								, context       = arguments.permissionContext
								, contextKeys   = arguments.permissionContextKeys
							);

							if ( removeField ) {
								fields.deleteAt( x );
							}
						}
					}
				}
			}
		}

		return strippedDefinition;
	}

	/**
	 * Reloads the form definitions from source directories
	 *
	 * @autodoc
	 *
	 */
	public void function reload() {
		_loadForms();
	}

// PRIVATE HELPERS
	private void function _loadForms() {
		var dirs               = _getFormDirectories();
		var prefix             = "";
		var dir                = "";
		var formName           = "";
		var files              = "";
		var file               = "";
		var subDir             = "";
		var forms              = {};
		var frm                = "";
		var resolvedExtensions = {};
		var resolveExtensions = function( formName, frmDefinition, allForms ){
			var parentFormName = arguments.frmDefinition.extends ?: "";

			if ( !Len( Trim( parentFormName ) ) || StructKeyExists( resolvedExtensions, arguments.formName ) ) {
				return arguments.frmDefinition;
			}

			if ( !StructKeyExists( arguments.allForms, parentFormName ) ) {
				throw(
					  type    = "FormService.MissingForm"
					, message = "The form [#parentFormName#], defined as an extension of [#arguments.formName#], could not be found."
				);
			}

			resolvedExtensions[ arguments.formName ] = true;

			return _mergeForms(
				  form1 = resolveExtensions( parentFormName, arguments.allForms[ parentFormName ], arguments.allForms )
				, form2 = arguments.frmDefinition
			);
		};

		for( dir in dirs ) {
			dir = ExpandPath( dir );
			prefix = _getSiteTemplatePrefixForDirectory( dir );
			files = DirectoryList( dir, true, "path", "*.xml" );
			for( file in files ){
				formName = ReplaceNoCase( file, dir, "" );
				formName = ReReplace( formName, "\.xml$", "" );
				formName = ListChangeDelims( formName, ".", "\/" );

				if ( Len( Trim( prefix ) ) ) {
					formName = ListPrepend( formName, prefix, "." );
				}

				forms[ formName ] = forms[ formName ] ?: [];
				forms[ formName ].append( _readForm( filePath=file ) );
			}
		}

		_setForms( {} );
		for( formName in forms ) {
			frm = forms[ formName ][ 1 ];
			for( var i=2; i <= forms[ formName ].len(); i++ ) {
				frm = _mergeForms(
					  form1 = frm
					, form2 = forms[ formName ][ i ]
				);
			}
			forms[ formName ] = frm;
		}
		for( formName in forms ) {
			frm = resolveExtensions( formName, forms[ formName ], forms );

			if ( _registerForm( formName, frm ) ) {
				_applyDefaultLabellingToForm( formName );
			}
		}
	}

	private boolean function _registerForm( required string formName, required struct formDefinition ) {
		if ( !_itemBelongsToDisabledFeature( arguments.formDefinition ) ) {
			_stripDisabledFeatures( arguments.formDefinition );

			var forms   = _getForms();
			var ruleset = _getValidationEngine().newRuleset( name="PresideForm.#formName#", rules=_getPresideFieldRuleGenerator().generateRulesFromPresideForm( formDefinition ) );

			forms[ formName ] = formDefinition;

			return true;
		}

		return false;
	}

	private struct function _readForm( required string filePath ) {
		var xml            = "";
		var tabs           = "";
		var theForm        = {};
		var formAttributes = {};

		try {
			var xmlContent = fileread( arguments.filePath, "utf-8" );
			xml            = XmlParse( xmlContent );
		} catch ( any e ) {
			throw(
				  type = "FormsService.BadFormXml"
				, message = "The form definition file, [#ListLast( arguments.filePath, '\/' )#], does not contain valid XML"
				, detail = e.message

			);
		}

		formAttribs = xml.form.xmlAttributes ?: {};
		for( var key in formAttribs ){
			theForm[ key ] = formAttribs[ key ];
		}
		theForm.tabs = [];

		if ( !_itemBelongsToDisabledFeature( theForm ) ) {
			tabs = XmlSearch( xml, "/form/tab" );

			for ( var i=1; i lte ArrayLen( tabs ); i++ ) {
				var attribs = tabs[i].xmlAttributes;

				var tab = {
					  title       = attribs.title       ?: ""
					, description = attribs.description ?: ""
					, id          = attribs.id          ?: ""
					, fieldsets   = []
				}
				StructAppend( tab, attribs, false );

				if ( StructKeyExists( tabs[i], "fieldset" ) ) {
					for( var n=1; n lte ArrayLen( tabs[i].fieldset ); n++ ){
						attribs = tabs[i].fieldset[n].xmlAttributes;

						var fieldset = {
							  title       = attribs.title       ?: ""
							, description = attribs.description ?: ""
							, id          = attribs.id          ?: ""
							, fields      = []
						};
						StructAppend( fieldset, attribs, false );

						if ( StructKeyExists( tabs[i].fieldset[n], "field" ) ) {
							for( var x=1; x lte ArrayLen( tabs[i].fieldset[n].field ); x++ ){
								var field = {};

								for( var key in tabs[i].fieldset[n].field[x].xmlAttributes ){
									field[ key ] = Duplicate( tabs[i].fieldset[n].field[x].xmlAttributes[ key ] );
								}

								_bindAttributesFromPresideObjectField( field );
								field.rules = _parseRules( field = tabs[i].fieldset[n].field[x] );

								ArrayAppend( fieldset.fields, field );
							}
						}

						ArrayAppend( tab.fieldsets, fieldset );
					}
				}

				ArrayAppend( theForm.tabs, tab );
			}
		}

		return theForm;
	}

	private void function _bindAttributesFromPresideObjectField( required struct field ) {
		var property    = "";
		var boundObject = "";
		var boundField  = "";
		var pobjService = "";

		if ( StructKeyExists( field, "binding" ) and Len( Trim( field.binding ) ) ) {
			if ( ListLen( field.binding, "." ) neq 2 ) {
				throw(
					  type    = "FormsService.MalformedBinding"
					, message = "The binding [#field.binding#] was malformed. Bindings should take the form, [presideObjectName.fieldName]"
				);
			}

			pobjService = _getPresideObjectService();
			boundField  = ListRest( field.binding, "." );
			boundObject = ListFirst( field.binding, "." );

			if ( !pobjService.objectExists( boundObject ) ) {
				field.name = boundField;
				return;
			}
			if ( !pobjService.fieldExists( boundObject, boundField ) ){
				field.name = boundField;
				return;
			}

			property = _getPresideObjectService().getObjectProperty( boundObject, boundField );

			StructAppend( field, property, false );
			field.sourceObject = boundObject;
			if ( not StructKeyExists( field, "name" ) ) {
				field.name = boundField;
			}
		}
	}

	private array function _parseRules( required any field ) {
		var rules = [];
		var rule  = "";
		var newRule = "";
		var attr  = "";
		var param = "";
		var i     = "";
		var n     = "";

		if ( IsDefined( "arguments.field.rule" ) )  {
			for( i=1; i lte ArrayLen( arguments.field.rule ); i++ ){
				rule = arguments.field.rule[i];
				newRule = {};
				for( attr in rule.xmlAttributes ){
					newRule[ attr ] = Duplicate( rule.xmlAttributes[ attr ] );
				}

				newRule.params = {};

				if ( IsDefined( "rule.param" ) ) {
					for( n=1; n lte ArrayLen( rule.param ); n++ ){
						param = rule.param[n];
						newRule.params[ param.xmlAttributes.name ] = param.xmlAttributes.value;
					}
				}

				ArrayAppend( rules, newRule );
			}
		}

		return rules;
	}

	private string function _getPresideObjectNameFromFormNameByConvention( required string formName ) {
		if ( [ "page-types", "preside-objects" ].find( ListFirst( arguments.formName, "." ) ) and ListLen( arguments.formName, "." ) gt 1 ) {
			return ListGetAt( arguments.formName, 2, "." );
		}

		if ( ListFirst( arguments.formName, "." ) eq "" and ListLen( arguments.formName, "." ) gt 1 ) {
			return ListGetAt( arguments.formName, 2, "." );
		}

		return "";
	}

	private string function _getFormControlHandler( required string type, required string context ) {
		var configuredControls = _getConfiguredControls();
		var defaultContext     = _getDefaultContextName();

		if ( StructKeyExists( configuredControls, arguments.type ) ) {
			if ( IsSimpleValue( configuredControls[ arguments.type ] ) ) {
				return configuredControls[ arguments.type ];
			}
			if ( IsStruct( configuredControls[ arguments.type ] ) ) {
				if ( StructKeyExists( configuredControls[ arguments.type ], arguments.context ) ) {
					return configuredControls[ arguments.type ][ arguments.context ];
				}
				if ( StructKeyExists( configuredControls[ arguments.type ], defaultContext ) ) {
					return configuredControls[ arguments.type ][ defaultContext ];
				}
			}
		}

		if ( _getColdbox().viewletExists( "formcontrols.#arguments.type#.#arguments.context#" ) ) {
			return "formcontrols.#arguments.type#.#arguments.context#";
		}

		return "formcontrols.#arguments.type#.#defaultContext#";
	}

	private string function _getDefaultFormControl() {
		return _getPresideObjectService().getDefaultFormControlForPropertyAttributes( argumentCollection = arguments );
	}

	private string function _getValidationRulesetFromFormName(
		  required string  formName
		,          boolean stripPermissionedFields = true
		,          string  permissionContext       = ""
		,          array   permissionContextKeys   = []
	) {
		var objectName = _getPresideObjectNameFromFormNameByConvention( arguments.formName );
		var rulesetName = "";

		if ( formExists( arguments.formName, false ) ) {
			rulesetName = "PresideForm.#arguments.formName#";
		} else {
			var siteTemplateFormName = _getSiteTemplatePrefix() & arguments.formName;
			if ( formExists( siteTemplateFormName, false ) ) {
				rulesetName = "PresideForm.#siteTemplateFormName#";
			} else if ( _getPresideObjectService().objectExists( objectName ) ) {
				rulesetName = "PresideObject.#objectName#";
			} else {
				return "";
			}
		}

		if ( arguments.stripPermissionedFields ) {
			var fullForm           = getForm( formName=formName );
			var modifiedForm       = getForm( argumentCollection=arguments );
			var fullFormString     = SerializeJson( fullForm );
			var modifiedFormString = SerializeJson( modifiedForm );

			if ( fullFormString != modifiedFormString ) {
				rulesetName &= "-permissioned-" & Hash( modifiedFormString );

				if ( !_getValidationEngine().rulesetExists( rulesetName ) ) {
					_getValidationEngine().newRuleset(
						  name  = rulesetName
						, rules = _getPresideFieldRuleGenerator().generateRulesFromPresideForm( modifiedForm )
					);
				}
			}
		}

		return rulesetName;
	}

	private struct function _getI18nFieldAttributes( required struct field ) {
		var i18n             = _getI18n();
		var fieldName        = arguments.field.name ?: "";
		var backupLabelUri   = "cms:preside-objects.default.field.#fieldName#.title";
		var fieldLabel       = arguments.field.label       ?: "";
		var fieldHelp        = arguments.field.help        ?: "";
		var fieldPlaceholder = arguments.field.placeholder ?: "";
		var attributes       = {};

		if ( Len( Trim( fieldLabel ) ) ) {
			if ( i18n.isValidResourceUri( fieldLabel ) ) {
				attributes.label = i18n.translateResource( uri=fieldLabel, defaultValue=i18n.translateResource( uri = backupLabelUri, defaultValue = fieldName ) );
			} else {
				attributes.label = fieldLabel;
			}
		} else {
			attributes.label = i18n.translateResource( uri = backupLabelUri, defaultValue = fieldName );
		}

		if ( Len( Trim( fieldHelp ) ) ) {
			if ( i18n.isValidResourceUri( fieldHelp ) ) {
				attributes.help = i18n.translateResource( uri=fieldHelp, defaultValue="" );
			} else {
				attributes.help = fieldHelp;
			}
		}

		if ( Len( Trim( fieldPlaceholder ) ) ) {
			if ( i18n.isValidResourceUri( fieldPlaceholder ) ) {
				attributes.placeholder = i18n.translateResource( uri=fieldPlaceholder, defaultValue="" );
			} else {
				attributes.placeholder = fieldPlaceholder;
			}
		}


		return attributes;
	}

	private struct function _getI18nTabOrFieldsetAttributes( required struct tabOrFieldset ) {
		var i18n       = _getI18n();
		var attributes = {};

		if ( Len( Trim( tabOrFieldset.title ?: "" ) ) ) {
			if ( i18n.isValidResourceUri( tabOrFieldset.title ) ) {
				attributes.title = i18n.translateResource( uri=tabOrFieldset.title, defaultValue="" );
			} else {
				attributes.title = tabOrFieldset.title;
			}
		}

		if ( Len( Trim( tabOrFieldset.description ?: "" ) ) ) {
			if ( i18n.isValidResourceUri( tabOrFieldset.description ) ) {
				attributes.description = i18n.translateResource( uri=tabOrFieldset.description, defaultValue="" );
			} else {
				attributes.description = tabOrFieldset.description;
			}
		}

		if ( Len( Trim( tabOrFieldset.iconClass ?: "" ) ) ) {
			if ( i18n.isValidResourceUri( tabOrFieldset.iconClass ) ) {
				attributes.iconClass = i18n.translateResource( uri=tabOrFieldset.iconClass, defaultValue="" );
			} else {
				attributes.iconClass = tabOrFieldset.iconClass;
			}
		}

		return attributes;
	}

	private string function _getPreProcessorForField( string preProcessor="", string control="" ) {
		var coldboxEvent = "";
		var coldbox      = _getColdbox();

		if ( Len( Trim( arguments.preProcessor ) ) ) {
			coldboxEvent = arguments.preProcessor;
		} else {
			if ( arguments.control eq "default" or not Len( Trim( arguments.control ) ) ) {
				coldboxEvent = _getDefaultFormControl( argumentCollection = arguments );
			} else {
				coldboxEvent = arguments.control;
			}
		}

		coldboxEvent = "preprocessors." & coldboxEvent;
		if ( coldbox.handlerExists( coldboxEvent ) ) {
			return coldboxEvent;
		}

		coldboxEvent = ListAppend( coldboxEvent, _getDefaultContextName(), "." );
		if ( coldbox.handlerExists( coldboxEvent ) ) {
			return coldboxEvent;
		}


		return "";
	}

	private struct function _mergeForms( required struct form1, required struct form2 ) {
		for( var attrib in form2 ) {
			if ( IsSimpleValue( form2[ attrib ] ) ) {
				form1[ attrib ] = form2[ attrib ];
			}
		}

		for( var tab in form2.tabs ){
			var matchingTab = {};
			if ( Len( Trim( tab.id ?: "" ) ) ) {
				for( var mTab in form1.tabs ){
					if ( ( mTab.id ?: "" ) == tab.id ) {
						matchingTab = mTab;
						break;
					}
				}
			}
			if ( StructIsEmpty( matchingTab ) ) {
				ArrayAppend( form1.tabs, tab );
				continue;
			} else if ( IsBoolean( tab.deleted ?: "" ) and tab.deleted ) {
				ArrayDelete( form1.tabs, matchingTab );
				continue;
			}

			for( var fieldSet in tab.fieldSets ){
				var matchingFieldset = {};
				if ( Len( Trim( fieldSet.id ?: "" ) ) ) {
					for( var mFieldset in matchingTab.fieldsets ){
						if ( ( mFieldset.id ?: "" ) == fieldSet.id ) {
							matchingFieldset = mFieldset;
							break;
						}
					}
				}
				if ( StructIsEmpty( matchingFieldset ) ) {
					ArrayAppend( matchingTab.fieldsets, fieldset );
					continue;
				} else if ( IsBoolean( fieldSet.deleted ?: "" ) and fieldSet.deleted ) {
					ArrayDelete( matchingTab.fieldSets, matchingFieldset );
					continue;
				}

				for( var field in fieldset.fields ) {
					var fieldMatched = false;
					var fieldDeleted = false;
					for( var mField in matchingFieldset.fields ){
						if ( ( mField.name ?: "" ) == field.name ) {
							if ( IsBoolean( field.deleted ?: "" ) and field.deleted ) {
								ArrayDelete( matchingFieldset.fields, mField );
								fieldDeleted = true;
							} else {
								StructAppend( mField, field );
								fieldMatched = true;
								break;
							}
						}
					}
					if ( !fieldMatched && !fieldDeleted ) {
						ArrayAppend( matchingFieldset.fields, field );
					}
				}
				StructDelete( fieldset, "fields" );
				var autoFieldsetAttribs = fieldset.autoGeneratedAttributes ?: [];
				for( var attrib in fieldset ) {
					if ( IsSimpleValue( fieldset[ attrib ] ) && Len( Trim( fieldset[ attrib ] ) ) && ( !StructKeyExists( matchingFieldset, attrib ) || !autoFieldsetAttribs.findNoCase( attrib ) ) ) {
						matchingFieldset[ attrib ] = fieldset[ attrib ];
					}
				}

				matchingFieldset.fields.sort( function( field1, field2 ){
					var order1 = Val( field1.sortOrder ?: 999999999 );
					var order2 = Val( field2.sortOrder ?: 999999999 );

					return order1 == order2 ? 0 : ( order1 > order2 ? 1 : -1 );
				} );
			}

			StructDelete( tab, "fieldsets" );
			var autoTabAttribs = tab.autoGeneratedAttributes ?: [];
			for( var attrib in tab ) {
				if ( IsSimpleValue( tab[ attrib ] ) && Len( Trim( tab[ attrib ] ) ) && ( !StructKeyExists( matchingTab, attrib ) || !autoTabAttribs.findNoCase( attrib ) )  ) {
					matchingTab[ attrib ] = tab[ attrib ];
				}
			}

			matchingTab.fieldsets.sort( function( fieldset1, fieldset2 ){
				var order1 = Val( fieldset1.sortOrder ?: 999999999 );
				var order2 = Val( fieldset2.sortOrder ?: 999999999 );

				return order1 == order2 ? 0 : ( order1 > order2 ? 1 : -1 );
			} );
		}
		form1.tabs.sort( function( tab1, tab2 ){
			var order1 = Val( tab1.sortOrder ?: 999999999 );
			var order2 = Val( tab2.sortOrder ?: 999999999 );

			return order1 == order2 ? 0 : ( order1 > order2 ? 1 : -1 );
		} );

		return form1;
	}

	private string function _getSiteTemplatePrefixForDirectory( required string directory ) {
		var matchRegex = "^.*?site-templates[\\/]([^/]+)[\\/]forms.*$";

		if (  ReFindNoCase( matchRegex, arguments.directory ) ) {
			return "site-template::" & ReReplace( arguments.directory, matchRegex, "\1" );
		}

		return "";
	}

	private boolean function _formControlHasLayout( required string control ) {
		switch( arguments.control ){
			case "hidden":
				return false;
		}

		return true;
	}

	private string function _getSiteTemplatePrefix() {
		var siteTemplate = _getSiteService().getActiveSiteTemplate( emptyIfDefault=true );
		return Len( Trim( siteTemplate ) ) ? ( "site-template::" & sitetemplate & "." ) : "";
	}

	private boolean function _itemBelongsToDisabledFeature( required struct itemDefinition ) {
		return Len( Trim( itemDefinition.feature ?: "" ) ) && !_getFeatureService().isFeatureEnabled( Trim( itemDefinition.feature ) );
	}

	private void function _stripDisabledFeatures( required struct formDefinition ) {
		var tabs = arguments.formDefinition.tabs ?: [];

		for( var i=tabs.len(); i>0; i-- ) {
			if ( _itemBelongsToDisabledFeature( tabs[ i ] ) ) {
				tabs.deleteAt( i );
			}

			var fieldsets = tabs[ i ].fieldSets ?: [];
			for( var n=fieldsets.len(); n>0; n-- ) {
				if ( _itemBelongsToDisabledFeature( fieldsets[ n ] ) ) {
					fieldsets.deleteAt( n );
				}

				var fields = fieldsets[ n ].fields ?: [];

				for( var x=fields.len(); x>0; x-- ) {
					if ( _itemBelongsToDisabledFeature( fields[ x ] ) ) {
						fields.deleteAt( x );
					}
				}
			}
		}
	}

	private string function _getDefaultI18nBaseUriForForm( required string formName ) {
		if ( formExists( arguments.formName ) ) {
			var formConfig = getForm( arguments.formName );

			if ( Len( Trim( formConfig.i18nBaseUri ?: "" ) ) ) {
				return formConfig.i18nBaseUri;
			}
		}

		var presideObjectName = _getPresideObjectNameFromFormNameByConvention( arguments.formName );
		if ( Len( Trim( presideObjectName ) ) ) {
			var presideObjectName = _getPresideObjectService().getObjectAttribute( presideObjectName, "derivedFrom", presideObjectName );
			if ( _getPresideObjectService().getObjectAttribute( presideObjectName, "isPageType", false ) ) {
				return "page-types.#presideObjectName#:";
			}
			return "preside-objects.#presideObjectName#:";
		}

		return "";
	}

	private void function _applyDefaultLabellingToForm( required string formName, struct frm=getForm( arguments.formName ) ) {
		var baseI18nUri = _getDefaultI18nBaseUriForForm( arguments.formName );

		var tabs = frm.tabs ?: [];

		for( var tab in tabs ) {
			if ( Len( Trim( baseI18nUri ) ) ) {
				tab.autoGeneratedAttributes = [];
				if ( Len( Trim( tab.id ?: "" ) ) ) {
					if ( !Len( Trim( tab.title ?: "" ) ) ) {
						tab.title = baseI18nUri & "tab.#tab.id#.title";
						tab.autoGeneratedAttributes.append( "title" );
					}
					if ( !Len( Trim( tab.description ?: "" ) ) ) {
						tab.description = baseI18nUri & "tab.#tab.id#.description";
						tab.autoGeneratedAttributes.append( "description" );
					}
					if ( !Len( Trim( tab.iconClass ?: "" ) ) ) {
						tab.iconClass = baseI18nUri & "tab.#tab.id#.iconClass";
						tab.autoGeneratedAttributes.append( "iconClass" );
					}
				}
			}
			var fieldsets = tab.fieldsets ?: [];
			for( var fieldset in fieldsets ) {
				if ( Len( Trim( baseI18nUri ) ) ) {
					fieldset.autoGeneratedAttributes = [];
					if ( Len( Trim( fieldset.id ?: "" ) ) ) {
						if ( !Len( Trim( fieldset.title ?: "" ) ) ) {
							fieldset.title = baseI18nUri & "fieldset.#fieldset.id#.title";
							fieldset.autoGeneratedAttributes.append( "title" );
						}
						if ( !Len( Trim( fieldset.description ?: "" ) ) ) {
							fieldset.description = baseI18nUri & "fieldset.#fieldset.id#.description";
							fieldset.autoGeneratedAttributes.append( "description" );
						}
					}
				}

				var fields = fieldset.fields ?: [];
				for( var field in fields ) {
					var fieldBaseI18n = "";
					if ( ListLen( field.binding ?: "", "." ) == 2 ) {
						var objName = ListFirst( field.binding, "." );
						if ( _getPresideObjectService().objectExists( objName ) && _getPresideObjectService().isPageType( objName ) ) {
							fieldBaseI18n = "page-types.#objName#:";
						} else {
							fieldBaseI18n = "preside-objects.#objName#:";
						}
					} else {
						fieldBaseI18n = baseI18nUri;
					}
					if ( Len( Trim( fieldBaseI18n ) ) && Len( Trim( field.name ?: "" ) ) ) {
						if ( !Len( Trim( field.label ?: "" ) ) ) {
							field.label = fieldBaseI18n & "field.#field.name#.title";
						}
						if ( !Len( Trim( field.placeholder ?: "" ) ) ) {
							field.placeholder = fieldBaseI18n & "field.#field.name#.placeholder";
						}
						if ( !Len( Trim( field.help ?: "" ) ) ) {
							field.help = fieldBaseI18n & "field.#field.name#.help";
						}
					}
				}
			}
		}
	}

	private string function _generateFormNameFromDefinition( required struct definition ) {
		return "dynamicform-" & LCase( Hash( SerializeJson( arguments.definition ) ) );
	}

	private string function _runDefaultValueFunction( required string objectName, required string default ) {
		var defaultValue = arguments.default ?: "";

		if ( ListLen( defaultValue, ":" ) > 1 ) {
			switch( ListFirst( defaultValue, ":" ) ) {
				case "cfml":
					defaultValue = Evaluate( ListRest( defaultValue, ":" ) );
				break;
				case "closure":
					var func = Evaluate( ListRest( defaultValue, ":" ) );
					defaultValue = func( {} );
				break;
				case "method":
					var obj = _getPresideObjectService().getObject( arguments.objectName );

					defaultValue = obj[ ListRest( defaultValue, ":" ) ]( {} );
				break;
			}
		}

		return defaultValue ?: "";
	}

// GETTERS AND SETTERS
	private array function _getFormDirectories() {
		return _formDirectories;
	}
	private void function _setFormDirectories( required array formDirectories ) {
		_formDirectories = arguments.formDirectories;
	}

	private any function _getPresideObjectService() {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) {
		_presideObjectService = arguments.presideObjectService;
	}

	private struct function _getForms() {
		return _forms;
	}
	private void function _setForms( required struct forms ) {
		_forms = arguments.forms;
	}

	private any function _getValidationEngine() {
		return _validationEngine;
	}
	private void function _setValidationEngine( required any validationEngine ) {
		_validationEngine = arguments.validationEngine;
	}

	private any function _getI18n() {
		return _i18n;
	}
	private void function _setI18n( required any i18n ) {
		_i18n = arguments.i18n;
	}

	private any function _getColdBox() {
		return _coldBox;
	}
	private void function _setColdBox( required any coldBox ) {
		_coldBox = arguments.coldBox;
	}

	private string function _getDefaultContextName() {
		return _defaultContextName;
	}
	private void function _setDefaultContextName( required string defaultContextName ) {
		_defaultContextName = arguments.defaultContextName;
	}

	private struct function _getConfiguredControls() {
		return _configuredControls;
	}
	private void function _setConfiguredControls( required struct configuredControls ) {
		_configuredControls = arguments.configuredControls;
	}

	private any function _getPresideFieldRuleGenerator() {
		return _presideFieldRuleGenerator;
	}
	private void function _setPresideFieldRuleGenerator( required any presideFieldRuleGenerator ) {
		_presideFieldRuleGenerator = arguments.presideFieldRuleGenerator;
	}

	private any function _getFeatureService() {
		return _featureService;
	}
	private void function _setFeatureService( required any featureService ) {
		_featureService = arguments.featureService;
	}

	private any function _getSiteService() {
		return _siteService;
	}
	private void function _setSiteService( required any siteService ) {
		_siteService = arguments.siteService;
	}
}