<cfparam name="args.action"            type="string" />
<cfparam name="args.known_as"          type="string" />
<cfparam name="args.userLink"          type="string" />
<cfparam name="args.record_id"         type="string" />
<cfparam name="args.detail.id"         type="string" default="" />
<cfparam name="args.detail.objectName" type="string" default="" />

<cfscript>
	userLink     = '<a href="#args.userLink#">#args.known_as#</a>';
	objectTitle  = translateResource( uri="preside-objects.#args.detail.objectName#:title.singular" );
	objectUrl    = event.buildAdminLink( linkTo="datamanager.object", queryString="id=" & args.detail.objectName );
	objectLink   = '<a href="#objectUrl#">#objectTitle#</a>';
	recordLabel  = Len( Trim( args.detail.objectName ) ) ? renderLabel( args.detail.objectName, args.record_id ) : "unknown";
	recordUrl    = event.buildAdminLink( linkTo="datamanager.viewRecord", queryString="object=#args.detail.objectName#&id=#args.record_id#" );
	recordLink   = '<a href="#recordUrl#">#recordLabel#</a>';

	message      = translateResource( uri="auditlog.datamanager:#args.action#.message", data=[ userLink, objectLink, recordLink ] );
</cfscript>

<cfoutput>
	#message#
</cfoutput>