component extends="preside.system.base.AdminHandler" {

	property name="rulesEngineFilterService"    inject="RulesEngineFilterService";
	property name="rulesEngineContextService"   inject="rulesEngineContextService";
	property name="rulesEngineConditionService" inject="rulesEngineConditionService";
	property name="customizationService"        inject="dataManagerCustomizationService";
	property name="datamanagerService"          inject="datamanagerService";
	property name="formsService"                inject="formsService";
	property name="messageBox"                  inject="messagebox@cbmessagebox";

// PUBLIC ACTIONS
	public void function unlockAction( event, rc, prc ) {
		var recordId = rc.id ?: "";

		if ( !Len( recordId ) ) {
			event.notFound();
		}
		event.initializeDatamanagerPage( objectName="rules_engine_condition", recordId=recordId );

		if ( !hasCmsPermission( "rulesEngine.unlock" ) ) {
			event.adminAccessDenied();
		}

		rulesEngineConditionService.unlockCondition( recordId );
		messageBox.info( translateResource( "preside-objects.rules_engine_condition:condition.unlocked" ) );

		var auditDetail = QueryRowToStruct( prc.record );
		auditDetail.append( { objectName="rules_engine_condition" } );

		event.audit(
			  action   = "datamanager_unlock_record"
			, type     = "datamanager"
			, recordId = recordId
			, detail   = auditDetail
		);

		setNextEvent( url=event.buildAdminLink( objectName="rules_engine_condition", recordId=recordId, operation="editRecord" ) );
	}

// PERMISSIONS
	private boolean function checkPermission( event, rc, prc, args={} ) {
		var objectName = "rules_engine_condition";

		if ( Len( Trim( rc.filterobject ?: "" ) ) ) {
			_checkProxyPermissionForObjectFilters( argumentCollection=arguments );
		}

		var allowedOps       = datamanagerService.getAllowedOperationsForObject( objectName );
		var permissionBase   = "rulesengine"
		var alwaysDisallowed = [ "manageContextPerms" ];
		var operationMapped  = [ "add", "edit", "delete", "clone" ];
		var permissionKey    = "#permissionBase#.#args.key#"
		var hasPermission    = !alwaysDisallowed.find( args.key )
		                    && ( !operationMapped.find( args.key ) || allowedOps.find( args.key ) )
		                    && hasCmsPermission( permissionKey );

		if ( !hasPermission && IsTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

	private boolean function _checkProxyPermissionForObjectFilters( event, rc, prc, args={} ) {
		var objectName = Trim( rc.filterobject );

		return runEvent( event="admin.datamanager._checkPermission", private=true, prepostExempt=true, eventArguments={
			  key             = "manageFilters"
			, object          = ( rc.filterobject ?: "" )
			, throwOnError    = IsTrue( args.throwOnError ?: "" )
			, checkOperations = false
		} );
	}


// LISTING
	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		if ( event.isDataManagerRequest() && event.getCurrentAction() == "manageFilters" ) {
			return "filterobject=" & ( prc.objectName ?: "" );
		}

		return "";
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters ?: [];

		rulesEngineFilterService.getRulesEngineSelectArgsForEdit( args=args );

		var filterObject = rc.filterObject ?: "";
		if ( Len( filterObject ) ) {
			ArrayAppend( args.extraFilters, { filter = {
				filter_object = filterObject
			} } );
		}
	}

	private array function getRecordActionsForGridListing( event, rc, prc, args={} ) {
		var record          = args.record ?: {};
		var recordId        = record.id   ?: "";
		var kind            = record.kind ?: "";
		var filterObject    = rc.filterObject ?: "";
		var operationSource = Len( filterObject ) ? "manageObjectFilters" : "rulesEngineManager";
		var actions         = [];
		var canEdit         = true;
		var canDelete       = true;

		if ( kind == "filter" ) {
			canEdit = canDelete = runEvent(
				  event = "admin.datamanager._checkPermission"
				, private = true
				, prepostExempt = true
				, eventArguments = {
					  key          = "manageFilters"
					, object       = record.filter_object ?: ""
					, throwOnError = false
				  }
			);

			canDelete = canDelete && !rulesEngineFilterService.filterIsUsed( recordId );
		} else {
			canEdit   = hasCmsPermission( "rulesengine.edit" );
			canDelete = hasCmsPermission( "rulesengine.delete" );
		}

		if ( canEdit ) {
			ArrayAppend( actions, {
				  link       = event.buildAdminLink( objectName="rules_engine_condition", recordId=recordId, operation="editRecord", operationSource=operationSource )
				, icon       = "fa-pencil"
				, contextKey = "e"
			} );
		}

		if ( canDelete ) {
			ArrayAppend( actions, {
				  link       = event.buildAdminLink( objectName="rules_engine_condition", recordId=recordId, operation="deleteRecordAction", operationSource=operationSource )
				, icon       = "fa-trash-o"
				, contextKey = "d"
				, class      = "confirmation-prompt"
				, title      = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ translateResource( "preside-objects.rules_engine_condition:title.singular" ), record.condition_name ] )
			} );
		} else {
			ArrayAppend( actions, {
				  link = "##"
				, icon = "fa-trash-o light-grey disabled"
			} );
		}

		return actions;
	}

	private array function getTopRightButtonsForObject( event, rc, prc, args={} ) {
		var actions = [];

		event.include( "/css/admin/specific/rulesengine/index/" );

		if ( IsTrue( prc.canAdd ?: "" ) ) {
			var contexts = rulesEngineContextService.listContexts();

			if ( ArrayLen( contexts ) ) {
				var children = [];

				for( var context in contexts ) {
					ArrayAppend( children, {
						  link  = event.buildAdminLink( objectName="rules_engine_condition", operation="addRecord", queryString='context=' & context.id )
						, title = '<p class="title"><i class="fa fa-fw #context.iconClass#"></i>&nbsp; #context.title#</p> <p class="description"><em class="light-grey">#context.description#</em></p>'
					} );
				}

				ArrayAppend( actions, {
					  title     = translateResource( 'cms:rulesEngine.add.condition.btn' )
					, btnClass  = "btn-success"
					, iconClass = "fa-plus"
					, children  = children
				} );
			}
		}

		return actions;
	}

