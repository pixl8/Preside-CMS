<cfscript>
	pageType = rc.pageType ?: "";
	parentId = rc.parent   ?: "";

	objectTitle    = translateResource( uri="page-types.#pageType#:name", defaultValue=pageType );
	addRecordTitle = translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitle ) ] );
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="sitetree.addPage", queryString="parent_page=#parentId#&page_type=#pageType#" )#" data-global-key="a">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-plus"></i>
				#addRecordTitle#
			</button>
		</a>
	</div>
</cfoutput>