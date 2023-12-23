classdef SessionStatsSubtotal
    properties
        Correct = 0;
        Incorrect = 0;
        Invalid = 0;
    end

    properties (Dependent)
        Total;
        Valid;
        Accuracy;
        ValidRate;
    end

    methods
        function obj = addCorrect(obj)
            % ADDCORRECT Adds one correct trial to the subtotal
            obj.Correct = obj.Correct + 1;
        end

        function obj = addIncorrect(obj)
            % ADDINCORRECT Adds one incorrect trial to the subtotal
            obj.Incorrect = obj.Incorrect + 1;
        end

        function obj = addInvalid(obj)
            % ADDINVALID Adds one invalid trial to the subtotal
            obj.Invalid = obj.Invalid + 1;
        end

        function obj = addByCode(obj, code)
            % ADDBYCODE Add an outcome using negative for invalid, positive
            % for correct, and zero for incorrect.
            %   Arguments:
            %     code A numeric value negative for invalid, positive for
            %          correct, or zero for incorrect trial

            arguments
                obj (1, 1) SessionStatsSubtotal
                code (1, 1) {mustBeNumeric}
            end

            if code < 0
                obj = obj.addInvalid();
            elseif code > 0
                obj = obj.addCorrect();
            else
                obj = obj.addIncorrect();
            end
        end

        function total = get.Total(obj)
            total = obj.Correct + obj.Incorrect + obj.Invalid;
        end

        function valid = get.Valid(obj)
            valid = obj.Correct + obj.Incorrect;
        end

        function accuracy = get.Accuracy(obj)
            accuracy = obj.Correct / max(obj.Valid, 1);
        end

        function validrate = get.ValidRate(obj)
            validrate = obj.Valid / max(obj.Total, 1);
        end
    end
end

