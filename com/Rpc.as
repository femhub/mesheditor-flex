package com
{
    import flash.events.*;
    import mx.rpc.http.*;
    import mx.rpc.events.*;

    import com.adobe.serialization.json.JSON;

    public class Rpc extends EventDispatcher
    {
        private var uuid:String = "";
        private var httpUserRequest:HTTPService;
		private var source:String = "";

        public function Rpc(url:String, uuid:String="101"):void
        {
            this.uuid = uuid;

            this.httpUserRequest = new HTTPService();

            this.httpUserRequest.url = url;
            this.httpUserRequest.method = "POST";
            this.httpUserRequest.contentType = "application/json"
            this.httpUserRequest.resultFormat = "text";
        }

        private function init():void
        {
			if(!this.httpUserRequest.hasEventListener(ResultEvent.RESULT))
				this.httpUserRequest.addEventListener(ResultEvent.RESULT, this.initResult);

            var arg:Object = {
                                "jsonrpc": "2.0",
                                "params": { "uuid":this.uuid },
                                "method": "RPC.Engine.init",
                                "id": 1
                            };

            var jsonArgs:String = JSON.encode(arg);
            this.httpUserRequest.request = jsonArgs;
            this.httpUserRequest.send();
        }

        private function initResult(evt:ResultEvent):void
        {
            var resObject:Object = JSON.decode(String(evt.result));

            if(resObject.result.status == "started" || resObject.result.reason == "engine-running")
            {
                Debug.jsLog("RPC initialization suceed !");
                trace("RPC initialization suceed !");

				Debug.jsLog("Return Value:");
				Debug.jsLog(String(evt.result));
				trace("Return Value");
				trace(String(evt.result));

                this.httpUserRequest.removeEventListener(ResultEvent.RESULT, this.initResult);
                this.httpUserRequest.addEventListener(ResultEvent.RESULT, this.queryResult);

				var arg:Object = {
									"jsonrpc": "2.0",
									"params": { "uuid":this.uuid, "source": this.source },
									"method": "RPC.Engine.evaluate",
									"id": 1
								};

				var jsonArgs:String = JSON.encode(arg);
				this.httpUserRequest.request = jsonArgs;
				this.httpUserRequest.send();

            }
            else
            {
                this.uuid = "";
                Debug.jsLog("RPC initialization failed:");

				Debug.jsLog("Return Value:");
				Debug.jsLog(String(evt.result));
				trace("Return Value");
				trace(String(evt.result));
            }
        }

        public function evaluate(source:String):void
	    {
	        this.source = source;
			this.init();
	    }

        private function queryResult(evt:ResultEvent):void
        {
            this.httpUserRequest.removeEventListener(ResultEvent.RESULT, this.queryResult);

            var meEvt:MeshEditorEvent = new MeshEditorEvent(MeshEditorEvent.RPC_RESULT);
            var res:String = String(evt.result);
            meEvt.data = JSON.decode(res);
            this.dispatchEvent(meEvt);
        }
    }
}
