/**
 * @feature admin and rulesEngine
 */
component extends="preside.system.base.AdminHandler" {

	property name="rulesEngineContextService"    inject="rulesEngineContextService";
	property name="rulesEngineConditionService"  inject="rulesEngineConditionService";
	property name="rulesEngineFieldTypeService"  inject="rulesEngineFieldTypeService";
	property name="rulesEngineFilterService"     inject="rulesEngineFilterService";
	property name="rulesEngineExpressionService" inject="rulesEngineExpressionService";
	property name="dataManagerService"           inject="featureInjector:datamanager:dataManagerService";
	property name="messageBox"                   inject="messagebox@cbmessagebox";
	property name="presideObjectService"         inject="PresideObjectService";
	property name="formsService"                 inject="formsService";
	property name="i18n"                         inject="i18n";

	public string function ajaxRenderField( event, rc, prc ) {
		var fieldConfig = event.getCollectionWithoutSystemVars();
		var fieldValue  = rc.fieldValue ?: "";
		var fieldType   = rc.fieldType  ?: "";

		fieldConfig.delete( "fieldValue" );
		fieldConfig.delete( "fieldType"  );

		return rulesEngineFieldTypeService.renderConfiguredField(
			  fieldType          = fieldType
			, value              = fieldValue
			, fieldConfiguration = fieldConfig
		);
	}

	public string function editFieldModal( event, rc, prc ) {
		var fieldConfig = event.getCollectionWithoutSystemVars();
		var fieldValue  = rc.fieldValue ?: "";
		var fieldType   = rc.fieldType  ?: "";

		fieldConfig.delete( "fieldValue" );
		fieldConfig.delete( "fieldType"  );

		prc.configScreen = rulesEngineFieldTypeService.renderConfigScreen(
			  fieldType          = fieldType
			, currentValue       = fieldValue
			, fieldConfiguration = fieldConfig
		);
		prc.configDescription = rulesEngineFieldTypeService.renderConfigScreenDescription(
			  fieldType          = fieldType
			, currentValue       = fieldValue
			, fieldConfiguration = fieldConfig
		);

		event.setLayout( "adminModalDialog" );
	}

	public void function editFieldModalAction() {
		// TODO: this is the most basic implementation - needs to be more involved here (field types should have ability to validate and process their own submissions)
		event.renderData( type="json", data={
			  success = true
			, value   = ( rc.value ?: "" )
		} );
	}

	public void function getConditionsForAjaxSelectControl() {
		var context                = rc.context ?: "";
		var validContexts          = rulesEngineContextService.listValidExpressionContextsForParentContexts( [ context ] );
		var contextAndObjectFilter = {
			  filter       = "rules_engine_condition.context in ( :rules_engine_condition.context )"
			, filterParams = { "rules_engine_condition.context" = validContexts }
		};

		var validFilterObjects = [];
		for( var validContext in validContexts ) {
			var filterObject = rulesEngineContextService.getContextObject( validContext );
			if ( filterObject.len() ) {
				validFilterObjects.append( filterObject );
			}
		}
		if ( validFilterObjects.len() ) {
			contextAndObjectFilter.filter &= " or rules_engine_condition.filter_object in ( :rules_engine_condition.filter_object )"
			contextAndObjectFilter.filterParams[ "rules_engine_condition.filter_object" ] = validFilterObjects;
		}

		var records = dataManagerService.getRecordsForAjaxSelect(
			  objectName    = "rules_engine_condition"
			, maxRows       = rc.maxRows ?: 1000
			, searchQuery   = rc.q       ?: ""
			, extraFilters  = [ contextAndObjectFilter ]
			, savedFilters  = [ "globalRulesEngineFilters" ]
			, ids           = ListToArray( rc.values ?: "" )
			, labelRenderer = "rules_engine_condition"
		);

		event.renderData( type="json", data=records );
	}

	public void function getFiltersForAjaxSelectControl() {
		var filterObject = rc.filterObject ?: "";
		var extraFilters = [ { filter={ "rules_engine_condition.filter_object" = filterObject } } ];

		if ( isTrue( rc.segmentationFiltersOnly ?: "" ) ) {
			extraFilters[ 1 ].filter.is_segmentation_filter = true;
			if ( Len( Trim( rc.excludeTree ?: "" ) ) ) {
				ArrayAppend( extraFilters, {
					  filterParams = { exclude={ type="cf_sql_varchar", value=rc.excludeTree } }
					, filter       = "
						rules_engine_condition.id != :exclude
						and ( rules_engine_condition.parent_segmentation_filter is null or rules_engine_condition.parent_segmentation_filter != :exclude )
						and ( parent_segmentation_filter.parent_segmentation_filter is null or parent_segmentation_filter.parent_segmentation_filter != :exclude )
						and ( parent_segmentation_filter$parent_segmentation_filter.parent_segmentation_filter is null or parent_segmentation_filter$parent_segmentation_filter.parent_segmentation_filter != :exclude )
						and ( parent_segmentation_filter$parent_segmentation_filter$parent_segmentation_filter.parent_segmentation_filter is null or parent_segmentation_filter$parent_segmentation_filter$parent_segmentation_filter.parent_segmentation_filter != :exclude )"
				} )
			}
		}

		var records       = dataManagerService.getRecordsForAjaxSelect(
			  objectName    = "rules_engine_condition"
			, maxRows       = rc.maxRows ?: 1000
			, searchQuery   = rc.q       ?: ""
			, savedFilters  = [ "globalRulesEngineFilters" ]
			, extraFilters  = extraFilters
			, ids           = ListToArray( rc.values ?: "" )
			, labelRenderer = "rules_engine_condition"
		);

		event.renderData( type="json", data=records );
	}


	public void function getFilterCount( event, rc, prc ) {
		var objectName            = rc.objectName ?: "";
		var preSavedFilters       = ListToArray( rc.preSavedFilters ?: "" );
		var preRulesEngineFilters = ListToArray( rc.preRulesEngineFilters ?: "" );
		var extraFilters          = [];
		var expressionArray       = "";
		var count                 = 0;

		try {
			expressionArray = DeSerializeJson( rc.condition ?: "" );
		} catch ( any e ) {}

		if ( !IsArray( expressionArray ) ) {
			expressionArray = [];
		}

		for( var filterId in preRulesEngineFilters ) {
			extraFilters.append( rulesEngineFilterService.prepareFilter(
				  objectName = objectName
				, filterId   = filterId
			) );
		}

		if ( objectName.len() ) {
			try {
				var count = rulesEngineFilterService.getMatchingRecordCount(
					  objectName      = objectName
					, expressionArray = expressionArray
					, savedFilters    = preSavedFilters
					, extraFilters    = extraFilters
				);
			} catch ( any e ) {}
		}

		event.renderData( data=NumberFormat( count ), type="text" );
	}

	public void function quickAddConditionForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";
		prc.contextData  = {};

		event.include( "/js/admin/specific/rulesEngine/lockingform/" );

		try {
			prc.contextData = DeSerializeJson( rc.contextData ?: "" );
			if ( !IsStruct( prc.contextData ) ) {
				prc.contextData = {};
			}
		} catch( any e ) {}

		event.setView( view="/admin/rulesEngine/quickAddConditionForm", layout="adminModalDialog" );
	}

	public void function quickEditConditionForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";

		prc.record = rulesEngineConditionService.getConditionRecord( rc.id ?: "" );

		event.setView( view="/admin/rulesEngine/quickEditConditionForm", layout="adminModalDialog" );
		event.include( "/js/admin/specific/rulesEngine/lockingform/" )

		prc.formName = "preside-objects.rules_engine_condition.admin.quickedit";

		if ( prc.record.recordCount ) {
			prc.record       = queryRowToStruct( prc.record );
			rc.context       = prc.record.context;
			rc.filter_object = prc.record.filter_object;

			if ( Len( Trim( rc.filter_object ?: "" ) ) ) {
				prc.formName &= ".filter";
			}

			if ( IsTrue( prc.record.is_locked ) ) {
				prc.formName = formsService.getMergedFormName(
					  formName          = prc.formName
					, mergeWithFormName = prc.formName & ".locked"
				);
			}
		} else {
			prc.record = {};
		}
	}

	public void function quickAddConditionAction( event, rc, prc ) {
		var object   = "rules_engine_condition";
		var formName = "preside-objects.#object#.admin.quickadd";
		var formData = event.getCollectionForForm( formName );

		_checkPermissions( argumentCollection=arguments, key="add" );

		if ( !_conditionToFilterCheck( argumentCollection=arguments, action="quickadd", formData=formData, ajax=true ) ) {
			if ( ( rc.convertAction ?: "" ) == "filter" && ( rc.filter_object ?: "" ).len() ) {
				rc.context = "";

				formName = "preside-objects.#object#.admin.quickadd.filter";
			} else {
				rc.filter_object = "";
			}
			runEvent(
				  event          = "admin.DataManager._quickAddRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object         = "rules_engine_condition"
					, formName       = formName
				  }
			);
		}
	}

	public void function quickEditConditionAction( event, rc, prc ) {
		var object      = "rules_engine_condition";
		var conditionId = rc.id ?: "";
		var record      = rulesEngineConditionService.getConditionRecord( conditionId );
		var formName    = "preside-objects.#object#.admin.quickedit";

		_checkPermissions( argumentCollection=arguments, key="edit" );
		if ( !record.recordCount ) {
			event.notFound();
		}

		if ( Len( Trim( record.filter_object ?: "" ) ) ) {
			formName &= ".filter";
		}

		if ( IsTrue( record.is_locked ) ) {
			formName = formsService.getMergedFormName(
				  formName          = formName
				, mergeWithFormName = formName & ".locked"
			);
		}
		var formData = event.getCollectionForForm( formName );

		if ( Len( Trim( record.filter_object ) ) || !_conditionToFilterCheck( argumentCollection=arguments, action="quickedit", formData=formData, ajax=true ) ) {
			if ( Len( Trim( record.filter_object ) ) || ( rc.convertAction ?: "" ) == "filter" && ( rc.filter_object ?: "" ).len() ) {
				rc.context = "";

				formName = "preside-objects.#object#.admin.quickedit.filter";
			} else {
				rc.filter_object = "";
			}

			runEvent(
				  event          = "admin.DataManager._quickEditRecordAction"
				, prePostExempt  = true
				, private        = true
				, eventArguments = {
					  object   = "rules_engine_condition"
					, formName = formName
				  }
			);
		}
	}


	public void function quickAddFilterForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";
		prc.contextData  = {};

		try {
			prc.contextData = DeSerializeJson( rc.contextData ?: "" );
			if ( !IsStruct( prc.contextData ) ) {
				prc.contextData = {};
			}
		} catch( any e ) {}

		event.include( "/js/admin/specific/datamanager/quickAddForm/" )
		     .include( "/js/admin/specific/rulesEngine/lockingform/" )
		     .include( "/js/admin/specific/saveFilterForm/" );

		event.setView( view="/admin/rulesEngine/quickAddFilterForm", layout="adminModalDialog" );
	}

	public void function quickEditFilterForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";
		event.include( "/js/admin/specific/datamanager/quickEditForm/" )
		     .include( "/js/admin/specific/rulesEngine/lockingform/" )
		     .include( "/js/admin/specific/saveFilterForm/" );

		prc.contextData  = {};

		try {
			prc.contextData = DeSerializeJson( rc.contextData ?: "" );
			if ( !IsStruct( prc.contextData ) ) {
				prc.contextData = {};
			}
		} catch( any e ) {}

		prc.record = rulesEngineConditionService.getConditionRecord( rc.id ?: "" );
		if ( prc.record.recordCount ) {
			prc.record = queryRowToStruct( prc.record );
		} else {
			prc.record = {};
		}

		if ( isEmptyString( rc.filter_object ?: "" ) ) {
			rc.filter_object = prc.record.filter_object ?: "";
		}

		prc.formName = "preside-objects.rules_engine_condition.admin.quickedit.filter";
		if ( IsTrue( prc.record.is_locked ?: "" ) ) {
			prc.formName = formsService.getMergedFormName(
				  formName          = prc.formName
				, mergeWithFormName = prc.formName & ".locked"
			)
		}

		event.setView( view="/admin/rulesEngine/quickEditFilterForm", layout="adminModalDialog" );
	}

	public void function superQuickAddFilterForm( event, rc, prc ) {
		prc.modalClasses = "modal-dialog-less-padding";
		event.include( "/js/admin/specific/datamanager/quickAddForm/" )
		     .include( "/js/admin/specific/saveFilterForm/" )
		     .include( "/js/admin/specific/rulesEngine/lockingform/" );
		event.setView( view="/admin/rulesEngine/superQuickAddFilterForm", layout="adminModalDialog" );
	}

	public void function quickAddFilterAction( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._quickAddRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object         = "rules_engine_condition"
				, formName       = "preside-objects.rules_engine_condition.admin.quickadd.filter"
			  }
		);
	}

	public void function quickEditFilterAction( event, rc, prc ) {
		var conditionId = rc.id ?: "";
		var record      = rulesEngineConditionService.getConditionRecord( conditionId );
		var formName    = "preside-objects.rules_engine_condition.admin.quickedit.filter";

		if ( IsTrue( record.is_locked ?: "" ) ) {
			formName = formsService.getMergedFormName(
				  formName          = formName
				, mergeWithFormName = formName & ".locked"
			)
		}

		runEvent(
			  event          = "admin.DataManager._quickEditRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object         = "rules_engine_condition"
				, formName       = formName
			  }
		);
	}

	public void function superQuickAddFilterAction( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._quickAddRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object         = "rules_engine_condition"
				, formName       = "preside-objects.rules_engine_condition.admin.superquickaddfilter"
			  }
		);
	}

	public void function ajaxDataGridFavourites( event, rc, prc ) {
		event.renderData( type="html", data=renderViewlet( event="admin.rulesengine.dataGridFavourites", args={
			objectName = rc.objectName ?: ""
		} ) );
	}

	public void function cloneCondition( event, rc, prc, args={} ) {
		_checkPermissions( argumentCollection=arguments, key="clone" );

		var id = rc.id ?: "";
		event.initializeDatamanagerPage( "rules_engine_condition", id );

		if ( !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:rulesEngine.condition.not.found.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="rulesEngine" ) );
		}
		prc.record       = queryRowToStruct( prc.record );
		rc.context       = prc.record.context;
		rc.filter_object = prc.record.filter_object;

		prc.formName = "preside-objects.rules_engine_condition.admin.clone";

		if ( Len( Trim( rc.filter_object ) ) ) {
			if ( IsTrue( prc.record.is_segmentation_filter ) ) {
				prc.formName &= ".segmentation.filter";
				prc.pageTitle    = translateResource( uri="cms:rulesEngine.clone.segmentation.filter.page.title", data=[ prc.record.condition_name ] );
				prc.pageSubTitle = translateResource( uri="cms:rulesEngine.clone.segmentation.filter.page.subtitle", data=[ prc.record.condition_name ] );
				event.addAdminBreadCrumb(
					  title = translateResource( uri="cms:rulesEngine.clone.segmentation.filter.breadcrumb.title", data=[ prc.record.condition_name ] )
					, link  = event.buildAdminLink( linkTo="rulesengine.cloneCondition", queryString="id=" & id )
				);

				prc.additionalArgs = {
					fields = {
						parent_segmentation_filter = {
						  	  filterObject            = prc.record.filter_object
						  	, segmentationFiltersOnly = true
						  	, excludeTree             = prc.recordId
						}
					}
				};
			} else {
				prc.formName &= ".filter";
				prc.pageTitle    = translateResource( uri="cms:rulesEngine.clone.filter.page.title", data=[ prc.record.condition_name ] );
				prc.pageSubTitle = translateResource( uri="cms:rulesEngine.clone.filter.page.subtitle", data=[ prc.record.condition_name ] );
				event.addAdminBreadCrumb(
					  title = translateResource( uri="cms:rulesEngine.clone.filter.breadcrumb.title", data=[ prc.record.condition_name ] )
					, link  = event.buildAdminLink( linkTo="rulesengine.cloneCondition", queryString="id=" & id )
				);
			}

		} else {
			prc.pageTitle    = translateResource( uri="cms:rulesEngine.clone.condition.page.title", data=[ prc.record.condition_name ] );
			prc.pageSubTitle = translateResource( uri="cms:rulesEngine.clone.condition.page.subtitle", data=[ prc.record.condition_name ] );
			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:rulesEngine.clone.condition.breadcrumb.title", data=[ prc.record.condition_name ] )
				, link  = event.buildAdminLink( linkTo="rulesengine.cloneCondition", queryString="id=" & id )
			);
		}
	}

	public void function cloneConditionAction( event, rc, prc ) {
		_checkPermissions( argumentCollection=arguments, key="clone" );

		var conditionId = rc.id ?: "";

		event.initializeDatamanagerPage( "rules_engine_condition", conditionId );

		var object   = "rules_engine_condition";
		var formName = "preside-objects.rules_engine_condition.admin.clone";

		if ( Len( prc.record.filter_object ) ) {
			if ( isTrue( prc.record.is_segmentation_filter ) ) {
				formName &= ".segmentation.filter";
			} else {
				formName &= ".filter";
			}
		}

		if ( Len( Trim( rc.context ?: "" ) ) ) {
			rc.filter_object = "";
		}

		runEvent(
			  event          = "admin.DataManager.cloneRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object        = object
				, errorUrl      = event.buildAdminLink( linkTo="rulesEngine.cloneCondition", queryString="id=" & conditionId )
				, formName      = formName
				, audit         = true
				, auditType     = "rulesEngine"
				, auditAction   = "clone_rules_engine_condition"
			}
		);
	}

	private boolean function cloneChildrenInBgThread( event, rc, prc, args={}, logger, progress ) {
		rulesEngineFilterService.cloneFilterChildren(
			  sourceId = ( args.oldId ?: "" )
			, targetId = ( args.newId ?: "" )
			, logger   = arguments.logger   ?: NullValue()
			, progress = arguments.progress ?: NullValue()
		);

		rulesEngineFilterService.recalculateSegmentationFilterData(
			  filterId            = args.newId ?: ""
			, recalculateChildren = true
			, logger              = arguments.logger ?: NullValue()
		);

		return true;
	}

	public void function downloadFilterExpressions( event, rc, prc ) {
		var objectName    = prc.filterObject ?: "";
		var excludeTags   = rc.excludeTags ?: "";
		var localFilePath = rulesEngineExpressionService.getExpressionsFile( filterObject=objectName, excludeTags=excludeTags );
		var etag          = _getEtag( localFilePath );
		_doBrowserEtagLookup( etag );
		header name="cache-control" value="max-age=31536000";
		header name="ETag" value=etag;
		content file=localFilePath type="application/json";abort;
	}

	public void function downloadConditionExpressions( event, rc, prc ) {
		var ruleContext   = prc.ruleContext ?: "";
		var excludeTags   = rc.excludeTags ?: "";
		var localFilePath = rulesEngineExpressionService.getExpressionsFile( context=ruleContext, excludeTags=excludeTags );
		var etag          = _getEtag( localFilePath );
		_doBrowserEtagLookup( etag );
		header name="cache-control" value="max-age=31536000";
		header name="ETag" value=etag;
		content file=localFilePath type="application/json";abort;
	}


