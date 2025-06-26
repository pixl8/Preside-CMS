/**
 * @feature                         webflow
 * @tablePrefix                     ""
 * @tenant                          site
 * @labelfield                      step_id
 * @labelrenderer                   webflowStep
 * @datamanagerEnabled              true
 * @datamanagerDefaultSortOrder     sort_order
 * @datamanagerGridFields           sort_order,step_id,title,short_title,intro
 * @datamanagerHiddenGridFields     webflow_id,position_type,instance_ref
 * @datamanagerDisallowedOperations add,delete,clone
 */
component {
	property name="webflow" relationship="many-to-one" relatedto="webflow_configuration" required=false uniqueindexes="webflowstep|1" ondelete="cascade";

	property name="webflow_id"   formula="${prefix}webflow.webflow_id";
	property name="instance_ref" formula="${prefix}webflow.instance_ref";

	property name="step_id" type="string" dbtype="varchar" maxlength=100  required=true uniqueindexes="webflowstep|2" renderer="webflowStep" batcheditable=false;
	property name="sort_order" type="numeric" dbtype="int" required=false  batcheditable=false;
	property name="position_type" type="string" dbtype="varchar" maxlength=10 required=false indexes="positiontype" enum="webflowPositionType" batcheditable=false;

	property name="title"       type="string"  dbtype="varchar" maxlength=100 required=false renderer="webflowStepTitle" batcheditable=false;
	property name="short_title" type="string"  dbtype="varchar" maxlength=50  required=false renderer="webflowStepShortTitle" batcheditable=false;
	property name="intro"       type="string"  dbtype="text"                                 renderer="webflowStepIntro" batcheditable=false;
	property name="config"      type="string"  dbtype="text" batcheditable=false;

	property name="next_button"   type="string" dbtype="varchar" maxlength=100;
	property name="back_button"   type="string" dbtype="varchar" maxlength=100;
	property name="cancel_button" type="string" dbtype="varchar" maxlength=100;
}