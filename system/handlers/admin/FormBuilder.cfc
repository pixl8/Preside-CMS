component extends="preside.system.base.AdminHandler" {

	property name="formBuilderService" inject="formBuilderService";
	property name="itemTypesService"   inject="formBuilderItemTypesService";
	property name="messagebox"         inject="coldbox:plugin:messagebox";


// PRE-HANDLER
	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "formbuilder" ) ) {
			event.notFound();
		}

		_permissionsCheck( "navigate", event );

		event.addAdminBreadCrumb(
			  title = translateResource( "formbuilder:breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="formbuilder" )
		);
		prc.pageIcon = "check-square-o";
	}

// DEFACTO PUBLIC ACTIONS
	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "formbuilder:page.title" );
		prc.pageSubtitle = translateResource( "formbuilder:page.subtitle" );

		prc.canAdd = hasCmsPermission( permissionKey="formbuilder.addform" );
	}

	public void function addForm( event, rc, prc ) {
		_permissionsCheck( "addform", event );

		prc.pageTitle    = translateResource( "formbuilder:add.form.page.title" );
		prc.pageSubtitle = translateResource( "formbuilder:add.form.page.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( "formbuilder:addform.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="formbuilder.addform" )
		);
	}

	public void function manageForm( event, rc, prc ) {
		prc.form = formBuilderService.getForm( rc.id ?: "" );

		if ( !prc.form.recordcount ) {
			messagebox.error( translateResource( "formbuilder:form.not.found.alert" ) );
			setNextEvent( url=event.buildAdminLink( "formbuilder" ) );
		}

		prc.pageTitle    = translateResource( uri="formbuilder:manage.form.page.title"   , data=[ prc.form.name ] );
		prc.pageSubtitle = translateResource( uri="formbuilder:manage.form.page.subtitle", data=[ prc.form.name ] );
		prc.canEdit      = hasCmsPermission( permissionKey="formbuilder.editform" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:manageform.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & prc.form.id )
		);

		event.includeData( {
			  "formbuilderFormId"              = prc.form.id
			, "formbuilderSaveNewItemEndpoint" = event.buildAdminLink( linkTo="formbuilder.addItemAction" )
			, "formbuilderItemConfigEndpoint"  = event.buildAdminLink( linkTo="formbuilder.renderItemConfig" )
		} );
	}

	public void function renderItemConfig( event, rc, prc ) {
		event.renderData( data={ title="Test this stuff", body="This would be the config form" }, type="json" );
	}

	public void function addItemAction( event, rc, prc ) {
		var configuration = event.getCollectionWithoutSystemVars();

		configuration.delete( "formId"   );
		configuration.delete( "itemType" );

		var newId = formBuilderService.addItem(
			  formId        = rc.formId   ?: ""
			, itemType      = rc.itemType ?: ""
			, configuration = configuration
		);

		event.renderData( type="plain", data=newId );
	}

	public void function editForm( event, rc, prc ) {
		_permissionsCheck( "editform", event );

		prc.form = formBuilderService.getForm( rc.id ?: "" );

		if ( !prc.form.recordcount ) {
			messagebox.error( translateResource( "formbuilder:form.not.found.alert" ) );
			setNextEvent( url=event.buildAdminLink( "formbuilder" ) );
		}
		prc.form = QueryRowToStruct( prc.form );

		prc.pageTitle    = translateResource( uri="formbuilder:edit.form.page.title"   , data=[ prc.form.name ] );
		prc.canEdit      = hasCmsPermission( permissionKey="formbuilder.editform" );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:manageform.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & prc.form.id )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="formbuilder:edit.form.breadcrumb.title", data=[ prc.form.name ] )
			, link  = event.buildAdminLink( linkTo="formbuilder.editform", queryStrign="id=" & prc.form.id )
		);
	}

// DOING STUFF ACTIONS
	public void function addFormAction( event, rc, prc ) {
		_permissionsCheck( "addform", event );

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "formbuilder_form"
				, errorAction      = "formbuilder.addform"
				, successAction    = "formbuilder.manageform"
				, addAnotherAction = "formbuilder.addform"
				, viewRecordAction = "formbuilder.manageform"
			}
		);
	}

	public void function editFormAction( event, rc, prc ) {
		_permissionsCheck( "editform", event );
		var formId = rc.id ?: "";

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "formbuilder_form"
				, errorUrl         = event.buildAdminLink( linkTo="formbuilder.editform", queryString="id=" & formId )
				, successUrl       = event.buildAdminLink( linkTo="formbuilder.manageform", queryString="id=" & formId )
			}
		);
	}

// AJAXY ACTIONS
	public void function getFormsForAjaxDataTables( event, rc, prc ) {
		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object          = "formbuilder_form"
				, useMultiActions = false
				, gridFields      = "name,description,locked,active,active_from,active_to"
				, actionsView     = "admin.formbuilder.formDataTableGridFields"
			}
		);
	}

// VIEWLETS
	private string function formDataTableGridFields( event, rc, prc, args ) {
		args.canEdit = hasCmsPermission( permissionKey="formbuilder.editform" );

		return renderView( view="/admin/formbuilder/_formGridFields", args=args );
	}

	private string function itemTypePicker( event, rc, prc, args ) {
		args.itemTypesByCategory = itemTypesService.getItemTypesByCategory();

		return renderView( view="/admin/formbuilder/_itemTypePicker", args=args );
	}

	private string function itemsManagement( event, rc, prc, args ) {
		args.items = formBuilderService.getFormItems( args.formId ?: "" );
		return renderView( view="/admin/formbuilder/_itemsManagement", args=args );
	}

// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "formbuilder." & arguments.key;
		var permitted = hasCmsPermission( permissionKey=permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}
}