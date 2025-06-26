/**
 * @nowirebox true
 */
component accessors=true {
	property name="id"                  type="string" default="";
	property name="configform"          type="string" default="";
	property name="stepRef"             type="string" default="";
	property name="subflowRef"          type="string" default="";
	property name="parentSubflowRef"    type="string" default="";
	property name="next"                type="array";
	property name="prev"                type="array";
	property name="preActions"          type="array";
	property name="postActions"         type="array";
	property name="display"             type="struct";
	property name="submission"          type="struct";
	property name="condition"           type="struct";
	property name="config"              type="struct";
	property name="finish"              type="boolean" default=false;
	property name="start"               type="boolean" default=false;
	property name="canCancel"           type="boolean" default=false;
	property name="ignoreTimeout"       type="boolean" default=false;
	property name="subflowEntryPoint"   type="boolean" default=false;
	property name="subflowExitPoint"    type="boolean" default=false;
	property name="subflowExitPointFor" type="array";

	public struct function getMemento() {
		return {
			  id                  = variables.id
			, configform          = variables.configform
			, stepRef             = variables.stepRef
			, subflowRef          = variables.subflowRef
			, parentSubflowRef    = variables.parentSubflowRef
			, next                = variables.next ?: []
			, prev                = variables.prev ?: []
			, preActions          = variables.preActions ?: []
			, postActions         = variables.postActions ?: []
			, display             = variables.display ?: {}
			, submission          = variables.submission ?: {}
			, condition           = variables.condition ?: {}
			, config              = variables.config    ?: {}
			, finish              = variables.finish
			, start               = variables.start
			, canCancel           = variables.canCancel
			, ignoreTimeout       = variables.ignoreTimeout
			, subflowEntryPoint   = variables.subflowEntryPoint
			, subflowExitPoint    = variables.subflowExitPoint
			, subflowExitPointFor = variables.subflowExitPointFor ?: []
		};
	}

	public struct function getDisplay() {
		return variables.display ?: {};
	}
	public struct function getSubmission() {
		return variables.submission ?: {};
	}

	public array function getPreActions() {
		return variables.preActions ?: [];
	}
	public boolean function hasPreActions() {
		return ArrayLen( getPreActions() );
	}

	public array function getPostActions() {
		return variables.postActions ?: [];
	}
	public boolean function hasPostActions() {
		return ArrayLen( getPostActions() );
	}

	public struct function getCondition() {
		return variables.condition ?: {};
	}
	public boolean function hasCondition() {
		return !StructIsEmpty( getCondition() );
	}

	public struct function getConfig() {
		return StructCopy( variables.config ?: {} );
	}

	public array function getNextSteps() {
		return variables.next ?: [];
	}
	public array function getPrevSteps() {
		return variables.prev ?: [];
	}
	public array function getSubflowExitPointFor() {
		return variables.subflowExitPointFor ?: [];
	}

}