package com
{
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.utils.*;
    import flash.filters.*;
    import mx.core.*;
    import com.*;
    import mx.managers.*;

    public class DrawingArea extends UIComponent
    {
        private var dictVertexMarker:Dictionary;
        private var dictElementMarker:Dictionary;
        private var dictBoundaryMarker:Dictionary;

        private var vertexContainer:Sprite;
        private var elementContainer:Sprite;
        private var boundaryContainer:Sprite;

        private var vertexSelectMarker:VertexSelectMarker;
        private var elementSelectMarker:ElementSelectMarker;
        private var boundarySelectMarker:BoundarySelectMarker;

        public var canvas:Sprite;
        private var grid:Grid;
        private var selectionLine:Sprite;
        private var msk:Sprite;
        
        public var scaleFactor:Number;
        private var vertexDragged:VertexMarker;
        private var vertexSelected:VertexMarker;

        private var timerUpdateVertex:Timer;
        private var timerUpdateSelectionLine:Timer;
        private var timerClickEvent:Timer;

        private const ADD_ELEMENT:int = 1;
        private const ADD_BOUNDARY:int = 2;

        public var readyToAdd:int;
        private var selectedVertexQueue:Array;
        private var pointBeforeDrag:Point;

        public var selectNearestVertex:Boolean = true;

        public function DrawingArea(w:int=100, h:int=100):void
        {
            super();

            this.percentWidth = w;
            this.percentHeight = h;
            this.scaleFactor = 200;

            this.vertexContainer = new Sprite();
            this.elementContainer = new Sprite();
            this.boundaryContainer = new Sprite();

            this.grid = new Grid();
            this.grid.drawGrid(this.scaleFactor);

            this.selectionLine = new Sprite();

            this.canvas = new Sprite();
            this.canvas.addChild(this.grid);
            this.canvas.addChild(this.elementContainer);
            this.canvas.addChild(this.boundaryContainer);
            this.canvas.addChild(this.vertexContainer);

            this.msk = new Sprite();

            this.addChild(this.canvas);
            this.addChild(this.msk);

            this.canvas.mask = this.msk;

            this.dictVertexMarker = new Dictionary();
            this.dictElementMarker = new Dictionary();
            this.dictBoundaryMarker = new Dictionary();

            this.vertexSelectMarker = new VertexSelectMarker();
            this.elementSelectMarker = new ElementSelectMarker();
            this.boundarySelectMarker = new BoundarySelectMarker();

            this.timerUpdateVertex = new Timer(50);
            this.timerUpdateVertex.addEventListener(TimerEvent.TIMER, this.timerUpdateVertexTimer);

            this.timerUpdateSelectionLine = new Timer(100);
            this.timerUpdateSelectionLine.addEventListener(TimerEvent.TIMER, this.timerUpdateSelectionLineTimer);

            this.timerClickEvent = new Timer(250,1);
            this.timerClickEvent.addEventListener(TimerEvent.TIMER, this.timerClickEventTimer);

            this.vertexDragged = null;
            this.pointBeforeDrag = new Point();

            this.readyToAdd = 0;
            this.selectedVertexQueue = [];
        }

        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            this.graphics.clear();
            this.graphics.beginFill(0xFFFFFF);
            this.graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
            this.graphics.endFill();

            this.msk.graphics.clear();
            this.msk.graphics.beginFill(0xFFFFFF);
            this.msk.graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
            this.msk.graphics.endFill();

            this.canvas.x = unscaledWidth/2;
            this.canvas.y = unscaledHeight/2;

            //this.canvas.graphics.beginFill();
            //this.canvas.graphics.drawRect(-200, 200, 400,400);
            //this.canvas.graphics.endFill();
        }

        public function addVertex(data:Object):void
        {
            var vm:VertexMarker = new VertexMarker(data);
            vm.updateVertex(this.scaleFactor);

            this.dictVertexMarker[data.id] = vm;
            this.vertexContainer.addChild(vm);
        }

        public function updateVertex(data:Object):void
        {
            var vm:VertexMarker = this.dictVertexMarker[data.id];
            vm.updateVertex(this.scaleFactor);
        }

        public function removeVertex(data:Object):void
        {
            this.vertexContainer.removeChild(this.dictVertexMarker[data.id]);
            delete this.dictVertexMarker[data.id];

            this.vertexSelectMarker.timeOut(null);
        }

        public function selectVertex(data:Object):void
        {
            this.vertexSelectMarker.x = this.dictVertexMarker[int(data.id)].x;
            this.vertexSelectMarker.y = this.dictVertexMarker[int(data.id)].y;
            this.vertexContainer.addChild(this.vertexSelectMarker);

            this.vertexSelectMarker.setTimeOut();
        }

        public function addElement(data:Object):void
        {
            var em:ElementMarker = new ElementMarker(data);
            this.dictElementMarker[data.id] = em;
            this.elementContainer.addChild(em);

            em.drawBorder(data, this.scaleFactor);
        }

        public function updateElement(data:Object):void
        {
            var em:ElementMarker = this.dictElementMarker[data.id] ;
            em.drawBorder(data, this.scaleFactor);
        }

        public function removeElement(data:Object):void
        {
            this.elementContainer.removeChild(this.dictElementMarker[data.id]);
            delete this.dictElementMarker[data.id];

            this.elementSelectMarker.timeOut(null);
        }

        public function selectElement(data:Object):void
        {
            this.boundaryContainer.addChild(this.elementSelectMarker);
            this.elementSelectMarker.drawBorder(data, this.scaleFactor);

            this.elementSelectMarker.setTimeOut();
        }

        public function addBoundary(data:Object):void
        {
            var bm:BoundaryMarker = new BoundaryMarker(data);
            this.dictBoundaryMarker[data.id] = bm;
            this.boundaryContainer.addChild(bm);

            bm.drawBorder(data, this.scaleFactor);
        }

        public function updateBoundary(data:Object):void
        {
            var bm:BoundaryMarker = this.dictBoundaryMarker[data.id] ;
            bm.drawBorder(data, this.scaleFactor);
        }

        public function removeBoundary(data:Object):void
        {
            this.boundaryContainer.removeChild(this.dictBoundaryMarker[data.id]);
            delete this.dictBoundaryMarker[data.id];

            this.elementSelectMarker.timeOut(null);
        }

        public function selectBoundary(data:Object):void
        {
            this.boundaryContainer.addChild(this.boundarySelectMarker);

            this.boundarySelectMarker.drawBorder(data, this.scaleFactor);
            this.boundarySelectMarker.setTimeOut();
        }

        public function clear():void
        {
            var key:String;

            for(key in this.dictVertexMarker)
            {
                this.vertexContainer.removeChild(this.dictVertexMarker[key]);
                delete this.dictVertexMarker[key];
            }

            for(key in this.dictElementMarker)
            {
                this.elementContainer.removeChild(this.dictElementMarker[key]);
                delete this.dictElementMarker[key];
            }

            for(key in this.dictBoundaryMarker)
            {
                this.boundaryContainer.removeChild(this.dictBoundaryMarker[key]);
                delete this.dictBoundaryMarker[key];
            }
        }

        public function getClickedPoint():Point
        {
            var p:Point = new Point();
            p.x = this.elementContainer.mouseX/this.scaleFactor;
            p.y = this.elementContainer.mouseY/this.scaleFactor;
            return p;
        }

        private function timerUpdateVertexTimer(evt:TimerEvent):void
        {
            this.vertexDragged.updateDataProvider(this.scaleFactor);

            var e:MeshEditorEvent = new MeshEditorEvent(MeshEditorEvent.VERTEX_UPDATED);
            e.data = this.vertexDragged.dataProvider;

            this.dispatchEvent(e);
        }

        private function timerClickEventTimer(evt:TimerEvent):void
        {
            this.updateSelectedVertexQueue();
        }

        private function timerUpdateSelectionLineTimer(evt:TimerEvent):void
        {
            this.selectionLine.graphics.clear();
            this.selectionLine.graphics.lineStyle(1, 0xFF00FF);
            this.selectionLine.graphics.moveTo(this.selectedVertexQueue[0].dataProvider.x*this.scaleFactor, -this.selectedVertexQueue[0].dataProvider.y*this.scaleFactor);

            for(var i:int=1;i<this.selectedVertexQueue.length;i++)
            {
                this.selectionLine.graphics.lineTo(this.selectedVertexQueue[i].dataProvider.x*this.scaleFactor, -this.selectedVertexQueue[i].dataProvider.y*this.scaleFactor);
            }

            this.selectionLine.graphics.lineTo(this.selectionLine.mouseX-3, (this.selectionLine.mouseY-3));
        }

        private function addToSelectedVertexQueue(vm:VertexMarker):void
        {
            if(this.selectedVertexQueue.length<4)
            {
                this.selectedVertexQueue.push(vm)
            }
            else
            {
                this.selectedVertexQueue.shift();
                this.selectedVertexQueue.push(vm);
            }

            trace ("-Queue-");
            var str:String = ""
            for each(var v:VertexMarker in this.selectedVertexQueue)
                str += v.dataProvider.id + ", ";
            trace(str);
        }

        public function clearSelectedVertexQueue():void
        {
            for each(var vm:VertexMarker in this.selectedVertexQueue)
            {
                vm.toggleSelect(false);
            }

            this.selectedVertexQueue.splice(0,this.selectedVertexQueue.length);

            this.timerUpdateSelectionLine.stop();
            this.selectionLine.graphics.clear();

            try
            {
                this.boundaryContainer.removeChild(this.selectionLine);
            }catch(e:Error){}
        }

        public function scrollCanvas(vPos:int=-1, hPos:int=-1):void
        {
            var i:int,p:int;

            //Scroll vertically
            if(vPos >=0 && hPos == -1)
            {
                i = (50 - vPos)
                p = int(this.scaleFactor*i);

                if(i == 0)
                    this.canvas.y = this.height/2;
                else
                    this.canvas.y = (this.height/2) + p;
            }
            //Scroll Horizontally
            else if(vPos == -1 && hPos >= 0)
            {
                i = (50 - hPos)
                p = int(this.scaleFactor*i);

                if(i == 0)
                    this.canvas.x = this.width/2;
                else
                    this.canvas.x = (this.width/2) + p;
            }
        }

        public function mouseUp(evt:MouseEvent):void
        {
            var e:MeshEditorEvent;

            if(evt.ctrlKey)
            {
                var p:Point = this.getClickedPoint();
                e = new MeshEditorEvent(MeshEditorEvent.VERTEX_ADDED);
                e.data = {x:p.x, y:-p.y};
                this.dispatchEvent(e);
            }
            if(evt.target is VertexMarker)
            {
                evt.target.stopDrag();
                this.timerUpdateVertex.stop();

                e = new MeshEditorEvent(MeshEditorEvent.VERTEX_DRAG_END);
                e.data = this.vertexDragged.dataProvider;
                e.data2 = this.pointBeforeDrag;

                this.dispatchEvent(e);

                this.vertexDragged = null;
                //pointBeforeDrag = null;
            }
            else
            {
                this.canvas.stopDrag();

                if(evt.target is DrawingArea)
                {
                    this.clearSelectedVertexQueue();
                }
            }
        }

        public function mouseDown(evt:MouseEvent):void
        {
            if(evt.shiftKey)
            {
                this.canvas.startDrag();
            }
            else if(evt.target is VertexMarker)
            {
                this.vertexDragged = VertexMarker(evt.target);
                evt.target.startDrag();

                //pointBeforeDrag = new Point();

                pointBeforeDrag.x = this.vertexDragged.dataProvider.x;
                pointBeforeDrag.y = this.vertexDragged.dataProvider.y;

                this.timerUpdateVertex.start();
            }
        }

        public function mouseClick(evt:MouseEvent):void
        {
            if(evt.target is VertexMarker)
            {
                this.vertexSelected = (evt.target as VertexMarker);
            }
            else
            {
                if(this.selectNearestVertex)
                {
                    var cx:Number = this.canvas.mouseX/this.scaleFactor;
                    var cy:Number = -this.canvas.mouseY/this.scaleFactor;

                    var dictDistance:Dictionary = new Dictionary();

                    for(var key:Object in this.dictVertexMarker)
                    {
                        var vm:VertexMarker = this.dictVertexMarker[key];
                        var distance:Number = Geometry.getDistance({x:cx,y:cy}, vm.dataProvider);

                        dictDistance[vm] = distance;
                        this.vertexSelected = vm;
                    }

                    for(var k:Object in dictDistance)
                    {
                        if(dictDistance[k] <= dictDistance[this.vertexSelected])
                            this.vertexSelected = (k as VertexMarker);
                    }
                }
            }

            this.timerClickEvent.start();
        }

        public function mouseDoubleClick(evt:MouseEvent):void
        {
            this.timerClickEvent.stop();

            var e:MeshEditorEvent;

            if(evt.target is VertexMarker)
            {
                e = new MeshEditorEvent(MeshEditorEvent.VERTEX_REMOVED);
                e.data = (evt.target as VertexMarker).dataProvider;
                this.dispatchEvent(e);
            }
            else if(evt.target is ElementMarker)
            {
                e = new MeshEditorEvent(MeshEditorEvent.ELEMENT_REMOVED);
                e.data = (evt.target as ElementMarker).dataProvider;
                this.dispatchEvent(e);
            }
            else if(evt.target is BoundaryMarker)
            {
                e = new MeshEditorEvent(MeshEditorEvent.BOUNDARY_REMOVED);
                e.data = (evt.target as BoundaryMarker).dataProvider;
                this.dispatchEvent(e);
            }
        }

        private function updateSelectedVertexQueue():void
        {
            var v1:Object, v2:Object, v3:Object, v4:Object;
            var e:MeshEditorEvent;

            this.addToSelectedVertexQueue(this.vertexSelected);
            this.vertexSelected.toggleSelect(true);

            if(this.selectedVertexQueue.length == 1)
            {
                /*
                if(this.readyToAdd == this.ADD_ELEMENT)
                {
                    this.elementContainer.addChild(this.selectionLine);
                }
                else if(this.readyToAdd == this.ADD_BOUNDARY)
                {
                    this.boundaryContainer.addChild(this.selectionLine);
                }*/

                this.boundaryContainer.addChild(this.selectionLine);

                this.timerUpdateSelectionLine.start();
            }

            if(this.readyToAdd == this.ADD_BOUNDARY && this.selectedVertexQueue.length >= 2)
            {
                this.timerUpdateSelectionLine.stop();
                this.selectionLine.graphics.clear();
                this.boundaryContainer.removeChild(this.selectionLine);

                v1 = selectedVertexQueue.pop();
                v1.toggleSelect(false);

                v2 = selectedVertexQueue.pop();
                v2.toggleSelect(false);

                e = new MeshEditorEvent(MeshEditorEvent.BOUNDARY_ADDED);
                e.data = {v1:v2.dataProvider, v2:v1.dataProvider, marker:1, angle:0, boundary:true};
                this.dispatchEvent(e);
            }
            else if(this.readyToAdd == this.ADD_ELEMENT && this.selectedVertexQueue.length == 4)
            {
                this.timerUpdateSelectionLine.stop();
                this.selectionLine.graphics.clear();
                this.boundaryContainer.removeChild(this.selectionLine);

                v1 = selectedVertexQueue.pop();
                v1.toggleSelect(false);

                v2 = selectedVertexQueue.pop();
                v2.toggleSelect(false);

                v3 = selectedVertexQueue.pop();
                v3.toggleSelect(false);

                v4 = selectedVertexQueue.pop();
                v4.toggleSelect(false);

                e = new MeshEditorEvent(MeshEditorEvent.ELEMENT_ADDED);

                if(v1 == v4)
                    e.data = {v1:v4.dataProvider, v2:v3.dataProvider, v3:v2.dataProvider, material:0};
                else
                    e.data = {v1:v4.dataProvider, v2:v3.dataProvider, v3:v2.dataProvider, v4:v1.dataProvider, material:0};

                this.dispatchEvent(e);
            }

            this.vertexSelected = null;
        }

        public function updateGrid():void
        {
            this.grid.drawGrid(this.scaleFactor);
        }

        public function showHideElement():void
        {
            this.elementContainer.visible = !this.elementContainer.visible;
        }

        public function showHideBoundary():void
        {
            this.boundaryContainer.visible = !this.boundaryContainer.visible;
        }
    }
}
