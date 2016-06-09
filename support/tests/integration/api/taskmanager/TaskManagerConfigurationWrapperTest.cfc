component extends="testbox.system.BaseSpec" {

	public void function run() output=false {
		describe( "getConfiguredTasks", function(){
			it( "should discover mix of Tasks.cfc and ScheduledTasks.cfc file in all the passed handler folders and return a structure of tasks that have been derived from the metadata on their handler actions", function(){
				var wrapper = _getWrapper();
				var tasks = {
					  task_1 = { name="Task 1", description="This is scheduled task 1", event="scheduledtasks.task_1", schedule="* 5 * * * *" , timeout=120, priority=0, isScheduled=true , displayGroup="default" }
					, task_2 = { name="Task 2", description="This is scheduled task 2", event="tasks.task_2"         , schedule="disabled"    , timeout=600, priority=0, isScheduled=false, displayGroup="default" }
					, task_3 = { name="Task 3", description="This is scheduled task 3", event="tasks.task_3"         , schedule="* 5 * * * *" , timeout=600, priority=0, isScheduled=true , displayGroup="default" }
					, task_4 = { name="Task 4", description="This is scheduled task 4", event="scheduledtasks.task_4", schedule="* 5 * * * *" , timeout=600, priority=0, isScheduled=true , displayGroup="Group x" }
					, task_5 = { name="Task 5", description="This is scheduled task 5", event="scheduledtasks.task_5", schedule="* 14 3 * * *", timeout=600, priority=0, isScheduled=true , displayGroup="default" }
				};

				expect( wrapper.getConfiguredTasks() ).toBe( tasks );
			} );
		} );
	}

	private any function _getWrapper() output=false {
		var dirs = [ "/tests/resources/taskmanagerConfigWrapper/folder1", "/tests/resources/taskmanagerConfigWrapper/folder2", "/tests/resources/taskmanagerConfigWrapper/folder3" ];

		return getMockBox().createMock( object=new preside.system.services.taskmanager.TaskManagerConfigurationWrapper(
			handlerDirectories = dirs
		) );
	}
}