<cfparam name="args.crumbs" type="array" />
<cfparam name="args.page"   type="any" />

<cfif args.page.getId() neq "/home">
	<cfoutput>
		<ul class="breadcrumb margin-no-top margin-right margin-no-bottom margin-left">
			<li><a href="index.html">Home</a></li>
			<cfloop array="#args.crumbs#" item="pageSlug" index="i">
				<li>[[#pageSlug#]]</li>
			</cfloop>
			<li class="active">#HtmlEditFormat( args.page.getTitle() )#</li>
		</ul>
	</cfoutput>
</cfif>