<!---@feature admin and emailCenter--->
<cfparam name="args.action"            type="string" />
<cfparam name="args.known_as"          type="string" />
<cfparam name="args.userLink"          type="string" />
<cfparam name="args.record_id"         type="string" />

<cfscript>
	userLink    = '<a href="#EncodeForHtmlAttribute( args.userLink )#">#EncodeForHtml( args.known_as )#</a>';
	recordLabel = renderLabel( "email_blueprint", args.record_id );
	recordUrl   = event.buildAdminLink( linkTo="emailCenter.Blueprints.edit", queryString="id=#args.record_id#" );
	recordLink  = '<a href="#EncodeForHtmlAttribute( recordUrl )#">#EncodeForHtml( recordLabel )#</a>';

	message = translateResource( uri="auditlog.emailblueprints:#args.action#.message", data=[ userLink, recordLink ] );
</cfscript>

<cfoutput>
	#message#
</cfoutput>