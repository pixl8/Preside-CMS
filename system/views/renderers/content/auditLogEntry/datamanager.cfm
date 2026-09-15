<!---@feature admin--->
<cfparam name="args.action"            type="string" />
<cfparam name="args.known_as"          type="string" />
<cfparam name="args.userLink"          type="string" />
<cfparam name="args.record_id"         type="string" />
<cfparam name="args.detail.id"         type="string" default="" />
<cfparam name="args.detail.objectName" type="string" default="" />

<cfscript>
	userLink     = '<a href="#args.userLink#">#args.known_as#</a>';
	objectTitle  = translateResource( uri="preside-objects.#args.detail.objectName#:title.singular" );
	objectUrl    = event.buildAdminLink( objectName=args.detail.objectName, operation="listing" );
	objectLink   = '<a href="#objectUrl#">#objectTitle#</a>';
	messageData  = [];

	if ( ListFindNoCase( "datamanager_save_listing_view,datamanager_update_listing_view,datamanager_delete_listing_view", args.action ) ) {
		messageData = [ userLink, EncodeForHtml( args.detail.label ?: args.record_id ), objectLink ];
	} else {
		recordLabel  = Len( Trim( args.detail.objectName ) ) ? renderLabel( args.detail.objectName, args.record_id ) : "unknown";
		recordUrl    = event.buildAdminLink( objectName=args.detail.objectName, recordId=args.record_id );
		recordLink   = '<a href="#recordUrl#">#recordLabel#</a>';
		messageData  = [ userLink, objectLink, recordLink ];
	}

	message = translateResource( uri="auditlog.datamanager:#args.action#.message", data=messageData );
</cfscript>

<cfoutput>
	#message#
</cfoutput>