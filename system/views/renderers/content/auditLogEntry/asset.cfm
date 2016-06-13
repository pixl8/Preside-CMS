<cfparam name="args.id"            type="string" />
<cfparam name="args.action"        type="string" />
<cfparam name="args.known_as"      type="string" />
<cfparam name="args.userLink"      type="string" />
<cfparam name="args.iconClass"     type="string" />
<cfparam name="args.detail.id"     type="string" default="" />
<cfparam name="args.detail.title"  type="string" default="unknown" />

<cfscript>
	assetUrl  = event.buildAdminLink( linkTo='assetmanager.editAsset', queryString='asset=' & args.detail.id );
	assetLink = '<a href="#assetUrl#">#args.detail.title#</a>';
	message = translateResource(
		  uri  = "auditlog.assetManager:#args.action#.message"
		, data = [ args.userLink, assetLink ]
	);
</cfscript>

<cfoutput>
	<p>
		<cfif Len( Trim( args.iconClass ) )>
			<i class="fa fa-fw fa-lg #args.iconClass#"></i>
		</cfif>

		#message#
	</p>

	<cfif Len( Trim( args.detail.id ) )>
		<a href="#assetUrl#">#renderAsset( assetId=args.detail.id, context="pickerIcon" )#</a>
	</cfif>
</cfoutput>