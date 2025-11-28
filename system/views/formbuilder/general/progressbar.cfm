<cfscript>
	formPageCount  = args.formPageCount  ?: 0;
	formPageNumber = args.formPageNumber ?: 0;
	formPageOffset = isTrue( args.configuration.use_summarypage ?: "" ) ? 1 : 0;

	progress = args.progress ?: Ceiling( ( ( formPageNumber - formPageOffset ) / formPageCount ) * 100 );
</cfscript>

<cfoutput>
	<div class="formbuilder-page-progress">
		<div class="progress-wrapper">
			<div class="progress">
				<div class="progress-bar" role="progressbar" aria-valuenow="#progress#" aria-valuemin="0" aria-valuemax="100" style="width: #progress#%;"></div>
			</div>
			<div class="progress-text" aria-label="#progress#%">
				#progress#%
			</div>
		</div>
	</div>
</cfoutput>