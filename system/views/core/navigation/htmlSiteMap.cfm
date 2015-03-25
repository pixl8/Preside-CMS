<cfparam name="args.tree" type="array" />

<cfoutput>
	<ul class="list-unstyled">
		<li>
			<a href="#event.buildLink( page=args.tree[1].id )#">#args.tree[1].title#</a>
		</li>
		<cfloop array="#args.tree[1].children#" item="page" index="i">
			#renderView( view="/core/navigation/_htmlSitemapPage", args=page )#
		</cfloop>
	</ul>
</cfoutput>