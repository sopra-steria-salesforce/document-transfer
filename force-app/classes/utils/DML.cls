public class DML {
	@TestVisible
	private static Boolean isMockDML = false;
	@TestVisible
	private static List<Object> enqueuedJobs = new List<Object>();
	public static AsyncOptions asyncOptions = new AsyncOptions();
	
	public static void enqueueJob(Object queueable){
		if (asyncOptions.MaximumQueueableStackDepth != 0 || asyncOptions.MaximumQueueableStackDepth != null) {
			if (!isMockDML) { System.enqueueJob(queueable,asyncOptions); }
			enqueuedJobs.add(queueable);
		}else {
			if (!isMockDML) { System.enqueueJob(queueable); }
			enqueuedJobs.add(queueable);
		}
		
	}
}