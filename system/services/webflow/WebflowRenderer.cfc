/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @webflowLibrary.inject          webflowSpecLibrary
	 * @webflowInstanceService.inject  webflowInstanceService
	 * @webflowConfigurator.inject     webflowConfigurationService
	 * @webflowActionsService.inject   webflowActionsService
	 * @formsService.inject            formsService
	 * @webflowLayoutArgs.inject       coldbox:setting:webflow.layout.args
	 * @formContext.inject             coldbox:setting:webflow.forms.context
	 * @formAdminContext.inject        coldbox:setting:webflow.forms.adminContext
	 * @formFieldLayout.inject         coldbox:setting:webflow.forms.fieldLayout
	 * @formFieldsetLayout.inject      coldbox:setting:webflow.forms.fieldsetLayout
	 * @formTabLayout.inject           coldbox:setting:webflow.forms.tabLayout
	 * @formLayout.inject              coldbox:setting:webflow.forms.layout
	 * @formIncludeValidationJs.inject coldbox:setting:webflow.forms.includeValidationJs
	 * @formJqueryRef.inject           coldbox:setting:webflow.forms.jqueryRef
	 */
	public any function init(
		  required any     webflowLibrary
		, required any     webflowInstanceService
		, required any     webflowConfigurator
		, required any     webflowActionsService
		, required any     formsService
		, required struct  webflowLayoutArgs
		, required string  formContext
		, required string  formAdminContext
		, required string  formFieldLayout
		, required string  formFieldsetLayout
		, required string  formTabLayout
		, required string  formLayout
		, required boolean formIncludeValidationJs
		, required string  formJqueryRef
	) {
		_setWebflowLibrary( arguments.webflowLibrary );
		_setWebflowInstanceService( arguments.webflowInstanceService );
		_setWebflowConfigurator( arguments.webflowConfigurator );
		_setWebflowActionsService( arguments.webflowActionsService );
		_setFormsService( arguments.formsService );
		_setWebflowLayoutArgs( arguments.webflowLayoutArgs );
		_setFormContext( arguments.formContext );
		_setFormAdminContext( arguments.formAdminContext );
		_setFormFieldLayout( arguments.formFieldLayout );
		_setFormFieldsetLayout( arguments.formFieldsetLayout );
		_setFormTabLayout( arguments.formTabLayout );
		_setFormLayout( arguments.formLayout );
		_setFormIncludeValidationJs( arguments.formIncludeValidationJs );
		_setFormJqueryRef( arguments.formJqueryRef );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Renders a webflow :)
	 *
	 * @webflowId    The ID of the registered webflow
	 * @instanceRef  The reference ID of the configuration instance of the webflow. For *singleton* webflows, this is always empty.
	 * @subReference An optional third sub-reference that will further refine the instance of the webflow to fetch and render - e.g. an event booking ID for the same workflow with multiple bookings
	 * @layout       Pass a viewlet for a non-default webflow layout
	 * @archived     Whether or not the flow should render an archived state
	 * @args         Optional struct that will be available to init state and stateArgs handlers to help set initial state, etc.
	 */
	public string function render(
		  required string  webflowId
		,          string  instanceRef  = ""
		,          string  subReference = ""
		,          string  layout       = ""
		,          boolean archived     = false
		,          struct  args         = {}
	) {
		var instance = _getInstance( argumentCollection=arguments, explicitArgs=args );

		if ( IsNull( local.instance ) ) {
			return _renderIneligbleMessage( argumentCollection=arguments );
		}

		var webflow    = _getWebflowLibrary().getWebflow( arguments.webflowId );
		var stepId     = instance.getActiveStep();
		var step       = _getWebflowStep( webflow, stepId );
		var stepConfig = _getWebflowConfigurator().getStepCopy(
		 	  argumentCollection = arguments
			, stepId             = step.getId()
		);

		var renderedStep = renderStep(
			  argumentCollection = arguments
			, step               = step
			, instance           = instance
			, stepConfig         = stepConfig
		);
		var layoutOptions = {
			  layout = arguments.layout
			, args   = {}
		};

		if ( !Len( Trim( layoutOptions.layout ) ) ) {
			layoutOptions = _getLayoutOptionsFromStep( webflow, step );
		}

		return renderLayout(
			  layoutViewlet = layoutOptions.layout
			, layoutArgs    = layoutOptions.args
			, webflowId     = arguments.webflowId
			, instanceRef   = arguments.instanceRef
			, subReference  = arguments.subReference
			, renderedStep  = renderedStep
			, stepConfig    = stepConfig
			, webflow       = webflow
			, step          = step
			, instance      = instance
			, webflowArgs   = arguments.args
		);
	}

	public string function renderStep(
		  required string           webflowId
		, required string           instanceRef
		, required WebflowStep      step
		, required WorkflowInstance instance
		, required struct           stepConfig
	) {
		var displayConfig = step.getDisplay();
		var convention = "webflow.#arguments.webflowId#.#arguments.step.getId()#";
		var formId = "webflow-#arguments.webflowId#-#arguments.instanceRef#-#arguments.step.getId()#"
		var rendered = "";

		if ( Len( Trim( displayConfig.form ?: "" ) ) ) {
			rendered = _renderStepForm(
				  formName   = displayConfig.form
				, formId     = formId
				, instance   = arguments.instance
				, stepConfig = arguments.stepConfig
			);
		} else if ( _getFormsService().formExists( convention ) ) {
			rendered = _renderStepForm(
				  formName   = convention
				, formId     = formId
				, instance   = arguments.instance
				, stepConfig = arguments.stepConfig
			);
		}

		if ( Len( Trim( displayConfig.viewlet.event ?: "" ) ) ) {
			rendered = _renderStepViewlet(
				  event        = displayConfig.viewlet.event
				, args         = displayConfig.viewlet.args ?: {}
				, instance     = arguments.instance
				, stepConfig   = arguments.stepConfig
				, renderedForm = rendered
				, webflowId    = arguments.webflowId
				, instanceRef  = arguments.instanceRef
				, step         = arguments.step
			);
		} else if ( $getColdbox().viewletExists( convention ) ) {
			rendered = _renderStepViewlet(
				  event        = convention
				, args         = {}
				, instance     = arguments.instance
				, stepConfig   = arguments.stepConfig
				, renderedForm = rendered
				, webflowId    = arguments.webflowId
				, instanceRef  = arguments.instanceRef
				, step         = arguments.step
			);
		}

		var interceptData = {
			  rendered    = rendered
			, webflowId   = arguments.webflowId
			, instanceRef = arguments.instanceRef
			, step        = arguments.step
			, instance    = arguments.instance
			, stepConfig  = arguments.stepConfig
		};

		$announceInterception( "postRenderWebflowStep", interceptData );

		return interceptData.rendered;
	}

	public string function renderLayout(
		  required string           layoutViewlet
		, required struct           layoutArgs
		, required string           webflowId
		, required string           instanceRef
		, required string           subReference
		, required string           renderedStep
		, required struct           stepConfig
		, required Webflow          webflow
		, required WebflowStep      step
		, required WorkflowInstance instance
		,          struct           webflowArgs = {}
	) {
		var viewletArgs = StructCopy( arguments.layoutArgs );

		StructAppend( viewletArgs, {
			  webflowId    = arguments.webflowId
			, instanceRef  = arguments.instanceRef
			, subReference = arguments.subReference
			, state        = arguments.instance.getState()
			, stepConfig   = arguments.stepConfig
			, step         = arguments.step
			, webflow      = arguments.webflow
			, renderedStep = arguments.renderedStep
			, webflowArgs  = arguments.webflowArgs
			, canCancel    = !arguments.step.getFinish() && arguments.step.getCanCancel()
			, hasNext      = _getWebflowActionsService().hasNextAction( arguments.instance )
			, hasPrev      = _getWebflowActionsService().hasPrevAction( arguments.instance )
		} );

		return $getColdbox().renderViewlet(
			  event = arguments.layoutViewlet
			, args  = viewletArgs
		);
	}

