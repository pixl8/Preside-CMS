<cfparam name="args.page" type="page" />

<cfset pg = args.page />
<cfset currentLetter = "" />

<cfoutput>
	<a class="pull-right" href="#getSourceLink( path=pg.getSourceFile() )#" title="Improve the docs"><i class="fa fa-pencil fa-fw"></i></a>
	#markdownToHtml( pg.getBody() )#

	<div class="row row-clear">
		<cfloop array="#pg.getChildren()#" index="i" item="child">
			<cfset slug = child.getSlug() />
			<cfset firstLetter = slug[1] />
			<cfif firstLetter != currentLetter>
				<cfif currentLetter.len()>
						</ul>
					</div>
				</cfif>
				<div class="col-lg-3 col-md-4 col-sm-6 col-xx-12">
					<h2 class="content-sub-heading">#UCase( firstLetter )#</h2>
					<ul class="nav tile-wrap">
			</cfif>

			<li><a class="tile" href="#child.getId()#.html"><span class="text-overflow">#HtmlEditFormat( child.getTitle() )#</span></a></li>

			<cfset currentLetter = firstLetter />
		</cfloop>
		</ul></div>
	</div>
</cfoutput>