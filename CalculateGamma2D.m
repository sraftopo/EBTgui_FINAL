function [ G ] = CalculateGamma2D( A1, A2, A1X, A1Y, A2X, A2Y, DTA, DD )
%GAMMA2D Summary of this function goes here
%  Inputs:
% (RTSafeDose, TPSDoseInterp, XCoords, YCoords, XCoordsInterp, YCoordsInterp, DTA, DD)


    try
        %scale dose as a percent of the maximum dose
        doseD = DD *  max(A1(:)); 

        A2int = A2; %interp2(A2pos, A2, range, 'linear', NaN);
        A1int = A1; % interp1(A1pos, A1, range, 'spline', NaN);

        size1 = size(A1int);
        
        G = zeros(size1) ; %this will be the output
    
        DTA2 = DTA^2;
        doseD2 = doseD^2;
        
        for i = 1 : size1(1)

            for j = 1 : size1(2)

                r2 = (A1X(i,j) - A2X).^2 + (A1Y(i,j) - A2Y).^2; 
                d2 = (A1int(i,j) - A2int).^2; 

                Ga = (r2 ./(DTA2) + d2./(doseD2));
                G(i,j) = min(Ga(:));

            end

        end
        
        G = sqrt(G);
        
    catch ex
        
       disp(ex.message); 
       
    end

end

