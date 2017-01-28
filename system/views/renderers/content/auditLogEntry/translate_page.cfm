<cfparam name="args.known_as"          type="string" />
<cfparam name="args.userLink"          type="string" />
<cfparam name="args.detail.id"         type="string" default="" />
<cfparam name="args.detail.page_type"  type="string" default="unknown" />
<cfparam name="args.detail.title"      type="string" default="unknown" />
<cfparam name="args.detail.languageId" type="string" default="" />

<cfscript>
	userLink     = '<a href="#args.userLink#">#args.known_as#</a>';
	pageType     = translateResource( "page-types.#args.detail.page_type#:name"     , args.detail.page_type );
	pageTypeIcon = translateResource( "page-types.#args.detail.page_type#:iconClass", "fa-file-o" );
	pageLink     = '<a href="#event.buildAdminLink( linkto="sitetree.editpage", querystring="id=" & args.detail.id  )#"><i class="fa fa-fw #pageTypeIcon#"></i> #args.detail.title#</a>';
	language     = renderLabel( objectName="multilingual_language", recordId=args.detail.languageId );
	message      = translateResource( uri="auditlog.sitetree:translate_page.message", data=[ userLink, pageLink, pagetype, language ] );
</cfscript>

<cfoutput>
	#message#
</cfoutput>