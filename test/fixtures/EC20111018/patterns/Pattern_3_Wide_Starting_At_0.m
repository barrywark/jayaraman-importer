% pipmake_single_stripe.m

pattern.x_num = 56; 	% There are 96 pixel around the display (12x8) 
pattern.y_num = 1; 		% two frames of Y, at 2 different spatial frequencies
pattern.num_panels = 14; 	% This is the number of unique Panel IDs required.
pattern.gs_val = 3; 	% This pattern will use 8 intensity levels
pattern.row_compression = 1;

Pats = 7*ones(16, 56, pattern.x_num, pattern.y_num);
Pats(:, 27:30, 1, 1) = 0;
%Pats(:, :, 1, 2) = [2*ones(4,7) zeros(4,7) 2*ones(4,7) zeros(4,7) 2*ones(4,7) zeros(4,7) 2*ones(4,7) zeros(4,7)];

for j = 2:56
        Pats(:,:,j,1) = ShiftMatrix(Pats(:,:,j-1,1),1,'r','y');
end


pattern.Pats = Pats;

% pattern.panel.map = 1:1:12;


A = 1:14;
pattern.Panel_map = flipud(reshape(A, 2, 7));

pattern.BitMapIndex = process_panel_map(pattern);
pattern.data = Make_pattern_vector(pattern);

directory_name = 'c:\matlabroot\Panels\Patterns\ClosedLoop';
str = [directory_name '\Pattern_3_Wide_Starting_At_0']
save(str, 'pattern');