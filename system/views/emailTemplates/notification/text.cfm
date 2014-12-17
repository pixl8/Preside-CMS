<cfparam name="args.notificationLink"     type="string" />
<cfparam name="args.userName"             type="string" />
<cfparam name="args.notificationBodyText" type="string" default="" />

<cfoutput>
Hi, #args.userName#

You have received a notification from the CMS. To view the notification, please copy and paste the link below into your browser's address bar:

#args.notificationLink#
<cfif Len( Trim( args.notificationBodyHtml ) )>
The notification received was:

-----------------------------------
#args.notificationBodyText#
-----------------------------------</cfif>
</cfoutput>