/**
 * @feature datamanagerworkflow
 */
component extends="preside.system.base.AdminHandler" {

	property name="datamanagerWorkflowService"  inject="datamanagerWorkflowService";

// PUBLIC COLDBOX ACTIONS
	public function actionForm( event, rc, prc ) {
		var args        = _commonActionChecks( argumentCollection=arguments );
		var baseI18nUri = "datamanagerWorkflow.#args.workflowId#:step.#args.step#.action.#args.action#";

		prc.pageTitle         = translateResource( uri="#baseI18nUri#.title"          , defaultValue=args.action );
		prc.pageSubTitle      = translateResource( uri="#baseI18nUri#.description"    , defaultValue="" );
		prc.pageIcon          = translateResource( uri="#baseI18nUri#.iconClass"      , defaultValue="fa-play" );
		prc.submitButtonLabel = translateResource( uri="#baseI18nUri#.form.submit.btn", defaultValue=translateResource( uri="datamanagerWorkflow:flow.action.form.submit.btn" ) );

		event.addAdminBreadCrumb( title=prc.pageTitle, link="" );

		StructAppend( prc, args );

		prc.cancelLink = event.buildAdminLink( objectName=args.objectName, recordId=args.recordId );
		prc.actionUrl  = event.buildAdminLink( linkto="datamanagerWorkflow.doAction", queryString="objectName=#args.objectName#&recordId=#args.recordId#&step=#args.step#&action=#args.action#" );
	}

	public function doAction( event, rc, prc ) {
		var args     = _commonActionChecks( argumentCollection=arguments );
		var formData = Len( args.formName ) ? event.getCollectionForForm( args.formName ) : {};

		if ( Len( args.formName ) ) {
			var actionFormUrl = event.buildAdminLink(
				  linkto      = "datamanagerWorkflow.actionForm"
				, queryString = "objectName=#args.objectName#&recordId=#args.recordId#&step=#args.step#&action=#args.action#"
			);

			if ( !ArrayFindNoCase( event.getSubmittedPresideForms(), args.formName ) ) {
				setNextEvent( url=actionFormUrl );
			}

			var validationResult = validateForm( args.formName, formData );
			if ( !validationResult.validated() ) {
				formData.validationResult = validationResult;
				messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
				setNextEvent( url=actionFormUrl, persistStruct=formData );
			}
		}

		var success = false;
		try {
			success = datamanagerWorkflowService.triggerAction( argumentCollection=args, formData=formData );
		} catch( any e ) {
			// TODO: something useful with errors
			rethrow;
		}

		if ( success ) {
			event.audit(
				  action   = "triggeraction"
				, type     = "datamanagerworkflow"
				, recordId = args.recordId
				, detail   = {
					  objectName = args.objectName
					, recordId   = args.recordId
					, workflowId = args.workflowId
					, step       = args.step
					, action     = args.action
					, formData   = formData
				  }
			);

			messagebox.info( translateResource(
				  uri          = "datamanagerWorkflow.#args.workflowId#:step.#args.step#.action.#args.action#.success"
				, data         = [ prc.recordLabel ]
				, defaultValue = translateResource( uri="datamanagerWorkflow:flow.successfully.transitioned", data=[ prc.recordLabel ] )
			) );
		} else {
			messagebox.warning( translateResource( uri="datamanagerWorkflow:flow.failed.to.transition", data=[ prc.recordLabel ] ) );
		}

		setNextEvent( url=event.buildAdminLink( objectname=prc.objectName, recordId=prc.recordId ));
	}

	public void function flowDiagram( event, rc, prc ) {
		content reset=true type="image/svg+xml";
		echo( datamanagerWorkflowService.renderFlowDiagram(
			  objectName = rc.objectName ?: ""
			, recordId   = rc.recordId   ?: ""
		) );
		abort;
	}

// VIEWLETS AND HELPERS
	private void function addWorkflowActionButtons( event, rc, prc, objectName="", actions=[], recordId="" ) {
		var workflowId = datamanagerWorkflowService.getWorkflowIdForRecord( objectName=arguments.objectName, recordId=arguments.recordId );

		if ( Len( workflowId ) ) {
			var status           = datamanagerWorkflowService.renderStatus( objectName=arguments.objectName, recordId=arguments.recordId, workflowId=workflowId );
			var childActions     = [];
			var availableActions = datamanagerWorkflowService.getAvailableActions(
				  objectName = arguments.objectName
				, recordId   = arguments.recordId
			);
			for( var i=1; i<=ArrayLen( availableActions ); i++ ) {
				var action      = availableActions[ i ];
				var actionI18nBase = "datamanagerWorkflow.#workflowId#:step.#action.step#.action.#action.action#";
				var actionTitle = translateResource( uri="#actionI18nBase#.title", defaultValue=action.action );

				if ( action.enabled ) {
					ArrayAppend( childActions, {
						  link   = event.buildAdminLink( linkto="datamanagerWorkflow.doAction", queryString="objectName=#arguments.objectName#&recordId=#arguments.recordId#&step=#action.step#&action=#action.action#" )
						, icon   = translateResource( uri="#actionI18nBase#.iconClass", defaultValue="fa-play" )
						, title  = actionTitle
						, prompt = translateResource( uri="#actionI18nBase#.prompt", defaultValue="" )
						, match  = translateResource( uri="#actionI18nBase#.match", defaultValue="" )
					} );
				} else {
					if ( !action.hasPermission ) {
						ArrayAppend( childActions, {
							  linkAttributes = { disabled="disabled", title=HtmlEditFormat( translateResource( uri="#actionI18nBase#.access.denied", defaultValue=translateResource( uri="datamanagerWorkflow:action.access.denied" ) ) ) }
							, linkClass      = "disabled"
							, icon           = "fa-lock"
							, title          = actionTitle
						} );
					} else if ( !action.passesCondition ) {
						ArrayAppend( childActions, {
							  linkAttributes = { disabled="disabled", title=HtmlEditFormat( translateResource( uri="#actionI18nBase#.condition.failed", defaultValue=translateResource( uri="datamanagerWorkflow:action.condition.failed" ) ) ) }
							, linkClass      = "disabled"
							, icon           = translateResource( uri="#actionI18nBase#.iconClass", defaultValue="fa-play" )
							, title          = actionTitle
						} );
					}
				}
			}

			if ( ArrayLen( childActions ) ) {
				ArrayAppend( childActions, "---" );
				ArrayAppend( childActions, {
					  link = event.buildAdminLink( objectName=arguments.objectName, recordId=arguments.recordId, queryString="tab=workflow" )
					, icon = "fa-code-fork"
					, title = translateResource( uri="datamanagerWorkflow:view.workflow.menu.item" )
				} );

				ArrayPrepend( arguments.actions, {
					  btnClass  = "btn-secondary-default"
					, iconClass = "fa-code-fork"
					, title     = translateResource( uri="datamanagerWorkflow:workflow.menu.btn", data=[ status ] )
					, children  = childActions
				} );
			} else {
				ArrayPrepend( arguments.actions,
					'<a class="btn btn-text-neutral" disabled="disabled"><i class="fa fa-fw fa-code-fork"></i> #translateResource( uri="datamanagerWorkflow:workflow.menu.btn", data=[ status ] )#</a>'
				);
			}
		}

		// TODO
	}

	private string function renderWorkflowStatus( event, rc, prc, args={} ){
		var workflowId  = args.workflowId ?: "";
		var activeSteps = args.activeSteps ?: [];
		var renderedSteps = [];
		var baseI18n      = "datamanagerWorkflow.#workflowId#:step";

		for( var step in activeSteps ) {
			ArrayAppend( renderedSteps, translateResource( uri="#baseI18n#.#step#.title", defaultValue=step ) );
		}

		if ( ArrayLen( renderedSteps ) ) {
			return ArrayToList( renderedSteps, ", " );
		}

		return translateResource( "datamanagerWorkflow:status.unknown" )
	}

	private function _appendStatePostFunction( event, rc, prc, args={}, wfInstance ) {
		if ( StructKeyExists( args, "state" ) && IsStruct( args.state ) && StructCount( args.state ) ) {
			wfInstance.appendState( args.state );
		}
	}

	private struct function _commonActionChecks( event, rc, prc ) {
		event.initializeDatamanagerPage(
			  objectName = ( rc.objectName ?: "" )
			, recordId   = ( rc.recordId   ?: "" )
		);

		if ( !Len( prc.recordId ) || !Len( rc.step ?: "" ) || !Len( rc.action ?: "" ) ) {
			event.notFound();
		}

		var workflowId = datamanagerWorkflowService.getWorkflowIdForRecord( objectName=prc.objectName, recordId=prc.recordId );
		var wfInstance = datamanagerWorkflowService.getInstance( objectName=prc.objectName, recordId=prc.recordId );
		var args = {
			  objectName = prc.objectName
			, recordId   = prc.recordId
			, workflowId = workflowId
			, wfInstance = wfInstance
			, step       = rc.step
			, action     = rc.action
		};

		if ( !prc.canEdit || !datamanagerWorkflowService.hasActionPermission( argumentCollection=args ) ) {
			event.adminAccessDenied();
		}

		if ( !datamanagerWorkflowService.actionPassesCondition( argumentCollection=args ) ) {
			messagebox.warning( translateResource(
				  uri          = "datamanagerWorkflow.#workflowId#:step.#rc.step#.action.#rc.action#.condition.failed"
				, data         = [ prc.recordLabel ]
				, defaultValue = translateResource( "datamanagerWorkflow:flow.action.condition.failed" )
			) );

			setNextEvent( url=event.buildAdminLink( objectname=prc.objectName, recordId=prc.recordId ) );
		}

		args.formName = datamanagerWorkflowService.getFormNameForAction( argumentCollection=args )

		return args;
	}
}