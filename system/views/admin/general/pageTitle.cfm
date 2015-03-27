<cfscript>
	param name="args.icon"     type="string" default="";
	param name="args.title"    type="string" default="";
	param name="args.subTitle" type="string" default="";

	icon = ReFind( "^fa\-", args.icon ) ? args.icon : "fa-#args.icon#";
</cfscript>

<cfoutput>
	<div class="page-header">
		<h1>
			<cfif Len( Trim( args.icon ) )>
				<i class="fa #icon#"></i>
			</cfif>

			#args.title#

			<cfif Len( Trim( args.subTitle ) )>
				<small>
					<i class="fa fa-angle-double-right"></i>
					<span class="page-subtitle">#args.subTitle#</span>
				</small>
			</cfif>
		</h1>
	</div><!-- /.page-header -->
</cfoutput>