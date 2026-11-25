component extends="preside.system.services.concurrency.AbstractHeartBeat" {

	variables._runCount     = 0;
	variables._runBehaviour = function(){};

	public void function setRunBehaviour( required any behaviour ) {
		variables._runBehaviour = arguments.behaviour;
	}

	public numeric function getRunCount() {
		return variables._runCount;
	}

	public void function $run() {
		variables._runCount++;
		variables._runBehaviour();
	}

	public any function $getRequestContext() {
		return {
			  autoSetSiteByHost = function(){}
			, isBackgroundThread = function(){}
		};
	}

	public void function $systemOutput() {}

	public boolean function $isFeatureEnabled() {
		return true;
	}

}
