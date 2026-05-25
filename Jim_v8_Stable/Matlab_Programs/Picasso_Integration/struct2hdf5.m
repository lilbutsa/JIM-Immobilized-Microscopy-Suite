function struct2hdf5(data,dataset,fp,fn)
% Author: Isaac Li
% This code is based on sample code from: 
% https://support.hdfgroup.org/HDF5/examples/api18-m.html
% Version 20220209:
% The function takes a struct and write to a compound HDF5 file. the fields
% in the struct will automatically populate in the HDF5.
% Automatically handles single, double, uint 8,16,32 data types, feel free
% to add more in the case structure below if your data has more.
% data - struct
% dataset - dataset name
% fp - filepath
% fn - filename
% This file is intended for use with HDF5 Library version 1.8

	full_fn       = [fp '\' fn];
	dims           = length(data.frame);

	%% Create a new file using the default properties.
	file = H5F.create (full_fn, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');

	%% Create the required data types for each field
	data_fieldnames = fieldnames(data);
	Nfield = length(data_fieldnames);
	for k = 1:Nfield
		switch class(data.(data_fieldnames{k}))
			% For more data types, see:
			% https://support.hdfgroup.org/HDF5/doc1.8/RM/PredefDTypes.html
			case 'single'
				h5_datatype(k) = H5T.copy('H5T_NATIVE_FLOAT');
			case 'double'
				h5_datatype(k) = H5T.copy('H5T_NATIVE_DOUBLE');
			case 'uint32'
				h5_datatype(k) = H5T.copy('H5T_NATIVE_UINT32');
			case 'uint16'
				h5_datatype(k) = H5T.copy('H5T_NATIVE_UINT16');
			case 'uint8'
				h5_datatype(k) = H5T.copy('H5T_NATIVE_UINT8');
            case 'int32'
				h5_datatype(k) = H5T.copy('H5T_NATIVE_INT32');
			otherwise
				error(['struct2hdf5: datatype not recognized, add when needed = ' data_fieldnames{k}]);
		end
		sz(k) = H5T.get_size(h5_datatype(k));
	end

	offset(1)=0;
	offset(2:Nfield) = cumsum(sz(1:(Nfield-1)));

	%% Create the compound datatype for memory.
		memtype = H5T.create ('H5T_COMPOUND', sum(sz));
		for k = 1:Nfield
			H5T.insert (memtype,data_fieldnames{k},offset(k),h5_datatype(k));	
		end

	%% Create the compound datatype for the file.  Because the standard
	% types we are using for the file may have different sizes than
	% the corresponding native types, we must manually calculate the
	% offset of each member.
		filetype = H5T.create ('H5T_COMPOUND', sum(sz));
		for k = 1:Nfield
			H5T.insert (filetype,data_fieldnames{k},offset(k),h5_datatype(k));	
		end

	%% Create dataspace.  Setting maximum size to [] sets the maximum
	% size to be the current size.
		space = H5S.create_simple (1,fliplr(dims), []);

	%% Create the dataset and write the compound data to it.
		dset = H5D.create (file, dataset, filetype, space, 'H5P_DEFAULT');
		H5D.write (dset, memtype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);

	%% Close and release resources.
		H5D.close(dset);
		H5S.close(space);
		H5T.close(filetype);
		H5F.close(file);

	%% debug
	% 	h5disp(full_fn);
end
