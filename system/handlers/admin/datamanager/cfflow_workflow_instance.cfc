/**
 * @feature    cfflow
 */
component extends="preside.system.base.EnhancedDataManagerBase" {
	variables.permissionBase = "webflows";
	variables.infoCardStyle  = "definitionList";
	variables.tabs           = [ "transitions", "default" ];
	variables.infoCol1       = [ "currentStatus", "currentStep", "owner" ];
	variables.infoCol2       = [ "sub_reference" ];
	variables.infoCol3       = [ "datecreated", "datemodified" ];

	property name="webflowConfigService"   inject="webflowConfigurationService";
	property name="webflowInstanceService" inject="WebflowInstanceService";
	property name="webflowLibrary"         inject="WebflowSpecLibrary";
	property name="webflowUtilsService"    inject="WebflowUtilsService";

	private string function _transitionsTab( event, rc, prc, args={} ) {
		args.diagramUrl = event.buildAdminLink(
			  linkto      = "datamanager.cfflow_workflow_instance.flowDiagram"
			, queryString = "objectName=#args.objectName#&recordId=#args.recordId#"
		);

		args.instanceHistory = objectDataTable( objectName="cfflow_workflow_instance_history", args={
			  useMultiActions = false
			, allowSearch     = false
			, allowFilter     = false
			, allowDataExport = false
			, noActions       = true
			, compact         = true
			, gridFields      = [ "step", "action", "result", "datecreated" ]
		} );

		return renderView( view="/admin/webflow/_instanceTransitions", args=args );
	}

	private string function _defaultTab( event, rc, prc, args={} ) {
		args.savedState    = Trim( args.record.state ?: "" );
		args.savedState    = IsJSON( args.savedState ) ? DeserializeJSON( args.savedState ) : {};
		args.hasPermission = hasCmsPermission( "webflows.admin.viewSavedState" );
		args.printedState  = webflowUtilsService.prettyPrintSavedState( savedState=args.savedState );

		return renderView( view="/admin/datamanager/webflow_configuration/_instanceDetail", args=args )
	}

	private string function _infoCardcurrentStatus( event, rc, prc, args={} ) {
		var currentStatus = renderField(
			  object   = "cfflow_workflow_instance"
			, property = "current_status"
			, data     = args.record.current_status ?: ""
		);

		if ( Len( currentStatus ) ) {
			return '<span class="badge badge-#( currentStatus == "active" ) ? "success" : "warning"#">#currentStatus#</span>';
		}
		return "";
	}

	private string function _infoCardCurrentStep( event, rc, prc, args={} ) {
		var recordId          = prc.recordId ?: ( args.recordId ?: "" );
		var latestCurrentStep = getPresideObject( "cfflow_workflow_instance_history" ).selectData(
			  filter       = { instance=recordId }
			, orderBy      = "datecreated DESC"
			, selectFields = [ "result as step_id", "instance.reference", "instance.sub_reference" ]
			, maxRows      = 1
			, returntype   = "singleRecordStruct"
		);

		if ( !StructIsEmpty( latestCurrentStep ) ) {
			return renderContent(
				  renderer = "webflowInstanceStepTitle"
				, data     = latestCurrentStep.step_id
				, args     = { webflowId=latestCurrentStep.reference, instanceRef=latestCurrentStep.sub_reference }
			);
		}
		return "";
	}

	private string function _infoCardDateCreated( event, rc, prc, args={} ) {
		var data = args.record.datecreated ?: "";

		if ( IsDate( data ) ) {
			return renderContent( "datetime", data, "relative" );
		}
		return "";
	}

	private string function _infoCardDateModified( event, rc, prc, args={} ) {
		var data = args.record.datemodified ?: "";

		if ( IsDate( data ) ) {
			return renderContent( "datetime", data, "relative" );
		}
		return "";
	}

// CUSTOM VIEWLETs
	public void function archiveInstanceAction( event, rc, prc, args={} ) {
		if ( !hasCmsPermission( "webflows.archiveInstance" ) ) {
			event.adminAccessDenied()
		}

		var instanceId  = Trim( rc.id        ?: "" );
		var instanceRef = Trim( rc.reference ?: "" );

		event.initializeDatamanagerPage( objectName="cfflow_workflow_instance", recordId=instanceId );
		if ( isEmptyString( instanceId ) || !IsQuery( prc.record ?: "" ) || !prc.record.recordcount ) {
			event.notFound();
		}

		var instanceWebflow = getPresideObject( "webflow_configuration" ).selectData(
			  selectFields = [ "id" ]
			, filter       = "webflow_id = :webflow_id AND ( is_singleton = :trueVal OR ( is_singleton = :falseVal AND instance_ref = :instance_ref ) )"
			, filterParams = {
				  webflow_id   = prc.record.reference
				, instance_ref = reference
				, trueVal      = { type="cf_sql_bit", value=true }
				, falseVal     = { type="cf_sql_bit", value=false }
			}
		);

		if ( !instanceWebflow.recordcount ) {
			event.notFound();
		}

		var success = webflowInstanceService.archiveWorkflow(
			  webflowId     = prc.record.reference
			, instanceRef   = prc.record.sub_reference
			, subReference  = prc.record.sub_sub_reference
			, explicitArgs  = { owner=prc.record.owner }
			, archiveReason = "adminarchive"
		);

		if ( success ) {
			messageBox.info( translateResource( uri="preside-objects.cfflow_workflow_instance:admin.archiveInstance.success.message" ) );
		} else {
			messageBox.error( translateResource( uri="preside-objects.cfflow_workflow_instance:admin.archiveInstance.failed.message" ) );
		}
		setNextEvent( url=event.buildAdminLink( objectName="webflow_configuration", recordId=instanceWebflow.id, querystring="tab=activeInstances&reference=#instanceRef#" ) );
	}

	public void function flowDiagram() {
		var objectName = Trim( rc.objectName ?: "" );
		var recordId   = Trim( rc.recordId   ?: "" );

		content reset=true type="image/svg+xml";
		Echo( webflowInstanceService.renderFlowDiagram( objectName=objectName, recordId=recordId ) );
		abort;
	}

// DATAMANAGER CUSTOMISATIONs
	private string function buildListingLink( event, rc, prc, args={} ) {
		var instanceRef   = Trim( prc.record.sub_reference ?: "" );
		var webflowId     = Trim( prc.record.reference ?: "" );
		var webflowDetail = getPresideObject( "webflow_configuration" ).selectData(
			  filter       = { webflow_id=webflowId }
			, selectFields = [ "id", "is_singleton" ]
			, returntype   = "singleRecordStruct"
		);

		if ( !StructIsEmpty( webflowDetail ) && isTrue( webflowDetail.is_singleton ) ) {
			return event.buildAdminLink(
				  objectName  = "webflow_configuration"
				, recordId    = webflowDetail.id
				, queryString = "#Len( instanceRef ) ? "reference=#instanceRef#" : ""#"
			);
		}

		return event.buildAdminLink( objectName="cfflow_workflow_instance" );
	}

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var record   = args.record  ?: {};
		var recordId = record.id    ?: "";
		var actions  = args.actions ?: [];

		if ( Len( recordId ) && hasCmsPermission( "webflows.archiveInstance" ) ) {
			ArrayAppend( args.actions, {
				  link  = event.buildAdminLink( linkto="datamanager.cfflow_workflow_instance.archiveInstanceAction", queryString="id=#recordId#&reference=#rc.reference ?: ""#" )
				, icon  = "fa-archive"
				, class = "red confirmation-prompt"
				, title = translateResource( uri="preside-objects.cfflow_workflow_instance:admin.archiveInstance.prompt", data=[ renderContent( "webflowOwner", record.owner ?: "" ) ] )
				, match = translateResource( uri="preside-objects.cfflow_workflow_instance:admin.archiveInstance.match" )
			} );
		}
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var qs         = [];
		var objectName = Trim( prc.objectName         ?: "" );
		var webflowId  = Trim( prc.record?.webflow_id ?: "" );

		if ( objectName == "webflow_configuration" ) {
			ArrayAppend( qs, "webflow_id=#webflowId#" );
		}

		if ( Len( Trim( rc.reference ?: "" ) ) ) {
			ArrayAppend( qs, "reference=#reference#" );
		} else if ( Len( Trim( prc.record.instance_ref ?: "" ) ) ) {
			ArrayAppend( qs, "reference=#prc.record.instance_ref#" );
		}

		return ArrayToList( qs, "&" );
	}
	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters   ?: [];
		var webflowId     = Trim( rc.webflow_id ?: "" );
		var referenceId   = Trim( rc.reference ?: "" );

		if ( Len( webflowId ) ) {
			ArrayAppend( args.extraFilters, { filter={ reference=webflowId } } );
		}
		if ( Len( referenceId ) ) {
			ArrayAppend( args.extraFilters, { filter={ sub_reference=referenceId } } );
		}
	}

	private void function extraTopRightButtonsForViewRecord( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var recordId   = prc.recordId    ?: "";
		var record     = prc.record      ?: {};
		args.actions   = args.actions    ?: [];

		if ( Len( recordId ) && hasCmsPermission( "webflows.archiveInstance" ) ) {
			var instanceRef = Trim( record.sub_reference ?: "" );

			ArrayPrepend( args.actions, {
				  link      = event.buildAdminLink( linkto="datamanager.cfflow_workflow_instance.archiveInstanceAction", queryString="id=#recordId#&reference=#instanceRef#" )
				, iconClass = "fa-archive"
				, btnClass  = "btn-danger"
				, title     = translateResource( uri="preside-objects.cfflow_workflow_instance:admin.archiveInstance.title" )
				, message   = translateResource( uri="preside-objects.cfflow_workflow_instance:admin.archiveInstance.message" )
				, prompt    = translateResource( uri="preside-objects.cfflow_workflow_instance:admin.archiveInstance.prompt", data=[ renderContent( "webflowOwner", record.owner ?: "" ) ] )
				, match     = translateResource( uri="preside-objects.cfflow_workflow_instance:admin.archiveInstance.match" )
			} );
		}
	}

	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		event.addAdminBreadCrumb(
			  title = translateResource( uri="preside-objects.webflow_configuration:title" )
			, link  = event.buildAdminLink( objectName="webflow_configuration" )
		);

		if ( Len( Trim( prc.recordId ?: "" ) ) ) {
			var webflowId     = Trim( prc.record.reference     ?: "" );
			var webflowRef    = Trim( prc.record.sub_reference ?: "" );
			var webflow       = webflowLibrary.getWebflow( webflowId );
			var webflowConfig = webflowConfigService.getFlowConfig(
				  webflowId   = webflow.getId()
				, instanceRef = webflow.getSingleton() ? "" : webflowRef
			);

			if ( Len( webflowConfig.id ?: "" ) ) {
				event.addAdminBreadCrumb(
					  title = renderLabel( "webflow_configuration", webflowConfig.id )
					, link  = event.buildAdminLink( objectName="webflow_configuration", recordId=webflowConfig.id )
				);

				if ( webflow.getSingleton() && Len( webflowRef ) ) {
					event.addAdminBreadCrumb(
						  title = renderContent( renderer="webflowInstanceReference", data=webflowRef, args={ webflowId=webflowId, plainText=true } )
						, link  = event.buildAdminLink( objectName="webflow_configuration", recordId=webflowConfig.id, queryString="tab=activeInstances&reference=#webflowRef#" )
					);
				}
			}
		}
	}
}