<cfparam name="args.translations"     type="array"  />
<cfparam name="args.translateUrlBase" type="string" />

<cfoutput>
	<cfif !arrayIsEmpty( args.translations )>
		<cfloop index="arrayIndex" from="1" to="3">
			<span class="text-center <cfif args.translations[arrayIndex].status eq 'active'>text-success<cfelseif args.translations[arrayIndex].status eq 'inprogress'>text-warning<cfelse>text-danger</cfif>">
				#args.translations[arrayIndex].iso_code#
			</span>
		</cfloop>
		<div class="action-buttons btn-group">
			<cfif arraylen(args.translations) GT 3>
				<a data-toggle="dropdown"><span class="fa fa-caret-down"></span></a>
				<ul class="dropdown-menu pull-right">
					<cfloop array="#args.translations#" item="language">
						<li>
							<a data-context-key="h" href="#args.translateUrlBase##language.id#">
								<span class="text-left <cfif language.status eq 'active'>text-success<cfelseif language.status eq 'inprogress'>text-warning<cfelse>text-danger</cfif>">
									<i class="fa fa-fw fa-pencil"></i>#language.name# ( #language.status# )
								</span>
							</a>
						</li>
					</cfloop>
				</ul>
			</cfif>
		</div>
	</cfif>
</cfoutput>