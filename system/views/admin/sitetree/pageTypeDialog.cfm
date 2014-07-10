<cfparam name="rc.parentPage" type="string" default="" />
<cfparam name="prc.pageTypes" type="array"  />

<cfset rootLink = event.buildAdminLink( linkTo="sitetree.addPage", querystring="parent_page=#rc.parentPage#&page_type=" ) />

<cfoutput>
	<ul class="list-unstyled page-type-list">
		<cfloop array="#prc.pageTypes#" index="pageType">
			<li class="page-type">
				<h3 class="page-type-title">
					<a href="#rootLink##pageType.getId()#">
						<i class="page-type-icon fa fa-lg #translateResource( 'page-types.#pageType.getId()#:iconclass', 'fa-file-o' )#"></i>
						#translateResource( uri=pageType.getName(), defaultValue=pageType.getId() )#
					</a>
				</h3>
				<p>#translateResource( uri=pageType.getDescription(), defaultValue="" )#</p>
			</li>
		</cfloop>
	</ul>
</cfoutput>