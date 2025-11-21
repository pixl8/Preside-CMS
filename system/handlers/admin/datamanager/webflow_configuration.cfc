/**
 * @feature webflow
 */
component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="webflowConfigurationService" inject="webflowConfigurationService";
	property name="webflowPlantUmlUtil"         inject="webflowPlantUmlUtil";
	property name="formsService"                inject="formsService";
	property name="dtHelper"                    inject="jQueryDatatablesHelpers";
	property name="flowDao"                     inject="preside:object:webflow_configuration";
	property name="stepDao"                     inject="preside:object:webflow_configuration_step";

	variables.permissionBase    = "webflows";
	variables.sidebarNavigation = true;
	variables.tabs              = [ "activeInstances", "archivedInstances", "steps" ];
	variables.infoCol3          = [];
	variables.infoCardStyle     = "definitionList";

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		event.setValue( name="pageFullWidth", value=true, private=true );
	}

// PUBLIC HANDLERS
	function flowsvg() {
		var webflowId = rc.webflowId ?: "";
		var collapse  = IsTrue( rc.collapse ?: true );

		content reset=true type="image/svg+xml";
		echo( webflowPlantUmlUtil.webflowToSvgDiagram( webflowId, collapse ) );
		abort;
	}

	public void function getInstancesGroupListingForAjaxDataTables( event, rc, prc, args={} ) {
		var instObjName     = Trim( rc.instanceObject ?: "" );
		var recordId        = Trim( rc.id             ?: "" );
		var webflowId       = Trim( rc.webflowId      ?: "" );
		var activeTab       = Trim( rc.tab            ?: "" );
		var listingQuery    = QueryNew( "" );
		var listingStartRow = dtHelper.getStartRow();
		var listingMaxRow   = dtHelper.getMaxRows();

		if ( Len( instObjName ) && Len( webflowId ) ) {
			var refGroupingConfig = webflowConfigurationService.getInstanceRefGroupingConfig(
				  webflowId    = webflowId
				, sourceObject = instObjName
			);

			if ( IsQuery( refGroupingConfig.groupedRefs ?: "" ) ) {
				var optionsCol   = [];
				    listingQuery = Duplicate( refGroupingConfig.groupedRefs );

				for ( var row in listingQuery ) {
					ArrayAppend( optionsCol, '<a href="#event.buildAdminLink(
						  objectName  = "webflow_configuration"
						, recordId    = recordId
						, querystring = "tab=#activeTab#&reference=#row.reference_id#"
					)#" class="card-body-link"><i class="fa fa-fw fa-eye"></i></a>' );

					QuerySetCell(
						  listingQuery
						, "reference_id"
						, renderContent( renderer="webflowInstanceReference", data=row.reference_id, args={ webflowId=webflowId, plainText=true } )
						, QueryCurrentRow( listingQuery )
					);
				}

				QueryAddColumn( listingQuery, "_options" , optionsCol );
			}
		}

		var listingTotalCount = Val( listingQuery.recordcount );
		var listingEndRow     = listingStartRow + listingMaxRow;

		event.renderData( type="json", data=dtHelper.queryToResult(
			  qry          = QuerySlice( listingQuery, listingStartRow, ( listingEndRow > listingTotalCount ) ? NullValue() : listingMaxRow )
			, columns      = QueryColumnArray( listingQuery )
			, totalRecords = listingTotalCount
		) );
	}

// INFOR CARDs
	private string function _infoCardInstanceRef( event, rc, prc, args={} ) {
		var webflowId = Trim( prc.record.webflow_id ?: "" );
		var reference = Trim( rc.reference          ?: "" );

		if ( Len( webflowId ) && Len( reference ) ) {
			return renderContent( renderer="webflowInstanceReference", data=reference, args={ webflowId=webflowId } );
		}
		return "";
	}

