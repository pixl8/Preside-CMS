<cfparam name="args.active"  type="boolean" default="false" />
<cfparam name="args.link"    type="string"  default="" />
<cfparam name="args.title"   type="string"  default="" />
<cfparam name="args.gotoKey" type="string"  default="" />

<cfoutput>
	<li<cfif args.active> class="active"</cfif>>
		<a href="#args.link#"<cfif Len( Trim( args.gotoKey ) )> data-goto-key="#args.gotoKey#"</cfif>>
			<i class="menu-icon fa fa-angle-double-right"></i>
			#args.title#
		</a>
	</li>
</cfoutput>