// BREADCRUMBS, and navigation
	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		var operationSource = event.getAdminOperationSource();
		var filterObject    = Trim( rc.filterObject ?: "" );

		if ( operationSource == "manageObjectFilters" && Len( filterObject ) ) {
			customizationService.runCustomization(
				  objectName     = filterObject
				, action         = "objectBreadcrumb"
				, defaultHandler = "admin.datamanager._objectBreadcrumb"
				, args           = {
					  objectName  = filterObject
					, objectTitle = translateResource( "preside-objects.#filterObject#:title" )
				}
			);

			event.addAdminBreadCrumb(
				  title = translateResource( uri="cms:datamanager.managefilters.breadcrumb.title" )
				, link  = event.buildAdminLink( objectName=filterObject, operation="managefilters" )
			);
		} else {
			event.addAdminBreadCrumb(
				  title = prc.objectTitlePlural
				, link  = event.buildAdminLink( objectName="rules_engine_condition" )
			);
		}
	}

	private string function buildListingLink( event, rc, prc, args={} ) {
		var operationSource = event.getAdminOperationSource();
		var filterObject    = Trim( rc.filterObject ?: "" );

		if ( operationSource == "manageObjectFilters" && Len( filterObject ) ) {
			return event.buildAdminLink( objectName=filterObject, operation="manageFilters" );
		}

		return event.buildAdminLink(
			  linkto      = "datamanager.object"
			, queryString = _queryString( "id=rules_engine_condition", args )
		);
	}

	private string function buildAddRecordLink( event, rc, prc, args={} ) {
		var qs = "object=rules_engine_condition";
		if ( Len( Trim( rc.context ?: "" ) ) ) {
			qs &= "&context=#rc.context#";
		}

		return event.buildAdminLink(
			  linkto      = "datamanager.addRecord"
			, queryString = _queryString( qs, args )
		);
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		var filterObject = Trim( rc.filterObject ?: "" );

		args.queryString = ListAppend( args.queryString ?: "", "filterObject=#filterObject#", "&" );

		return runEvent(
			  event          = "admin.objectLinks.buildEditRecordLink"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);
	}


	private string function buildEditRecordActionLink( event, rc, prc, args={} ) {
		var filterObject = Trim( rc.filterObject ?: "" );

		args.queryString = ListAppend( args.queryString ?: "", "filterObject=#filterObject#", "&" );

		return runEvent(
			  event          = "admin.objectLinks.buildEditRecordActionLink"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);
	}

	private string function buildDeleteRecordActionLink( event, rc, prc, args={} ) {
		var filterObject = Trim( rc.filterObject ?: "" );

		args.queryString = ListAppend( args.queryString ?: "", "filterObject=#filterObject#", "&" );

		return runEvent(
			  event          = "admin.objectLinks.buildDeleteRecordActionLink"
			, private        = true
			, prePostExempt  = true
			, eventArguments = { args=args }
		);
	}

