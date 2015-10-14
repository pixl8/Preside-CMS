<cfparam name="args.page" type="page" />

<cfset pg = args.page />
<cfset currentLetter = "" />

<cfoutput>
	<a class="pull-right" href="#getSourceLink( path=pg.getSourceFile() )#" title="Improve the docs"><i class="fa fa-pencil fa-fw"></i></a>
	#markdownToHtml( pg.getBody() )#

	<div class="tile-wrap tile-wrap-animation">
		<cfloop array="#pg.getChildren()#" index="i" item="child">
			<cfset slug = child.getSlug() />
			<cfset firstLetter = slug[1] />
			<cfif firstLetter != currentLetter>
				<cfif currentLetter.len()>
						</div>
					</div>
				</cfif>
				<div class="tile tile-collapse tile-collapse-full">
					<div class="tile-toggle" data-target="##function-#LCase( firstLetter )#" data-toggle="tile">
						<div class="tile-inner">
							<div class="text-overflow"><strong>#UCase( firstLetter )#</strong></div>
						</div>
					</div>
					<div class="tile-active-show collapse" id="function-#LCase( firstLetter )#">
			</cfif>

			<span class="tile">
				<div class="tile-inner">
					<div class="text-overflow">[[#child.getId()#]]</div>
				</div>
			</span>

			<cfset currentLetter = firstLetter />
		</cfloop>
	</div>
</cfoutput>