// PRIVATE HELPERS
	private string function _renderIneligbleMessage(
		  required string  webflowId
		,          string  instanceRef = ""
	) {
		var config = _getWebflowConfigurator().getFlowConfig( argumentCollection=arguments );

		return $renderContent( "richeditor", config.ineligble_message ?: "" );
	}

	private string function _renderStepViewlet(
		  required string           event
		, required struct           args
		, required struct           stepConfig
		, required WorkflowInstance instance
		, required string           renderedForm
		, required string           webflowId
		, required string           instanceRef
		, required any              step
	) {
		var viewletArgs = arguments.args;
		var state = arguments.instance.getState();
		StructAppend( viewletArgs, {
			  state       = state
			, stepConfig  = arguments.stepConfig
			, webflowId   = arguments.webflowId
			, instanceRef = arguments.instanceRef
			, stepId      = arguments.step.getId()
		} );

		if ( IsStruct( state._webflowTransitionError[ arguments.step.getId() ] ?: "" ) ) {
			viewletArgs.wfTransitionError = state._webflowTransitionError[ arguments.step.getId() ];
		}

		if ( Len( Trim( renderedForm ) ) ) {
			viewletArgs.renderedForm = renderedForm;
		}

		var rendered = $getColdbox().runEvent(
			  event          = arguments.event
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=viewletArgs, wfInstance=arguments.instance }
		);

		if ( !IsNull( local.rendered ) ) {
			return rendered;
		}

		return "";
	}

	private string function _renderStepForm(
		  required string           formName
		, required string           formId
		, required WorkflowInstance instance
		, required struct           stepConfig
	) {
		var event    = $getRequestContext();
		var rc       = event.getCollection();
		var formArgs = {
			  formName              = arguments.formName
			, formId                = arguments.formId
			, savedData             = arguments.instance.getState()
			, additionalArgs        = _getFormAdditionalArgs( stepConfig )
			, validationResult      = rc.validationResult ?: ""
			, context               = event.isAdminRequest() ? _getFormAdminContext() : _getFormContext()
			, fieldLayout           = _getFormFieldLayout()
			, fieldsetLayout        = _getFormFieldsetLayout()
			, tabLayout             = _getFormTabLayout()
			, formLayout            = _getFormLayout()
			, includeValidationJs   = _getFormIncludeValidationJs()
			, validationJsJqueryRef = _getFormJqueryRef()
		};

		$announceInterception( "preRenderWebflowStepForm", {
			  renderFormArgs = formArgs
			, wfinstance     = arguments.instance
			, stepConfig     = arguments.stepConfig
		} );

		return _getFormsService().renderForm( argumentCollection=formArgs );
	}

	private any function _getInstance(
		  required string  webflowId
		, required string  instanceRef
		,          string  subReference = ""
		,          boolean archived     = false
		,          boolean lazyLoad     = true
		,          struct  explicitArgs = {}
	) {
		var svc = _getWebflowInstanceService();

		if ( !svc.instanceExists( argumentCollection=arguments ) ) {
			return svc.createInstance( argumentCollection=arguments );
		}

		return svc.getInstance( argumentCollection=arguments );
	}

	private struct function _getLayoutOptionsFromStep( required Webflow webflow, required WebflowStep step ) {
		var stepDisplay = step.getDisplay();
		if ( Len( Trim( stepDisplay.layout.event ?: "" ) ) ) {
			return {
				  layout = stepDisplay.layout.event
				, args   = stepDisplay.layout.args ?: _getWebflowLayoutArgs()
			};
		}

		var flowLayout = webflow.getLayout();
		if ( Len( Trim( flowLayout.event ?: "" ) ) ) {
			return {
				  layout = flowLayout.event
				, args   = flowLayout.args ?: _getWebflowLayoutArgs()
			};
		}

		return {
			  layout = "webflow.default.layout"
			, args   = flowLayout.args ?: _getWebflowLayoutArgs()
		};
	}

	private WebflowStep function _getWebflowStep( required Webflow webflow, required string stepId ) {
		for( var step in arguments.webflow.getSteps() ) {
			if ( step.getId() == arguments.stepId ) {
				return step;
			}
		}

		throw( "Step, [#arguments.stepId#], not found in webflow, [#arguments.webflow.getId()#]", "preside.webflow.step.not.found" );
	}

	private struct function _getFormAdditionalArgs( required struct stepConfig ) {
		var additionalArgs = {};
		var fieldConfigPattern = "form\.field\.(.*)?\.(.*)$";
		var fieldsetConfigPattern = "form\.fieldset\.(.*)?\.(.*)$";
		var tabConfigPattern = "form\.tab\.(.*)?\.(.*)$";

		for( var key in stepConfig ) {
			if ( ReFindNoCase( fieldConfigPattern, key ) ) {
				var fieldName   = ReReplaceNoCase( key, fieldConfigPattern, "\1" );
				var settingName = ReReplaceNoCase( key, fieldConfigPattern, "\2" );
				var value       = stepConfig[ key ];

				if ( Len( Trim( value ) ) ) {
					additionalArgs.fields = additionalArgs.fields ?: {};
					additionalArgs.fields[ fieldName ] = additionalArgs.fields[ fieldName ] ?: {};
					additionalArgs.fields[ fieldName ][ settingName ] = value;
				}
			} else if ( ReFindNoCase( fieldsetConfigPattern, key ) ) {
				var fieldName   = ReReplaceNoCase( key, fieldsetConfigPattern, "\1" );
				var settingName = ReReplaceNoCase( key, fieldsetConfigPattern, "\2" );
				var value       = stepConfig[ key ];

				if ( Len( Trim( value ) ) ) {
					additionalArgs.fieldsets = additionalArgs.fieldsets ?: {};
					additionalArgs.fieldsets[ fieldName ] = additionalArgs.fieldsets[ fieldName ] ?: {};
					additionalArgs.fieldsets[ fieldName ][ settingName ] = value;
				}
			} else if ( ReFindNoCase( tabConfigPattern, key ) ) {
				var fieldName   = ReReplaceNoCase( key, tabConfigPattern, "\1" );
				var settingName = ReReplaceNoCase( key, tabConfigPattern, "\2" );
				var value       = stepConfig[ key ];

				if ( Len( Trim( value ) ) ) {
					additionalArgs.tabs = additionalArgs.tabs ?: {};
					additionalArgs.tabs[ fieldName ] = additionalArgs.tabs[ fieldName ] ?: {};
					additionalArgs.tabs[ fieldName ][ settingName ] = value;
				}
			}
		}

		return additionalArgs;
	}

