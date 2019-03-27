component extends="preside.system.base.AdminHandler" {

	property name="ruleDao"             inject="presidecms:object:url_redirect_rule";
	property name="messageBox"          inject="messagebox@cbmessagebox";

// public handlers
	public void function preHandler( event ) {
		super.preHandler( argumentCollection=arguments );

		_checkPermissions( event=event, key="navigate" );

		prc.pageIcon = "fa-code-fork";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:urlRedirects.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="urlRedirects" )
		);
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:urlRedirects.pageTitle" );
		prc.pageSubtitle = translateResource( "cms:urlRedirects.pageSubtitle" );
	}

	public void function deleteRuleAction( event, rc, prc ) {
		_checkPermissions( event=event, key="deleteRule" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object      = "url_redirect_rule"
				, postAction  = "urlRedirects"
				, audit       = true
				, auditType   = "urlredirects"
				, auditAction = "delete_redirect_rule"
			}
		);
	}

	public void function getRulesForAjaxDataTables( event, rc, prc ) {
		_checkPermissions( event=event, key="read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "url_redirect_rule"
				, gridFields  = "label,source_url_pattern,redirect_to_link"
				, actionsView = "/admin/urlRedirects/_rulesGridActions"
			}
		);
	}

	public void function addRule( event, rc, prc ) {
		_checkPermissions( event=event, key="addRule" );

		prc.pageTitle    = translateResource( "cms:urlRedirects.addRule.pageTitle" );
		prc.pageSubtitle = translateResource( "cms:urlRedirects.addRule.pageSubtitle" );
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:urlRedirects.addRule.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="urlRedirects.addRule" )
		);
	}

	public void function addRuleAction( event, rc, prc ) {
		_checkPermissions( event=event, key="addRule" );

		runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "url_redirect_rule"
				, errorAction      = "urlRedirects.addRule"
				, successAction    = "urlRedirects"
				, addAnotherAction = "urlRedirects.addRule"
				, viewRecordAction = "urlRedirects.editRule"
				, audit            = true
				, auditType        = "urlredirects"
				, auditAction      = "add_redirect_rule"
			}
		);
	}

	function editRule( event, rc, prc ) {
		_checkPermissions( event=event, key="editRule" );
		var ruleId = rc.id ?: "";

		if ( Len( Trim( ruleId ) ) ) {
			prc.record = ruleDao.selectData( id=ruleId );
		}

		if ( !Len( Trim( ruleId ) ) ||  !prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:urlRedirects.ruleNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="urlRedirects" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		prc.pageTitle    = translateResource( uri="cms:urlRedirects.editRule.pageTitle", data=[ prc.record.label ] );
		prc.pageSubtitle = translateResource( uri="cms:urlRedirects.editRule.pageSubtitle", data=[ prc.record.label ] );
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:urlRedirects.editRule.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="urlRedirects.editRule", queryString="id=" & ruleId )
		);
	}
	function editRuleAction( event, rc, prc ) {
		_checkPermissions( event=event, key="editRule" );

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object        = "url_redirect_rule"
				, errorAction   = "urlRedirects.editRule"
				, successAction = "urlRedirects"
				, audit         = true
				, auditType     = "urlredirects"
				, auditAction   = "edit_redirect_rule"
			}
		);
	}

	function exportAction( event, rc, prc ) {
		_checkPermissions( event=event, key="read" );

		runEvent(
			  event          = "admin.DataManager._exportDataAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = { objectName="url_redirect_rule" }
		);
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) {
		if ( !hasCmsPermission( "urlRedirects." & arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}