%RUN_PERM_CHECK_DEMO Generate and inspect perm_check golden vectors.
%
% This script is location-aware. It may be run directly from MATLAB
% without first changing into scripts/matlab/examples.

clear; clc;

this_file = mfilename('fullpath');
examples_dir = fileparts(this_file);
matlab_dir = fileparts(examples_dir);
project_root = fileparts(fileparts(matlab_dir));

addpath(fullfile(matlab_dir, 'models'));
addpath(fullfile(matlab_dir, 'generators'));

out_file = fullfile(project_root, ...
    'tb', 'common', 'golden_vectors', 'perm_check_golden_vectors.csv');

T = generate_perm_check_vectors(out_file);

disp('First 12 generated vectors:');
disp(T(1:12, :));

fprintf('\nCoverage summary:\n');
fprintf('  rows:       %d\n', height(T));
fprintf('  allowed:    %d\n', nnz(T.allow));
fprintf('  faulted:    %d\n', nnz(T.fault));
fprintf('  tt_bypass:  %d\n', nnz(T.tt_bypass));

allowed_by_req = groupsummary(T, 'req_code', 'sum', 'allow');

figure('Name', 'perm_check allow count by request code');
bar(double(allowed_by_req.req_code), allowed_by_req.sum_allow);
grid on;
xlabel('req_code, bit0=R bit1=W bit2=X');
ylabel('allowed cases');
title('soft-mmu-68k perm_check golden vector summary');
