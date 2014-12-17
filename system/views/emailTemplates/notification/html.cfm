<cfparam name="args.notificationLink"     type="string" />
<cfparam name="args.userName"             type="string" />
<cfparam name="args.notificationBodyHtml" type="string" default="" />

<cfoutput>
	<p>Hi, #args.userName#</p>

	<p>You have received a notification from the CMS. To view the notification, please follow the link below:</p>
	<p><a href="#args.notificationLink#">#args.notificationLink#</a></p>

	<cfif Len( Trim( args.notificationBodyHtml ) )>
		<p>The notification received was:</p>
		<hr />
		#args.notificationBodyHtml#
		<hr />
	</cfif>
</cfoutput>