component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @formDirectories.inject           presidecms:directories:forms
	 * @presideObjectService.inject      PresideObjectService
	 * @validationEngine.inject          ValidationEngine
	 * @i18n.inject                      coldbox:plugin:i18n
	 * @coldbox.inject                   coldbox
	 * @presideFieldRuleGenerator.inject PresideFieldRuleGenerator
	 * @defaultContextName.inject        coldbox:fwSetting:EventAction
	 * @configuredControls.inject        coldbox:setting:formControls
	 */
	public any function init(
		  required array  formDirectories
		, required any    presideObjectService
		, required any    validationEngine
		, required any    i18n
		, required any    coldbox
		, required any    presideFieldRuleGenerator
		, required string defaultContextName
		, required struct configuredControls
	) output=false {
		_setValidationEngine( arguments.validationEngine );
		_setPresideObjectService( arguments.presideObjectService );
		_setI18n( arguments.i18n );
		_setColdbox( arguments.coldbox );
		_setFormDirectories( arguments.formDirectories );
		_setPresideFieldRuleGenerator( arguments.presideFieldRuleGenerator );
		_setDefaultContextName( arguments.defaultContextName );
		_setConfiguredControls( arguments.configuredControls );

		_loadForms();

		return this;
	}

// PUBLIC API METHODS
	public array function listForms() output=false {
		var forms = StructKeyArray( _getForms() );

		ArraySort( forms, "textnocase" );

		return forms;
	}

	public boolean function formExists( required string formName ) output=false {
		var forms = _getForms();

		return StructKeyExists( forms, arguments.formName );
	}

	public struct function getForm( required string formName ) output=false {
		var forms = _getForms();
		var objectName = "";

		if ( formExists( arguments.formName ) ) {
			return StructFind( _getForms(), arguments.formName );
		}

		objectName = _getPresideObjectNameFromFormNameByConvention( arguments.formName );
		if ( _getPresideObjectService().objectExists( objectName ) ) {
			return getDefaultFormForPresideObject( objectName );
		}

		throw(
			  type = "FormsService.MissingForm"
			, message = "The form, [#arguments.formName#], could not be found"
		);
	}

	public struct function mergeForms( required string formName, required string mergeWithFormName ) output=false {
		var mergedName = getMergedFormName( arguments.formName, arguments.mergeWithFormName, false );

		if ( formExists( mergedName ) ) {
			return getForm( mergedName );
		}

		var merged = _mergeForms(
			  form1 = Duplicate( getForm( arguments.formName ) )
			, form2 = Duplicate( getForm( arguments.mergeWithFormName ) )
		);

		_registerForm( mergedName, merged );

		return merged;
	}

	public struct function getFormField( required string formName, required string fieldName ) output=false {
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

	public any function listFields( required string formName ) output=false {
		var frm    = getForm( arguments.formName );
		var fields = [];

		for( var tab in frm.tabs ){
			for( var fieldset in tab.fieldsets ) {
				for( var field in fieldset.fields ) {
					ArrayAppend( fields, field.name ?: "" );
				}
			}
		}

		return fields;
	}

	public struct function getDefaultFormForPresideObject( required string objectName ) output=false {
		var fields = _getPresideObjectService().getObjectProperties( objectName = arguments.objectName );
		var formLayout = {
			tabs = [{
				title       = "",
				description = "",
				fieldsets   = [{
					title       = "",
					description = "",
					fields      = []
				}]
			}]
		};

		for( var fieldName in fields ){
			var field = fields[ fieldName ];
			if ( field.getAttribute( "control", "" ) neq "none" ) {
				ArrayAppend( formLayout.tabs[1].fieldsets[1].fields, field.getMemento() );

				formLayout.tabs[1].fieldsets[1].fields[ ArrayLen( formLayout.tabs[1].fieldsets[1].fields ) ].sourceObject = arguments.objectName;
			}
		}

		return formLayout;
	}

	public string function renderForm(
		  required string  formName
		,          string  mergeWithFormName    = ""
		,          string  context              = "admin"
		,          string  fieldLayout          = "formcontrols.layouts.field"
		,          string  fieldsetLayout       = "formcontrols.layouts.fieldset"
		,          string  tabLayout            = "formcontrols.layouts.tab"
		,          string  formLayout           = "formcontrols.layouts.form"
		,          string  formId               = ""
		,          string  component            = ""
		,          any     validationResult     = ""
		,          boolean includeValidationJs  = true
		,          struct  savedData            = {}
	) output=false {
		var frm               = Len( Trim( arguments.mergeWithFormName ) ) ? mergeForms( arguments.formName, arguments.mergeWithFormName) : getForm( arguments.formName );
		var coldbox           = _getColdbox();
		var i18n              = _getI18n();
		var renderedTabs      = CreateObject( "java", "java.lang.StringBuffer" );
		var activeTab         = true;
		var renderedFieldSets = "";
		var renderedFields    = "";
		var renderArgs        = "";

		for( var tab in frm.tabs ){
			renderedFieldSets = CreateObject( "java", "java.lang.StringBuffer" );
			if ( not Len( Trim( tab.id ?: "" ) ) ) {
				tab.id = CreateUUId();
			}

			for( var fieldset in tab.fieldsets ) {
				renderedFields = CreateObject( "java", "java.lang.StringBuffer" );

				for( var field in fieldset.fields ) {
					if ( ( field.control ?: "default" ) neq "none" ) {
						renderArgs = {
							  name      = field.name    ?: ""
							, type      = field.control ?: "default"
							, context   = arguments.context
							, label     = _getFieldLabel( field=field, formName=arguments.formName )
							, layout    = arguments.fieldLayout
							, savedData = arguments.savedData
						};

						if ( not IsSimpleValue( validationResult ) and validationResult.fieldHasError( field.name ) ) {
							renderArgs.error = i18n.translateResource(
								  uri          = validationResult.getError( field.name )
								, defaultValue = validationResult.getError( field.name )
								, data         = validationResult.listErrorParameterValues( field.name )
							);
						}

						if ( renderArgs.type eq "default" ) {
							renderArgs.type = _getDefaultFormControl( argumentCollection = field );
						}

						if ( StructKeyExists( arguments.savedData, field.name ) ) {
							renderArgs.defaultValue = arguments.savedData[ field.name ];
						} else if ( StructKeyExists( field, "default" ) ) {
							renderArgs.defaultValue = field.default;
						}

						StructAppend( renderArgs, field, false );

						renderedFields.append( renderFormControl( argumentCollection=renderArgs ) );
					}
				}

				renderArgs = Duplicate( fieldset );
				renderArgs.content = renderedFields.toString();
				renderedFieldSets.append( coldbox.renderViewlet(
					  event = arguments.fieldsetLayout
					, args  = renderArgs
				) );
			}

			renderArgs = Duplicate( tab );
			renderArgs.content = renderedFieldSets.toString();
			renderArgs.active  = activeTab;
			renderedTabs.append( coldbox.renderViewlet(
				  event = arguments.tabLayout
				, args  = renderArgs
			) );
			activeTab = false;
		}

		return coldbox.renderViewlet( event=arguments.formLayout, args={
			  formId           = arguments.formId
			, content          = renderedTabs.toString()
			, tabs             = frm.tabs
			, validationResult = arguments.validationResult
			, validationJs     = arguments.includeValidationJs ? getValidationJs( arguments.formName, arguments.mergeWithFormName ) : ""
		} );
	}

	public string function renderFormControl(
		  required string  name
		, required string  type
		,          string  context      = _getDefaultContextName()
		,          string  id           = arguments.name
		,          string  label        = ""
		,          string  savedValue   = ""
		,          string  defaultValue = ""
		,          struct  savedData    = {}
		,          string  error        = ""
		,          boolean required     = false
		,          string  layout       = "formcontrols.layouts.field"

	) output=false {
		var coldbox         = _getColdbox();
		var handler         = _getFormControlHandler( type=arguments.type, context=arguments.context );
		var renderedControl = "";

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
			renderedControl = coldbox.renderViewlet( event=arguments.layout, args={
				  control  = renderedControl
				, label    = arguments.label
				, for      = arguments.id
				, error    = arguments.error
				, required = arguments.required
			} );
		}

		return renderedControl;
	}

	public any function validateForm( required string formName, required struct formData, boolean preProcessData=true ) output=false {
		var ruleset = _getValidationRulesetFromFormName( arguments.formName );

		if ( arguments.preProcessData ) {
			return _getValidationEngine().validate(
				  ruleset = ruleset
				, data    = arguments.formData
				, result  = preProcessForm( argumentCollection = arguments )
			);
		}

		return _getValidationEngine().validate(
			  ruleset = ruleset
			, data    = arguments.formData
		);
	}

	public any function getValidationJs( required string formName, string mergeWithFormName="" ) output=false {
		var validationFormName = Len( Trim( mergeWithFormName ) ) ? getMergedFormName( formName, mergeWithFormName ) : formName;

		return _getValidationEngine().getJqueryValidateJs(
			ruleset = _getValidationRulesetFromFormName( validationFormName )
		);
	}

	public any function preProcessForm( required string formName, required struct formData ) output=false {
		var formFields       = listFields( arguments.formName );
		var fieldValue       = "";
		var validationResult = _getValidationEngine().newValidationResult();

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

	public any function preProcessFormField( required string formName, required string fieldName, required string fieldValue ) output=false {
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

	public string function getMergedFormName( required string formName, required string mergeWithFormName, boolean createIfNotExists=true ) output=false {
		var mergedName = formName & ".merged.with." & mergeWithFormName;

		if ( createIfNotExists && !formExists( mergedName ) ) {
			mergeForms( formName, mergeWithFormName );
		}

		return mergedName;
	}

	public void function reload() output=false {
		_loadForms();
	}

// PRIVATE HELPERS
	private void function _loadForms() output=false {
		var dirs     = _getFormDirectories();
		var dir      = "";
		var formName = "";
		var files    = "";
		var file     = "";
		var subDir   = "";
		var forms    = {};
		var frm      = "";

		for( dir in dirs ) {
			dir = ExpandPath( dir );
			files = DirectoryList( dir, true, "path", "*.xml" );
			for( file in files ){
				formName = ReplaceNoCase( file, dir, "" );
				formName = ReReplace( formName, "\.xml$", "" );
				formName = ListChangeDelims( formName, ".", "\/" );

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
			_registerForm( formName, frm );
		}
	}

	private void function _registerForm( required string formName, required struct formDefinition ) output=false {
		var forms   = _getForms();
		var ruleset = _getValidationEngine().newRuleset( name="PresideForm.#formName#" );

		forms[ formName ] = formDefinition;

		ruleset.addRules(
			rules = _getPresideFieldRuleGenerator().generateRulesFromPresideForm( formDefinition )
		);
	}

	private struct function _readForm( required string filePath ) output=false {
		var xml     = "";
		var tabs    = "";
		var theForm = { tabs = [] };
		var form    = "";

		try {
			xml = XmlParse( arguments.filePath );
		} catch ( any e ) {
			throw(
				  type = "FormsService.BadFormXml"
				, message = "The form definition file, [#ListLast( arguments.filePath, '\/' )#], does not contain valid XML"
				, detail = e.message

			);
		}

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

		return theForm;
	}

	private void function _bindAttributesFromPresideObjectField( required struct field ) output=false {
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

			if ( not pobjService.objectExists( boundObject ) ) {
				throw(
					  type = "FormsService.BadBinding"
					, message = "The preside object, [#boundObject#], referred to in the form field binding, [#field.binding#], could not be found. Valid objects are #SerializeJson( pobjService.listObjects() )#"
				);
			}
			if ( not pobjService.fieldExists( boundObject, boundField ) ){
				throw(
					  type = "FormsService.BadBinding"
					, message = "The field, [#boundField#], referred to in the form field binding, [#field.binding#], could not be found in Preside Object, [#boundObject#]"
				);
			}

			property = _getPresideObjectService().getObjectProperty( boundObject, boundField ).getMemento();

			StructAppend( field, property, false );
			field.sourceObject = boundObject;
			if ( not StructKeyExists( field, "name" ) ) {
				field.name = boundField;
			}
		}
	}

	private array function _parseRules( required any field ) output=false {
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

	private string function _getPresideObjectNameFromFormNameByConvention( required string formName ) output=false {
		if ( ListFirst( arguments.formName, "." ) eq "preside-objects" and ListLen( arguments.formName, "." ) gt 1 ) {
			return ListGetAt( arguments.formName, 2, "." );
		}

		return "";
	}

	private string function _getFormControlHandler( required string type, required string context ) output=false {
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

	private string function _getDefaultFormControl() output=false {
		return _getPresideObjectService().getDefaultFormControlForPropertyAttributes( argumentCollection = arguments );
	}

	private string function _getValidationRulesetFromFormName( required string formName ) output=false {
		var objectName = _getPresideObjectNameFromFormNameByConvention( arguments.formName );

		if ( formExists( arguments.formName ) ) {
			return "PresideForm.#arguments.formName#";
		}

		if ( _getPresideObjectService().objectExists( objectName ) ) {
			return "PresideObject.#objectName#";
		}

		return "";
	}

	private string function _getFieldLabel( required struct field, required string formName ) output=false {
		var i18n       = _getI18n();
		var fieldName  = arguments.field.name ?: "";
		var objectName = Len( Trim( field.binding ?: "" ) ) ? ListFirst( field.binding, "." ) : _getPresideObjectNameFromFormNameByConvention( arguments.formName );
		var defaultUri = _getPresideObjectService().getResourceBundleUriRoot( objectName ) & "field.#fieldName#.title";
		var backupUri  = "cms:preside-objects.default.field.#fieldName#.title";
		var fieldLabel = arguments.field.label ?: "";

		if ( Len( Trim( fieldLabel ) ) ) {
			return i18n.translateResource( uri=fieldLabel, defaultValue=fieldLabel );
		}

		return i18n.translateResource(
			  uri          = defaultUri
			, defaultValue = i18n.translateResource( uri = backupUri, defaultValue = fieldName )
		);
	}

	private string function _getPreProcessorForField( string preProcessor="", string control="" ) output=false {
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

	private struct function _mergeForms( required struct form1, required struct form2 ) output=false {
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
			} elseif ( IsBoolean( tab.deleted ?: "" ) and tab.deleted ) {
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
				} elseif ( IsBoolean( fieldSet.deleted ?: "" ) and fieldSet.deleted ) {
					ArrayDelete( matchingTab.fieldSets, matchingFieldset );
					continue;
				}

				for( var field in fieldset.fields ) {
					var fieldMatched = false;
					for( var mField in matchingFieldset.fields ){
						if ( mField.name == field.name ) {
							if ( IsBoolean( field.deleted ?: "" ) and field.deleted ) {
								ArrayDelete( matchingFieldset.fields, mField );
							} else {
								StructAppend( mField, field );
								fieldMatched = true;
								break;
							}
						}
					}
					if ( !fieldMatched and !( IsBoolean( field.deleted ?: "" ) and field.deleted ) ) {
						ArrayAppend( matchingFieldset.fields, field );
					}
				}
				StructDelete( fieldset, "fields" );
				for( var attrib in fieldset ) {
					if ( IsSimpleValue( fieldset[ attrib ] ) and Len( Trim( fieldset[ attrib ] ) ) ) {
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
			for( var attrib in tab ) {
				if ( IsSimpleValue( tab[ attrib ] ) and Len( Trim( tab[ attrib ] ) ) ) {
					matchingTab[ attrib ] = tab[ attrib ];
				}
			}
		}

		return form1;
	}

// GETTERS AND SETTERS
	private array function _getFormDirectories() output=false {
		return _formDirectories;
	}
	private void function _setFormDirectories( required array formDirectories ) output=false {
		_formDirectories = arguments.formDirectories;
	}

	private any function _getPresideObjectService() output=false {
		return _presideObjectService;
	}
	private void function _setPresideObjectService( required any presideObjectService ) output=false {
		_presideObjectService = arguments.presideObjectService;
	}

	private struct function _getForms() output=false {
		return _forms;
	}
	private void function _setForms( required struct forms ) output=false {
		_forms = arguments.forms;
	}

	private any function _getValidationEngine() output=false {
		return _validationEngine;
	}
	private void function _setValidationEngine( required any validationEngine ) output=false {
		_validationEngine = arguments.validationEngine;
	}

	private any function _getI18n() output=false {
		return _i18n;
	}
	private void function _setI18n( required any i18n ) output=false {
		_i18n = arguments.i18n;
	}

	private any function _getColdBox() output=false {
		return _coldBox;
	}
	private void function _setColdBox( required any coldBox ) output=false {
		_coldBox = arguments.coldBox;
	}

	private string function _getDefaultContextName() output=false {
		return _defaultContextName;
	}
	private void function _setDefaultContextName( required string defaultContextName ) output=false {
		_defaultContextName = arguments.defaultContextName;
	}

	private struct function _getConfiguredControls() output=false {
		return _configuredControls;
	}
	private void function _setConfiguredControls( required struct configuredControls ) output=false {
		_configuredControls = arguments.configuredControls;
	}

	private any function _getPresideFieldRuleGenerator() output=false {
		return _presideFieldRuleGenerator;
	}
	private void function _setPresideFieldRuleGenerator( required any presideFieldRuleGenerator ) output=false {
		_presideFieldRuleGenerator = arguments.presideFieldRuleGenerator;
	}
}