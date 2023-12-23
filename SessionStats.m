classdef SessionStats < handle
    properties
        History;
        ByDirection;
        ByCoherence;
    end

    properties (Dependent)
        All;
    end

    methods
        function obj = SessionStats()
            obj = obj@handle();

            obj.History = []; % All structs contain Left, Coherence, OutcomeCode
            obj.ByDirection.Left = SessionStatsSubtotal();
            obj.ByDirection.Right = SessionStatsSubtotal();
        end

        function addCorrect(obj, trial)
            % ADDCORRECT Mark a trial as correct
            %   Arguments:
            %     trial A struct containing Left, Coherence

            obj.addOutcome(trial, 1);
        end

        function addIncorrect(obj, trial)
            % ADDCORRECT Mark a trial as incorrect
            %   Arguments:
            %     trial A struct containing Left, Coherence

            obj.addOutcome(trial, 0);
        end

        function addInvalid(obj, trial)
            % ADDINVALID Mark a trial as invalid
            %   Arguments:
            %     trial A struct containing Left, Coherence

            obj.addOutcome(trial, -1);
        end

        function [subtotal,subtotal_L,subtotal_R] = recentHistory(obj, count)
            % RECENTHISTORY Retrieve a subtotal for recent trials
            %   Arguments:
            %     count A number of trials (at most) to summarize
            %   Returns three SessionStatsSubtotal

            arguments
                obj (1, 1) SessionStats
                count (1, 1) {mustBeNonnegative, mustBeInteger}
            end

            subtotal = SessionStatsSubtotal();
            subtotal_L = SessionStatsSubtotal();
            subtotal_R = SessionStatsSubtotal();

            if isempty(obj.History)
                return;
            end

            first = max(size(obj.History, 1) - count + 1, 1);
            for i = first:size(obj.History, 1)
                item = obj.History(i);
                subtotal = subtotal.addByCode(item.OutcomeCode);
                if item.Left == 1
                    subtotal_L = subtotal_L.addByCode(item.OutcomeCode);
                else
                    subtotal_R = subtotal_R.addByCode(item.OutcomeCode);
                end
            end
        end

        function subtotal = byCoherence(obj, coherence)
            % RECENTHISTORY Retrieve a subtotal for all trials with the
            % same coherence value
            %   Arguments:
            %     coherence A unit-range coherence value to summarize
            %   Returns a SessionStatsSubtotal
            
            arguments
                obj (1, 1) SessionStats
                coherence (1, 1) {mustBeNonnegative}
            end

            cname = SessionStats.nameCoherence(coherence);
            if ~isfield(obj.ByCoherence, cname)
                subtotal = SessionStatsSubtotal();
            else
                subtotal = obj.ByCoherence.(cname);
            end
        end

        function total = get.All(obj)
            total = obj.ByDirection.Left;
            total.Correct = total.Correct + obj.ByDirection.Right.Correct;
            total.Incorrect = total.Incorrect + obj.ByDirection.Right.Incorrect;
            total.Invalid = total.Invalid + obj.ByDirection.Right.Invalid;
        end
    end

    methods (Access = protected)
        function addOutcome(obj, trial, code)
            if trial.Left
                obj.ByDirection.Left = obj.ByDirection.Left.addByCode(code);
            else
                obj.ByDirection.Right = obj.ByDirection.Right.addByCode(code);
            end

            cname = SessionStats.nameCoherence(trial.Coherence);
            if ~isfield(obj.ByCoherence, cname)
                obj.ByCoherence.(cname) = SessionStatsSubtotal();
            end

            obj.ByCoherence.(cname) = obj.ByCoherence.(cname).addByCode(code);

            obj.History = [obj.History; struct('Left', trial.Left, 'Coherence', trial.Coherence, 'OutcomeCode', code)];
        end
    end

    methods (Static, Access = protected)
        function s = nameCoherence(coherence)
            s = sprintf('c%d', ceil(coherence * 10000));
        end
    end
end