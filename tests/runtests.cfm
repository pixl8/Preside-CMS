<cfscript> 
	reporter  = url.reporter  ?: "raw";
	scope     = url.scope     ?: "full";
	directory = url.directory ?: "";
	testbox   = new testbox.system.TestBox( options={}, reporter=reporter, directory={
		  recurse  = true
		, mapping  = Len( directory ) ? "integration.api.#directory#" : "integration"
		, filter   = function( required path ){
			if ( scope=="quick" ) {
				var excludes = [
					  "presideObjects/PresideObjectServiceTest"
					, "security/CsrfProtectionServiceTest"
					, "admin/LoginServiceTest"
					, "admin/AuditServiceTest"
					, "sitetree/SiteServiceTest"
				];
				for( var exclude in excludes ) {
					if ( ReFindNoCase( listLast( exclude, "/" ), path ) ) {
						return false;
					}
				}
				return true;
			}
			return true;
		}
	} );
	TAB=chr(9);
	NL = chr(13);
	failedTestCases= [];
	
	// strips off the stack trace to exclude testbox and back to the first .cfc call in the stack
	public array function trimJavaStackTrace( required string st ){
		local.tab = chr( 9 );
		local.stack = [];
		local.i = find( "/testbox/", arguments.st );
		if ( request.testDebug ?: false || i eq 0 ){ // dump it all out
			arrayAppend( stack, TAB & arguments.st );
			return stack;
		}
		local.tmp = mid( arguments.st, 1, i ); // strip out anything after testbox
		local.tmp2 = reverse( local.tmp );
		local.i = find( ":cfc.", local.tmp2 ); // find the first cfc line
		if ( local.i gt 0 ){
			local.i = len( local.tmp )-i;
			local.j = find( ")", local.tmp, local.i ); // find the end of the line
			if ( local.j > 0 )
				local.tmp = mid( local.tmp, 1, local.j );
		}
		arrayAppend( stack, TAB & local.tmp );
		
		local.firstCausedBy = find( "Caused by:", arguments.st );
		if ( firstCausedBy gt 0 ) {
			arrayAppend( stack, TAB & TAB & TAB & "... omitted verbose (ant / pagecontext / testbox) default stacktraces ... " );
			arrayAppend( stack, mid( arguments.st, firstCausedBy) );
		}
		return stack;
	}

	struct function reportMem( string type, struct prev={}, string name="" ) {
		var qry = getMemoryUsage( type );
		var report = [];
		var used = { name: arguments.name };
		querySort(qry,"type,name");
		loop query=qry {
			if (qry.max == -1)
				var perc = 0;
			else 
				var perc = int( ( qry.used / qry.max ) * 100 );
			//if(qry.max<0 || qry.used<0 || perc<90) 	continue;
			//if(qry.max<0 || qry.used<0 || perc<90) 	continue;
			var rpt = replace(ucFirst(qry.type), '_', ' ')
				& " " & qry.name & ": " & numberFormat(perc) & "%, " & numberFormat( qry.used / 1024 / 1024 ) & " Mb";
			if ( structKeyExists( arguments.prev, qry.name ) ) {
				var change = numberFormat( (qry.used - arguments.prev[ qry.name ] ) / 1024 / 1024 );
				if ( change gt 0 ) {
					rpt &= ", (+ " & change & "Mb )";
				} else if ( change lt 0 ) {
					rpt &= ", ( " & change & "Mb )";
				}
			}
			arrayAppend( report, rpt );
			used[ qry.name ] = qry.used;
		}
		return {
			report: report,
			usage: used
		};
	}

	// report current memory usage
	_reportMemStat = reportMem( "", {}, "bootup" );

	request._start = getTickCount();
	request._tick = getTickCount();
	request.overhead = [];
	
	try {
		silent {
			result = testbox.run(
				callbacks = {
					onBundleStart = function( cfc, testResults ){
						var meta = getComponentMetadata( cfc );
						systemOutput( TAB & meta.name & " ", false );
					},
					onBundleEnd = function( cfc, testResults ){
						var bundle = arrayLast( testResults.getBundleStats() );
						var oh = ( getTickCount() - request._tick )-bundle.totalDuration;
						request._tick = getTickCount();
						ArrayAppend( request.overhead, oh );
						if ( bundle.totalPass eq 0 && ( bundle.totalFail + bundle.totalError ) eq 0 ){
							systemOutput( TAB & " (skipped)", true );
						} else {
							var didntPassSummary = (bundle.totalSkipped gt 0) ? ", #bundle.totalSkipped# skipped" : "";
							if ( bundle.totalError > 0 ){
								didntPassSummary &= ", #bundle.totalError# ERRORED";
							}
							if ( bundle.totalFail > 0 ){
								didntPassSummary &= ", #bundle.totalFail# FAILED";
							}
							systemOutput( TAB & " ( #bundle.totalPass# test#bundle.totalPass>1?"s":""# passed in #NumberFormat(bundle.totalDuration)# ms#didntPassSummary# )", true );
						}
						if ( ( bundle.totalFail + bundle.totalError ) > 0 ) {

							systemOutput( "ERRORED" & NL & "	Suites/Specs: #bundle.totalSuites#/#bundle.totalSpecs#
	Failures: #bundle.totalFail#
	Errors:   #bundle.totalError#
	Pass:     #bundle.totalPass#
	Skipped:  #bundle.totalSkipped#"
							, true );
							
							if ( !isNull( bundle.suiteStats ) ) {
								loop array=bundle.suiteStats item="local.suiteStat" {
									local.specStats = duplicate(suiteStat.specStats);
									// spec stats are also nested 
									loop array=suiteStat.suiteStats item="local.nestedSuiteStats" {
										if ( !isEmpty( local.nestedSuiteStats.specStats ) ) {
											loop array=local.nestedSuiteStats.specStats item="local.nestedSpecStats" {
												arrayAppend( local.specStats, local.nestedspecStats );
											}
										}
									}
				
									if ( isEmpty( local.specStats ) ) {
										systemOutput( "WARNING: suiteStat for [#bundle.name#] was empty?", true );
									} else {
										loop array=local.specStats item="local.specStat" {
											if ( !isNull( specStat.failMessage ) && len( trim( specStat.failMessage ) ) ) {
				
												var failedTestCase = {
													type       : "Failed"
													,bundle     : bundle.name
													,testCase   : specStat.name
													,errMessage : specStat.failMessage
													,cfmlStackTrace : []
													,stackTrace : ""
												};
												if ( structKeyExists( specStat.error, "stackTrace" ) )
													failedTestCase.stackTrace = specStat.error.stackTrace;
				
												failedTestCases.append( failedTestCase );
				
												systemOutput( NL & specStat.name );
												systemOutput( NL & TAB & "Failed: " & specStat.failMessage, true );
												//systemOutput( specStat, true);
												if ( !isNull( specStat.failOrigin ) && !isEmpty( specStat.failOrigin ) ){
				
													var rawStackTrace = specStat.failOrigin;
													//var testboxPath = getDirectoryFromPath( rawStackTrace[1].template );
													var testboxPath = "/testbox/";
				
													//systemOutput(TAB & TAB & "at", true);
													
													//systemOutput( rawStackTrace, true);
													//systemOutput( testboxPath, true);
				
													loop array=rawStackTrace item="local.st" index="local.i" {
				
														if ( !st.template.hasPrefix( testboxPath ) ){
															if ( local.i eq 1 or st.template does not contain "testbox" ){
																var frame = st.template & ":" & st.line;
																failedTestCase.cfmlStackTrace.append( frame );
																systemOutput( TAB & frame, true );
															}
														}
													}
												}
												systemOutput( NL );
											} // if !isNull
				
											if ( !isNull( specStat.error ) && !isEmpty( specStat.error ) ){
				
												var failedTestCase = {
													type       : "Errored"
													,bundle     : bundle.name
													,testCase   : specStat.name
													,errMessage : specStat.error.Message
													,cfmlStackTrace : []
													,stackTrace : ""
												};
												if ( structKeyExists( specStat.error, "stackTrace" ) )
													failedTestCase.stackTrace = specStat.error.stackTrace;
				
												failedTestCases.append( failedTestCase );
				
												systemOutput( NL & specStat.name );
												systemOutput( NL & TAB & "Errored: " & specStat.error.Message, true );
												if ( len( specStat.error.Detail ) )
													systemOutput( TAB & "Detail: " & specStat.error.Detail, true );

												//systemOutput(specStat.error, true);
				
												if ( !isNull( specStat.error.TagContext ) && !isEmpty( specStat.error.TagContext ) ){
				
													var rawStackTrace = specStat.error.TagContext;
				
													//systemOutput(TAB & TAB & "at", true);
				
													loop array=rawStackTrace item="local.st" index="local.i" {
														if ( local.i eq 1 or st.template does not contain "testbox" ){
															var frame = st.template & ":" & st.line;
															failedTestCase.cfmlStackTrace.append( frame );
															systemOutput( TAB & frame, true );
														}
													}
													systemOutput( NL );
													/*
													if (arrayLen(rawStackTrace) gt 0){
														systemOutput(TAB & rawStackTrace[1].codePrintPlain, true);
														systemOutput(NL);
													}
													*/
												}
												if ( !isNull( specStat.error.stackTrace ) && !isEmpty( specStat.error.stackTrace ) ){
													systemOutput( TAB & specStat.error.type, true );
													// printStackTrace( specStat.error.stackTrace );
													//systemOutput( TAB & specStat.error.stackTrace, true );
													var arrStack = trimJavaStackTrace( specStat.error.stackTrace );
													loop array=arrStack item="s"{
														systemOutput( TAB & s, true );
													}
													systemOutput( NL );
												}
				
											//	systemOutput(NL & serialize(specStat.error), true);
				
											} // if !isNull
										}
									}
								}
							} else {
								systemOutput( "WARNING: bundle.suiteStats was null?", true );
							}
							//systemOutput(serializeJson(bundle.suiteStats));
						}
						// report out any slow test specs, because for Lucee, slow performance is a bug (tm)
						if ( !isNull( bundle.suiteStats ) ) {
							loop array=bundle.suiteStats item="local.suiteStat" {
								if ( !isNull( suiteStat.specStats ) ) {
									loop array=suiteStat.specStats item="local.specStat" {
										if ( specStat.totalDuration gt 5000 )
											systemOutput( TAB & TAB & specStat.name & " took #numberFormat( specStat.totalDuration )#ms", true );
									}
								}
							}
						}

						// exceptions
						if ( !isSimpleValue( bundle.globalException ) ) {
							systemOutput( "Global Bundle Exception
							#bundle.globalException.type#
							#bundle.globalException.message#
							#bundle.globalException.detail#
		=============================================================
		Begin Stack Trace
		=============================================================
		#bundle.globalException.stacktrace#
		=============================================================
		End Stack Trace
		=============================================================", true);
						}

					}
				}
			);
			result = testbox.getResult();
		} // silent

		public string function identifyDatasource ( struct datasource ) localmode=true {
			dbinfo type="Version" datasource="#arguments.datasource#" name="verify";
			dbDesc = [];
			loop list="#verify.columnlist#" item="col" {
				ArrayAppend( dbDesc, verify[ col ] );
			}
			return ArrayToList( dbDesc, ", " );
		}

		results = [];
		results_md = ["## Preside CMS, Lucee #server.lucee.version# / Java #server.java.version#", ""];

		systemOutput( NL & NL & "=============================================================", true );
		arrayAppend( results, "Lucee Version: #server.lucee.version#");
		arrayAppend( results, "Java Version: #server.java.version#");
		arrayAppend( results, "Java Compiler Version: #server.java.javaCompilerVersion?:'unknown'#");
		arrayAppend( results, "Database: #identifyDatasource('preside_test_suite')#");
		arrayAppend( results, "TestBox Version: #testbox.getVersion()#");
		arrayAppend( results, "Total Execution time: (#NumberFormat( ( getTickCount()-request._start) / 1000 )# s)");
		arrayAppend( results, "Test Execution time: (#NumberFormat( result.getTotalDuration() /1000 )# s)");
		arrayAppend( results, "Average Test Overhead: (#NumberFormat( ArrayAvg( request.overhead ) )# ms)");
		arrayAppend( results, "Total Test Overhead: (#NumberFormat( ArraySum( request.overhead ) )# ms)");
		javaManagementFactory = createObject( "java", "java.lang.management.ManagementFactory" );
		threadCount = javaManagementFactory.getThreadMXBean().getThreadCount();
		arrayAppend( results, "Active Threads: #NumberFormat( threadCount )#");
		arrayAppend( results, "");
		postTestMeM = reportMem( "", _reportMemStat.usage );
		arrayAppend( results, postTestMeM.report, true );
		arrayAppend( results, "-- Force GC -- ");
		createObject( "java", "java.lang.System" ).gc();
		
		postTestGC = reportMem( "", postTestMeM.usage )
		arrayAppend( results, "");
		arrayAppend( results, postTestGC.report, true );
		
		
		
		arrayAppend( results, "");
		arrayAppend( results, "=============================================================" & NL);
		arrayAppend( results, "-> Bundles/Suites/Specs: #result.getTotalBundles()#/#result.getTotalSuites()#/#result.getTotalSpecs()#");
		arrayAppend( results, "-> Pass:     #result.getTotalPass()#");
		arrayAppend( results, "-> Skipped:  #result.getTotalSkipped()#");
		arrayAppend( results, "-> Failures: #result.getTotalFail()#");
		arrayAppend( results, "-> Errors:   #result.getTotalError()#");

		arrayAppend( results_md, "" );
		loop array=results item="summary"{
			systemOutput( summary, true );
			arrayAppend( results_md, summary );
		}
		arrayAppend( results_md, "" );

		if ( !isEmpty( failedTestCases ) ){
			for ( el in failedTestCases ){
				arrayAppend( results, el.type & ": " & el.bundle & NL & TAB & el.testCase );
				arrayAppend( results, TAB & el.errMessage );
				arrayAppend( results_md, "#### " & el.type & " " & el.bundle );
				arrayAppend( results_md, "###### " & el.testCase );
				arrayAppend( results_md, "" );
				arrayAppend( results_md, el.errMessage );

				if ( !isEmpty( el.cfmlStackTrace ) ){
					//arrayAppend( results, TAB & TAB & "at", true);
					for ( frame in el.cfmlStackTrace ){
						arrayAppend( results, TAB & TAB & frame );
						if ( false and structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
							file_ref = replace( frame, server.system.environment.GITHUB_WORKSPACE, "" );
							arrayAppend( results_md,
								"- [#file_ref#](#github_commit_base_href##replace(file_ref,":", "##L")#)"
								& " [branch](#github_branch_base_href##replace(file_ref,":", "##L")#)" );
						}
					}
				}

				if ( !isEmpty( el.stackTrace ) ){
					arrayAppend( results_md, "" );
					arrayAppend( results, NL );
					arrStack = trimJavaStackTrace( el.stackTrace );
					for (s in arrStack) {
						arrayAppend( results, s );
						arrayAppend( results_md, s );
					}
				}

				arrayAppend( results_md, "" );
				arrayAppend( results, NL );
			}
			arrayAppend( results_md, "" );
			arrayAppend( results, NL );
		}	

		if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
			fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, ArrayToList( results_md, NL ) );
		} else {
			content reset=true; echo( ArrayToList( results, NL ) );  // to browser
		}
		loop array=#results# item="resultLine" {
			systemOutput( resultLine, (resultLine neq NL) );
		}
		

	} catch( e ){
		systemOutput( "-------------------------------------------------------", true );
		// systemOutput( "Testcase failed:", true );
		systemOutput( e.message, true );
		systemOutput( ReReplace( Serialize( e.stacktrace ), "[\r\n]\s*([\r\n]|\Z)", Chr( 10 ) , "ALL" ), true ); // avoid too much whitespace from dump
		systemOutput( "-------------------------------------------------------", true );
		rethrow;
	}

	fails = arrayLen( failedTestCases );
	if ( fails > 0 )
		throw "#fails# test cases failed, exiting";
	else
		abort;
</cfscript>