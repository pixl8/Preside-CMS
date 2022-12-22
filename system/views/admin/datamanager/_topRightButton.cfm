<cfscript>
	link      = args.link      ?: "";
	globalKey = args.globalKey ?: "";
	btnClass  = args.btnClass  ?: "";
	iconClass = args.iconClass ?: "";
	title     = args.title     ?: "";
	prompt    = args.prompt    ?: "";
	children  = args.children  ?: [];
	target    = args.target    ?: "";
	match     = args.match     ?: "";
</cfscript>

<cfoutput>
	<cfif !children.len()>
		<a class="pull-right btn #btnClass# btn-sm inline<cfif prompt.len()> confirmation-prompt</cfif>" href="#link#" data-global-key="#globalKey#"<cfif prompt.len()> title="#HtmlEditFormat( prompt )#"</cfif><cfif target.len()> target="#target#"</cfif><cfif match.len()> data-confirmation-match="#match#"</cfif>>
			<cfif !isEmpty(iconClass)><i class="fa fa-fw #iconClass#"></i></cfif>
			#title#
		</a>
	<cfelse>
		<div class="btn-group<cfif Len( link )> primary-action-with-dropdown</cfif> pull-right">
			<cfif Len( link )>
				<a class="btn #btnClass# btn-sm inline<cfif prompt.len()> confirmation-prompt</cfif>" href="#link#" data-global-key="#globalKey#"<cfif prompt.len()> title="#HtmlEditFormat( prompt )#"</cfif><cfif target.len()> target="#target#"</cfif><cfif match.len()> data-confirmation-match="#match#"</cfif>>
					<cfif !isEmpty(iconClass)><i class="fa fa-fw #iconClass#"></i></cfif>
					#title#
				</a>
				<button data-toggle="dropdown" class="btn btn-sm #btnClass# inline dropdown-toggle">
					<span class="fa fa-caret-down"></span>
				</button>
			<cfelse>
				<button data-toggle="dropdown" class="btn btn-sm #btnClass# inline">
					<span class="fa fa-caret-down"></span>
					<cfif !isEmpty(iconClass)><i class="fa #iconClass#"></i>&nbsp; </cfif>#title#
				</button>
			</cfif>

			<ul class="dropdown-menu" role="menu" aria-labelledby="dLabel">
				<cfloop array="#children#" item="child" index="i">
					<cfif IsSimpleValue( child )>
						<cfif child eq "---">
							<li class="divider"></li>
						<cfelse>
							#child#
						</cfif>
					<cfelse>
						<li>
							<a href="#( child.link ?: '' )#"<cfif ( child.target ?: "" ).len()> target="#target#"</cfif> class="<cfif Len( child.prompt ?: "") > confirmation-prompt</cfif>" <cfif Len( child.prompt ?: "")> title="#HtmlEditFormat( child.prompt )#"</cfif> <cfif Len( child.match ?: "")> data-confirmation-match="#child.match#"</cfif>>
								<cfif ( child.icon ?: '' ).len()>
									<i class="fa fa-fw #( child.icon ?: '' )#"></i>&nbsp;
								</cfif>
								#( child.title ?: "" )#
							</a>
						</li>
					</cfif>
				</cfloop>
			</ul>
		</div>
	</cfif>
</cfoutput>