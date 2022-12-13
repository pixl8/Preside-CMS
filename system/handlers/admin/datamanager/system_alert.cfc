component {

	property name="systemAlertsService" inject="systemAlertsService";
	property name="messageBox"          inject="messagebox@cbmessagebox";

	private void function extraRecordActionsForGridListing( event, rc, prc, args={} ) {
		var record     = args.record     ?: {};
		var recordId   = record.id       ?: "";
		var objectName = args.objectName ?: "";
		args.actions   = args.actions    ?: [];

		ArrayAppend( args.actions, {
			  link  = event.buildAdminLink( objectName=objectName, operation="rerunCheck", recordId=recordId )
			, title = translateResource( "cms:systemAlerts.rerunCheck.title" )
			, icon  = "fa-redo"
		} );
	}

	private array function getTopRightButtonsForViewRecord( event, rc, prc, args={} ) {
		var actions    = [];
		var objectName = args.objectName ?: "";
		var recordId   = prc.recordId    ?: "";

		ArrayAppend( actions, {
			  link      = event.buildAdminLink( objectName=objectName, operation="rerunCheck", recordId=recordId )
			, btnClass  = "btn-info"
			, iconClass = "fa-redo"
			, title     = translateResource( "cms:systemAlerts.rerunCheck.title" )
		} );

		return actions;
	}

	private string function preRenderRecord() {
		var newlyCreated = prc.record.datemodified == prc.record.datecreated;
		var justUpdated  = DateDiff( "s", prc.record.datemodified, Now() ) < 5;
		var checkFailed  = !newlyCreated && justUpdated;

		if ( !checkFailed ) {
			return "";
		}
		return renderView( view="/admin/datamanager/system_alert/_checkFailed" );
	}

	private string function preRenderRecordLeftCol() {
		var recordId = prc.recordId ?: "";
		args.alert   = systemAlertsService.getAlert( id=recordId );

		return renderView( view="/admin/datamanager/system_alert/_renderAlert", args=args );
	}

	public void function rerunCheck( event, rc, prc, args={}) {
		var recordId    = rc.id ?: "";
		var rerunResult = systemAlertsService.rerunCheck( recordId );
		var redirectId  = "";

		switch( rerunResult ) {
			case "fails":
				redirectId = recordId;
				break;
			case "cleared":
				messageBox.info( translateResource( "cms:systemAlerts.rerunCheck.cleared" ) );
				break;
			case "notfound":
				messageBox.error( translateResource( "cms:systemAlerts.rerunCheck.notfound" ) );
				break;
		}

		setNextEvent( url=event.buildAdminLink( objectName="system_alert", recordId=redirectId ) );
	}

	private string function buildRerunCheckLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkto="datamanager.system_alert.rerunCheck", queryString="id=#( args.recordId ?: "" )#" );
	}

}