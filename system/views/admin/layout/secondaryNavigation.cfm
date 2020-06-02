<cfparam name="args.items" type="array">

<cfoutput>
	<div class="sidebar h-sidebar navbar-collapse collapse ace-save-state">
		<ul class="nav nav-list">
			<cfloop array="#args.items#" item="item" index="i">
				#renderView( view="/admin/layout/sidebar/_menuItem", args=item )#
			</cfloop>
		</ul>
	</div>
</cfoutput>