<cfscript>
	itemsBySection = args.itemsBySection ?: [];
</cfscript>

<cfoutput>
	<ul class="list-unstyled">
		<cfif !itemsBySection.len()>
			<li class="section empty">
				<div class="instructions">
					<p>#translateResource( "formbuilder:manage.empty.form.notice")#</p>
					<i class="fa fa-fw fa-lg fa-plus blue"></i>
				</div>
				<ul class="list-unstyled items">
				</ul>
			</li>
		<cfelse>
			<!--- TODO --->
		</cfif>
	</ul>
</cfoutput>