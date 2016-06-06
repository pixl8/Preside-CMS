---
id: taskmanager
title: Preside Task Manager
---

As of v10.7.0, PresideCMS comes with an built-in task management system designed for running and monitoring scheduled and ad-hoc tasks in the system. For example, you might have a nightly data import task, or an ad-hoc task for optimizing images.

![Screenshot of taskmanager task list](images/screenshots/taskmanagertasks.png)

Tasks are defined using convention and run in your full application context so have access to all your data and service layers. Each task is run as a background thread and can be monitored using the real time log view.

![Screenshot of taskmanager live log](images/screenshots/taskmanagerlogs.png)

## Defining tasks

The system uses a coldbox handler, `Tasks.cfc`, to define tasks (it also supports a `ScheduledTasks.cfc` handler for backward compatibility).

* Each task is defined as a private action in the `Tasks.cfc` handler and decorated with metadata to give information about the task.
* The action must return a boolean value to indicate success or failure
* The action accepts a `logger` argument that should be used for all task logging - doing so will enable the live log view for your task. 

For example:

```luceescript
// /handlers/Tasks.cfc
component {
	property name="elasticSearchEngine" inject="elasticSearchEngine";

	/**
	 * Rebuilds the search indexes from scratch, ensuring that they are all up to date with the latest data
	 *
	 * @priority     13
	 * @schedule     0 *\/15 * * * *
	 * @timeout      120
	 * @displayName  Rebuild search indexes
	 * @displayGroup default
	 */
	private boolean function rebuildSearchIndexes( event, rc, prc, logger ) {
		return elasticSearchEngine.rebuildIndexes( logger=arguments.logger ?: NullValue() );
	}
}
```

### Task priority

When tasks run on a schedule, the system currently only allows a single task to run at any one time. If two or more tasks are due to run, the system uses the `@priority` value to determine which task should run first. Tasks with _higher_ priority values will take priority over tasks with lower values.