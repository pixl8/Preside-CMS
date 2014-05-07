<cfparam name="args.icon"     type="string" default="" />
<cfparam name="args.title"    type="string" default="" />
<cfparam name="args.subTitle" type="string" default="" />

<cfoutput>
	<div class="page-header">
		<h1>
			<cfif Len( Trim( args.icon ) )>
				<i class="fa fa-#args.icon#"></i>
			</cfif>

			#args.title#

			<cfif Len( Trim( args.subTitle ) )>
				<small>
					<i class="fa fa-angle-double-right"></i>
					#args.subTitle#
				</small>
			</cfif>
		</h1>
	</div><!-- /.page-header -->
</cfoutput>