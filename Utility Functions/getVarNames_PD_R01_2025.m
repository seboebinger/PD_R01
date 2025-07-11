function varNames = getVarNames_PD_R01_2025()
% loads desired variable names
varNames = {...
...% Caclulated Pert Kinematics (Scalars)
'pertdir_calc_deg'  'pertdir_calc_round_deg'... 
'pertdisp_calc_cm'  'pertvel_calc_cm_s'     'pertacc_calc_g'... 
'platonset'...
...% Misc.
'AnalogFrameRate'   'DigitalFrameRate'      'VideoFrameRate'... 
'atime'             'mtime'                 'mass'...
...% EMG - Filtered
'EMG_SC_R'          'EMG_SC_L'... 
'EMG_MGAS_R'        'EMG_MGAS_L'...
'EMG_SOL_R'         'EMG_SOL_L'...
'EMG_TA_R'          'EMG_TA_L'...
'EMG_BFLH_R'        'EMG_BFLH_L'...
'EMG_VMED_R'        'EMG_VMED_L'...
'EMG_RF_R'          'EMG_RF_L'...
'EMG_GLUTMED_R'     'EMG_GLUTMED_L'...
...% EMG - Raw
'EMG_MGAS_R_raw'    'EMG_MGAS_L_raw'... 
'EMG_SOL_R_raw'     'EMG_SOL_L_raw'...
'EMG_TA_R_raw'      'EMG_TA_L_raw'...
'EMG_BFLH_R_raw'    'EMG_BFLH_L_raw'...
'EMG_VMED_R_raw'    'EMG_VMED_L_raw'... 
'EMG_RF_R_raw'      'EMG_RF_L_raw'...
...% Force Plate
'Left_Fx'   'Left_Fy'   'Left_Fz'...
'Left_Mx'   'Left_My'   'Left_Mz'...
'Right_Fx'  'Right_Fy'  'Right_Fz'...
'Right_Mx'  'Right_My'  'Right_Mz'...
...% Pert Kinematics (time series)
'LVDT_X'                'LVDT_Y'...
'Velocity_X'            'Velocity_Y'...
'Accels_X'              'Accels_Y'...
...% CoM kinematics
'COMPos_X'              'COMPos_Y'...
'COMPosminusLVDT_X'     'COMPosminusLVDT_Y'...
'COMVelo_X'             'COMVelo_Y'...
'COMAccel_X'            'COMAccel_Y'...
...% CoP
'COP_X'                 'COP_Y'};%...
% ...% Joint Angles -- Need to add after 3rd pass
% 'Hip_a_R'               'Hip_a_L'... % a == angle ()
% 'Knee_a_R'              'Knee_a_L'...
% 'Ankle_a_R'             'Ankle_a_L'... 
% 'Hip_a2_R'              'Hip_a2_L'... % a2 == angle ()
% 'Knee_a2_R'             'Knee_a2_L'...
% 'Ankle_a2_R'            'Ankle_a2_L'...
% 'Hip_m_R'               'Hip_m_L'... % m == moment
% 'Knee_m_R'              'Knee_m_L'...
% 'Ankle_m_R'             'Ankle_m_L' ...
% ...% Heel Markers -- needed?
% 'LHEE_Y'                'RHEE_Y'...
% 'LHEE_Z'                'RHEE_Z'};

end