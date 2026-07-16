/**
 * Default handlers and viewlets for webflow
 *
 * @feature webflow
 */
component {

	property name="webflowSubmissionService"    inject="webflowSubmissionService";
	property name="webflowInstanceService"      inject="webflowInstanceService";
	property name="webflowProgressService"      inject="webflowProgressService";
	property name="webflowConfigurationService" inject="webflowConfigurationService";
	property name="webflowRenderer"             inject="webflowRenderer";
	property name="webflowExceptions"           inject="coldbox:setting:webflow.exceptions";
	property name="webflowProgressBarClass"     inject="coldbox:setting:webflow.layout.progressBar.class";

// MAIN RENDER VIEWLET
	/**
	 * @cacheable false
	 *
	 */
	private string function render( event, rc, prc, args={} ) {
		event.preventPageCache();

		_archiveCheck( argumentCollection=arguments );
		_expiredCheck( argumentCollection=arguments, redirect=false );
		_correctStepCheck( argumentCollection=arguments );

		return webflowRenderer.render(
			  argumentCollection = args
			, archiveId          = ( rc.complete ?: "" )
		);
	}

	/**
	 * @cacheable false
	 *
	 */
	private string function ajaxRender( event, rc, prc, args={} ) {
		event.preventPageCache();
		event.include( assetId="/css/frontend/webflow/ajaxLayout/", group="webflowAjax" );
		event.setLayout( "adminModalDialog" );

		var webflowQs = "";
		for ( var key in args ) {
			webflowQs = ListAppend( webflowQs, "#key#=#args[ key ]#", "&" );
		}

		var flowLinkArgs = {
			  linkto      = event.isAdminRequest() ? "webflow.ajaxLayout" : "webflow.default.ajaxLayout"
			, queryString = "flowQs=#UrlEncode( ToBase64( webflowQs ) )#"
		};

		if ( event.isAdminRequest() ) {
			args.flowLink = event.buildAdminLink( argumentCollection=flowLinkArgs );
		} else {
			args.flowLink = event.buildLink( argumentCollection=flowLinkArgs );
		}

		return renderView( view="/webflow/default/ajaxRender", args=args );
	}

// PUBLIC ACTIONS
	public void function submitAction( event, rc, prc ) {
		_processSubmission( event, rc, prc, function( flowArgs ){
			webflowSubmissionService.doNext(
				  webflowId    = arguments.flowArgs.webflowId
				, instanceRef  = arguments.flowArgs.instanceRef
				, subReference = arguments.flowArgs.subReference
				, stepId       = arguments.flowArgs.stepId
				, explicitArgs = arguments.flowArgs.args
			);

			var archivedId = webflowInstanceService.archiveCompleteWebflow(
				  webflowId    = arguments.flowArgs.webflowId
				, instanceRef  = arguments.flowArgs.instanceRef
				, subReference = arguments.flowArgs.subReference
			);

			if ( Len( archivedId ) ) {
				rc._rurl = _getRedirectUrl( argumentCollection=arguments );
				rc._rurl &= ( rc._rurl contains '?' ? "&" : "?" ) & "complete=#archivedId#";
			}
		} );
	}

	public void function backAction( event, rc, prc ) {
		_processSubmission( event, rc, prc, function( flowArgs ) {
			webflowSubmissionService.doPrev(
				  webflowId    = arguments.flowArgs.webflowId
				, instanceRef  = arguments.flowArgs.instanceRef
				, subReference = arguments.flowArgs.subReference
				, stepId       = arguments.flowArgs.stepId
				, explicitArgs = arguments.flowArgs.args
			);
		} );
	}

	public void function backToStepAction( event, rc, prc ) {
		_processSubmission( event, rc, prc, function( flowArgs ) {
			webflowSubmissionService.backToStep(
				  webflowId     = arguments.flowArgs.webflowId
				, instanceRef   = arguments.flowArgs.instanceRef
				, subReference = arguments.flowArgs.subReference
				, currentStepId = arguments.flowArgs.stepId
				, backToStepId  = ( rc.backToStep ?: "" )
			);
		} );

	}

	public void function cancelAction( event, rc, prc ) {
		_processSubmission( event, rc, prc, function( flowArgs ) {
			webflowSubmissionService.doCancel(
				  webflowId    = arguments.flowArgs.webflowId
				, instanceRef  = arguments.flowArgs.instanceRef
				, subReference = arguments.flowArgs.subReference
				, stepId       = arguments.flowArgs.stepId
				, explicitArgs = arguments.flowArgs.args
			);
		} );
	}

	/**
	 * @cacheable false
	 *
	 */
	public string function ajaxLayout( event, rc, prc, args={} ) {
		event.preventPageCache();

		var flowArgs = {};
		var flowQs   = Trim( rc.flowQs ?: "" );
		    flowQs   = ListToArray( ToString( ToBinary( UrlDecode( flowQs ) ) ), "&" );

		for ( var qs in flowQs ) {
			if ( ListLen( qs, "=" ) > 1 ) {
				flowArgs[ ListFirst( qs, "=" ) ] = ListRest( qs, "=" );
			}
		}

		flowArgs.layout        = "";
		flowArgs.useAjaxLayout = true;

		return renderViewlet( event="webflow.default.render", args=flowArgs );
	}

// VIEWLETS
	private string function layout( event, rc, prc, args={} ){
		args.isLazyLoaded = !webflowInstanceService.instanceExists(
			  webflowId    = args.webflowId    ?: ""
			, instanceRef  = args.instanceRef  ?: ""
			, subReference = args.subReference ?: ""
			, explicitArgs = args.webflowArgs  ?: {}
			, archiveId    = args.archiveId    ?: ""
		);
		args.formId       = args.formId     ?: "webflow-#args.webflowId#-#args.instanceRef#-#args.step.getId()#"
		args.formAction   = args.formAction ?: _getSubmitAction( argumentCollection=arguments );
		args.title        = renderView( view="/webflow/default/stepTitle", args=args );
		args.introCopy    = renderContent(
			  renderer = "richeditor"
			, data     = ( args.stepConfig.intro ?: "" )
			, context  = [ "webflow", "website" ]
		);

		args.messages         = renderViewlet( event="webflow.default.messages", args=args );
		args.obfuscatedFields = encryptWebflowArgs( args.webflowId, args.instanceRef, args.subReference, args.step.getId() );
		args.returnUrl        = stringToHex( getWebflowReturnUrl() );

		args.hiddenFormFields = renderView( view="/webflow/default/hiddenFormFields", args=args );

		if ( !IsTrue( args.noActions ?: "" ) ) {
			args.actions = renderViewlet( event="webflow.default.actions", args=args );
		}

		if ( IsTrue( args.showProgress ?: true ) && IsTrue( args.stepConfig.showProgress ?: true ) ) {
			args.progressBar = renderViewlet( event="webflow.default.progressbar", args=args );
		}

		if ( event.isAdminRequest() ) {
			event.include( "/css/admin/specific/webflowlayout/" );
		}

		return renderView( view="/webflow/default/layout", args=args );
	}

	private string function messages( event, rc, prc, args={} ) {
		var rendered = "";

		args.successMessage = Trim( rc.webflowSuccessMessage ?: "" );
		args.errorMessage   = Trim( rc.webflowErrorMessage   ?: "" );
		args.warningMessage = Trim( rc.webflowWarningMessage ?: "" );

		if ( !Len( args.errorMessage ) && IsInstanceOf( rc.validationResult ?: "", "ValidationResult" ) ) {
			if ( !rc.validationResult.validated() ) {
				args.errorMessage = rc.validationResult.getGeneralMessage();

				if ( Len( Trim( args.errorMessage ) ) ) {
					args.errorMessage = Trim( translateResource( uri=rc.validationResult.getGeneralMessage(), defaultValue=args.errorMessage ) );
				}

				if ( !Len( Trim( args.errorMessage ) ) ) {
					args.errorMessage = Trim( translateResource( uri="webflow:error.validation.errors" ) );
				}
			}
		}

		if ( Len( args.errorMessage ) ) {
			rendered = renderView( view="/webflow/default/errorMessage", args=args );
		}

		if ( Len( args.successMessage ) ) {
			rendered &= renderView( view="/webflow/default/successMessage", args=args );
		}

		if ( Len( args.warningMessage ) ) {
			rendered &= renderView( view="/webflow/default/warningMessage", args=args );
		}

		return rendered;
	}

	private string function actions( event, rc, prc, args={} ){
		var extraQs                  = "";
		var useAjaxLayout            = IsTrue( args.useAjaxLayout ?: "" );
		var additionalAction         = IsStruct( args.additionalAction ?: "" ) ? Duplicate( args.additionalAction ) : {};
		var additionalHandler        = Trim( args.additionalActionHandler ?: "" );
		var additionalHandlerResult  = "";
		var additionalActionHref     = "";
		var additionalActionUrlValue = "";
		var webflowActionQs          = "";

		if ( useAjaxLayout ) {
			extraQs = "&args.useAjaxLayout=true&_rurl=#args.returnUrl ?: ""#";
		}

		webflowActionQs = "csrfToken=#event.getCsrfToken()#&_wid=#UrlEncode( args.obfuscatedFields )##extraQs#";

		if ( IsTrue( args.hasNext ?: "" ) && IsFalse( args.disableNext ?: "" ) ) {
			args.nextButton = renderViewlet( event="webflow.default.nextButton", args=args );
		}
		if ( IsTrue( args.hasPrev ?: "" ) && IsFalse( args.disablePrev ?: "" ) ) {
			args.prevLink   = args.prevLink ?: event.buildLink( linkto="webflow.default.backAction", queryString=webflowActionQs );
			args.prevButton = renderViewlet( event="webflow.default.prevButton", args=args );
		}
		if ( IsTrue( args.canCancel ?: "" ) ) {
			args.cancelLink   = args.cancelLink ?: event.buildLink( linkto="webflow.default.cancelAction", queryString=webflowActionQs );
			args.cancelButton = renderViewlet( event="webflow.default.cancelButton", args=args );
		}

		if ( Len( additionalHandler ) && getController().handlerExists( additionalHandler ) ) {
			additionalHandlerResult = runEvent(
				  event          = additionalHandler
				, private        = true
				, prePostExempt  = true
				, eventArguments = { args=args }
			);

			if ( IsStruct( additionalHandlerResult ) ) {
				StructAppend( additionalAction, additionalHandlerResult, true );
			}
		}

		args.additionalActionLabel = Trim( additionalAction.label ?: "" );
		args.additionalActionClass = Trim( additionalAction.class ?: "" );
		args.extraButtonGroupWith  = LCase( Trim( additionalAction.groupWith ?: "next" ) );
		additionalActionUrlValue   = Trim( additionalAction.url ?: "" );

		if ( Len( additionalActionUrlValue ) ) {
			if ( ReFindNoCase( "^(https?:|/|##|\?|//)", additionalActionUrlValue ) ) {
				additionalActionHref = additionalActionUrlValue;
			} else if ( getController().handlerExists( additionalActionUrlValue ) ) {
				if ( event.isAdminRequest() ) {
					additionalActionHref = event.buildAdminLink( linkto=additionalActionUrlValue, queryString=webflowActionQs );
				} else {
					additionalActionHref = event.buildLink( linkto=additionalActionUrlValue, queryString=webflowActionQs );
				}
			}
		}

		args.additionalActionUrl = Trim( additionalActionHref );

		if ( Len( args.additionalActionLabel ) && Len( args.additionalActionUrl ) ) {
			args.extraButton = renderViewlet( event="webflow.default.extraButton", args=args );
		}

		return renderView( view="/webflow/default/actions", args=args );
	}

	private string function progressBar( event, rc, prc, args={} ) {
		var instance = webflowInstanceService.getInstance(
			  webflowId    = args.webflowId    ?: ""
			, instanceRef  = args.instanceRef  ?: ""
			, subReference = args.subReference ?: ""
			, archiveId    = ( rc.complete ?: "" )
		);

		if ( IsNull( local.instance ) ) {
			return "";
		}
		var isAdminRequest     = event.isAdminRequest();
		var isComplete         = instance.isComplete();
		var backToStepBaseLink = event.buildLink( linkto="webflow.default.backToStepAction", queryString="csrfToken=#event.getCsrfToken()#&_wid=#UrlEncode( args.obfuscatedFields )#&backToStep={stepid}" );
		var flowConfig         = webflowConfigurationService.getFlowConfig( webflowId=args.webflowId ?: "" );
		var progressbarLayout  = Trim( flowConfig.progressbar_layout ?: "" );
		var stepTitles         = webflowConfigurationService.getStepTitles(
			  webflowId   = args.webflowId   ?: ""
			, instanceRef = args.instanceRef ?: ""
			, short       = true
		);

		args.useAjaxLayout      = args.useAjaxLayout    ?: false;
		args.progressBarClass   = args.progressBarClass ?: webflowProgressBarClass;
		args.progressIndicators = webflowProgressService.getProgressIndicators( instance );
		args.stepCount          = ArrayLen( args.progressIndicators );
		args.currentStepNumber  = 1;
		args.currentStepTitle   = "";

		for( var i=1; i<=ArrayLen( args.progressIndicators ); i++ ) {
			var step = args.progressIndicators[ i ];

			if ( step.status == "active" ) {
				args.currentStepNumber = i;

				if ( isComplete ) {
					step.class = "step-complete";
				} else {
					step.class = "step-current";
				}
			} else if ( step.status == "complete" ) {
				step.class = "step-complete";
			} else {
				step.class = "step-pending";
			}
			if ( isAdminRequest ) {
				step.class &= " #LCase( step.status )#";
			}
			step.title = stepTitles[ step.step ] ?: step.step;

			if ( step.status == "active" ) {
				args.currentStepTitle = step.title;
			}

			if ( !isComplete && step.status == "complete" && !args.useAjaxLayout ) {
				step.link = Replace( backToStepBaseLink, "{stepid}", step.step );
			} else {
				step.link = "";
			}
		}

		if ( isAdminRequest ) {
			return renderView( view="/admin/webflow/progressbar", args=args );
		}

		if ( Len( progressbarLayout ) ) {
			args.progressBarClass = translateResource( uri="enum.webflowProgressBarType:#progressbarLayout#.cssclass", defaultValue="" );

			if ( getController().viewletExists( "webflow.default.progressbar._#progressbarLayout#" ) ) {
				return renderViewlet( event="webflow.default.progressbar._#progressbarLayout#", args=args );
			}
		}

		return renderView( view="/webflow/default/progressbar", args=args );
	}

// HELPERS
	private void function _processSubmission( event, rc, prc, processFn ) {
		if ( event.getHTTPHeader( "sec-purpose" ) == "prefetch" ) {
			content reset=true;
			header statuscode="400" statustext="Not allowed";
			abort;
		}

		var flowArgs = decryptWebflowArgs();
		flowArgs.args = {};

		for( var key in rc ) {
			if ( ReFindNoCase( "^args\..+$", key ) ) {
				flowArgs.args[ ReReplaceNoCase( key, "^args\.(.+)$", "\1" ) ] = rc[ key ];
			}
		}

		if ( flowArgs.valid ) {
			var instanceExists = webflowInstanceService.instanceExists( webflowId=flowArgs.webflowId, instanceRef=flowArgs.instanceRef, subReference=flowArgs.subReference );

			if ( !instanceExists || event.validateCsrfToken( rc.csrfToken ?: "" ) ) {
				if ( !webflowInstanceService.currentStepIgnoresExpiryOnSubmission( webflowId=flowArgs.webflowId, instanceRef=flowArgs.instanceRef, subReference=flowArgs.subReference ) ) {
					_expiredCheck( argumentCollection=arguments, args=flowArgs );
				}
				try {
					processFn( flowArgs );
				} catch( any e ) {
					if ( !arrayFindNoCase( webflowExceptions.safe ?: [], e.type ?: "" ) ) {
						logError( e );
					}
					_persistError( event, rc, prc, "webflow:error.unexpected.submission.error", [ e.message ] );
				}
			} else {
				_persistError( event, rc, prc, "webflow:error.csrf.token.invalid" );
			}
		} else {
			_persistError( event, rc, prc, "webflow:error.missing.submission.args" )
		}

		setNextEvent( url=_getRedirectUrl( argumentCollection=arguments, flowArgs=flowArgs ) );
	}

	private void function _expiredCheck( event, rc, prc, args={}, redirect=true ) {
		var webflowId    = args.webflowId    ?: "";
		var instanceRef  = args.instanceRef  ?: "";
		var subReference = args.subReference ?: "";

		if ( webflowInstanceService.archiveExpiredWorkflow( webflowId, instanceRef, subReference ) ) {
			var flowConfig = webflowConfigurationService.getFlowConfig( webflowId, instanceRef );
			var message = Len( Trim( flowConfig.timeout_message ?: "" ) ) ? renderContent( "richeditor", flowConfig.timeout_message ) : "webflow:error.inactive.timeout";

			_persistError( event, rc, prc, message );

			if ( arguments.redirect ) {
				setNextEvent( url=_getRedirectUrl( argumentCollection=arguments ) );
			}
		}
	}

	private void function _archiveCheck( event, rc, prc, args={} ) {
		var archiveId = rc.complete ?: "";

		if ( Len( archiveId ) ) {
			var instance = webflowInstanceService.getInstance( webflowId=args.webflowId ?: "", instanceRef=args.instanceRef ?: "", subReference=args.subReference ?: "", archiveId=( rc.complete ?: "" ) );
			if ( IsNull( local.instance ) ) {
				setNextEvent( url=Replace( event.getCurrentUrl(), "complete=#rc.complete#", "" ) );
			}
		}
	}

	private void function _correctStepCheck( event, rc, prc, args={} ) {
		var askedForStep = rc._ws ?: "";
		var instance = webflowInstanceService.getInstance( webflowId=args.webflowId ?: "", instanceRef=args.instanceRef ?: "", subReference=args.subReference ?: "" );

		if ( IsNull( local.instance ) ) {
			return;
		}

		var currentStep = instance.getActiveStep();
		if ( !Len( Trim( currentStep ) ) ) {
			webflowInstanceService.deleteBrokenInstance( instance );
			_persistError( argumentCollection=arguments, message="webflow:error.step.not.found" );
			setNextEvent( url=event.getCurrentUrl() );
		}

		try {
			askedForStep = ToString( ToBinary( askedForStep ) );
		} catch( any e ) {
			askedForStep = "";
		}

		if ( !Len( Trim( askedForStep ) ) ) {
			askedForStep = currentStep;
		}

		if ( askedForStep != currentStep ) {
			try {
				webflowSubmissionService.backToStep(
					  webflowId     = args.webflowId    ?: ""
					, instanceRef   = args.instanceRef  ?: ""
					, subReference  = args.subReference ?: ""
					, currentStepId = currentStep
					, backToStepId  = askedForStep
				);
			} catch( preside.webflow.step.not.completed e ) {
 			} catch( preside.webflow.step.not.active e ) {
			} catch( preside.webflow.instance.not.active e ) {
			}
		}
	}

	private void function _persistError( event, rc, prc, message, data=[] ) {
		var persist = event.getCollectionWithoutSystemVars();
		persist.webflowErrorMessage = translateResource( uri=arguments.message, data=data, defaultValue=arguments.message );

		getController().getRequestService().getFlashScope().putAll(
			  map     = persist
			, saveNow = true
		);
	}

	private string function _getRedirectUrl( event, rc, prc, flowArgs ) {
		var redirectUrl = _decodeEncodedRUrl( rc._rurl ?: "" );

		if ( IsEmpty( redirectUrl ) ) {
			redirectUrl = cgi.http_referer ?: "";
		}

		if ( StructKeyExists( arguments, "flowArgs" ) && Len( Trim( arguments.flowArgs.webflowId ?: "" ) ) ) {
			var wfInstance  = webflowInstanceService.getInstance( argumentCollection=flowArgs );
			if ( !IsNull( local.wfInstance ) ) {
				var stepId = ToBase64( wfInstance.getActiveStep() );
				var stepIdPattern = "([\?&]_ws=)(.*?)(&|$)";
				if ( ReFindNoCase( stepIdPattern, redirectUrl ) ) {
					redirectUrl = ReReplaceNoCase( redirectUrl, stepIdPattern, "\1#stepId#\3" );
				} else if ( len( stepId ) ) {
					var delim = Find( "?", redirectUrl ) ? "&" : "?";
					redirectUrl &= delim & "_ws=" & stepId;
				}
			}
		}

		if ( isFeatureEnabled( "sites" ) && IsValid( "url", redirectUrl ) ) {
			var rurlDomain    = _getUrlDomain( redirectUrl );
			var site          = event.getSite();
			var allowedDomain = getSystemSetting( "workflow", "allowed_redirect_domain", site.domain );

			if ( isEmptyString( allowedDomain ) ) {
				allowedDomain = site.domain;
			}

			if( !listFind( allowedDomain, rurlDomain, Chr(13) & Chr(10) ) ) {
				return event.getSiteUrl();
			}
		}

		return redirectUrl;
	}

	private string function _decodeEncodedRUrl( string encodedRUrl="" ) output=false {
		if ( !Len( arguments.encodedRUrl ) ) {
			return "";
		}

		try {
			return hexToString( arguments.encodedRUrl );
		} catch( any e ) {
			return arguments.encodedRUrl;
		}
	}

	private string function _getUrlDomain( required string redirectUrl ) output=false {
		if( !reFind( "^https?:\/\/", redirectUrl ) ) {
			return "";
		}

		var urlDomain = listFirst( reReplaceNoCase( redirectUrl, '^https?:\/\/(.+)', '\1' ), "/:" );
		return urlDomain ?: "";
	}

	private string function _getSubmitAction( event, rc, prc ) {
		if ( event.isAdminRequest() ) {
			return event.buildAdminLink( linkto="webflow.submitAction" );
		}
		return event.buildLink( linkto="webflow.default.submitAction" );
	}
}