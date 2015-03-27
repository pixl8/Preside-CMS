<cfparam name="args.notificationLink"     type="string" default="" />
<cfparam name="args.userName"             type="string" default="" />
<cfparam name="args.notificationBodyText" type="string" default="" />

<cfoutput>
	<cfif Len( Trim( args.userName ) )>
		<p>Hi, #args.userName#</p>

	</cfif>
	<cfif !Len( Trim( args.notificationLInk ) )>
		<p>You have received a notification from the CMS.</p>
	<cfelse>
		<p>You have received a notification from the CMS. To view the notification, please follow the link below:</p>
		<p><a href="#args.notificationLink#">#args.notificationLink#</a></p>
	</cfif>
	<cfif Len( Trim( args.notificationBodyHtml ) )>
		<p>The notification received was:</p>
		<hr />
		#args.notificationBodyHtml#
		<hr />
	</cfif>
</cfoutput>