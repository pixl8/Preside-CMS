---
id: taskmanager-predefinedtasks
title: Task manager - pre-defined scheduled tasks
---

As of v10.7.0, PresideCMS comes with an built-in task management system designed for running and monitoring scheduled and ad-hoc tasks in the system. For example, you might have a nightly data import task, or an ad-hoc task for optimizing images. 

This page describes how you can pre-define tasks that will appear in the automatic scheduling UI. For ad-hoc background tasks, see [[taskmanager-adhoctasks]].

![Screenshot of taskmanager task list](images/screenshots/taskmanagertasks.png)


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
	 * @priority         13
	 * @schedule         0 *\/15 * * * *
	 * @timeout          120
	 * @displayName      Rebuild search indexes
	 * @displayGroup     search
	 * @exclusivityGroup search
	 */
	private boolean function rebuildSearchIndexes( event, rc, prc, logger ) {
		return elasticSearchEngine.rebuildIndexes( logger=arguments.logger ?: NullValue() );
	}
}
```

### Scheduling tasks

Tasks can be given a default schedule, or defined as _not_ scheduled tasks using the `@schedule` attribute. The attribute expects a value of either `disabled` or an extended (6 point) [cron definition](http://www.nncron.ru/help/EN/working/cron-format.htm). Some example cron definitions:

```luceescript
/**
 * Every 15 minutes
 * @schedule 0 *\/15 * * * *
 *
 * At 25 minutes past the hour, every 2 hours
 * @schedule 0 25 *\/2 * * *
 *
 * At 4:06 AM, only on Tuesday
 * @schedule 0 06 04 * * Tue
 */
```

Note how we need to escape slashes (`/`) in the cron syntax with a backwards slash (`\`). i.e. regular cron syntax: `0 */15 * * * *` vs our escaped version `0 *\/15 * * * *`. This is because the regular syntax would end the CFML comment with `*/` and render everything after that useless.

>>> The UI of the task manager also uses cron syntax for defining the schedule of tasks.

#### Ad-hoc tasks

You can define tasks to explicitly have _no_ schedule, demanding that tasks are then either run programatically or manually through the admin user interface. To do so, set the `@schedule` attribute to disabled:

```luceescript
/**
 *
 * @schedule     disabled
 * @timeout      120
 * @displayName  Optimize images
 */
private boolean function optimizeImages( event, rc, prc, logger ) {
	myAwesomeImageService.doMagic( logger=argumnets.logger ?: NullValue() );
}
```

### Task priority

When tasks run on a schedule, the system currently only allows a single task to run at any one time. If two or more tasks are due to run, the system uses the `@priority` value to determine which task should run first. Tasks with _higher_ priority values will take priority over tasks with lower values.

### Timeouts

Tasks can be given a timeout value using the `@timeout` attribute. Values are in seconds. If the timeout is reached, the system will terminate the running thread for the task using a java thread interrupt.

### Display groups

You can optionally use display groups to break-up the view of tasks in to multiple grouped tabs. For example, you may have a group for maintenance tasks and another group for CRM data syncs. Simply use the `@displayGroup` attribute and tasks with the same "display group" will be grouped together in tabs.

### Exclusivity groups

You can optionally use exclusivity groups to ensure that related tasks do not run concurrently. For example, you may have several data syncing tasks that would be problematic if they all ran at the same time.

By default, the exclusivity group for a task is set to the *display group* of the task.

It you set the exclusivity group of a task to `none`, the task can be run at any point in time.

Use the `@exclusivityGroup` attribute to declare your exclusivity groups per task (or leave alone to use display group).

>>> If no groups are specified, a default group of "default" will be used.

### Invoking tasks programatically

In cases where you need to start a background task as a result of some progmmable event, you can call the [[taskmanagerservice-runtask]] method of the [[api-taskmanagerservice]] directly, or use the [[api-presidesuperclass]] [[presidesuperclass-$runtask]] method (see [[presidesuperclass]]). For example:

```luceescript
// /services/AssetManagerService.cfc
/**
 * @presideService
 * @singleton
 */
component {
	// ...

	public boolean function editFolderPermissions( ... ) {
		// ...

		$runTask( taskKey="moveAssets", args={ folder=arguments.folder } )

		// ...
	}

	// ...
}
```