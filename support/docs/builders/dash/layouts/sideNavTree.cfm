<cfparam name="args.pageLineage" type="array" />
<cfparam name="args.crumbs"      type="array" />
<cfparam name="args.docTree"     type="any" />

<cfoutput>
	<ul class="nav">
		<cfloop array="#args.docTree.getTree()#" item="firstLevelPage" index="i">
			<cfif firstLevelPage.getId() neq "/home" && firstLevelPage.getVisible()>
				<cfset firstLevelActive  = args.pageLineage.find( firstLevelPage.getId() ) />
				<cfset firstLevelCurrent = args.pageLineage[ args.pageLineage.len() ] == firstLevelPage.getId() />
				<li class="<cfif firstLevelActive>active</cfif> <cfif firstLevelCurrent>current</cfif>">

					[[#firstLevelPage.getId()#]]

					<cfset subIsOpen = firstLevelActive />
					<cfsavecontent variable="subnav">
						<cfloop array="#firstLevelPage.getChildren()#" item="secondLevelPage" index="n">
							<cfif secondLevelPage.getVisible()>
								<cfset secondLevelActive = args.pageLineage.find( secondLevelPage.getId() ) />
								<cfif secondLevelActive>
									<cfset subIsOpen = true />
								</cfif>
								<li<cfif secondLevelActive> class="active"</cfif>>[[#secondLevelPage.getId()#]]</li>
							</cfif>
						</cfloop>
					</cfsavecontent>


					<cfif Trim( subnav ).len()>
						<span class="menu-collapse-toggle <cfif !subIsOpen>collapsed</cfif>" data-target="###firstLevelPage.getId()#" data-toggle="collapse" aria-expanded="#subIsOpen#">
							<i class="icon icon-close menu-collapse-toggle-close"></i>
							<i class="icon icon-add menu-collapse-toggle-default"></i>
						</span>
						<ul class="menu-collapse <cfif subIsOpen>expand<cfelse>collapse</cfif>" id="#firstLevelPage.getId()#">
							#subnav#
						</ul>
					</cfif>
				</li>
			</cfif>
		</cfloop>
	</ul>
</cfoutput>