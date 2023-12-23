function ctl = ginsert(grid, r, c, cons, varargin)
% GINSERT Construct and add a control to uigridlayout
%   Returns the constructed control
%   Arguments:
%     grid     The destination grid to be used as the control's parent
%     r, c     The row, column to set as the layout location of the control
%     cons     The function handle to use for the component constructed
%     varargin The arguments passed to the constructor after parent

ctl = cons(grid, varargin{:});
ctl.Layout.Row = r;
ctl.Layout.Column = c;

end
