%
%
%     non-negative ICA 
%           Implements the method presented in:
%     `Blind Separation of Positive Sources by Globally Convergent Gradient Search´
%     (https://core.ac.uk/download/pdf/76988305.pdf)
% 
% 
%       Usage: 
%           [sources, mixingmatrix] = rs_nnica(X, num_sources, lr, max_iter, tol, rowvar)
% 
%           where: 
%               X = data matrix (nchannels x nsamples)
%               num_sources = number of ICs requested
%               lr = learning rate
%               max_iter: Maximum number of iterations of gradient descent.
%               tol: Tolerance on update at each iteration.
%           
%   
%           - Richard Somervail, 2021
%
%
%%  
function [sources, mixingmatrix] = rs_nnica(X, num_sources, lr, max_iter, tol)

% initialise default settings
if isempty(num_sources), num_sources = size(X,1); end
if isempty(lr), lr = 0.03; end
if isempty(max_iter), max_iter = 5000; end
if isempty(tol), tol = 1e-8; end

if num_sources > size(X,1)
    error 'rs_nnica: number of requested components exceeds number of channels'
end

% Whiten the data
disp 'whitening the data (without removing mean) ...'
[Z, V] = rs_whiten(X, num_sources, false);
disp '... data whitened'

% algorithm assumes data has been transposed here
Z = Z';

% Initialize W
W = eye(num_sources);
disp 'running ICA iterations ...'
for i = 1:max_iter
    
    W0 = W;
    
    % Compute gradient
    Y = W * Z;
    f = arrayfun( @(y) min([0,y]) , Y  ); % find min between mat and 0
    f_Y = f * Y';
    E = (f_Y - f_Y') ./ size(Y,2);

    % Gradient descent
    W = W - (lr .* (E*W));

%     % Symmetric orthonormalization (from the script I adapted)
%     M = W * W';
%     [vecs, vals] = eig(M, 'vector');  
%     vals = real(vals); vecs = real(vecs); 
%     W_sqrt = vecs ./ sqrt(vals); 
%     W_sqrt = W_sqrt * vecs';
%     W = W_sqrt * W;

    % Symmetric orthonormalization (adapted from the paper directly, should be equation 4.6)
    W = ((W * W')^(-1/2)) * W;
%     M = W * W';
%     W = (M^(-1/2)) * W;
    
%     % check orthogonality of W (debug step only)
%     W' - inv(W) % should be zeros
%     W * W' % should be identity matrix
%     W * W' - eye(size(W)) % difference with identity matrix (should be zeroes)
    
    fprintf('it %d, W-change: %.8f\n', i, norm(W - W0))
    if norm(W - W0) < tol  %  ||  stopFlag
        break    
    end
    
end % end iteration loop
disp '... iterations finished'

% Independent sources (up to an unknown permutation y = Q * s)
Y = W * Z;

% Compute the mixing matrix A' = A * Q.T
% (which is A up to a permutation of its columns)
% from the identity y = Q * s = W * V * A * s.
% It then holds x = A * s = A * Q.T * y = A' * y.
% Note: A' is computed as the right Moore-Penrose
% inverse of W * V, but A' may not be unique since
% in general p != num_sources and any right inverse
% could be taken as A'.
WV = W * V;
WV_ =  WV * WV'; 
WV_ = WV' / WV_; % RS: code analyzer suggested this instead of the commented line below
% WV_ = inv(WV_); WV_ = WV' * WV_; 

sources = Y;
mixingmatrix = WV_;

end % end function
