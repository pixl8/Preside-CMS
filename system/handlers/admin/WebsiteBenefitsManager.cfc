component extends="preside.system.base.AdminHandler" output=false {

	property name="websiteBenefitDao"    inject="presidecms:object:website_benefit";
	property name="messageBox"           inject="coldbox:plugin:messageBox";
	property name="bCryptService"        inject="bCryptService";

	function prehandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

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
				, gridFields  = "label,description"
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

		var newId = runEvent(
			  event          = "admin.DataManager._addRecordAction"
			, prePostExempt  = true
			, private        = true
			, eventArguments = {
				  object           = "website_benefit"
				, errorAction      = "websiteBenefitsManager.addBenefit"
				, successAction    = "websiteBenefitsManager"
				, addAnotherAction = "websiteBenefitsManager.addBenefit"
				, viewRecordAction = "websiteBenefitsManager.editBenefit"
			}
		);
	}

	function editBenefit( event, rc, prc ) output=false {
		_checkPermissions( event=event, key="websiteBenefitsManager.edit" );

		prc.record = websiteBenefitDao.selectData( filter={ id=rc.id ?: "" } );

		if ( not prc.record.recordCount ) {
			messageBox.error( translateResource( uri="cms:websiteBenefitsManager.benefitNotFound.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="websiteBenefitsManager" ) );
		}
		prc.record = queryRowToStruct( prc.record );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:websiteBenefitsManager.editBenefit.page.title", data=[ prc.record.label ] )
			, link  = event.buildAdminLink( linkTo="websiteBenefitsManager.editBenefit", queryString="id=#(rc.id ?: '')#" )
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
				, successAction = "websiteBenefitsManager"
			}
		);
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
			}
		);
	}

// private utility
	private void function _checkPermissions( required any event, required string key ) output=false {
		if ( !hasPermission( arguments.key ) ) {
			event.adminAccessDenied();
		}
	}

}