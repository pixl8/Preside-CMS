<cfparam name="args.active"       type="boolean" default="false" />
<cfparam name="args.link"         type="string"  default="" />
<cfparam name="args.title"        type="string"  default="" />
<cfparam name="args.icon"         type="string"  default="" />
<cfparam name="args.subMenu"      type="string"  default="" />
<cfparam name="args.subMenuItems" type="array"   default="#ArrayNew(1)#" />
<cfparam name="args.gotoKey"      type="string"  default="" />

<cfoutput>
	<li<cfif args.active> class="active"</cfif>>
		<cfif Len( Trim( args.subMenu ) ) or args.subMenuItems.len()>
			<a class="dropdown-toggle" href="##">
				<i class="menu-icon fa fa-fw #args.icon#"></i>
				<span class="menu-text">#args.title#</span>
				<b class="arrow fa fa-angle-down"></b>
			</a>
		<cfelse>
			<a href="#args.link#"<cfif Len( Trim( args.gotoKey ) )> data-goto-key="#args.gotoKey#"</cfif>>

				<i class="menu-icon fa fa-fw #args.icon#"></i>
				<span class="menu-text">#args.title#</span>
			</a>
		</cfif>

		<cfif Len( Trim( args.subMenu ) )>
			<ul class="submenu">#args.subMenu#</ul>
		<cfelseif args.subMenuItems.len()>
			<ul class="submenu">
				<cfloop array="#args.subMenuItems#" item="item" index="i">
					#renderView( view="/admin/layout/sidebar/_subMenuItem", args=item )#
				</cfloop>
			</ul>
		</cfif>
	</li>
</cfoutput>
