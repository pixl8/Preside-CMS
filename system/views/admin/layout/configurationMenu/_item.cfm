<cfparam name="args.active"       type="boolean" default="false" />
<cfparam name="args.link"         type="string"  default="" />
<cfparam name="args.title"        type="string"  default="" />
<cfparam name="args.icon"         type="string"  default="" />
<cfparam name="args.subMenu"      type="string"  default="" />
<cfparam name="args.subMenuItems" type="array"   default="#ArrayNew(1)#" />
<cfparam name="args.gotoKey"      type="string"  default="" />

<cfoutput>
	<li<cfif args.active> class="active"</cfif>>
		<a href="#args.link#"<cfif Len( Trim( args.gotoKey ) )> data-goto-key="#args.gotoKey#"</cfif>>
			<i class="menu-icon fa fa-fw #args.icon#"></i>
			#args.title#
		</a>

		<!--- TODO: figure out submenu render --->
	</li>
</cfoutput>