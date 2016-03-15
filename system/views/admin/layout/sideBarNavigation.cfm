<cfscript>
	handler = event.getCurrentHandler();
	sidebarItems = getSetting( "adminSideBarItems" );
</cfscript>


<cfoutput>
	<div class="sidebar" id="sidebar">
		<script type="text/javascript">
			try{ace.settings.check('sidebar' , 'fixed')}catch(e){}
		</script>

		<ul class="nav nav-list">
			<cfloop array="#sidebarItems#" item="item" index="i">
				#renderView( view="admin/layout/sidebar/#item#" )#
			</cfloop>
		</ul>

		<div class="sidebar-collapse sidebar-toggle" id="sidebar-collapse">
			<i class="fa fa-angle-double-left" data-icon1="fa fa-angle-double-left" data-icon2="fa fa-angle-double-right"></i>
		</div>

		<script type="text/javascript">
			try{ace.settings.check('sidebar' , 'collapsed')}catch(e){}
		</script>
	</div>
</cfoutput>