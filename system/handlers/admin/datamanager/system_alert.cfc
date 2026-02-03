component extends="preside.system.base.EnhancedDataManagerBase" {

	property name="systemAlertsService"   inject="systemAlertsService";
	property name="messageBox"            inject="messagebox@cbmessagebox";
	property name="datamanagerService"    inject="datamanagerService";
	property name="presideObjectService"  inject="presideObjectService";

	variables.permissionBase = "presideobject.system_alert";
	variables.tabs           = [ "default", "data" ];
	variables.infoCol1       = [ "level" ];
	variables.infoCol2       = [ "context", "reference" ];
	variables.infoCol3       = [ "datecreated", "datemodified" ];

	private string function _defaultTab( event, rc, prc, args={} ) {
		var recordId = prc.recordId ?: "";
		args.alert   = systemAlertsService.getAlert( id=recordId );

		return renderView( view="/admin/datamanager/system_alert/_renderAlert", args=args );
	}

	private string function _dataTab( event, rc, prc, args={} ) {
		if ( Len( prc.record.data ?: "" ) ) {
			if ( prc.record.data != "{}" ) {
				return renderField(
					  object   = prc.objectName
					, property = "data"
					, data     = prc.record.data
				);
			}
		}
		return "";
	}

	private string function _infoCardLevel( event, rc, prc, args={} ) {
		return '<i class="fa fa-fw fa-thermometer-half"></i>&nbsp;' & translateResource( "preside-objects.system_alert:field.level.title") & ":&nbsp;" & renderField(
			  object   = prc.objectName
			, property = "level"
			, data     = prc.record.level
		);
	}

	private string function _infoCardDateCreated( event, rc, prc, args={} ) {
		return '<i class="fa fa-fw fa-plus"></i>&nbsp;' & translateResource( "preside-objects.system_alert:field.datecreated.title") & ":&nbsp;"
			 & DateTimeFormat( args.record.datecreated, 'd mmm yyyy HH:nn' );
	}

	private string function _infoCardDateModified( event, rc, prc, args={} ) {
		return '<i class="fa fa-fw fa-clock-o"></i>&nbsp;' & translateResource( "preside-objects.system_alert:field.datemodified.title") & ":&nbsp;"
			 & DateTimeFormat( args.record.datemodified, 'd mmm yyyy HH:nn' );
	}

	private string function _infoCardContext( event, rc, prc, args={} ) {
		return '<i class="fa fa-fw fa-project-diagram"></i>&nbsp;' & translateResource( "preside-objects.system_alert:field.context.title") & ":&nbsp;" & renderField(
			  object   = prc.objectName
			, property = "context"
			, data     = prc.record.context
		);
	}

	private string function _infoCardReference( event, rc, prc, args={} ) {
		return '<i class="fa fa-fw fa-code"></i>&nbsp;' & translateResource( "preside-objects.system_alert:field.reference.title") & ":&nbsp;" & renderField(
			  object   = prc.objectName
			, property = "reference"
			, data     = prc.record.reference
		);
	}

	private void function extraTopRightButtonsForObject( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		args.actions = args.actions ?: [];
		for( var i=ArrayLen( args.actions ); i>0; i-- ) {
			if ( ( args.actions[ i ].globalKey ?: "" ) == "p" ) {
				arrayDeleteAt( args.actions, i );
			}
		}
	}

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