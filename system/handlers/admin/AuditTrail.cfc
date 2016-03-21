component extends="preside.system.base.AdminHandler" output=false {

	public void function preHandler( event ) output=false {
		super.preHandler( argumentCollection=arguments );

		_permissionsCheck( "navigate", event );

		prc.pageIcon = "fa-history";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:auditTrail.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="auditTrail" )
		);
	}

	public void function index( event, rc, prc ) output=false {
		prc.filterType    = StructKeyExists( rc,'filterType' )  ? rc.filterType  : "";
		prc.filterValue   = StructKeyExists( rc,'filterValue' ) ? rc.filterValue : "";
		var filterDetails = _getFilterAndExtraFilters( prc.filterType, prc.filterValue);
		prc.logs          = getModel( "AuditService" ).getAuditTrailLog( 1, 10, filterDetails.filter , filterDetails.extraFilters );
		prc.pageTitle     = translateResource( "cms:auditTrail.page.title" );
		prc.pageSubTitle  = translateResource( "cms:auditTrail.page.subtitle" );
	}

	public any function loadMore( event, rc, prc ) output=false {
		var page          = val( val ( rc.page ?: 2 ) - 1 ) * 10 + 1;
		var filterDetails = _getFilterAndExtraFilters( rc.filterType, rc.filterValue);
		prc.logs          = getModel( "AuditService" ).getAuditTrailLog( page, 10, filterDetails.filter, filterDetails.extraFilters );
		event.noLayout();
	}

	public void function viewLog( event, rc, prc ) {
		prc.auditTrail = getModel( "AuditService" ).getAuditLog( rc.id ?: "" );

		if ( !prc.auditTrail.recordCount ) {
			event.adminNotFound();
		}
		event.nolayout();
	}

	public string function getFilters( event, rc, prc ) {
		prc.logs        = getModel( "AuditService" ).getAuditTrailLog();
		prc.filterType  = rc.type ?: "";
		prc.userLists   = ListRemoveDuplicates( valueList( prc.logs.known_as ) );
		prc.users       = listToArray( prc.userLists );
		prc.userIdLists = ListRemoveDuplicates( valueList( prc.logs.user ) );
		prc.userIds     = listToArray( prc.userIdLists );
		prc.actionLists = ListRemoveDuplicates( valueList( prc.logs.action ) );
		prc.actions     = listToArray( prc.actionLists );
		prc.filterControl = {};

		switch( prc.filterType ){
			case "DateRange":
				var dateType = "From,To";
				for( date in dateType ) {
					prc.filterControl[date] = renderFormControl(
						 type             = "datepicker"
						, name            = "datecreated"
						, label           = date &" "&"Date"
					);
				}
			break;
			case "Action":
				prc.filterControl = renderFormControl(
					  type   = "select"
					, name   = "action"
					, label  = "Action"
					, values = prc.actions ?: []
					, labels = prc.actions ?: []
					, class  = "form-control"
				);
			break;
			case "User":
				prc.filterControl = renderFormControl(
					  type   = "select"
					, name   = "user"
					, label  = "User"
					, values = prc.userIds   ?: []
					, labels = prc.users     ?: []
					, class  = "form-control"
				);
			break;
		}

		event.nolayout();
	}

	public void function search( event, rc, prc ) {
		var filterType  = rc.fieldnames  ?: "";
		var filterValue = rc[filterType] ?: "";
		var filter      = { "#filterType#" = filterValue };
		setNextEvent( url = event.buildAdminLink( linkTo="auditTrail" ) , querystring="filterType=#filterType#&filterValue=#filterValue#" );
	}

	// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "auditTrail." & arguments.key;
		var permitted = hasCmsPermission( permissionKey=permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

	private struct function _getFilterAndExtraFilters( required string type, required any value ) {
		var filterObject.filter       = {};
		var filterObject.extraFilters = [];
		var fromDate                  = listToArray( listFirst( arguments.value ), '-' );
		var toDate                    = listToArray( listLast( arguments.value ), '-' );

		if( len( arguments.type ) && arguments.type != 'datecreated') {
		   filterObject.filter  = { "#arguments.Type#" = arguments.value };
		}

		if(arguments.type == 'datecreated' && !ArrayIsEmpty( fromDate ) and !ArrayIsEmpty( toDate )) {
			filterObject.extraFilters.append({
				  filter       = "audit_log.datecreated between :From and :To"
				, filterParams = { From = { type="cf_sql_varchar", value="#datetimeformat( createdate( fromDate[1], fromDate[2], fromDate[3]),' yyyy-mm-dd HH:nn:ss ')#" } , To = { type="cf_sql_varchar", value="#datetimeformat(createdate(toDate[1],toDate[2],toDate[3]),'yyyy-mm-dd HH:nn:ss')#" } }
			});
		}

		return filterObject;
	}

}