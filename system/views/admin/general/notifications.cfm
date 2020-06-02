<cfscript>
	msgBox = getModel( "messagebox@cbmessagebox" );
	msg = Duplicate( msgBox.getMessage() );
	msgBox.clearMessage();
	stickyNotifications = getSetting( "adminNotificationsSticky" );
	position            = getSetting( "adminNotificationsPosition" );



	param name="msg.type"    default="";
	param name="msg.message" default="";

	gritterClass = "";
	switch( msg.type ){
		case "info"   : gritterClass="gritter-success"; break;
		case "error"  : gritterClass="gritter-error"; break;
		case "warning": gritterClass="gritter-warning"; break;
	}
</cfscript>

<cfif Len( Trim( msg.type ) ) and Len( Trim( msg.message ) ) and Len( gritterClass )>
	<cfsavecontent variable="js"><cfoutput>
		( function( $ ){
			$.gritter.options.position = "#position#";
			$.gritter.add({
				  title      : #SerializeJson( translateResource( "cms:#msg.type#.notification.title" ) )#
				, text       : #SerializeJson( msg.message )#
				, class_name : '#gritterClass#'
				, sticky     : #stickyNotifications#
			});
		} ) ( presideJQuery );
	</cfoutput></cfsavecontent>

	<cfset event.includeInlineJs( js ) />
</cfif>