// GETTERS AND SETTERS
	private any function _getWebflowLibrary() {
	    return _webflowLibrary;
	}
	private void function _setWebflowLibrary( required any webflowLibrary ) {
	    _webflowLibrary = arguments.webflowLibrary;
	}

	private any function _getWebflowInstanceService() {
	    return _webflowInstanceService;
	}
	private void function _setWebflowInstanceService( required any webflowInstanceService ) {
	    _webflowInstanceService = arguments.webflowInstanceService;
	}

	private any function _getWebflowConfigurator() {
	    return _webflowConfigurator;
	}
	private void function _setWebflowConfigurator( required any webflowConfigurator ) {
	    _webflowConfigurator = arguments.webflowConfigurator;
	}

	private any function _getWebflowActionsService() {
	    return _webflowActionsService;
	}
	private void function _setWebflowActionsService( required any webflowActionsService ) {
	    _webflowActionsService = arguments.webflowActionsService;
	}

	private any function _getFormsService() {
	    return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
	    _formsService = arguments.formsService;
	}

	private struct function _getWebflowLayoutArgs() {
		return _webflowLayoutArgs;
	}
	private void function _setWebflowLayoutArgs( required any webflowLayoutArgs ) {
		_webflowLayoutArgs = arguments.webflowLayoutArgs;
	}

	private string function _getFormContext() {
	    return _formContext;
	}
	private void function _setFormContext( required string formContext ) {
	    _formContext = arguments.formContext;
	}

	private any function _getFormAdminContext() {
		return _formAdminContext;
	}
	private void function _setFormAdminContext( required any formAdminContext ) {
		_formAdminContext = arguments.formAdminContext;
	}

	private string function _getFormFieldLayout() {
	    return _formFieldLayout;
	}
	private void function _setFormFieldLayout( required string formFieldLayout ) {
	    _formFieldLayout = arguments.formFieldLayout;
	}

	private string function _getFormFieldsetLayout() {
	    return _formFieldsetLayout;
	}
	private void function _setFormFieldsetLayout( required string formFieldsetLayout ) {
	    _formFieldsetLayout = arguments.formFieldsetLayout;
	}

	private string function _getFormTabLayout() {
	    return _formTabLayout;
	}
	private void function _setFormTabLayout( required string formTabLayout ) {
	    _formTabLayout = arguments.formTabLayout;
	}

	private string function _getFormLayout() {
	    return _formLayout;
	}
	private void function _setFormLayout( required string formLayout ) {
	    _formLayout = arguments.formLayout;
	}

	private boolean function _getFormIncludeValidationJs() {
	    return _formIncludeValidationJs;
	}
	private void function _setFormIncludeValidationJs( required boolean formIncludeValidationJs ) {
	    _formIncludeValidationJs = arguments.formIncludeValidationJs;
	}

	private string function _getFormJqueryRef() {
	    return _formJqueryRef;
	}
	private void function _setFormJqueryRef( required string formJqueryRef ) {
	    _formJqueryRef = arguments.formJqueryRef;
	}
}