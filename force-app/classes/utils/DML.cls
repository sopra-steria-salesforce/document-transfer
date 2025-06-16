public class DML {
	@TestVisible
	private static Boolean isMockDML = false;
	@TestVisible
	private static List<Object> enqueuedJobs = new List<Object>();

	public static void enqueueJob(Object queueable){
		if (!isMockDML) { System.enqueueJob(queueable); }
		enqueuedJobs.add(queueable);
	}
}