// PRIVATE HELPERs
	private string function _checkInstanceSingletonRedirect( event, rc, prc, args={} ) {
		var reference   = Trim( rc.reference            ?: "" );
		var instObjName = Trim( args.instanceObjectName ?: "" );
		var webflowId   = Trim( prc.record.webflow_id   ?: "" );

		if ( instObjName == "cfflow_workflow_instance" ) {
			args.col1      = [ "active_instances_count", "timedout_instances_count", "step_count" ];
			args.col2      = [ "instanceRef", "progressbar_layout", "timeout_in_minutes" ];
			args.col3      = [ "created", "modified" ];
			args.infoCards = _infoCard( argumentCollection=arguments );
		}

		if ( isEmptyString( reference ) && Len( instObjName ) && Len( webflowId ) ) {
			args.refGroupingConfig = webflowConfigurationService.getInstanceRefGroupingConfig( webflowId=webflowId, sourceObject=instObjName );

			if ( IsQuery( args.refGroupingConfig.groupedRefs ?: "" ) && args.refGroupingConfig.groupedRefs.recordcount ) {
				return renderView( view="/admin/datamanager/webflow_configuration/_instancesGroup", args=args );
			}
		}

		if ( Len( reference ) ) {
			var renderedReference = renderContent( renderer="webflowInstanceReference", data=reference, args={ webflowId=webflowId, plainText=true } );

			event.addAdminBreadCrumb( title=renderedReference, link="" );

			prc.pageTitle = translateResource(
				  uri  = "preside-objects.webflow_configuration:pageTitle.with.instRef"
				, data = [ prc.pageTitle, renderedReference ]
			);
		}

		return renderView( view="/admin/datamanager/webflow_configuration/_instancesTab", args=args );
	}

// BETTER VIEW RECORD CUSTOMIZATIONS
	private string function renderSidebarHeader( event, rc, prc, args={} ) {
		var sidebarCurrentTab = Trim( rc.tab ?: "" );
		var referenceId       = Trim( rc.reference ?: "" );

		if ( sidebarCurrentTab == "activeInstances" && Len( referenceId ) ) {
			prc.adminSidebarItems = prc.adminSidebarItems ?: [];

			var activeInstancesTitle = translateResource( uri="preside-objects.webflow_configuration:viewtab.activeInstances.title" )
			var activeInstancesItem  = ArrayFilter( prc.adminSidebarItems, function( _item ) {
				return ( _item.title ?: "" ) == activeInstancesTitle;
			} );

			activeInstancesItem = ArrayLen( activeInstancesItem ) ? ArrayFirst( activeInstancesItem ) : {};

			if ( !StructIsEmpty( activeInstancesItem ) ) {
				activeInstancesItem.submenuItems = activeInstancesItem.submenuItems ?: [];

				var recordId        = Trim( prc.record.id         ?: "" );
				var webflowId       = Trim( prc.record.webflow_id ?: "" );
				var refGrouping     = webflowConfigurationService.getInstanceRefGroupingConfig( webflowId=webflowId, sourceObject="cfflow_workflow_instance" );
				var refGroupingRefs = refGrouping.groupedRefs ?: QueryNew( "" );

				if ( refGroupingRefs.recordcount ) {
					activeInstancesItem.open = isEmptyString( sidebarCurrentTab ) || ( sidebarCurrentTab == "activeInstances" );

					for ( var groupRef in refGroupingRefs ) {
						var refId = Trim( groupRef.reference_id ?: "" );

						if ( Len( refId ) ) {
							var refLabel = renderContent( renderer="webflowInstanceReference", data=refId, args={ webflowId=webflowId, plainText=true, shortTitle=true } );

							if ( Len( refLabel ) ) {
								ArrayAppend( activeInstancesItem.submenuItems, {
									  title  = refLabel
									, link   = event.buildAdminLink( objectName="webflow_configuration", recordId=recordId, querystring="tab=activeInstances&reference=#refId#" )
									, active = ( ( args.instanceObjectName ?: "" ) == "cfflow_workflow_instance" ) && ( referenceId == refId )
								} );
							}
						}
					}
				}
			}
		}

		return renderView( view="/admin/datamanager/webflow_configuration/_sidebarHeader", args=args );
	}

	private string function _activeInstancesTab( event, rc, prc, args={} ) {
		args.instanceObjectName = "cfflow_workflow_instance";
		args.gridFields         = args.gridFields ?: [ "owner", "current_status", "current_step", "datecreated", "datemodified" ];

		prc.pageTitle = translateResource( uri="preside-objects.webflow_configuration:pageTitle.activeInstances" );

		return _checkInstanceSingletonRedirect( argumentCollection=arguments );
	}

	private string function _archivedInstancesTab( event, rc, prc, args={} ) {
		args.instanceObjectName = "cfflow_workflow_archived_instance";
		args.gridFields         = args.gridFields     ?: [ "owner", "archive_reason", "time_taken", "date_started", "date_archived" ];
		args.groupingLayout     = args.groupingLayout ?: "listing";

		prc.pageTitle = translateResource( uri="preside-objects.webflow_configuration:pageTitle.archivedInstances" );

		return _checkInstanceSingletonRedirect( argumentCollection=arguments );
	}

	private string function _stepsTab( event, rc, prc, args={} ) {
		args.svgLink = event.buildAdminLink( linkto='datamanager.webflow_configuration.flowsvg', queryString='webflowId=#prc.record.webflow_id#' );
		args.fullSvgLink = event.buildAdminLink( linkto='datamanager.webflow_configuration.flowsvg', queryString='webflowId=#prc.record.webflow_id#&collapse=false' );
		args.stepstable = objectDataTable( objectName="webflow_configuration_step", args={
			  allowSearch     = false
			, allowFilter     = false
			, useMultiActions = false
			, compact         = true
		} );

		return renderView( view="/admin/datamanager/webflow_configuration/_stepsTab", args=args )
	}

