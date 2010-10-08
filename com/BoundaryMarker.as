package com
{
    import com.*;
    import flash.ui.*;
    import flash.events.*;
    import flash.display.*;
    import flash.geom.*;

    public class BoundaryMarker extends Sprite
    {
        public var dataProvider:Object;

        public function BoundaryMarker(data:Object)
        {
            super();
            this.dataProvider = data;
            this.doubleClickEnabled = true;

            this.buttonMode = true;
            this.useHandCursor = true;
        }

        //It should be called only after ElementMarker is placed in the display list
        public function drawBorder(boundary:Object, scaleFactor:Number):void
        {
            this.graphics.clear();
            this.graphics.lineStyle(2, 0x000000);
            //this.graphics.beginFill(0xCECECE, 0.5);

            if(boundary.angle == 0)
            {
                //this.x = scaleFactor*boundary.v1.x;
                //this.y = -scaleFactor*boundary.v1.y;
                this.graphics.moveTo(scaleFactor*boundary.v1.x, -scaleFactor*boundary.v1.y);

                //var gp:Point = this.parent.localToGlobal(new Point(scaleFactor*boundary.v2.x, -scaleFactor*boundary.v2.y));
                //var lp:Point = this.globalToLocal(gp);
                //this.graphics.lineTo(lp.x, lp.y);

                //this.graphics.lineTo(0,0);
                //this.graphics.endFill();
                this.graphics.lineTo(scaleFactor*boundary.v2.x, -scaleFactor*boundary.v2.y);
            }
            else
            {
                var arcInfo:Object = Geometry.getArcInfo(boundary);
                DrawingShapes.drawArc1(this.graphics, arcInfo, scaleFactor);
            }
        }
    }
}
