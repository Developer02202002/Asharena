package util 
{
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.utils.describeType;
	import flash.utils.Endian;
	import flash.utils.getDefinitionByName;
	/**
	 * Boilerplate base class to do auto-reflection of sharable properties within AS3 Worker bridge classes
	 * 
	 * For message channels to be received from Main app, use the "toMain" variable name prefix. Anything else is treated as to be received from worker itself.
	 * @author Glenn Ko
	 */
	public class AS3WorkerBridge 
	{
		private var _doTrace:Function;
		
		public var toMainErrorChannel:MessageChannel; 
		public var toMainTraceChannel:MessageChannel;
		
		public static const RESPONSE_SYNC:int = int.MAX_VALUE;

		public function AS3WorkerBridge() 
		{
			_doTrace = trace;
		
		}
		
		public function initAsPrimordial(worker:Worker):void {  // overwrite this to intiialize any required variables specific to primodial case. Don't call super if you wish not to use reflection.
		
			var xml:XML  = describeType(this);
			var varList:XMLList = xml.variable;
			var len:int = varList.length();
			var untypedMe:* = this;
			for (var i:int = 0; i < len; i++) {
				var node:XML = varList[i];
				var name:String = node.@name;
				var type:String = node.@type;
				var untypedInstance:* = untypedMe[name];
				if (untypedInstance === null) {
					untypedInstance = type != "flash.system::MessageChannel" ? new (getDefinitionByName(type) as Class)() : name.slice(0,6)!="toMain" ? Worker.current.createMessageChannel(worker) : worker.createMessageChannel(Worker.current);
					untypedMe[name] = untypedInstance;
				}
				
				if (type === "flash.utils::ByteArray") {
					untypedInstance.endian = Endian.LITTLE_ENDIAN;
					untypedInstance.shareable = true;
				}
				worker.setSharedProperty(name, untypedInstance );
			}
		}
		
		
		protected function initAsPrimodialManually(worker:Worker):void {
			worker.setSharedProperty("toMainErrorChannel", toMainErrorChannel = worker.createMessageChannel(Worker.current));
			worker.setSharedProperty("toMainTraceChannel", toMainTraceChannel = worker.createMessageChannel(Worker.current));
		}
		
		
		public function initAsChild():void { // do reflection to get shared properties
			var xml:XML  = describeType(this);
			var varList:XMLList = xml.variable;
			var len:int = varList.length();
			var untypedMe:* = this;
			for (var i:int = 0; i < len; i++) {
				var node:XML = varList[i];
				var name:String = node.@name;
				var type:String = node.@type;
				untypedMe[name] = Worker.current.getSharedProperty(name);
				if (type === "flash.utils::ByteArray") {
					untypedMe[name].endian = Endian.LITTLE_ENDIAN;
				}
			}
		}
		
		protected function initAsWorkerManually(worker:Worker):void {
			toMainErrorChannel = Worker.current.getSharedProperty("toMainErrorChannel");
			toMainTraceChannel = Worker.current.getSharedProperty("toMainTraceChannel");
		}
		
		public function sendTrace(str:Object):void {
			toMainTraceChannel.send(str.toString());
		}
		
		public function sendError(err:Error):void {
			toMainErrorChannel.send(err.name + "\n"+err.message + "\n"+ err.getStackTrace());
		}
		
		public function throwErrorHandler(e:Event):void {
			throw new Error(toMainErrorChannel.receive());
		}
		
		public function setupErrorThrowHandler():void {
			toMainErrorChannel.addEventListener(Event.CHANNEL_MESSAGE, throwErrorHandler);
		}
		
		public function get doTrace():Function 
		{
			return _doTrace;
		}
		
		public function set doTrace(value:Function):void 
		{
			_doTrace = value;
		}
		
	}

}