// DATAMANAGER CUSTOMIZATIONS
	private string function listingViewlet( event, rc, prc, args={} ) {
		var webflowConfigCount = flowDao.selectData( recordCountOnly=true, savedFilters=[ "webflowsNonAdminFlows" ] );
		var globalStepCount    = stepDao.selectData( recordCountOnly=true, filter={ webflow="" } );

		event.include( "/css/admin/specific/datamanager/viewTabs/" );

		args.tabs = [ {
			  id        = "flows"
			, iconClass = translateResource( "preside-objects.webflow_configuration:iconClass" ) & " blue"
			, title     = translateResource( "preside-objects.webflow_configuration:title" ) & " <span class=""badge"">#NumberFormat( webflowConfigCount )#</span>"
			, content   = renderViewlet( event="admin.datamanager._objectListingViewlet", args={ objectName="webflow_configuration" } )
		} ];

		if ( globalStepCount ) {
			args.tabs.append({
				  id        = "steps"
				, iconClass = translateResource( "preside-objects.webflow_configuration_step:iconClass" ) & " orange"
				, title     = translateResource( "preside-objects.webflow_configuration:viewtab.globalsteps.title" ) & " <span class=""badge"">#NumberFormat( globalStepCount )#</span>"
				, content   = objectDataTable( objectName="webflow_configuration_step", args={ gridFields=[ "step_id", "title", "short_title", "intro", "datemodified" ], multiActions=false } )
			} );
		}

		return renderView( view="/admin/datamanager/_tabs", args=args );
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.savedFilters = args.savedFilters ?: [];
		ArrayAppend( args.savedFilters, "webflowsNonAdminFlows" );
	}

	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var flowId            = prc.record.webflow_id ?: "";
		var mainForm          = "preside-objects.webflow_configuration";
		var subflowConfigForm = webflowConfigurationService.getSubflowConfigForms( flowId );
		var configForm        = webflowConfigurationService.getFlowConfigForm( flowId );

		for ( var subflowForm in subflowConfigForm ) {
			mainForm = formsService.getMergedFormName( mainForm, subflowForm );
		}

		if ( Len( Trim( configForm ) ) ) {
			return formsService.getMergedFormName( mainForm, configForm );
		}

		return mainForm;
	}

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		try {
			StructAppend( prc.record, DeSerializeJson( prc.record.config ), false );
		} catch( any e ) {}
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		var flowId            = prc.record.webflow_id ?: "";
		var subflowConfigForm = webflowConfigurationService.getSubflowConfigForms( flowId );
		var configForm        = webflowConfigurationService.getFlowConfigForm( flowId );
		var configStruct      = {};

		for ( var subflowForm in subflowConfigForm ) {
			configStruct.append( event.getCollectionForForm( subflowForm ) );
		}

		if ( Len( Trim( configForm ) ) ) {
			args.formData = args.formData ?: {};
			configStruct.append( event.getCollectionForForm( configForm ) );
		}

		args.formData.config = serializeJSON( configStruct );
	}
}