<cfparam name="args.userName"       type="string" />
<cfparam name="args.websiteName"    type="string" />
<cfparam name="args.loginId"        type="string" />
<cfparam name="args.emailAddress"   type="string" />
<cfparam name="args.resetLink"      type="string" />
<cfparam name="args.welcomeMessage" type="string" default="" />

<cfoutput>
Welcome #args.userName#,

#args.createdBy# has invited you to be a CMS user for #args.websiteName#. <cfif Len( Trim( args.welcomeMessage ) )>#args.createdBy# says:

---------------------
#args.welcomeMessage#
----------------------</cfif>

To login for the first time, please copy and paste the following link into your browser and we will guide you through the setting your password:

#args.resetLink#

Your login id is #args.loginId#.
</cfoutput>