<cfscript>
	link      = args.link      ?: "";
	target    = args.target    ?: "";
	icon      = args.icon      ?: "";
	title     = args.title     ?: "";
	prompt    = args.prompt    ?: "";
	match     = args.match     ?: "";
	linkClass = args.linkClass ?: "";
	liClass   = args.liClass   ?: "";
	children  = args.children  ?: [];

	linkAttributes = renderHtmlAttributes( attribs=( args.linkAttributes ?: {} ), attribPrefix=( args.linkAttributePrefix ?: "" ) );

	hasSubMenu = ArrayLen( children );

	if ( Len( prompt ) && !Find( "confirmation-prompt", linkClass ) ) {
		linkClass &= " confirmation-prompt";
	}
	if ( hasSubMenu && !Find( "dropdown-menu-anchor", linkClass ) ) {
		linkClass &= " dropdown-menu-anchor";
		liClass   &= " dropdown dropdown-hover";
	}
</cfscript>

<cfoutput>
	<li class="#liClass#">
		<a<cfif Len( link )> href="#link#"</cfif><cfif Len( target )> target="#target#"</cfif> class="#linkClass#" <cfif Len( prompt )> title="#HtmlEditFormat( prompt )#"</cfif> <cfif Len( match )> data-confirmation-match="#match#"</cfif> #linkAttributes#>
			<cfif Len( icon )>
				<i class="fa fa-fw #icon#"></i>&nbsp;
			</cfif>

			#title#

			<cfif hasSubMenu>
				<i class="fa fa-caret-right dropdown-menu-caret"></i>
			</cfif>
		</a>
		<cfif hasSubMenu>
			<ul class="dropdown-menu">
				<cfloop array="#children#" item="child" index="n">
					<cfif IsSimpleValue( child )>
						<cfif ReFind( "^-+$", child )> <!--- e.g. "-", "---", etc. --->
							<li class="divider"></li>
						<cfelse>
							#child#
						</cfif>
					<cfelse>
						#renderView( view="/admin/datamanager/_topRightButtonChildItem", args=child )#
					</cfif>
				</cfloop>
			</ul>
		</cfif>
	</li>
</cfoutput>