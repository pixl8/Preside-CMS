<cfparam name="args.children"             type="array"  />
<cfparam name="args.id"                   type="string" />
<cfparam name="args.title"                type="string" />
<cfparam name="args.exclude_from_sitemap" type="any"    />
<cfparam name="args.active"               type="any"    />

<cfif IsFalse( args.exclude_from_sitemap ) && IsTrue( args.active )>
	<cfoutput>
		<li>
			<a href="#event.buildLink( page=args.id )#">#args.title#</a>
			<cfif args.children.len()>
				<ul class="list-unstyled">
					<cfloop array="#args.children#" item="page" index="i">
						#renderView( view="/core/navigation/_htmlSiteMapPage", args=page )#
					</cfloop>
				</ul>
			</cfif>
		</li>
	</cfoutput>
</cfif>