classdef sacfile
   %SACFILE loads sac data into a structure
   %   Detailed explanation goes here
   
   % TODO: Add support for alphanumeric file
   properties
      filename = '/Users/celso/Git/gismotools/GISMO/contributed/test_scripts/test_data/example_sacfile.sac'
      header
      machineformat = '';
      sacformat = 'binary';
      data
      % headerdefinition;
   end
   
   methods
      function obj = sacfile(filename_, sacformat_)
         if exist('filename_','var')
            obj.filename = filename_;
         end
         if ~exist(obj.filename,'file')
            warning('sac:sacfile:noFile','file doesn''t seem to exist: %s',obj.filename);
         end
         if exist('sacformat_','var')
            obj.sacformat = sacformat_;
         end
         % obj.headerdefinition = obj.headerdescription(obj.sacformat);
         obj = obj.loadheader;
         obj = obj.loaddata;
      end
        
      
   end
   methods(Access = private)
      function obj = loadheader(obj)
         if isempty(obj.machineformat)
            obj = obj.setmachineformat;
         end
         assert(~isempty(obj.machineformat), 'First choose a machine format. This will be automated');
         if exist(obj.filename,'file');
            %try
            FID = fopen(obj.filename,'r',obj.machineformat);
            hd = obj.headerdescription(obj.sacformat);
            for n = 1 : numel(hd)
               info = hd(n);
               fseek(FID, info.start,'bof');
               switch info.datatype
                  case 'F'
                     
                     v = fread(FID,1,'float32');
                  case 'I'
                     v = fread(FID,1,'int32');
                     if info.name(1) == 'I' && ~strcmp(info.name(1),'INTERNAL') % enumeration!
                        % fprintf('%s : %d\n',info.name,v);
                        v = sac.sacenums(v);
                     end
                  case 'L'
                     v = fread(FID,1,'int32');
                  case 'K'
                     if info.name(end) == '*'
                        info.name(end) = '';
                        %stupid special case
                        v = fread(FID,16,'uchar');
                     else
                        v = fread(FID,8,'uchar');
                     end
                     v = strtrim(char(v'));
                  otherwise
                     error('erk')
               end
               obj.header.(info.name) = v;
            end
            fclose(FID);
         end
      end
      function obj = loaddata(obj)
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
      function obj = setmachineformat(obj)
         if exist(obj.filename,'file');
            hd = obj.headerdescription(obj.sacformat);
            targfield = hd(strcmp({hd.name},'NVHDR'));
            FID = fopen(obj.filename,'r','ieee-le');
            fseek(FID,targfield.start, 0);
            NVHDR = fread(FID,1,'uint32',0);
            if NVHDR > 10
               obj.machineformat = 'ieee-be';
            else
               obj.machineformat = 'ieee-le';
            end
            fclose(FID);
         end
      end
   end 
   methods(Static)
      function fields = headerdescription(sacformat_)
         % returns an array of structs that contain:
         %     start = offset in bytes
         %     datatype = code for type of data
         %     name = name of field
         persistent headerdefinition
         if isempty(headerdefinition)
            headerdefinition = containers.Map;
         elseif headerdefinition.iskey(sacformat_)
            fields = headerdefinition(sacformat_);
            return
         end
         %either empty or it doesn't contain key.
         wordSizeInBytes = 4;
         fields.start = 0;
         fields.datatype = '';
         fields.name = '';
         fieldLength = containers.Map();
         fieldLength('F') = 4; %bytes
         fieldLength('I') = 4; %bytes
         fieldLength('K')=8;   %bytes
         fieldLength('L')=4;   %bytes
         FID = fopen('+sac/sac_binary_header_definition.txt');
         % read format from tab-delimitede:
         % #COMMENTS
         % STARTWORD TYPE FIELD1 FIELD2 FIELD3 FIELD4 FIELD5
         B = textscan(FID,'%d %c %s %s %s %s %s','commentstyle','#');
         fclose(FID);
         page.offsets = B{1};
         page.types = B{2};
         page.field = [B{3:end}];
         N = 1;
         for pageIdx = 1:numel(page.offsets)
            startIdx = page.offsets(pageIdx) .* wordSizeInBytes;
            datatype = page.types(pageIdx);
            jumpsize = fieldLength(datatype);
            field = page.field(pageIdx,:);
            for fieldIdx = 1 : numel(page.field(pageIdx,:))
               name = field{fieldIdx};
               if ~isempty(name)
                  fields(N).start = startIdx;
                  fields(N).datatype = datatype;
                  fields(N).name = name;
                  N = N + 1;
                  startIdx = startIdx + jumpsize;
               end
            end
         end
      end
   end
   
end

