component extends="preside.system.base.AdminHandler" {

	property name="websitePermissionService" inject="websitePermissionService";
	property name="websiteBenefitDao"        inject="presidecms:object:website_benefit";
	property name="messageBox"               inject="messagebox@cbmessagebox";

	function prehandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "websiteUsers" ) || !isFeatureEnabled( "websiteBenefits" ) ) {
			event.notFound();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:websiteBenefitsManager.benefitspage.title" )
			, link  = event.buildAdminLink( linkTo="websiteBenefitsManager" )
		);
	}

	function index( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.navigate" );
	}

	function getBenefitsForAjaxDataTables( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.read" );

		runEvent(
			  event          = "admin.DataManager._getObjectRecordsForAjaxDataTables"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object      = "website_benefit"
				, gridFields  = "label,priority,description"
				, actionsView = "/admin/websiteBenefitsManager/_benefitsGridActions"
			}
		);
	}

	function addBenefit( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.add" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:websiteBenefitsManager.addBenefit.page.title" )
			, link  = event.buildAdminLink( linkTo="websiteBenefitsManager.addBenefit" )
		);
	}
	function addBenefitAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.add" );

		var object = "website_benefit";
		var newId = runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "website_benefit"
				, errorAction      = "websiteBenefitsManager.addBenefit"
				, redirectOnSuccess = false
				, audit             = true
				, auditType         = "websitebenefitsmanager"
				, auditAction       = "add_website_benefit"
			}
		);
		var newRecordLink = event.buildAdminLink( linkTo="websiteBenefitsManager.editBenefit", queryString="id=#newId#" );

		websitePermissionService.syncBenefitPermissions( benefitId=newId, permissions=ListToArray( rc.permissions ?: "" ) );

		messageBox.info( translateResource( uri="cms:datamanager.recordAdded.confirmation", data=[
			  translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object )
			, '<a href="#newRecordLink#">#event.getValue( name='label', defaultValue=translateResource( uri="cms:datamanager.record" ) )#</a>'
		] ) );

		if ( Val( rc._addanother ?: 0 ) ) {
			setNextEvent( url=event.buildAdminLink( linkTo="websiteBenefitsManager.addBenefit" ), persist="_addAnother" );
		} else {
			setNextEvent( url=event.buildAdminLink( linkTo="websiteBenefitsManager" ) );
		}
	}

	function editBenefit( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.edit" );

		var id = rc.id ?: "";

		prc.record = websiteBenefitDao.selectData( filter={ id=id } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:websiteBenefitsManager.benefitNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="websiteBenefitsManager" ) );
		}
		prc.record = queryRowToStruct( prc.record );
		prc.record.permissions = websitePermissionService.listPermissionKeys( benefit = id ).toList();

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:websiteBenefitsManager.editBenefit.page.title", data=[ prc.record.label ] )
			, link  = event.buildAdminLink( linkTo="websiteBenefitsManager.editBenefit", queryString="id=#id#" )
		);
	}
	function editBenefitAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.edit" );

		runEvent(
			  event          = "admin.DataManager._editRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object        = "website_benefit"
				, errorAction   = "websiteBenefitsManager.editBenefit"
				, redirectOnSuccess = false
				, audit             = true
				, auditType         = "websitebenefitsmanager"
				, auditAction       = "edit_website_benefit"
			}
		);

		websitePermissionService.syncBenefitPermissions( benefitId=rc.id ?: "", permissions=ListToArray( rc.permissions ?: "" ) );

		messageBox.info( translateResource( uri="cms:websiteBenefitsManager.benefit.saved.confirmation", data=[ rc.label ?: "" ] ) );
		setNextEvent( url=event.buildAdminLink( linkTo="websiteBenefitsManager" ) );
	}

	function deleteBenefitAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.delete" );

		runEvent(
			  event          = "admin.DataManager._deleteRecordAction"
			, private        = true
			, prePostExempt  = true
			, eventArguments = {
				  object     = "website_benefit"
				, postAction = "websiteBenefitsManager"
				, audit             = true
				, auditType         = "websitebenefitsmanager"
				, auditAction       = "delete_website_benefit"
			}
		);
	}

	function prioritize( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.prioritize" );

		prc.benefits = websiteBenefitDao.selectData( orderBy="priority desc" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:websiteBenefitsManager.prioritize.breadcrumb" )
			, link  = event.buildAdminLink( linkTo="websiteBenefitsManager.prioritize" )
		);
	}

	function prioritizeAction( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.prioritize" );

		var benefits = rc.benefits ?: "";

		benefits = ListToArray( benefits );
		CreateObject( "java", "java.util.Collections" ).reverse( benefits );

		websitePermissionService.prioritizeBenefits( benefits );

		messageBox.info( translateResource( uri="cms:websiteBenefitsManager.priority.saved.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="websiteBenefitsManager" ) );
	}

	function exportAction( event, rc, prc ) {
		_checkPermissions( event=event, key="websiteBenefitsManager.read" );

		runEvent(
			  event          = "admin.DataManager._exportDataAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = { objectName="website_benefit" }
		);
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) output=false {
		if ( !hasCmsPermission( arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}