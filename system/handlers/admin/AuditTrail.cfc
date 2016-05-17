component extends="preside.system.base.AdminHandler" {

	property name="auditService" inject="auditService";

	public void function preHandler( event ) {
		super.preHandler( argumentCollection = arguments );

		_permissionsCheck( "navigate", event );

		prc.pageIcon = "fa-history";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:auditTrail.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo = "auditTrail" )
		);
	}

	public void function index( event, rc, prc ) {
		prc.user          = StructKeyExists( rc,'user' )          ? rc.user        : "";
		prc.action        = StructKeyExists( rc,'action' )        ? rc.action      : "";
		prc.dateFilters   = structKeyExists( rc,'dateFilters' )   ? rc.dateFilters : "";
		var filterDetails = _getFilterAndExtraFilters( prc.user, prc.action, prc.dateFilters );
		prc.logs          = auditService.getAuditTrailLog( 1, 10, filterDetails.filter , filterDetails.extraFilters );
		prc.filterLabel   = _getfilterLabel( prc.user, prc.action, prc.dateFilters );
		prc.pageTitle     = translateResource( "cms:auditTrail.page.title" );
		prc.pageSubTitle  = translateResource( "cms:auditTrail.page.subtitle" );
	}

	public any function loadMore( event, rc, prc ) {
		var page          = val( val ( rc.page ?: 2 ) - 1 ) * 10 + 1;
		var filterDetails = _getFilterAndExtraFilters( rc.user, rc.action, rc.dateFilters );
		prc.logs          = auditService.getAuditTrailLog( page, 10, filterDetails.filter, filterDetails.extraFilters );
		event.noLayout();
	}

	public void function viewLog( event, rc, prc ) {
		prc.auditTrail = auditService.getAuditLog( rc.id ?: "" );

		if ( !prc.auditTrail.recordCount ) {
			event.adminNotFound();
		}
		event.nolayout();
	}

	public string function getFilters( event, rc, prc ) {
		prc.userFilter     = rc.user        ?: '';
		prc.actionFilter   = rc.action      ?: '';
		prc.dateFilter     = rc.dateFilters ?: '';
		prc.filterType     = rc.type        ?: "";
		prc.filterValue    = rc.value       ?: "";
		prc.logs           = auditService.getAuditTrailLog();
		prc.userLists      = ListRemoveDuplicates( valueList( prc.logs.known_as ) );
		prc.users          = listToArray( prc.userLists );
		prc.userIdLists    = ListRemoveDuplicates( valueList( prc.logs.user ) );
		prc.userIds        = listToArray( prc.userIdLists );
		prc.actionLists    = ListRemoveDuplicates( valueList( prc.logs.action ) );
		prc.actions        = listToArray( prc.actionLists );
		prc.filterControl  = '';

		switch( prc.filterType ) {
			case "dateCreated":
				var type     = {};
				var dateType = "From,To";
				if( len( prc.dateFilter ) ) {
					type.from = listFirst( prc.dateFilter );
					type.to   = listLast( prc.dateFilter );
				}
				for( date in dateType ) {
					prc.filterControl = prc.filterControl&renderFormControl(
						  type         = "datepicker"
						, name         = "datecreated"
						, label        = date &" "&"Date"
						, defaultValue = type[date] ?: ""
					);
				}
				prc.filterControl = prc.filterControl&renderFormControl( type = 'hidden',  name = 'action', defaultValue = prc.actionFilter )&renderFormControl( type = 'hidden',  name = 'user', defaultValue = prc.userFilter );
			break;

			case "Action":
				prc.filterControl = renderFormControl(
					  type         = "select"
					, name         = "action"
					, label        = "Action"
					, values       = prc.actions ?: []
					, labels       = prc.actions ?: []
					, class        = "form-control"
					, defaultValue = prc.actionFilter
				)&renderFormControl( type = 'hidden',  name = 'dateCreated', defaultValue = prc.dateFilter )&renderFormControl( type = 'hidden',  name = 'user', defaultValue = prc.userFilter );
			break;

			case "User":
				prc.filterControl = renderFormControl(
					  type         = "select"
					, name         = "user"
					, label        = "User"
					, values       = prc.userIds   ?: []
					, labels       = prc.users     ?: []
					, class        = "form-control"
					, defaultValue = prc.userFilter
				)&renderFormControl( type = 'hidden',  name = 'dateCreated', defaultValue = prc.dateFilter )&renderFormControl( type = 'hidden',  name = 'action', defaultValue = prc.actionFilter );
			break;
		}
		event.nolayout();
	}

	public void function search( event, rc, prc ) {
		var fieldnames  = listToArray( rc.fieldnames );
		var querystring = '';
		for ( field in fieldnames ){
			if( rc[ field ] != '' ){
				var fieldName = ( field == 'datecreated' ) ? 'dateFilters' : field;
				if( querystring != '' ){
					querystring   = querystring & '&';
				}
				querystring   = querystring & fieldName & '=' & rc[ field ];
			}
		}
		setNextEvent( url = event.buildAdminLink( linkTo="auditTrail" ) , querystring="#querystring#" );
	}

	// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "auditTrail." & arguments.key;
		var permitted = hasCmsPermission( permissionKey = permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

	private struct function _getFilterAndExtraFilters( required string user, required string action, required string datecreated ) {
		var filterObject.filter       = {};
		var filterObject.extraFilters = [];
		var fromDate                  = listToArray( listFirst( arguments.datecreated ), '-' );
		var toDate                    = listToArray( listLast( arguments.datecreated ), '-' );

		if( arguments.datecreated != '' && !ArrayIsEmpty( fromDate ) and !ArrayIsEmpty( toDate ) ) {
			filterObject.extraFilters.append({
				  filter       = "audit_log.datecreated between :From and :To"
				, filterParams = { From = { type="cf_sql_varchar", value="#datetimeformat( createdate( fromDate[1], fromDate[2], fromDate[3]),' yyyy-mm-dd HH:nn:ss ')#" } , To = { type="cf_sql_varchar", value="#datetimeformat(createdate(toDate[1],toDate[2],toDate[3]),'yyyy-mm-dd HH:nn:ss')#" } }
			});
		}
		if ( arguments.user != '' ){
			structInsert( filterObject.filter, "user", arguments.user );
		}
		if( arguments.action != '' ){
			structInsert( filterObject.filter, "action", arguments.action );
		}
		return filterObject;
	}

	private array function _getfilterLabel( required string user, required string action, required string datecreated ) {
		var filtersData = [];
		var filterData  = {};

		if( len( arguments.dateCreated ) ) {
			filtersData.append({
				  type  = "dateCreated"
				, value = "Date created after" & " " & dateFormat( listfirst( arguments.datecreated ), "dd mmm yyyy")
				, icon  = "fa fa-calendar"
			});
		}
		if( len( arguments.action ) ) {
			filtersData.append({
				  type  = "Action"
				, value = "Action:" & " " & arguments.action
				, icon  = "fa fa-cogs"
			});
		}
		if( len( arguments.user ) ) {
			var filter           = { user = "#arguments.user#" };
			var auditTrail       = auditService.getAuditTrailLog( filter = filter );
			filtersData.append({
				  type  = "User"
				, value = "User:" & " " & auditTrail.known_as
				, icon  = "fa fa-user"
			});
		}
		return filtersData;
	}

}