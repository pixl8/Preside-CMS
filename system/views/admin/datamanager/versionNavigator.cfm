<cfscript>
	param name="args.prevVersion"            type="numeric";
	param name="args.nextVersion"            type="numeric";
	param name="args.latestPublishedVersion" type="numeric";
	param name="args.object"                 type="string";
	param name="args.id"                     type="string";
	param name="args.version"                type="string";
	param name="args.isDraft"                type="boolean" default=false;
	param name="args.isLatest"               type="boolean";
	param name="args.versions"               type="query";
	param name="args.baseUrl"                type="string" default="#event.buildAdminLink( linkTo='datamanager.editRecord'   , queryString='object=#args.object#&id=#args.id#&version=' )#";
	param name="args.allVersionsUrl"         type="string" default="#event.buildAdminLink( linkTo='datamanager.recordHistory', queryString='object=#args.object#&id=#args.id#' )#";
	param name="args.publishUrl"             type="string" default="";
	param name="args.discardDraftsUrl"       type="string" default="";

	objectTitleSingular = translateResource( uri="preside-objects.#args.object#:title.singular", defaultValue="record" );

	if ( args.isDraft ) {
		alertClass   = "warning";
		alertMessage = translateResource( uri="cms:version.navigator.#( args.isLatest ? 'latest.draft.version.message' : 'old.draft.version.message' )#", data=[ LCase( objectTitleSingular ) ] );
	} else {
		isLatestPublished = args.version == args.latestPublishedVersion;
		alertClass        = args.isLatest || isLatestPublished ? "success" : "warning";

		if ( !args.isLatest && isLatestPublished ) {
			alertMessage = translateResource( uri="cms:version.navigator.current.published.version.message", data=[ LCase( objectTitleSingular ) ] );
		} else {
			alertMessage = translateResource( uri="cms:version.navigator.#( args.isLatest ? 'current.version.message' : 'old.version.message' )#", data=[ LCase( objectTitleSingular ) ] );
		}
	}
</cfscript>

<cfif args.versions.recordCount gt 1>
	<cfoutput>
		<div class="version-navigator clearfix alert alert-block alert-#alertClass#">
			<p class="pull-left">
				<i class="fa fa-history fa-lg fa-fw"></i> #alertMessage#

				<cfif args.isDraft && args.isLatest && Len( args.publishUrl & args.discardDraftsUrl )>
					<br><br>
					<i class="fa fa-fw fa-lg"></i>

					<cfif Len( Trim( args.publishUrl ) )>
						<a href="#args.publishUrl#" class="btn btn-sm btn-info confirmation-prompt" title="#HtmlEditFormat( translateResource( 'cms:publish.draft.confirmation' ) )#"><i class="fa fa-fw fa-check"></i> #translateResource( "cms:publish.draft.btn" )#</a>
					</cfif>
					<cfif args.latestPublishedVersion and Len( Trim( args.discardDraftsUrl ) )>
						<a href="#args.discardDraftsUrl#" class="btn btn-sm btn-danger confirmation-prompt" title="#HtmlEditFormat( translateResource( 'cms:discard.draft.confirmation' ) )#"><i class="fa fa-fw fa-trash"></i> #translateResource( "cms:discard.drafts.btn" )#</a>
					</cfif>
				</cfif>
			</p>

			<div class="pull-right">
				<cfif args.prevVersion>
					<a href="#args.baseUrl##args.prevVersion#" title="#HtmlEditFormat( translateResource( 'cms:version.navigator.prev.title' ) )#"><i class="fa fa-lg fa-arrow-circle-o-left"></i></a>
				<cfelse>
					<i class="fa fa-lg fa-arrow-circle-o-left disabled"></i>
				</cfif>

				<a href="#args.allVersionsUrl#" title="#HtmlEditFormat( translateResource( 'cms:version.navigator.viewall.title' ) )#"><i class="fa fa-lg fa-ellipsis-h"></i></a>

				<cfif args.nextVersion>
					<a href="#args.baseUrl##args.nextVersion#" title="#HtmlEditFormat( translateResource( 'cms:version.navigator.next.title' ) )#"><i class="fa fa-lg fa-arrow-circle-o-right"></i></a>
				<cfelse>
					<i class="fa fa-lg fa-arrow-circle-o-right disabled"></i>
				</cfif>
			</div>
		</div>
	</cfoutput>
</cfif>