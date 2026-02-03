<!---@feature admin--->
<cfparam name="args.active"     type="boolean" default="false" />
<cfparam name="args.id"         type="string"  default="" />
<cfparam name="args.link"       type="string"  default="" />
<cfparam name="args.title"      type="string"  default="" />
<cfparam name="args.icon"       type="string"  default="" />
<cfparam name="args.subMenu"    type="string"  default="" />
<cfparam name="args.gotoKey"    type="string"  default="" />
<cfparam name="args.separator"  type="boolean" default="false" />
<cfparam name="args.dropdownDirection" type="string" default="right" />

<cfscript>
	hasSubMenu = Len( args.subMenu ?: "" );
	if ( hasSubMenu ) {
		if ( args.dropdownDirection == "right" ) {
			dropdownClass = "dropdown-menu-left";
		} else {
			args.dropdownDirection = "left";
			dropdownClass = "dropdown-menu-right";
		}
	}
</cfscript>

<cfoutput>
	<cfif args.separator>
		<li class="divider"></li>
	<cfelse>
		<cfif hasSubMenu>
			<li class="dropdown dropdown-hover<cfif args.active> active</cfif>" data-item-id="#args.id#">
				<a href="##" class="dropdown-menu-anchor">
					<i class="dropdown-menu-icon fa fa-fw #args.icon#"></i>
					<span class="dropdown-menu-title">#args.title#</span>
					<i class="fa fa-caret-#LCase( args.dropdownDirection )# dropdown-menu-caret"></i>
				</a>
				<ul class="dropdown-menu #dropdownClass#">
					#args.subMenu#
				</ul>
			</li>
		<cfelse>
			<li<cfif args.active> class="active"</cfif> data-item-id="#args.id#">
				<a href="#args.link#"<cfif Len( Trim( args.gotoKey ) )> data-goto-key="#args.gotoKey#"</cfif>>
					<i class="menu-icon fa fa-fw #args.icon#"></i>
					#args.title#
				</a>
			</li>
		</cfif>
	</cfif>
</cfoutput>