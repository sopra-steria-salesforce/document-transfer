trigger AccountTrigger on Account (after update) {
   new MetadataTriggerHandler().run();
}