<cfparam name="args.action"        type="string" />
<cfparam name="args.known_as"      type="string" />
<cfparam name="args.userLink"      type="string" />
<cfparam name="args.iconClass"     type="string" />
<cfparam name="args.detail.id"    type="string" default="" />
<cfparam name="args.detail.label" type="string" default="unknown" />

<cfscript>
	folderLink = '<a href="#event.buildAdminLink( linkTo='assetmanager', queryString='folder=' & args.detail.id )#">#args.detail.label#</a>';
	message = translateResource(
		  uri  = "auditlog.assetManager:#args.action#.message"
		, data = [ args.userLink, folderLink ]
	);
</cfscript>

<cfoutput>
	<cfif Len( Trim( args.iconClass ) )>
		<i class="fa fa-fw fa-lg #args.iconClass#"></i>
	</cfif>

	#message#
</cfoutput>