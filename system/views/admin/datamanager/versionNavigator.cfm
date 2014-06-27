<cfscript>
	param name="args.prevVersion"    type="numeric";
	param name="args.nextVersion"    type="numeric";
	param name="args.object"         type="string";
	param name="args.version"        type="string";
	param name="args.versions"       type="query";
	param name="args.baseUrl"        type="string" default="#event.buildAdminLink( linkTo='datamanager.editRecord'   , queryString='object=#args.object#&id=#args.id#&version=' )#";
	param name="args.allVersionsUrl" type="string" default="#event.buildAdminLink( linkTo='datamanager.recordHistory', queryString='object=#args.object#&id=#args.id#' )#";

	objectTitleSingular = translateResource( uri="preside-objects.#args.object#:title.singular", defaultValue="record" );
</cfscript>

<cfif args.versions.recordCount gt 1>
	<cfoutput>
		<div class="version-navigator clearfix alert alert-block alert-#( args.nextVersion ? 'warning' : 'success' )#">
			<p class="pull-left">
				<i class="fa fa-history fa-lg"></i>
				&nbsp;
				#translateResource( uri="cms:version.navigator.#( args.nextVersion ? 'old.version.message' : 'current.version.message' )#", data=[ LCase( objectTitleSingular ) ] )#
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