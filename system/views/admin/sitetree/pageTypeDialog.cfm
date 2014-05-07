<cfparam name="args.parent"    type="string" />
<cfparam name="args.pageTypes" type="array"  />

<cfset rootLink = event.buildAdminLink( linkTo="sitetree.addPage", querystring="parent_page=#args.parent#&page_type=" ) />

<cfoutput>
	<ul>
		<cfloop array="#args.pageTypes#" index="pageType">
			<li>
				<a href="#rootLink##pageType.getId()#">
					#translateResource( uri=pageType.getName(), defaultValue=pageType.getId() )#
				</a>
			</li>
		</cfloop>
	</ul>
</cfoutput>