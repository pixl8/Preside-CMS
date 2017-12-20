<cfscript>
	link      = args.link      ?: "";
	globalKey = args.globalKey ?: "";
	btnClass  = args.btnClass  ?: "";
	iconClass = args.iconClass ?: "";
	title     = args.title     ?: "";
</cfscript>
<cfoutput>
	<a class="pull-right inline" href="#link#" data-global-key="#globalKey#">
		<button class="btn #btnClass# btn-sm">
			<i class="fa fa-fw #iconClass#"></i>
			#title#
		</button>
	</a>
</cfoutput>