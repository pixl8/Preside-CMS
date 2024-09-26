<!---@feature admin--->
<cfparam name="args.active"       type="boolean" default="false" />
<cfparam name="args.link"         type="string" default="" />
<cfparam name="args.title"        type="string" default="" />
<cfparam name="args.gotoKey"      type="string" default="" />
<cfparam name="args.separator"    type="boolean" default="false" />
<cfparam name="args.subMenu"      type="string" default="" />
<cfparam name="args.submenuItems" type="array"  default="#ArrayNew(1)#" />

<cfscript>
	hasSubMenu = Len( Trim( args.subMenu ) ) || ArrayLen( args.submenuItems );
	menuClass = "";

	if ( args.active ) {
		menuClass = "active";
		if ( hasSubMenu ) {
			menuClass &= " open";
		}
	}
</cfscript>

<cfoutput>
	<cfif !args.separator>
		<li class="#menuClass#">

			<cfif hasSubMenu>
				<a href="##" class="dropdown-toggle">
					#args.title#
					<b class="arrow fa fa-angle-down"></b>
				</a>
			<cfelse>
				<a href="#args.link#"<cfif Len( Trim( args.gotoKey ) )> data-goto-key="#args.gotoKey#"</cfif>>
					<i class="menu-icon fa fa-angle-double-right"></i>
					#args.title#
				</a>
			</cfif>

			<cfif Len( Trim( args.subMenu ) )>
				<ul class="submenu">
					#args.subMenu#
				</ul>
			<cfelseif args.subMenuItems.len()>
				<ul class="submenu">
					<cfloop array="#args.subMenuItems#" item="item" index="i">
						#renderView( view="/admin/layout/sidebar/_subMenuItem", args=item )#
					</cfloop>
				</ul>
			</cfif>
		</li>
	</cfif>
</cfoutput>