// ADDING RECORDS
	private void function preRenderAddRecordForm() {
		var contextId = rc.context ?: "";
		var contexts  = rulesEngineContextService.listContexts();

		for( var context in contexts ) {
			if ( context.id == contextId ) {
				prc.context = context;
				break;
			}
		}

		if ( !IsStruct( prc.context ?: "" ) ) {
			event.notFound();
		}

		event.include( "/js/admin/specific/rulesEngine/lockingform/" );
	}

	private void function preAddRecordAction( event, rc, prc, args={} ){
		var formData = args.formData ?: {};

		if ( !args.validationResult.validated() ) {
			StructDelete( formData,  "context" );
		} else {
			_conditionToFilterCheck( argumentCollection=arguments, action="add", formData=formData );

			if ( ( rc.convertAction ?: "" ) == "filter" && ( rc.filter_object ?: "" ).len() ) {
				formData.context = "";
				formData.filter_object = rc.filter_object;
			}
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
				var objectName = renderContent( "objectName", objectsFilterable[ 1 ] );
				var response = { success=false, convertPrompt=renderView( view="/admin/datamanager/rules_engine_condition/convertConditionToFilter", args={
					  id                = rc.id ?: ""
					, formData          = arguments.formData
					, objectsFilterable = objectsFilterable
					, saveAction        = arguments.action
					, submitAction      = event.buildAdminLink( objectName="rules_engine_condition", operation="#arguments.action#RecordAction", recordId=( rc.id ?: "" ) )
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
				setNextEvent( url=event.buildAdminLink( linkto="datamanager.rules_engine_condition.convertConditionToFilter" ), persistStruct=persist );
			}
		}

		return false;
	}

	public void function convertConditionToFilter( event, rc, prc ) {
		var action        = rc.saveAction ?: "";
		var recordId      = rc.id ?: "";
		var permissionKey = "";

		event.initializeDatamanagerPage(
			  objectName = "rules_engine_condition"
			, recordId   = recordId
		);

		switch( action ) {
			case "quickadd":
			case "add":
				permissionKey = "add";
			break;
			case "edit":
			case "quickedit":
				permissionKey = "edit";
			break;
			default:
				event.notFound();
		}

		runEvent( event="admin.datamanager._checkPermission", private=true, prepostExempt=true, eventArguments={
			  objectName = "rules_engine_condition"
			, key        = permissionKey
		} );

		switch( action ) {
			case "add":
				prc.submitAction = event.buildAdminLink( objectName="rules_engine_condition", operation="addRecordAction" );
			break;
			case "edit":
				prc.submitAction = event.buildAdminLink( objectName="rules_engine_condition", operation="editRecordAction" );
			break;
		}

		var objectsFilterable = rc.objectsFilterable ?: [];
		if ( !IsArray( objectsFilterable ) || !objectsFilterable.len() ) {
			event.notFound();
		}

		prc.pageTitle    = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.page.title" );
		prc.pageSubTitle = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.page.subtitle" );

		var objectName      = renderContent( "objectName", objectsFilterable[ 1 ] );
		prc.pageDescription = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.intro.single.object", data=[ objectName ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:rulesEngine.convert.condition.to.filter.breadcrumb.title" )
			, link  = ""
		);
	}

// EDITING RECORDS
	private string function getEditRecordFormName( event, rc, prc, args={} ) {
		var formName = "";

		if ( Len( Trim( prc.record.filter_object ?: "" ) ) ) {
			rc.filter_object = prc.record.filter_object ?: "";
			event.include( "/js/admin/specific/saveFilterForm/" );
			formName = "preside-objects.rules_engine_condition.admin.edit.filter";
		} else {
			rc.context = prc.record.context ?: "";
			formName = "preside-objects.rules_engine_condition.admin.edit";
		}

		if ( IsTrue( prc.record.is_locked ?: "" ) ) {
			prc.readOnly = !Len( Trim( prc.record.filter_object ?: "" ) );
			formName = formsService.getMergedFormName( formName, formName & ".locked" );
		}

		event.include( "/js/admin/specific/rulesEngine/lockingform/" );
		return formName;
	}

	private string function preRenderEditRecordForm( event, rc, prc, args={} ) {
		if ( IsTrue( args.record.is_locked ?: "" ) ) {
			args.canUnlock = hasCmsPermission( "rulesengine.unlock" );
			if ( args.canUnlock ) {
				args.unlockLink = event.buildAdminLink( linkto="datamanager.rules_engine_condition.unlockAction", queryString="id=#prc.recordId#" );
			}

			return renderView( view="/admin/datamanager/rules_engine_condition/_lockedMessage", args=args );
		}

		return "";
	}

	private void function preEditRecordAction( event, rc, prc, args={} ){
		var formData = args.formData ?: {};

		_conditionToFilterCheck( argumentCollection=arguments, action="edit", formData=formData );

		if ( ( rc.convertAction ?: "" ) == "filter" && Len( rc.filter_object ?: "" ) ) {
			formData.context = "";
			formData.filter_object = rc.filter_object;
		}

		switch ( args.formData.filter_sharing_scope ?: "" ) {
			case "global":
				args.formData.owner            = "";
				args.formData.user_groups      = "";
				args.formData.allow_group_edit = 0;
				break;
			case "individual":
				args.formData.user_groups      = "";
				args.formData.allow_group_edit = 0;
				break;
		}
	}

// HELPERS
	private string function _queryString( required string querystring, struct args={} ) {
		var extraQs = args.queryString ?: "";

		if ( extraQs.len() ) {
			return arguments.queryString & "&" & extraQs;
		}

		return arguments.queryString;
	}
}