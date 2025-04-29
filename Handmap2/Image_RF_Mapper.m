classdef Image_RF_Mapper < ImageGraphic
    properties
       ScaleStep = 0.1
    end
    properties (Access = protected)
        LB_Hold
        Picked
        PickedPosition
        % RB_Hold
        % Resize
        % PickedScale
        KB_Hold
        bOldTracker
    end
    methods
        function obj = Image_RF_Mapper(varargin)
            obj@ImageGraphic(varargin{:});
            obj.bOldTracker = isprop(obj.Tracker,'MouseData');
            % obj.WindowType = 'circular';
        end
        
        function init(obj,p)
            init@ImageGraphic(obj,p);
            obj.LB_Hold = false;
            obj.Picked = false;
            % obj.RB_Hold = false;
            % obj.Resize = false;
            obj.KB_Hold = false(1,2);
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@ImageGraphic(obj,p);
            
            % get the mouse and keyboard input
            if obj.bOldTracker
                xydeg = obj.Tracker.CalFun.pix2deg(obj.Tracker.MouseData(end,:));
                up    = mglgetkeystate(38);  % up arrow
                down  = mglgetkeystate(40);  % down arrow
            else 
                xydeg = obj.Tracker.CalFun.pix2deg(obj.Tracker.XYData(end,:));
                up    = obj.Tracker.KeyInput(end,2);
                down  = obj.Tracker.KeyInput(end,4);
        
            end
            LB_Down = obj.Tracker.ClickData{1}(end);
            % % RB_Down = obj.Tracker.ClickData{2}(end);
            
            % mouse control
            r = sqrt(sum((xydeg-obj.Position).^2));
            % keyboard
            theta = acosd((xydeg(1)-obj.Position(1))/r);
			if xydeg(2)-obj.Position(2)<0, theta = 360-theta; end
            
            if ~obj.LB_Hold && LB_Down, obj.Picked = true;  obj.LB_Hold = true; obj.PickedPosition = xydeg - obj.Position; end
            if obj.LB_Hold && ~LB_Down, obj.Picked = false; obj.LB_Hold = false; end
            if obj.Picked, obj.Position = xydeg - obj.PickedPosition; end
            
            % if ~obj.RB_Hold && RB_Down, obj.Resize = true;  obj.RB_Hold = true; obj.PickedScale = r - obj.Scale(1)/100; end
            % if obj.RB_Hold && ~RB_Down, obj.Resize = false; obj.RB_Hold = false; end
            % if obj.Resize
            %     apsize = r - obj.PickedScale
            %     if 0<apsize, objScale = [r r]*10; end
            % end

            if ~obj.Picked && 0<r, obj.Angle = mod(theta,360); end

            % keyboard control
            % if ~left && obj.KB_Hold(1)
            %     a = obj.SpatialFrequency - obj.SpatialFrequencyStep;
            %     if 0<a, obj.SpatialFrequency = a; end
            % end
            if ~up && obj.KB_Hold(1)
                obj.Scale = obj.Scale + obj.ScaleStep;
            end
            % if ~right && obj.KB_Hold(3)
            %     obj.SpatialFrequency = obj.SpatialFrequency + obj.SpatialFrequencyStep;
            % end
            if ~down && obj.KB_Hold(2)
                a = obj.Scale -obj.ScaleStep;
                if 0<a, obj.Scale = a; end
            end
            obj.KB_Hold = [up down];
          
        end
        % function draw(obj,p)
        %     draw@SineGrating(obj,p);
        %     if obj.InfoDisplay
        %         % display some information on the control screen
        %         p.dashboard(1,sprintf('Position = [%.1f %.1f], Radius = %.1f, Direction = %.1f',obj.Position,obj.Radius,obj.Direction));
        %         p.dashboard(2,sprintf('SpatialFrequency = %.1f, TemporalFrequency = %.1f',obj.SpatialFrequency,obj.TemporalFrequency));
        %     end
        % end
    end
end
