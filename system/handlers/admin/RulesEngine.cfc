component extends="preside.system.base.AdminHandler" {

	property name="rulesEngineContextService"   inject="rulesEngineContextService";
	property name="rulesEngineConditionService" inject="rulesEngineConditionService";
	property name="rulesEngineFieldTypeService" inject="rulesEngineFieldTypeService";
	property name="rulesEngineFilterService"    inject="rulesEngineFilterService";
	property name="dataManagerService"          inject="dataManagerService";
	property name="messageBox"                  inject="messagebox@cbmessagebox";
	property name="presideObjectService"        inject="PresideObjectService";
	property name="formsService"                inject="formsService";

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
		var filterObject  = rc.filterObject ?: "";
		var records       = dataManagerService.getRecordsForAjaxSelect(
			  objectName    = "rules_engine_condition"
			, maxRows       = rc.maxRows ?: 1000
			, searchQuery   = rc.q       ?: ""
			, savedFilters  = [ "globalRulesEngineFilters" ]
			, extraFilters  = [ { filter={ "rules_engine_condition.filter_object" = filterObject } } ]
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

// VIWLETS
	private string function dataGridFavourites( event, rc, prc, args ) {
		var objectName = args.objectName ?: "";

		args.favourites          = rulesEngineFilterService.getFavourites( objectName );
		args.nonFavouriteFilters = rulesEngineFilterService.getNonFavouriteFilters( objectName );
		args.noSavedFilters      = ( args.nonFavouriteFilters.recordCount + args.favourites.recordCount ) == 0;

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
			var rulesGroup = presideObjectService.selectData( objectName="rules_engine_condition", id=rc.id, selectFields=[ "security_group.id as group_id", "owner" ], forcejoins="left" );

			if ( rulesGroup.recordCount ) {
				prc.filterScope = Len( rulesGroup.group_id ) && Len( rulesGroup.owner ) ? "group" : ( Len( rulesGroup.owner ) ? "individual" : "global" );
			}
		}
	}
}