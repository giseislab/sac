classdef sacfile
   %SACFILE loads sac data into a structure
   %   Detailed explanation goes here
   
   % TODO: Add support for alphanumeric file
   properties
      filename = '/Users/celso/Git/gismotools/GISMO/contributed/test_scripts/test_data/example_sacfile.sac'
      header
      machineformat = 'ieee-le';
      sacformat = 'binary'; % 'binary' or 'alphanumeric'
      data
   end
   
   methods
      function obj = sacfile(filename_, sacformat_)
         disp('sacfile constructor')
         if exist('filename_','var')
            obj.filename = filename_;
         end
         if ~exist(obj.filename,'file')
            warning('sac:sacfile:noFile','file doesn''t seem to exist: %s',obj.filename);
         end
         if exist('sacformat_','var')
            obj.sacformat = sacformat_;
         end
         obj = obj.loadbinaryheader;
         obj = obj.loaddata;
      end
        
      function nslc = locationstring(obj)
         %LOCATIONSTRING gets this network.station.location.channel
         %  whitespac is trimmed
         nslc = [strtrim(obj.header.KNETWK), '.', ...
            strtrim(obj.header.KSTNM), '.',...
            strtrim(obj.header.KHOLE), '.',...
            strtrim(obj.header.KCMPNM)];
      end
      
   end
   methods(Access = private)
      function obj = loadbinaryheader(obj)
         disp('loadbinaryheader')
         if isempty(obj.machineformat)
            obj = obj.setmachineformat;
         end
         assert(~isempty(obj.machineformat), 'First choose a machine format. This will be automated');
         if exist(obj.filename,'file');
            %try
            FID = fopen(obj.filename,'r',obj.machineformat);
            hd = obj.headerDesc(obj.sacformat);
            for n = 1 : numel(hd)
               v = fread(FID,hd(n).count,hd(n).datatype);
               if strcmp(hd(n).datatype,'uchar')
                  v = char(v(:)');
               end
               obj.header.(hd(n).name) = v;
               
            end
            %{
                     v = fread(FID,1,'int32');
                     if info.name(1) == 'I' && ~strcmp(info.name(1),'INTERNAL') % enumeration!
                        % fprintf('%s : %d\n',info.name,v);
                        v = sac.sacenums(v);
                     end
            %}
            fclose(FID);
         end
      end
      function obj = loaddata(obj)
         disp('load data');
         obj.header.NPTS;
         evenly = obj.header.LEVEN;
         FID = fopen(obj.filename,'r',obj.machineformat);
         fseek(FID,158*4,0);
         obj.data.dependent = fread(FID,obj.header.NPTS,'float32');
         if ~evenly
            obj.data.independent = fread(FID,obj.header.NPTS,'float32');
         else
            obj.data.independent = [];
         end
         fclose(FID);
      end
      function obj = learnAboutFile(obj)
         disp('learn about file');
         % determines machine format and header format
         FID = fopen(obj.filename,'r');
         try
         obj.sacformat = determineFormat(fgets(FID,1));
         catch er
            rethrow(er)
         end
         fclose(FID);
         obj = load_headerdescription(obj);

         function myformat = determineFormat(testchar)
            if testchar == char(0)
               myformat = 'binary';
            else
               myformat = 'alphanumeric';
            end
         end
      end
      function obj = setmachineformat(obj)
         FID = fopen(obj.filename,'r',obj.machineformat);
         if ~ obj.hasCorrectMachineformat(fid)
            switch obj.machineformat
               case 'ieee-le'
                  obj.machineformat = 'ieee-be';
               case 'ieee-be'
                  obj.machineformat = 'ieee-le';
            end
         end
         fclose(FID);
      end
      function bool = hasCorrectMachineformat(obj,FID)
         p = ftell(FID);
         headerversion = obj.headerDesc(obj.sacformat, 'NVHDR');
         fseek(FID,targfield.pos,'bof');
         NVHDR = fread(FID, headerversion.count, headerversion.datatype);
         bool = NVHDR < 10;
         seek(FID, p, 'bof');
      end
     
   end
   
   methods(Static)
      function fields = headerDesc(sacformat_, fieldname)
         % headerDesc(sacformat) returns a structure of fields
         %          containing: pos, count, datatype, name
         %
         % headerdesc(sacformat, fieldname) returns only the structure for
         % the requested field.
         
         persistent headerdefinition
         if isempty(headerdefinition)
            headerdefinition = containers.Map;
         elseif headerdefinition.iskey(sacformat_)
            fields = headerdefinition(sacformat_);
            if exist('fieldname','var')
               fields = fields(strcmp({fields.name},fieldname));
            end
            return
         end
         
         
         FID = fopen('+sac/sac_binary_header_desc.txt');
         try
         B = textscan(FID,'%d %d %s %s','commentstyle','#');
         catch er
            rethrow(er);
         end
         fclose(FID);
         for n = 1 : numel(B{1})
            fields(n).pos = B{1}(n); % offset in file
            fields(n).count = B{2}(n); % number of elements to read
            fields(n).datatype = B{3}{n}; % datatype read from disk
            fields(n).name = B{4}{n};
         end
         if exist('fieldname','var')
            fields = fields(strcmp({fields.name},fieldname));
         end
      end
   end
   
end

