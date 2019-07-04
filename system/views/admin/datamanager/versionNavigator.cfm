<cfscript>
	param name="args.prevVersion"            type="numeric";
	param name="args.nextVersion"            type="numeric";
	param name="args.latestPublishedVersion" type="numeric";
	param name="args.object"                 type="string";
	param name="args.id"                     type="string";
	param name="args.version"                type="string";
	param name="args.isDraft"                type="boolean" default=false;
	param name="args.isLatest"               type="boolean";
	param name="args.baseUrl"                type="string" default="#event.buildAdminLink( objectName=args.object, recordId=args.id, operation='editRecord', args={ version='{version}' } )#";
	param name="args.allVersionsUrl"         type="string" default="#event.buildAdminLink( objectName=args.object, recordId=args.id, operation='recordHistory' )#";
	param name="args.discardDraftsUrl"       type="string" default="";

	objectTitleSingular = translateResource( uri="preside-objects.#args.object#:title.singular", defaultValue="record" );

	if ( args.isDraft ) {
		alertClass   = "warning";
		alertMessage = translateResource( uri="cms:version.navigator.#( args.isLatest ? 'latest.draft.version.message' : 'old.draft.version.message' )#", data=[  objectTitleSingular  ] );
	} else {
		isLatestPublished = args.version == args.latestPublishedVersion;
		alertClass        = args.isLatest || isLatestPublished ? "success" : "warning";

		if ( !args.isLatest && isLatestPublished ) {
			alertMessage = translateResource( uri="cms:version.navigator.current.published.version.message", data=[  objectTitleSingular  ] );
		} else {
			alertMessage = translateResource( uri="cms:version.navigator.#( args.isLatest ? 'current.version.message' : 'old.version.message' )#", data=[  objectTitleSingular  ] );
		}
	}
</cfscript>

<cfif args.prevVersion or args.nextVersion>
	<cfoutput>
		<div class="version-navigator clearfix alert alert-block alert-#alertClass#">
			<p class="pull-left">
				<i class="fa fa-history fa-lg fa-fw"></i> #alertMessage#

				<cfif args.isDraft && args.isLatest && args.latestPublishedVersion && Len( args.discardDraftsUrl )>
					<br><br>
					<i class="fa fa-fw fa-lg"></i>
					<a href="#args.discardDraftsUrl#" class="btn btn-sm btn-danger confirmation-prompt" title="#HtmlEditFormat( translateResource( 'cms:discard.draft.confirmation' ) )#"><i class="fa fa-fw fa-trash"></i> #translateResource( "cms:discard.drafts.btn" )#</a>
				</cfif>
			</p>

			<div class="pull-right">
				<cfif args.prevVersion>
					<a href="#args.baseUrl.replace( '{version}', args.prevVersion )#" title="#HtmlEditFormat( translateResource( 'cms:version.navigator.prev.title' ) )#"><i class="fa fa-lg fa-arrow-circle-o-left"></i></a>
				<cfelse>
					<i class="fa fa-lg fa-arrow-circle-o-left disabled"></i>
				</cfif>

				<a href="#args.allVersionsUrl#" title="#HtmlEditFormat( translateResource( 'cms:version.navigator.viewall.title' ) )#"><i class="fa fa-lg fa-ellipsis-h"></i></a>

				<cfif args.nextVersion>
					<a href="#args.baseUrl.replace( '{version}', args.nextVersion )#" title="#HtmlEditFormat( translateResource( 'cms:version.navigator.next.title' ) )#"><i class="fa fa-lg fa-arrow-circle-o-right"></i></a>
				<cfelse>
					<i class="fa fa-lg fa-arrow-circle-o-right disabled"></i>
				</cfif>
			</div>
		</div>
	</cfoutput>
</cfif>