// VIWLETS
	private string function dataGridFavourites( event, rc, prc, args ) {
		var objectName = args.objectName ?: "";

		if ( rulesEngineFilterService.objectSupportsSegmentationFilters( objectName ) ) {
			args.segmentationFilters =  rulesEngineFilterService.getSegmentationFiltersForFavourites( objectName );
		} else {
			args.segmentationFilters = [];
		}
		args.favourites          = rulesEngineFilterService.getFavourites( objectName );
		args.nonFavouriteFilters = rulesEngineFilterService.getNonFavouriteFilters( objectName );
		args.noSavedFilters      = ( args.nonFavouriteFilters.recordCount + args.favourites.recordCount + ArrayLen( args.segmentationFilters ) ) == 0;

		if ( args.noSavedFilters ) {
			args.canManageFilters = runEvent(
				  event         = "admin.datamanager._checkPermission"
				, private       = true
				, prePostExempt = true
				, eventArguments = {
					  key          = "managefilters"
					, object       = objectName
					, throwOnError = false
				}
			)
		}

		return renderView( view="/admin/rulesEngine/_dataGridFavourites", args=args );
	}


// PRIVATE HELPERS
	private void function _checkPermissions( event, rc, prc, required string key ) {
		var permKey = "rulesEngine." & arguments.key;

		if ( !hasCmsPermission( permissionKey=permKey ) ) {
			event.adminAccessDenied();
		}

		if ( arrayFindNoCase( [ "edit","delete" ], key ) && Len( rc.id ?: "" ) ) {
			var args = { objectName="rules_engine_condition"
				, recordCountOnly = true
				, selectFields    = [ "rules_engine_condition.id" ]
			};

			rulesEngineFilterService.getRulesEngineSelectArgsForEdit( args=args, rulesEngineId=rc.id );

			if ( !presideObjectService.selectData( argumentCollection=args ) ) {
				event.adminAccessDenied();
			}

			_checkRuleScope( rc, prc, key );
		}
	}

	private boolean function _conditionToFilterCheck( event, rc, prc, required string action, required struct formData, boolean ajax=false ) {
		if( Len( Trim( rc.convertAction ?: "" ) ) || Len( Trim( rc.filter_object ?: "" ) ) ) {
			return false;
		}

		try {
			var expressionArray = DeSerializeJson( formData.expressions ?: "" );
		} catch( any e ){
			return false;
		}

		if ( !isArray( expressionArray ) ) {
			return false;
		}
		var objectsFilterable = rulesEngineConditionService.listObjectsFilterableByCondition( expressionArray );

		if ( objectsFilterable.len() == 1 ) {
			if ( arguments.ajax ) {
				var objectName      = renderContent( "objectName", objectsFilterable[ 1 ] );
				var response = { success=false, convertPrompt=renderView( view="/admin/datamanager/rules_engine_condition/convertConditionToFilter", args={
					  id                = rc.id ?: ""
					, formData          = arguments.formData
					, objectsFilterable = objectsFilterable
					, saveAction        = arguments.action
					, submitAction      = event.buildAdminLink( linkto="rulesEngine.#arguments.action#ConditionAction" )
					, pageDescription   = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.intro.single.object", data=[ objectName ] )
				} ) };

				event.renderData( data=response, type="json" );

				return true;
			} else {
				var persist = {
					  formData          = arguments.formData
					, objectsFilterable = objectsFilterable
					, saveAction        = arguments.action
					, id                = rc.id ?: ""
				}
				setNextEvent( url=event.buildAdminLink( linkto="rulesEngine.convertConditionToFilter" ), persistStruct=persist );
			}
		}

		return false;
	}

	private void function _checkRuleScope( rc, prc, required string key ) {
		if ( key == 'edit' ) {
			var rulesGroup = presideObjectService.selectData( objectName="rules_engine_condition", id=rc.id, selectFields=[ "user_groups.id as group_id", "owner" ], forcejoins="left" );

			if ( rulesGroup.recordCount ) {
				prc.filterScope = Len( rulesGroup.group_id ) && Len( rulesGroup.owner ) ? "group" : ( Len( rulesGroup.owner ) ? "individual" : "global" );
			}
		}
	}

	private string function _getEtag( required string fullPath ) {
		return Left( LCase( Hash( SerializeJson( GetFileInfo( arguments.fullPath ) ) ) ), 8 );
	}

	private string function _doBrowserEtagLookup( required string etag ) {
		var headers = getHTTPRequestData( false ).headers;
		if ( ( headers[ "If-None-Match" ] ?: "" ) == arguments.etag ) {
			content reset=true;header statuscode=304 statustext="Not Modified";abort;
		}
	}
}