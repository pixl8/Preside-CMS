<cfparam name="args.link"    type="string"  default="" />
<cfparam name="args.title"   type="string"  default="" />

<cfoutput>
	<li>
		<a href="#args.link#">
			<i class="fa fa-angle-double-right"></i>
			#args.title#
		</a>
	</li>
</cfoutput>