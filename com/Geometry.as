package com
{
    import Math;
    import flash.geom.*;
    import mx.collections.*;

    public class Geometry
    {
        public static function ccw(A:Object, B:Object, C:Object):Boolean
        {
            return (C.y-A.y)*(B.x-A.x) > (B.y-A.y)*(C.x-A.x);
        }

        public static function intersect(A:Object, B:Object, C:Object, D:Object):Boolean
        {
            return Geometry.ccw(A, C, D) != Geometry.ccw(B, C, D) && Geometry.ccw(A, B, C) != Geometry.ccw(A, B, D);
        }

        public static function twoEdgesIntersect(e1:Array, e2:Array):Boolean
        {
            return Geometry.intersect(e1[0], e1[1], e2[0], e2[1]);
        }

        public static function anyEdgesIntersect(edges:Array):Boolean
        {
            for(var i:int = 0; i<edges.length; i++)
            {
                for(var j:int = i+1; j<edges.length; j++)
                {
                    var e1:Array = edges[i];
                    var e2:Array = edges[j];

                    if(e1[1] == e2[0] || e1[0] == e2[1])
                        continue;

                    if(Geometry.twoEdgesIntersect(e1, e2))
                        return true;
                }
            }
            return false;
        }

        public static function edgeIntersectsEdges(e1:Array, edges:Array):Boolean
        {
            for(var i:int=0; i<edges.length; i++)
            {
                var e2:Array = edges[i];

                if(e1[1] == e2[0] || e1[0] == e2[1])
                    continue;

                if(Geometry.twoEdgesIntersect(e1, e2))
                    return true
            }

            return false
        }

        public static function pointInsidePolygon(checkPoint:Object, polyEdges:Array):Boolean
        {
            var intersect:int = 0;
            var testEdge:Array = [checkPoint, {x:100, y:checkPoint.y}];

            for each(var e:Array in polyEdges)
            {
                if(Geometry.twoEdgesIntersect(testEdge, e))
                    intersect += 1;
            }

            if(intersect % 2 == 0)
                return false;
            else
                return true;

            return false;
        }

        public static function findLoop(edges:Array):Array
        {
            var loops:Array = [];
            var loopId:int = 0, currentEdge:int = 0;

            loops.push([edges[0]]);
            edges.splice(0,1);

            var currentLoop:Array = loops[loopId];
            var l:int = edges.length;

            try
            {
                while(l > 0)
                {
                    for(var i:int=0;i<edges.length;i++)
                    {
                        if(currentLoop[currentEdge][0] == edges[i][0] || currentLoop[currentEdge][0] == edges[i][1] || currentLoop[currentEdge][1] == edges[i][0] || currentLoop[currentEdge][1] == edges[i][1])
                        {
                            currentLoop.push(edges[i])
                            edges.splice(i,1);
                            break;
                        }
                    }

                    currentEdge++;

                    if(currentLoop.length > 2 && (currentLoop[0][0] == currentLoop[currentLoop.length-1][0] || currentLoop[0][0] == currentLoop[currentLoop.length-1][1] || currentLoop[0][1] == currentLoop[currentLoop.length-1][0] || currentLoop[0][1] == currentLoop[currentLoop.length-1][1]))
                    {
                        if(edges.length >= 1)
                        {
                            loops.push([edges[0]])
                            edges.splice(0,1);
                            loopId += 1;
                            currentLoop = loops[loopId];
                            currentEdge = 0;
                        }
                    }

                    l--;
                }
            }
            catch(e:Error)
            {
                return null;
            }

            if(currentLoop.length > 2 && (currentLoop[0][0] == currentLoop[currentLoop.length-1][0] || currentLoop[0][0] == currentLoop[currentLoop.length-1][1] || currentLoop[0][1] == currentLoop[currentLoop.length-1][0] || currentLoop[0][1] == currentLoop[currentLoop.length-1][1]))
                return loops
            else
                return null;

            return loops;
        }

        public static function getPolygonVerticesFromPolygonEdges(polygonEdges:Array):Array
        {
            var polyVertices:Array = [];

            var e1:Array = polygonEdges[0];
            for(var i:int=1; i<=polygonEdges.length;i++)
            {
                var e2:Array = polygonEdges[i%polygonEdges.length];

                if(e1[0] == e2[0] || e1[0] == e2[1])
                {
                    polyVertices.push(e1[0]);
                }
                else if(e2[0] == e1[0] || e2[0] == e1[1])
                {
                    polyVertices.push(e2[0]);
                }

                e1 = e2;
            }

            //polyVertices.push(polyVertices[0]);

            return polyVertices;
        }

        public static function getDistance(v1:Object, v2:Object):Number
        {
            return Math.sqrt((v2.x-v1.x)*(v2.x-v1.x) + (v2.y-v1.y)*(v2.y-v1.y));
        }

        public static function calcIncenterOfTriangle(triangle:Object):Point
        {
            var a:Number,b:Number,c:Number,p:Number;

            a = Geometry.getDistance(triangle.v2, triangle.v3);
            b = Geometry.getDistance(triangle.v3, triangle.v1);
            c = Geometry.getDistance(triangle.v1, triangle.v2);
            p = a + b + c;

            var ap:Number = a/p;
            var bp:Number = b/p;
            var cp:Number = c/p;

            var x1:Number = ap*triangle.v1.x;
            var y1:Number = ap*triangle.v1.y;

            var x2:Number = ap*triangle.v2.x;
            var y2:Number = ap*triangle.v2.y;

            var x3:Number = ap*triangle.v3.x;
            var y3:Number = ap*triangle.v3.y;

            return new Point(x1+x2+x3, y1+y2+y3);
        }

        public static function getRadiusOfArc(boundary:Object):Number
        {
            var a:Number = Geometry.getDistance(boundary.v1, boundary.v2);
            var r:Number = Math.sqrt(a*a/(2*(1-Math.cos(Math.abs(boundary.angle)*Math.PI/180))));

            return r;
        }

        public static function getPath(edges:Array):Array
        {
            var path:Array = [edges[0]];
            var avEdges:Array = [];

            for(var i:int=1;i<edges.length;i++)
            {
                avEdges.push(edges[i]);
            }

            i=0;
            while(avEdges.length > 0)
            {
                var edgFound:Boolean = false;

                for(var j:int=0;j<avEdges.length;j++)
                {
                    if(path[i].v2 == avEdges[j].v1)
                    {
                        path.push(avEdges[j]);
                        edgFound = true;
                        avEdges.splice(j,1);
                        break;
                    }
                }

                if(!edgFound)
                {
                    for(j=0;j<avEdges.length;j++)
                    {
                        if(path[i].v2 == avEdges[j].v2)
                        {
                            var e:Object = new Object();
                            e.v1 = avEdges[j].v2;
                            e.v2 = avEdges[j].v1;

                            if(avEdges[j].boundary != undefined && avEdges[j].marker != undefined && avEdges[j].angle != undefined)
                            {
                                e.boundary = avEdges[j].boundary;
                                e.marker = Number(avEdges[j].marker);
                                e.angle = -Number(avEdges[j].angle);
                            }

                            path.push(e);
                            avEdges.splice(j,1);
                            break;
                        }
                    }
                }

                i++;
            }

            return path;
        }

        public static function getArcInfo2(boundary:Object):Object
        {
            var A:Object = boundary.v1;
            var B:Object = boundary.v2;

            var r:Number = Geometry.getRadiusOfArc(boundary);

            var Ex:Number, Ey:Number
            Ex = (A.x + B.x)/2;
            Ey = (A.y + B.y)/2;

            var AE:Number, CE:Number;
            AE = Math.sqrt((A.x - Ex)*(A.x - Ex) + (A.y - Ey)*(A.y - Ey));
            CE = Math.sqrt(r*r - AE*AE);

            var angAB:Number, angCE:Number;
            angAB = Math.atan2(B.y-A.y, B.x-A.x);
            angCE = angAB + Math.PI/2.0;

            //two possible centers
            var C:Point = new Point(); //center
            var D:Point = new Point(); //center

            C.x = Ex - CE * Math.cos(angCE);
            C.y = Ey - CE * Math.sin(angCE);

            D.x = Ex + CE * Math.cos(angCE);
            D.y = Ey + CE * Math.sin(angCE);

            var angCA:Number, angCB:Number, angDA:Number, angDB:Number;

            angCA = Math.atan2(A.y-C.y, A.x-C.x);
            if(angCA < 0)
                angCA -= 2.0*Math.PI;

            angCB = Math.atan2(B.y-C.y, B.x-C.x);
            if(angCB < 0)
                angCB -= 2.0*Math.PI;

            angDA = Math.atan2(A.y-D.y, A.x-D.x);
            if(angDA < 0)
                angDA += 2.0*Math.PI;

            angDB = Math.atan2(B.y-D.y, B.x-D.x);
            if(angDB < 0)
                angDB += 2.0*Math.PI;

            var rad_to_deg:Number = 57.295779513;

            //Convert angle to degree
            angCA *= rad_to_deg;
            angCB *= rad_to_deg;
            angDA *= rad_to_deg;
            angDB *= rad_to_deg;

            if(angDB < angDA)
            {
                angDB += 360;
            }

            if(angCB > angCA)
            {
                angCB -= 360;
            }


/////////////////////////////////////////////////
            if(Math.abs(angCB) > 360)
            {
                if(angCB < 0)
                    angCB += 360;
                else
                    angCB -= 360;
            }

            if(Math.abs(angCA) > 360)
            {
                if(angCA < 0)
                    angCA += 360;
                else
                    angCA -= 360;
            }

            var arcInfo:Object = new Object();

            if(boundary.angle > 0)
            {
                arcInfo.center = D;
                arcInfo.startAngle = angDA;
                arcInfo.endAngle = angDB;
            }
            else
            {
                arcInfo.center = C;
                arcInfo.startAngle = angCA;
                arcInfo.endAngle = angCB;
            }

            arcInfo.radius = r;
            arcInfo.centerAngle = boundary.angle;

            trace("-- Arc Info --");
            trace(C.x, C.y, angCA, angCB);
            trace(D.x, D.y, angDA, angDB);
            trace(r, arcInfo.centerAngle);

            return arcInfo;
        }

        public static function getArcInfo(boundary:Object):Object
        {
            var A:Object;
            var B:Object;

            if(boundary.angle > 0)
            {
                A = boundary.v1;
                B = boundary.v2;
            }
            else if(boundary.angle < 0)
            {
                A = boundary.v2;
                B = boundary.v1;
            }

            var r:Number = Geometry.getRadiusOfArc(boundary);

            var Ex:Number, Ey:Number
            Ex = (A.x + B.x)/2;
            Ey = (A.y + B.y)/2;

            var AE:Number, CE:Number;
            AE = Math.sqrt((A.x - Ex)*(A.x - Ex) + (A.y - Ey)*(A.y - Ey));
            CE = Math.sqrt(r*r - AE*AE);

            var angAB:Number, angCE:Number;
            angAB = Math.atan2(B.y-A.y, B.x-A.x);
            angCE = angAB + Math.PI/2.0;

            //two possible centers
            var C:Point = new Point(); //center
            var D:Point = new Point(); //center

            C.x = Ex - CE * Math.cos(angCE);
            C.y = Ey - CE * Math.sin(angCE);

            D.x = Ex + CE * Math.cos(angCE);
            D.y = Ey + CE * Math.sin(angCE);

            var angCA:Number, angCB:Number, angDA:Number, angDB:Number;

            angCA = Math.atan2(A.y-C.y, A.x-C.x);
            if(angCA < 0)
                angCA += 2.0*Math.PI;

            angCB = Math.atan2(B.y-C.y, B.x-C.x);
            if(angCB < 0)
                angCB += 2.0*Math.PI;

            angDA = Math.atan2(A.y-D.y, A.x-D.x);
            if(angDA < 0)
                angDA += 2.0*Math.PI;

            angDB = Math.atan2(B.y-D.y, B.x-D.x);
            if(angDB < 0)
                angDB += 2.0*Math.PI;

            var rad_to_deg:Number = 57.295779513;
            var tmp:Number;

            //Convert angle to degree
            angCA *= rad_to_deg;
            angCB *= rad_to_deg;
            angDA *= rad_to_deg;
            angDB *= rad_to_deg;

            if(angDA > angDB)
            {
                angDA = angDA - 360;
            }

            if(angCA > angCB)
            {
                angCA = angCA - 360;
            }

            var arcInfo:Object = new Object();

            arcInfo.center = D;
            arcInfo.startAngle = angDA;
            arcInfo.endAngle = angDB;

            arcInfo.radius = r;

            //trace("-- Arc Info --");
            //trace(C.x, C.y, angCA, angCB);
            //trace(D.x, D.y, angDA, angDB);
            //trace(r, boundary.angle);

            return arcInfo;
        }
    }
}
