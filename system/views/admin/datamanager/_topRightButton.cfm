<cfscript>
	link      = args.link      ?: "";
	globalKey = args.globalKey ?: "";
	btnClass  = args.btnClass  ?: "";
	iconClass = args.iconClass ?: "";
	title     = args.title     ?: "";
	prompt    = args.prompt    ?: "";
	children  = args.children  ?: [];
</cfscript>

<cfoutput>
	<cfif !children.len()>
		<a class="pull-right inline<cfif prompt.len()> confirmation-prompt</cfif>" href="#link#" data-global-key="#globalKey#"<cfif prompt.len()> title="#HtmlEditFormat( prompt )#"</cfif>>
			<button class="btn #btnClass# btn-sm">
				<i class="fa fa-fw #iconClass#"></i>
				#title#
			</button>
		</a>
	<cfelse>
		<button data-toggle="dropdown" class="btn btn-sm #btnClass# pull-right inline">
			<span class="fa fa-caret-down"></span>
			<i class="fa fa-fw #iconClass#"></i>&nbsp; #title#
		</button>

		<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
			<cfloop array="#children#" item="child" index="i">
				<li>
					<a href="#( child.link ?: '' )#">
						<i class="fa fa-fw #( child.icon ?: '' )#"></i>&nbsp; #( child.title ?: "" )#
					</a>
				</li>
			</cfloop>
		</ul>
	</cfif>
</cfoutput>