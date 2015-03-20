<cfparam name="args.notificationLink"     type="string" default="" />
<cfparam name="args.userName"             type="string" default="" />
<cfparam name="args.notificationBodyText" type="string" default="" />

<cfoutput>
<cfif Len( Trim( args.userName ) )>Hi, #args.userName#

</cfif>You have received a notification from the CMS.<cfif Len( Trim( args.notificationLink ) )>To view the notification, please copy and paste the link below into your browser's address bar:

#args.notificationLink#</cfif>
<cfif Len( Trim( args.notificationBodyHtml ) )>
The notification received was:

-----------------------------------
#args.notificationBodyText#
-----------------------------------</cfif>
</cfoutput>