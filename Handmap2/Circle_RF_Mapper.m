classdef Circle_RF_Mapper < CircleGraphic
    properties
       InfoDisplay = false
    end
    properties (Access = protected)
        LB_Hold
        Picked
        PickedPosition
        bOldTracker
    end
    methods
        
        function obj = Circle_RF_Mapper(varargin)
            obj@CircleGraphic(varargin{:});
            obj.List = { [1 1 1], [NaN NaN NaN], [10 10], [0 0], 1, 0 };  % edgecolor, facecolor, size, position, scale, angle
            obj.bOldTracker = isprop(obj.Tracker,'MouseData');

        end
        
        function init(obj,p)
            init@CircleGraphic(obj,p);
            obj.LB_Hold = false;
            obj.Picked = false;

        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@CircleGraphic(obj,p);
            
            % get the mouse and keyboard input
            if obj.bOldTracker
                xydeg = obj.Tracker.CalFun.pix2deg(obj.Tracker.MouseData(end,:));
            else 
                xydeg = obj.Tracker.CalFun.pix2deg(obj.Tracker.XYData(end,:));
        
            end
            LB_Down = obj.Tracker.ClickData{1}(end);

            
            % mouse control
            r = sqrt(sum((xydeg-obj.Position).^2));
            
            if ~obj.LB_Hold && LB_Down, obj.Picked = true;  obj.LB_Hold = true; obj.PickedPosition = xydeg - obj.Position; end
            if obj.LB_Hold && ~LB_Down, obj.Picked = false; obj.LB_Hold = false; end
            if obj.Picked, obj.Position = xydeg - obj.PickedPosition; end
            

          
        end
        function draw(obj,p)
            draw@CircleGraphic(obj,p);
            if obj.InfoDisplay
                % display some information on the control screen
                p.dashboard(1,sprintf('TG Position = [%.1f %.1f]',obj.Position));

            end
        end
    end
end
