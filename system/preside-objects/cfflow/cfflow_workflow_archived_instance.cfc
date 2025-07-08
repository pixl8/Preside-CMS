/**
 * @nolabel                        true
 * @versioned                      false
 * @tablePrefix                    ""
 * @useCache                       true
 * @feature                        cfflow
 * @labelrenderer                  cfflow_instance_label
 * @datamanagerEnabled             true
 * @datamanagerAllowedOperations   read
 * @datamanagerDefaultSortOrder    date_archived DESC, date_started
 */
component {
	property name="workflow_id"       type="string" dbtype="varchar" maxlength=100 required=true  indexes="workflowid" autofilter=false;
	property name="owner"             type="string" dbtype="varchar" maxlength=100 required=true  indexes="owner" renderer="webflowOwner";
	property name="reference"         type="string" dbtype="varchar" maxlength=100 required=true  indexes="reference,subreference|1";
	property name="sub_reference"     type="string" dbtype="varchar" maxlength=100 required=false indexes="subreference|2" renderer="webflowInstanceReference";
	property name="sub_sub_reference" type="string" dbtype="varchar" maxlength=100 required=false indexes="subreference|3";

	property name="completed"     type="boolean" dbtype="boolean" default=false indexes="completed";
	property name="state"         type="string" dbtype="longtext" autofilter=false;

	// for stats
	property name="archive_reason"        required=true  type="string"  dbtype="varchar" maxlength=20  indexes="archivereason" enum="cfflowArchiveReason";
	property name="time_taken"            required=true  type="numeric" dbtype="int"                   indexes="timetaken" renderer="webflowTimeTaken";
	property name="transition_count"      required=true  type="numeric" dbtype="int"                   indexes="transitioncount";
	property name="date_started"          required=true  type="date"    dbtype="datetime"              indexes="datestarted";
	property name="date_archived"         required=true  type="date"    dbtype="datetime"              indexes="datearchived";
	property name="active_steps"          required=false type="string"  dbtype="varchar" maxlength=255 indexes="currentsteps";
	property name="completed_steps_hash"  required=false type="string"  dbtype="varchar" maxlength=35  indexes="completedStepsHash";
	property name="step_transitions_hash" required=false type="string"  dbtype="varchar" maxlength=35  indexes="stepTransitionsHash";
	property name="completed_steps"       required=false type="string"  dbtype="longtext";
	property name="step_transitions"      required=false type="string"  dbtype="longtext";
}